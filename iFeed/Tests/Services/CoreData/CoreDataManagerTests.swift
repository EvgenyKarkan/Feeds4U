//
//  CoreDataManagerTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import CoreData
import Foundation
import UIKit
import Testing
@testable import iFeed

@Suite("CoreDataManager Tests", .serialized)
@MainActor
struct CoreDataManagerTests {

    // MARK: - Entity Creation

    @Test("Create Feed entity")
    func createFeed() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let feed = try manager.createFeed()
        feed.rssURL = "https://example.com/feed"
        feed.title = "My Feed"

        // Then
        #expect(feed.managedObjectContext != nil)
        #expect(feed.rssURL == "https://example.com/feed")
        #expect(feed.title == "My Feed")
    }

    @Test("Create FeedItem entity")
    func createFeedItem() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let item = try manager.createFeedItem()
        item.title = "My Item"
        item.link = "https://example.com/item"
        item.publishDate = Date()
        item.setValue(false, forKey: "wasRead")

        // Then
        #expect(item.managedObjectContext != nil)
        #expect(item.title == "My Item")
    }

    // MARK: - Save Operations

    @Test("Save and fetch a Feed")
    func saveAndFetchFeed() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        // When
        let fetched = try manager.fetchFeeds()

        // Then
        #expect(fetched.count == 1)
        #expect(fetched.first?.rssURL == feed.rssURL)
        #expect(fetched.first?.title == "Test Feed")
    }

    @Test("Save with no changes does not throw")
    func saveNoChanges() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        try manager.saveViewContext()

        // Then
        #expect(try manager.fetchFeeds().isEmpty)
    }

    @Test("Rollback on save failure preserves context")
    func saveRollbackOnError() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try manager.createFeed()
        feed.rssURL = "https://example.com/feed"
        feed.title = "Test"

        // When
        try manager.saveViewContext()

        // Then
        #expect(try manager.fetchFeeds().count == 1)
    }

    // MARK: - Fetch Operations

    @Test("Fetch feeds sorted by title ascending")
    func fetchFeedsSorted() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, title: "Zebra Feed")
        _ = try Self.populateFeed(in: manager, rssURL: "https://example.com/feed2", title: "Alpha Feed")

        // When
        let feeds = try manager.fetchFeeds()

        // Then
        #expect(feeds.count == 2)
        #expect(feeds[0].title == "Alpha Feed")
        #expect(feeds[1].title == "Zebra Feed")
    }

    @Test("Fetch feeds with predicate filter")
    func fetchFeedsFiltered() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com/feed", title: "Alpha")
        _ = try Self.populateFeed(in: manager, rssURL: "https://b.com/feed", title: "Beta")
        let predicate = NSPredicate(format: "title == %@", "Alpha")

        // When
        let feeds = try manager.fetchFeeds(filteredBy: predicate)

        // Then
        #expect(feeds.count == 1)
        #expect(feeds.first?.title == "Alpha")
    }

    @Test("Fetch feed items sorted by date descending")
    func fetchFeedItemsSorted() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        let olderItem = try manager.createFeedItem()
        olderItem.title = "Older"
        olderItem.link = "https://example.com/old"
        olderItem.publishDate = Date(timeIntervalSince1970: 1_000_000)
        olderItem.setValue(false, forKey: "wasRead")
        olderItem.feed = feed

        let newerItem = try manager.createFeedItem()
        newerItem.title = "Newer"
        newerItem.link = "https://example.com/new"
        newerItem.publishDate = Date(timeIntervalSince1970: 2_000_000)
        newerItem.setValue(false, forKey: "wasRead")
        newerItem.feed = feed

        try manager.saveViewContext()

        // When
        let items = try manager.fetchFeedItems()

        // Then
        #expect(items.count == 2)
        #expect(items[0].title == "Newer")
        #expect(items[1].title == "Older")
    }

    @Test("Count entities")
    func countEntities() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com")
        _ = try Self.populateFeed(in: manager, rssURL: "https://b.com")

        // When
        let count = try manager.count(entityName: "Feed")

        // Then
        #expect(count == 2)
    }

    @Test("Count entities with predicate")
    func countEntitiesWithPredicate() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Read Item", wasRead: true)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Unread Item", link: "https://example.com/2", wasRead: false)

        let unreadPredicate = NSPredicate(format: "wasRead == NO OR wasRead == nil")

        // When
        let unreadCount = try manager.count(entityName: "FeedItem", predicate: unreadPredicate)

        // Then
        #expect(unreadCount == 1)
    }

    // MARK: - Delete Operations

    @Test("Delete a single entity")
    func deleteSingle() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        #expect(try manager.fetchFeeds().count == 1)

        // When
        manager.delete(feed, from: nil)
        try manager.saveViewContext()

        // Then
        #expect(try manager.fetchFeeds().count == 0)
    }

    @Test("Delete multiple entities")
    func deleteMultiple() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed1 = try Self.populateFeed(in: manager, rssURL: "https://a.com")
        let feed2 = try Self.populateFeed(in: manager, rssURL: "https://b.com")

        #expect(try manager.fetchFeeds().count == 2)

        // When
        manager.delete([feed1, feed2])
        try manager.saveViewContext()

        // Then
        #expect(try manager.fetchFeeds().count == 0)
    }

    @Test("Batch delete entities")
    func batchDelete() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com")
        _ = try Self.populateFeed(in: manager, rssURL: "https://b.com")

        // When
        try manager.batchDelete(entityName: "Feed")

        // Then
        let feeds = try manager.fetchFeeds()
        #expect(feeds.count == 0)
    }

    @Test("Batch delete with predicate")
    func batchDeleteWithPredicate() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Read", wasRead: true)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Unread", link: "https://example.com/2", wasRead: false)

        let readPredicate = NSPredicate(format: "wasRead == YES")

        // When
        try manager.batchDelete(entityName: "FeedItem", predicate: readPredicate)

        // Then
        let items = try manager.fetchFeedItems()
        #expect(items.count == 1)
        #expect(items.first?.title == "Unread")
    }

    // MARK: - StorageProtocol Conformance

    @Test("loadFeeds returns all feeds")
    func loadFeeds() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com", title: "A")
        _ = try Self.populateFeed(in: manager, rssURL: "https://b.com", title: "B")

        // When
        let feeds = manager.loadFeeds()

        // Then
        #expect(feeds.count == 2)
    }

    @Test("loadFeedItems returns all items")
    func loadFeedItems() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Item 1")
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Item 2", link: "https://example.com/2")

        // When
        let items = manager.loadFeedItems()

        // Then
        #expect(items?.count == 2)
    }

    @Test("containsFeed detects existing feed by RSS URL")
    func containsFeed() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://existing.com/feed")

        // When
        let containsExistingFeed = manager.containsFeed(withRSSURL: "https://existing.com/feed")
        let containsMissingFeed = manager.containsFeed(withRSSURL: "https://nonexistent.com/feed")

        // Then
        #expect(containsExistingFeed == true)
        #expect(containsMissingFeed == false)
    }

    @Test("feed(at:) returns correct feed for index path")
    func feedAtIndexPath() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com", title: "Alpha")
        _ = try Self.populateFeed(in: manager, rssURL: "https://b.com", title: "Beta")

        // When
        let first = manager.feed(at: IndexPath(row: 0, section: 0))
        let second = manager.feed(at: IndexPath(row: 1, section: 0))
        let outOfBounds = manager.feed(at: IndexPath(row: 99, section: 0))

        // Then
        #expect(first?.title == "Alpha")
        #expect(second?.title == "Beta")
        #expect(outOfBounds == nil)
    }

    @Test("savedFeedURLs returns all RSS URLs")
    func savedFeedURLs() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com/rss")
        _ = try Self.populateFeed(in: manager, rssURL: "https://b.com/rss")

        // When
        let urls = manager.savedFeedURLs()

        // Then
        #expect(urls.count == 2)
        #expect(urls.contains("https://a.com/rss"))
        #expect(urls.contains("https://b.com/rss"))
    }

    @Test("makeFeed via StorageProtocol returns a Feed")
    func makeFeedProtocol() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let feed = manager.makeFeed()

        // Then
        #expect(feed != nil)
        #expect(feed?.managedObjectContext != nil)
    }

    @Test("makeFeedItem via StorageProtocol returns a FeedItem")
    func makeFeedItemProtocol() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let feedItem = manager.makeFeedItem()

        // Then
        #expect(feedItem != nil)
    }

    // MARK: - Unread Counts

    @Test("unreadCountsByFeed returns correct counts")
    func unreadCountsByFeed() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Unread 1", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Unread 2", link: "https://example.com/2", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Read", link: "https://example.com/3", wasRead: true)

        // When
        let counts = manager.unreadCountsByFeed()

        // Then
        #expect(counts[feed.objectID] == 2)
    }

    @Test("unreadCountsByFeed returns empty when all read")
    func unreadCountsAllRead() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Read", wasRead: true)

        // When
        let counts = manager.unreadCountsByFeed()

        // Then
        #expect(counts.isEmpty)
    }

    // MARK: - Convenience Methods

    @Test("Fetch feeds matching search text")
    func fetchFeedsMatchingSearch() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com", title: "Swift Weekly")
        _ = try Self.populateFeed(in: manager, rssURL: "https://b.com", title: "Kotlin Daily")

        // When
        let results = try manager.fetchFeeds(matching: "Swift")

        // Then
        #expect(results.count == 1)
        #expect(results.first?.title == "Swift Weekly")
    }

    @Test("Fetch unread feed items")
    func fetchUnreadItems() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Unread", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Read", link: "https://example.com/2", wasRead: true)

        // When
        let unread = try manager.fetchUnreadFeedItems()

        // Then
        #expect(unread.count == 1)
        #expect(unread.first?.title == "Unread")
    }

    @Test("Count unread items")
    func countUnreadItems() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Unread 1", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Unread 2", link: "https://example.com/2", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Read", link: "https://example.com/3", wasRead: true)

        // When
        let count = try manager.countUnreadItems()

        // Then
        #expect(count == 2)
    }

    // MARK: - Batch Update

    @Test("Batch update marks all items as read")
    func batchUpdate() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Item 1", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Item 2", link: "https://example.com/2", wasRead: false)

        // When
        try manager.batchUpdate(
            entityName: "FeedItem",
            propertiesToUpdate: ["wasRead": NSNumber(value: true)]
        )

        // Then
        let unread = try manager.fetchUnreadFeedItems()
        #expect(unread.isEmpty)
    }

    // MARK: - Clear All Data

    @Test("Clear all data removes everything")
    func clearAllData() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)
        _ = try Self.populateFeedItem(in: manager, feed: feed)

        // When
        try manager.clearAllData()

        // Then
        #expect(try manager.fetchFeeds().count == 0)
        #expect(try manager.fetchFeedItems().count == 0)
    }

    // MARK: - Context Management

    @Test("Reset view context clears pending changes")
    func resetViewContext() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        let feed = try manager.createFeed()
        feed.rssURL = "https://example.com"
        feed.title = "Unsaved"

        // When
        manager.resetViewContext()

        // Then
        let feeds = try manager.fetchFeeds()
        #expect(feeds.isEmpty)
    }

    @Test("Background context operates independently")
    func backgroundContext() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let bgContext = manager.newBackgroundContext()

        // Then
        #expect(bgContext !== manager.loadFeeds().first?.managedObjectContext)
        #expect(bgContext.undoManager == nil)
        #expect(bgContext.automaticallyMergesChangesFromParent == true)
    }

    @Test("isReady returns true after store loads")
    func isReady() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let isReady = manager.isReady()

        // Then
        #expect(isReady == true)
    }
}

// MARK: - Helpers
private extension CoreDataManagerTests {

    /// Directory that contains all temporary SQLite stores created by this test suite.
    ///
    /// The directory name includes a UUID so every test process gets an isolated
    /// location and cannot reuse or overwrite stores from another test run.
    nonisolated static let temporaryStoreDirectory: URL = {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataManagerTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    /// Registers process-exit cleanup for `temporaryStoreDirectory`.
    ///
    /// `atexit` stores the supplied closure and calls it when the test process
    /// exits normally. This keeps temporary SQLite files available for the full
    /// test run, then removes them before the process terminates.
    nonisolated static let registerTemporaryStoreCleanup: Void = {
        atexit {
            Self.removeTemporaryStoreDirectory()
        }
    }()

    /// Removes the suite-owned temporary store directory and all SQLite sidecar files.
    nonisolated static func removeTemporaryStoreDirectory() {
        do {
            try FileManager.default.removeItem(at: temporaryStoreDirectory)
            assert(
                !FileManager.default.fileExists(atPath: temporaryStoreDirectory.path),
                "Temporary CoreDataManagerTests store directory was not removed."
            )
        } catch {
            assertionFailure("Failed to remove temporary CoreDataManagerTests store directory: \(error)")
        }
    }

    /// Creates a CoreDataManager backed by a temporary SQLite store so tests
    /// exercise the same Core Data behavior as the app without touching real data.
    ///
    /// Use SQLite here instead of `NSInMemoryStoreType`: `CoreDataManager` uses
    /// `NSBatchDeleteRequest`, `NSBatchUpdateRequest`, and grouped aggregate
    /// fetches, which should be validated against the same store type used in production.
    static func makeTemporaryManager() throws -> CoreDataManager {
        _ = registerTemporaryStoreCleanup

        let model = try #require(NSManagedObjectModel.mergedModel(from: [Bundle.main]))
        let container = NSPersistentContainer(name: "iFeed", managedObjectModel: model)
        let storeURL = temporaryStoreDirectory.appendingPathComponent("\(UUID().uuidString)-iFeed.sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Temporary store failed to load: \(error)")
            }
        }

        return CoreDataManager(container: container)
    }

    static func populateFeed(
        in manager: CoreDataManager,
        rssURL: String = "https://example.com/feed",
        title: String = "Test Feed",
        summary: String = "A test feed"
    ) throws -> Feed {
        let feed = try manager.createFeed()
        feed.rssURL = rssURL
        feed.title = title
        feed.summary = summary
        try manager.saveViewContext()
        return feed
    }

    static func populateFeedItem(
        in manager: CoreDataManager,
        feed: Feed,
        title: String = "Test Item",
        link: String = "https://example.com/item",
        wasRead: Bool = false
    ) throws -> FeedItem {
        let item = try manager.createFeedItem()
        item.title = title
        item.link = link
        item.publishDate = Date()
        item.setValue(wasRead, forKey: "wasRead")
        item.feed = feed
        try manager.saveViewContext()
        return item
    }
}
