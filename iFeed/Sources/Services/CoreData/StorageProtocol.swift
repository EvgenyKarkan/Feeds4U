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

/// Provides factory methods for app-owned Core Data entities.
protocol EntityCreating {
    /// Creates and inserts a new `Feed` managed object into the storage context.
    ///
    /// The returned object is unsaved until `saveChanges()` is called.
    func makeFeed() -> Feed?

    /// Creates and inserts a new `FeedItem` managed object into the storage context.
    ///
    /// The returned object is unsaved until `saveChanges()` is called.
    func makeFeedItem() -> FeedItem?
}

/// Provides deletion support for managed objects owned by the storage context.
protocol EntityDeleting {
    /// Marks a managed object for deletion from the storage context.
    ///
    /// The deletion is not persisted until `saveChanges()` is called.
    ///
    /// - Parameter object: Managed object to delete.
    func delete(_ object: NSManagedObject)
}

/// Defines the app's storage facade for feeds and feed items.
///
/// `StorageProtocol` hides Core Data implementation details from modules such as
/// parsing, search, and feed presentation. Methods intentionally keep legacy
/// error behavior: some fetches return empty collections or `nil` instead of
/// throwing because existing callers treat storage failures as empty state.
protocol StorageProtocol: EntityCreating, EntityDeleting {
    /// Loads every saved feed.
    ///
    /// - Returns: Saved feeds, or an empty array when storage cannot fetch them.
    func loadFeeds() -> [Feed]

    /// Loads every saved feed item.
    ///
    /// - Returns: Saved feed items, or `nil` when storage cannot fetch them.
    func loadFeedItems() -> [FeedItem]?

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

    /// Returns all saved RSS URLs.
    func savedFeedURLs() -> Set<String>
}
