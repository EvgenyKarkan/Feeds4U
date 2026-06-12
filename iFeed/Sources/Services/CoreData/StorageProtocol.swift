//
//  StorageProtocol.swift
//  iFeed
//
//  Created by Evgeny Karkan on 26.03.2024.
//  Copyright © 2024 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData.NSManagedObject
import CoreData.NSManagedObjectID
#if DEBUG
import Mocking
#endif

// MARK: - StorageError
enum StorageError: LocalizedError {
    case feedCreationFailed

    var errorDescription: String? {
        switch self {
        case .feedCreationFailed:
            return String.localized(key: LocalizableKeys.Errors.feedCreationFailed)
        }
    }
}

/// Defines the app's storage facade for feeds and feed items.
///
/// `StorageProtocol` hides Core Data implementation details from modules such as
/// parsing, search, and feed presentation. Methods intentionally keep legacy
/// error behavior: some fetches return empty collections or `nil` instead of
/// throwing because existing callers treat storage failures as empty state.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol StorageProtocol {
    /// Loads every saved feed.
    ///
    /// - Returns: Saved feeds, or an empty array when storage cannot fetch them.
    func loadFeeds() -> [Feed]

    /// Loads every saved feed item.
    ///
    /// - Returns: Saved feed items, or `nil` when storage cannot fetch them.
    func loadFeedItems() -> [FeedItem]?

    /// Loads specific feed items by their object IDs in a single fetch.
    ///
    /// IDs of deleted objects are silently omitted and duplicate IDs collapse
    /// into one object. Result order is newest-first, not input order.
    func loadFeedItems(withIDs objectIDs: [NSManagedObjectID]) -> [FeedItem]

    /// Loads the items of a single feed, newest first.
    ///
    /// Sorting (publish date descending, link ascending as a deterministic
    /// tie-break) happens at the SQL level and results are batched, so callers
    /// never pay for materialising the whole relationship in memory.
    ///
    /// - Parameter feed: Feed whose items should be loaded.
    /// - Returns: The feed's items, or an empty array when the fetch fails.
    func feedItems(for feed: Feed) -> [FeedItem]

    /// Returns the number of unread items in `feed` using `COUNT(*)` —
    /// no managed objects are materialised.
    func unreadCount(for feed: Feed) -> Int

    /// Returns the total number of items in `feed` using `COUNT(*)`.
    ///
    /// Unlike reading `feed.feedItems.count`, this never fires the to-many
    /// relationship fault, so no item objects are materialised.
    func itemCount(for feed: Feed) -> Int

    /// Re-faults `item`'s content row, releasing its article HTML from memory.
    ///
    /// Call after the HTML has been handed off (e.g. copied into the article
    /// reader) — the next `htmlContent` read transparently re-fetches it.
    /// A no-op when the content is already a fault or carries unsaved changes
    /// (re-faulting would discard them).
    func releaseContent(of item: FeedItem)

    /// Marks every unread item of `feed` as read using a batch update that
    /// runs directly in the store; affected objects are merged back into the
    /// context so in-memory state stays consistent.
    func markAllAsRead(in feed: Feed)

    /// Returns the feed displayed at a table index path.
    ///
    /// - Parameter indexPath: Index path from a feed list table view.
    /// - Returns: The feed at `indexPath.row`, or `nil` when the row is invalid.
    func feed(at indexPath: IndexPath) -> Feed?

    /// Persists pending changes in the storage context.
    func saveChanges()

    /// Checks whether a feed with the supplied RSS URL is already stored.
    ///
    /// - Parameter rssURL: Absolute RSS URL string to look up.
    /// - Returns: `true` when a saved feed has the same RSS URL.
    func containsFeed(withRSSURL rssURL: String) -> Bool

    /// Returns unread item counts grouped by feed object ID.
    func unreadCountsByFeed() -> [NSManagedObjectID: Int]

    /// Loads only titles and object IDs for all feed items on a background
    /// context. Used for memory-efficient search indexing.
    ///
    /// `completion` is always invoked **on the main actor** with the index, or
    /// `nil` when the fetch failed — see `importFeed` for why the closure type
    /// is plain `@Sendable`.
    func fetchFeedItemIndex(_ completion: @escaping @Sendable ([(title: String, objectID: NSManagedObjectID)]?) -> Void)

    /// Returns all saved RSS URLs.
    func savedFeedURLs() -> Set<String>

    /// Creates and inserts a new `Feed` managed object into the storage context.
    ///
    /// The returned object is unsaved until `saveChanges()` is called.
    func makeFeed() -> Feed?

    /// Creates and inserts a new `FeedItem` managed object into the storage context.
    ///
    /// The returned object is unsaved until `saveChanges()` is called.
    func makeFeedItem() -> FeedItem?

    /// Marks a managed object for deletion from the storage context.
    ///
    /// The deletion is not persisted until `saveChanges()` is called.
    ///
    /// - Parameter object: Managed object to delete.
    func delete(_ object: NSManagedObject)

    /// Returns the feed with the given object ID from the view context, or `nil`
    /// when no such object exists. Must be called on the main queue.
    func loadFeed(withID id: NSManagedObjectID) -> Feed?

    /// Runs `callback` once the persistent store is available — synchronously
    /// when it is already loaded, otherwise on the main queue right after the
    /// asynchronous store load finishes. Use this to refresh UI that was built
    /// before the store came online at launch.
    func performWhenStoreReady(_ callback: @escaping @Sendable () -> Void)

    /// Imports a parsed feed with all its items on a background context and saves.
    ///
    /// Heavy entity creation happens off the main thread. `completion` is always
    /// invoked **on the main actor** with the saved feed's object ID, or `nil`
    /// when the import failed. (The closure is typed `@Sendable` rather than
    /// `@MainActor` because mock generation cannot carry the isolation attribute;
    /// callers may rely on main-actor delivery via `MainActor.assumeIsolated`.)
    func importFeed(_ data: ParsedFeedData,
                    rssURL: String,
                    completion: @escaping @Sendable (NSManagedObjectID?) -> Void)

    /// Merges parsed items into an existing feed on a background context,
    /// persisting only entries that are genuinely new: an entry is skipped
    /// when its link is already stored, or when its title and publish date
    /// both match an existing item (a republish under a new URL).
    ///
    /// `completion` is always invoked **on the main actor** once the merge (and
    /// save) finished — see `importFeed` for why the type is plain `@Sendable`.
    func refreshFeedItems(with items: [ParsedFeedItemData],
                          forFeedWith feedID: NSManagedObjectID,
                          completion: @escaping @Sendable () -> Void)
}
