//
//  Search.swift
//  iFeed
//
//  Created by Julius Bahr on 22.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData

/// Performs local search over feed items using a text matching engine
///
/// This struct provides full-text search capabilities across all feed items stored in Core Data.
/// It uses a `MatchingEngine` to perform fuzzy text matching with configurable thresholds.
///
/// **Usage Pattern:**
/// 1. Call `fillMatchingEngine(completion:)` to index all feed items
/// 2. Call `search(for:resultsFound:)` to perform searches
///
/// **Performance:**
/// - Indexing: O(n) where n is the number of feed items
/// - Searching: O(log n) with matching engine optimizations
/// - Results are sorted by publish date (newest first)
struct Search {

    // MARK: - Private Properties

    /// The text matching engine that performs fuzzy search
    ///
    /// This engine must be filled before searches can be performed.
    /// It indexes feed item titles for fast lookup.
    private var matchingEngine: MatchingEngine?

    /// Core Data manager for accessing feed items
    ///
    /// Reused instance to avoid creating multiple managers.
    private let coreDataManager = Brain.brain.coreDater

    // MARK: - Public API

    /// Fills the matching engine with all available feed items
    ///
    /// This method fetches all feed items from Core Data and indexes their titles
    /// in the matching engine for subsequent search operations.
    ///
    /// **Process:**
    /// 1. Fetches all feed items from Core Data
    /// 2. Converts feed items to `TextualData` objects
    /// 3. Indexes the data in the matching engine
    /// 4. Calls completion when indexing is complete
    ///
    /// **Performance:**
    /// - Time complexity: O(n) where n is the number of feed items
    /// - Should be called on a background queue for large datasets
    ///
    /// - Parameter completion: Called when indexing completes (on arbitrary queue)
    ///
    /// - Important: This method must complete successfully before calling `search(for:resultsFound:)`.
    ///              If no feed items exist, completion is called immediately.
    mutating func fillMatchingEngine(completion: @escaping () -> Void) {
        // Fetch all feed items from Core Data
        guard let allFeedItems = coreDataManager.allFeedItems(), !allFeedItems.isEmpty else {
            completion()
            return
        }

        // Convert feed items to TextualData objects for indexing
        // Using compactMap with explicit type would be more robust, but map is fine here
        // since we're creating TextualData for every item
        let textualData = allFeedItems.map { feedItem -> TextualData in
            TextualData(
                inputString: feedItem.title,
                origin: nil,
                originObject: feedItem
            )
        }

        // Initialize and fill the matching engine
        matchingEngine = MatchingEngine()
        matchingEngine?.fillMatchingEngine(
            with: textualData,
            onlyRemoveFrequentStopwords: true,
            completion: completion
        )
    }

    /// Searches for feed items matching the given search term
    ///
    /// Performs fuzzy text matching against indexed feed item titles and returns
    /// matching items sorted by publish date (newest first).
    ///
    /// **Matching Behavior:**
    /// - Uses fuzzy matching with a threshold of 0.005 (adjustable)
    /// - Matches are case-insensitive
    /// - Stop words are filtered during indexing
    /// - Multiple feed items can have the same title (different feeds, different content)
    ///
    /// **Performance:**
    /// - Search: O(log n) with matching engine
    /// - Sorting: O(m log m) where m is the number of results
    /// - Deduplication: O(m) where m is the number of results
    ///
    /// - Parameters:
    ///   - searchTerm: The text to search for in feed item titles
    ///   - resultsFound: Closure called with matching feed items, or nil if no matches
    ///
    /// - Important: `fillMatchingEngine(completion:)` must be called first.
    ///              If the engine isn't filled, `resultsFound` will be called with nil.
    ///
    /// **Example:**
    /// ```swift
    /// var search = Search()
    /// search.fillMatchingEngine {
    ///     search.search(for: "Swift") { results in
    ///         if let items = results {
    ///             print("Found \(items.count) items")
    ///         }
    ///     }
    /// }
    /// ```
    func search(for searchTerm: String, resultsFound: ([FeedItem]?) -> Void) {
        // Verify the matching engine is ready
        guard matchingEngine?.isFilled ?? false else {
            resultsFound(nil)
            return
        }

        // Create a query from the search term
        let query = TextualData(
            inputString: searchTerm,
            origin: nil,
            originObject: nil
        )

        // Perform the search with a relevance threshold of 0.005
        // Lower threshold = more permissive matching
        try? matchingEngine?.results(betterThan: 0.005, for: query) { results in
            guard let results = results, !results.isEmpty else {
                resultsFound(nil)
                return
            }

            // Convert textual results back to FeedItem objects
            // Use flatMap to flatten nested arrays and compactMap to filter out non-FeedItem objects
            let feedItems: [FeedItem] = results.flatMap { result in
                result.textualResults.compactMap { textualData in
                    textualData.originObject as? FeedItem
                }
            }

            // Guard against empty results after conversion
            guard !feedItems.isEmpty else {
                resultsFound(nil)
                return
            }

            // Remove duplicate references to the same Core Data object
            // This can happen if the matching engine returns the same result multiple times
            // Note: Feed items with the same title but different objectIDs are kept (different articles)
            var uniqueFeedItems: [FeedItem] = []
            var seenObjectIDs = Set<NSManagedObjectID>()

            for item in feedItems {
                // insert(_:) returns (inserted: Bool, memberAfterInsert: Element)
                // We only append if this objectID hasn't been seen before
                if seenObjectIDs.insert(item.objectID).inserted {
                    uniqueFeedItems.append(item)
                }
            }

            // Sort by publish date (newest first)
            let sortedItems = uniqueFeedItems.sorted { $0.publishDate > $1.publishDate }

            resultsFound(sortedItems)
        }
    }
}
