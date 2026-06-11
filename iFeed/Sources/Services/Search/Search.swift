//
//  Search.swift
//  iFeed
//
//  Created by Julius Bahr on 22.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData
import SimpleSimilarity
#if DEBUG
import Mocking
#endif

// MARK: - TextMatching

/// A narrow abstraction over `SimpleSimilarity.MatchingEngine` that enables dependency injection
/// and unit testing without pulling in the real engine.
///
/// ``Search`` only needs three capabilities from the underlying engine:
/// - knowing whether it has been indexed yet (`isFilled`)
/// - populating its text corpus (`fillMatchingEngine(with:onlyRemoveFrequentStopwords:completion:)`)
/// - executing a scored fuzzy query (`results(betterThan:for:resultsFound:)`)
///
/// Keeping the protocol surface minimal means tests can stub every behaviour with a lightweight mock
/// and production code is shielded from future API changes in `SimpleSimilarity`.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol TextMatching {

    /// `true` once the engine has been given a text corpus and is ready to answer queries.
    ///
    /// Calling `results(betterThan:for:resultsFound:)` before this flag is `true` throws
    /// `MatchingEngineNotFilledError`.
    var isFilled: Bool { get }

    /// Builds the internal search index from the supplied text corpus.
    ///
    /// The operation is performed asynchronously on an internal queue managed by `SimpleSimilarity`.
    /// `completion` is called — on an arbitrary background queue — once indexing finishes.
    ///
    /// - Parameters:
    ///   - corpus: The collection of textual entries to index. Each entry's `inputString` is
    ///     tokenised and weighted; `originObject` is carried through unchanged so callers can
    ///     map results back to their source objects (e.g. `NSManagedObjectID`).
    ///   - onlyRemoveFrequentStopwords: Pass `true` to strip only the highest-frequency stop words
    ///     (recommended for short feed titles). Pass `false` for aggressive stop-word removal.
    ///   - completion: Called on an arbitrary queue when indexing has finished. The engine is safe
    ///     to query immediately after this closure executes.
    func fillMatchingEngine(with corpus: [TextualData], onlyRemoveFrequentStopwords: Bool, completion: @escaping () -> Void)

    /// Queries the engine and returns all results whose similarity score exceeds a threshold.
    ///
    /// Results are delivered asynchronously via `resultsFound`. Each `Result` in the array
    /// contains a ranked list of `TextualData` entries and an overall quality score.
    ///
    /// - Parameters:
    ///   - betterThan: The minimum similarity score (0.0 – 1.0) a result must reach to be
    ///     included. Lower values return more (potentially weaker) matches; higher values
    ///     restrict results to strong matches only.
    ///   - query: A `TextualData` whose `inputString` is the user's search term.
    ///   - resultsFound: Called asynchronously with the ranked results, or `nil` when no entry
    ///     in the corpus scores above `betterThan`.
    /// - Throws: `MatchingEngineNotFilledError` if the engine has not been indexed yet.
    func results(betterThan: Float, for query: TextualData, resultsFound: @escaping ([Result]?) -> Void) throws
}

/// Retroactive conformance — `MatchingEngine` already satisfies every ``TextMatching`` requirement,
/// so no additional implementation is needed.
extension MatchingEngine: TextMatching {}

/// A closure that creates a brand-new ``TextMatching`` engine on demand.
///
/// Using a factory rather than a stored engine instance allows ``Search`` to recreate the
/// engine whenever a rebuild is required, which keeps the indexing state consistent even
/// if the caller triggers re-indexing multiple times.
/// In tests, the factory simply returns the injected mock.
typealias MatchingEngineFactory = () -> any TextMatching

// MARK: - Search

/// A facade that provides full-text search over all `FeedItem` records in Core Data.
///
/// `Search` wraps the callback-based `SimpleSimilarity.MatchingEngine` behind a clean `async/await`
/// interface and handles the two-phase lifecycle that fuzzy search requires:
///
/// **Phase 1 — Index:** call `fillMatchingEngine()` to build the search index. Only `FeedItem`
/// titles are indexed; full objects are **not** loaded at this stage, keeping memory usage
/// proportional to the number of titles rather than to the full object graph. The index is
/// rebuilt lazily: once built, subsequent calls are no-ops until ``markIndexDirty()`` flags
/// the corpus as changed, so searching repeatedly does not pay for re-indexing.
///
/// **Phase 2 — Query:** call `search(for:)` as many times as needed. Each call wraps the engine's
/// asynchronous callback in a `CheckedContinuation` and materialises only the matching
/// `FeedItem` objects on the `@MainActor` using their `NSManagedObjectID`s, which are safe to
/// pass across actor boundaries.
///
/// **Concurrency model:**
/// Both `fillMatchingEngine()` and `search(for:)` are marked `@MainActor` via the ``Searchable``
/// protocol, so they always run on the main actor. The underlying `SimpleSimilarity` callbacks
/// may fire on a background thread internally, but the continuation bridge re-enters the main actor
/// before any `NSManagedObject` is touched.
///
/// **Usage:**
/// ```swift
/// let search = Search(storage: coreDataManager)
/// await search.fillMatchingEngine()            // build index (no-op when already clean)
/// let results = await search.search(for: "Swift concurrency")  // query
/// search.markIndexDirty()                      // after feeds/items change
/// ```
///
/// **Performance summary:**
/// | Operation    | Complexity                                  |
/// |--------------|---------------------------------------------|
/// | Indexing     | O(n) — n = number of feed items             |
/// | Query        | O(log n) — engine uses an inverted index    |
/// | Sorting      | O(m log m) — m = number of matching items   |
/// | Deduplication| O(m)                                        |
///
/// A `@MainActor` reference type shared through the DI container, so every module
/// talks to the same index and a single dirty flag invalidates it for all of them.
@MainActor
final class Search {

    // MARK: - Private Properties

    /// The lazily created text matching engine.
    ///
    /// `nil` until `fillMatchingEngine()` has been called at least once. A fresh instance is
    /// created on every rebuild so that re-indexing is always clean —
    /// there is no partial-update API in `SimpleSimilarity`.
    private var matchingEngine: (any TextMatching)?

    /// `true` when the feed-item corpus has changed since the last successful indexing.
    ///
    /// Starts `true` so the first `fillMatchingEngine()` call always builds the index;
    /// reset to `false` after a successful fill and flipped back by ``markIndexDirty()``.
    private var needsReindex = true

    /// The storage layer used to read feed data from Core Data.
    ///
    /// Injected at init time so the same `CoreDataManager` instance that the rest of the app uses
    /// is reused here, avoiding duplicate persistent store connections.
    private let storage: any StorageProtocol

    /// Creates the underlying `TextMatching` engine when indexing begins.
    ///
    /// Stored as a factory rather than a pre-built engine so that tests can inject a mock without
    /// subclassing or global state, and so that `Search` can remain a value type.
    private let matchingEngineFactory: MatchingEngineFactory

    // MARK: - Init

    /// Creates a new `Search` instance bound to the given storage layer.
    ///
    /// - Parameters:
    ///   - storage: The storage facade used to load the feed-item index and to materialise
    ///     matched `FeedItem` objects after a query.
    ///   - matchingEngineFactory: A closure that produces a fresh ``TextMatching`` engine.
    ///     Defaults to `{ MatchingEngine() }` in production; pass a closure returning a mock in
    ///     tests to avoid spinning up the real engine.
    init(storage: any StorageProtocol, matchingEngineFactory: @escaping MatchingEngineFactory = { MatchingEngine() }) {
        self.storage = storage
        self.matchingEngineFactory = matchingEngineFactory
    }
}

// MARK: - Searchable
extension Search: Searchable {

    /// Builds the full-text search index from every `FeedItem` currently in the store.
    ///
    /// Calling it replaces any previously built engine with a fresh one populated from the
    /// current corpus. It suspends the caller until the `SimpleSimilarity` engine has
    /// finished indexing. When an index already exists and ``markIndexDirty()`` has not
    /// been called since it was built, the method returns immediately without re-indexing.
    ///
    /// **Why index only titles?**
    /// Fetching every `FeedItem` as a fully materialised `NSManagedObject` would load all
    /// relationships, binary data, and change-tracking overhead into memory. Instead,
    /// `fetchFeedItemIndex(_:)` returns a lightweight `(title, objectID)` tuple for each
    /// item — no relationships, no faults — and runs its fetch on a background context,
    /// so even a large corpus never blocks the main thread while indexing starts.
    ///
    /// **Why store `NSManagedObjectID` in `originObject`?**
    /// `TextualData.originObject` is an `AnyObject?` slot that `SimpleSimilarity` carries through
    /// unchanged. Storing the `NSManagedObjectID` here lets `search(for:)` later retrieve the
    /// matching IDs directly from the engine's results without maintaining a separate lookup table.
    ///
    /// **Concurrency bridge:**
    /// `SimpleSimilarity.MatchingEngine.fillMatchingEngine(with:…)` is callback-based and fires its
    /// completion on an internal background queue. `withCheckedContinuation` bridges this into
    /// structured concurrency: the `@MainActor`-isolated `fillMatchingEngine()` suspends, the
    /// engine indexes on its own queue, and then the continuation resumes back on the main actor.
    ///
    /// **Process:**
    /// 1. Loads a lightweight `(title, objectID)` index from Core Data via `StorageProtocol`
    ///    (the fetch itself runs on a background context; the result arrives on the main actor)
    /// 2. Maps each entry to a `TextualData` object, embedding the `NSManagedObjectID` for later retrieval
    /// 3. Creates a fresh engine via the injected factory
    /// 4. Passes the corpus to the engine and suspends until the callback fires
    ///
    /// - Important: If `fetchFeedItemIndex(_:)` delivers `nil` or an empty array, the method returns
    ///   immediately and the engine is left in its previous state (or remains `nil` if never filled).
    func fillMatchingEngine() async {
        // Skip the rebuild when the index is current — searching repeatedly must not
        // re-fetch every title and re-index the whole corpus.
        guard needsReindex || matchingEngine == nil else {
            return
        }

        // Bridge the callback-based index fetch into async/await. Storage
        // contractually delivers the callback on the main actor, and only
        // Sendable values (strings and object IDs) cross the boundary.
        let itemIndex: [(title: String, objectID: NSManagedObjectID)]? = await withCheckedContinuation { continuation in
            storage.fetchFeedItemIndex { index in
                continuation.resume(returning: index)
            }
        }

        guard let itemIndex, !itemIndex.isEmpty else {
            // Nothing to index — either the store is empty or the fetch failed.
            // Returning early avoids creating a useless empty engine.
            return
        }

        // Map each (title, objectID) index entry to a TextualData value.
        // `inputString` is what the engine tokenises and scores; `originObject` is an opaque
        // pass-through slot — we store the NSManagedObjectID so that search results can be
        // mapped back to FeedItem objects without an extra lookup.
        let textualData = itemIndex.map { entry -> TextualData in
            TextualData(
                inputString: entry.title,
                origin: nil,
                originObject: entry.objectID
            )
        }

        // Always create a new engine instance so re-indexing starts clean.
        // SimpleSimilarity has no incremental-update API, so a full rebuild is the only option.
        matchingEngine = matchingEngineFactory()

        // Bridge the callback-based engine API into async/await.
        // The continuation body is non-`@Sendable`, so capturing `matchingEngine`
        // here is safe — no data race is possible.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            matchingEngine?.fillMatchingEngine(
                with: textualData,
                onlyRemoveFrequentStopwords: true,  // strip only the noisiest stop words for short titles
                completion: { continuation.resume() }
            )
        }

        // Index is current again — subsequent fills are no-ops until the corpus changes.
        needsReindex = false
    }

    /// Flags the index as stale after the feed-item corpus changed
    /// (feed added, refreshed, or deleted). The next ``fillMatchingEngine()``
    /// call performs a full rebuild.
    func markIndexDirty() {
        needsReindex = true
    }

    /// Returns feed items whose titles fuzzy-match the given search term, sorted newest-first.
    ///
    /// The method is split into two clearly separated phases to respect Swift 6's strict
    /// actor-isolation rules for `NSManagedObject`:
    ///
    /// **Phase A — ID extraction (inside the continuation callback):**
    /// The `SimpleSimilarity` results callback fires on an arbitrary background thread. At this
    /// point only `NSManagedObjectID` values are extracted from the results — these are `Sendable`
    /// and safe to cross actor boundaries. No `NSManagedObject` is touched here.
    ///
    /// **Phase B — Object materialisation (after the continuation, on `@MainActor`):**
    /// Back on the main actor, `loadFeedItems(withIDs:)` uses the view context to turn the IDs
    /// into fully faulted `FeedItem` objects. Accessing managed objects only from the main actor
    /// keeps Core Data concurrency rules satisfied.
    ///
    /// **Why 0.005 as the similarity threshold?**
    /// `SimpleSimilarity` scores range from 0.0 to 1.0. A threshold of 0.005 is intentionally
    /// permissive: it admits weak matches so that single-word queries against multi-word titles
    /// still surface relevant results. This value was chosen empirically for feed-item titles and
    /// can be adjusted if recall/precision needs change.
    ///
    /// **Why deduplicate?**
    /// The engine may place the same corpus entry in multiple scored result buckets when a title
    /// matches different aspects of the query. Deduplication by `objectID` ensures each feed item
    /// appears at most once in the returned array.
    ///
    /// - Parameters:
    ///   - searchTerm: The user-supplied text to search for in feed item titles.
    ///
    /// - Returns: An array of matching `FeedItem` objects sorted by `publishDate` descending,
    ///   or `nil` when the engine is unfilled, no items score above the threshold, or all matched
    ///   IDs fail to load from the store.
    ///
    /// - Important: `fillMatchingEngine()` must be called before this method. Calling it on an
    ///   unfilled engine returns `nil` immediately without querying the engine.
    @MainActor func search(for searchTerm: String) async -> [FeedItem]? {
        // Bail out early if the engine was never created or its index is empty.
        // This prevents a `MatchingEngineNotFilledError` throw below.
        guard let engine = matchingEngine, engine.isFilled else {
            return nil
        }

        // Wrap the search term in a TextualData query object.
        // `origin` and `originObject` are nil because a query has no backing store entity —
        // only corpus entries need an originObject for result mapping.
        let query = TextualData(
            inputString: searchTerm,
            origin: nil,
            originObject: nil
        )

        // Phase A: run the engine query and extract NSManagedObjectIDs.
        //
        // The `resultsFound` closure fires on a background thread managed by SimpleSimilarity.
        // We must not touch any NSManagedObject here. Only NSManagedObjectID — which is
        // Sendable and context-independent — is extracted and handed to the continuation.
        //
        // The `do/catch` handles `MatchingEngineNotFilledError`; in normal operation the guard
        // above prevents this, but the catch makes the path explicit and safe.
        let objectIDs: [NSManagedObjectID]? = await withCheckedContinuation { continuation in
            do {
                try engine.results(betterThan: 0.005, for: query) { results in
                    guard let results, !results.isEmpty else {
                        // Engine found nothing above the threshold — signal no match.
                        continuation.resume(returning: nil)
                        return
                    }
                    // Flatten all result entries and collect their embedded NSManagedObjectIDs.
                    // `compactMap` silently skips any entry whose originObject is not an ID
                    // (e.g. the query object itself, which has originObject == nil).
                    let ids = results.flatMap { result in
                        result.textualResults.compactMap { $0.originObject as? NSManagedObjectID }
                    }
                    continuation.resume(returning: ids.isEmpty ? nil : ids)
                }
            } catch {
                // Engine threw (e.g. not filled) — treat as no results.
                continuation.resume(returning: nil)
            }
        }

        // If the engine produced no usable IDs, there is nothing to return.
        guard let objectIDs else { return nil }

        // Phase B: materialise FeedItem objects on @MainActor.
        //
        // `loadFeedItems(withIDs:)` fetches from the view context, which must only be accessed
        // on the main thread. We are guaranteed to be on @MainActor here because `search(for:)`
        // is isolated to @MainActor via the Searchable protocol.
        let matchedItems = storage.loadFeedItems(withIDs: objectIDs)
        guard !matchedItems.isEmpty else { return nil }

        // Deduplicate by objectID: the engine may return the same item from multiple
        // Result entries (e.g. when a title matches several scored buckets).
        // Insertion-order is preserved so the subsequent sort is the only ordering applied.
        var uniqueFeedItems: [FeedItem] = []
        var seenObjectIDs = Set<NSManagedObjectID>()
        for item in matchedItems {
            if seenObjectIDs.insert(item.objectID).inserted {
                uniqueFeedItems.append(item)
            }
        }

        // Sort newest-first so the caller always receives a predictable, date-ordered list
        // regardless of the order the engine returned the matches.
        return uniqueFeedItems.sorted { $0.publishDate > $1.publishDate }
    }
}
