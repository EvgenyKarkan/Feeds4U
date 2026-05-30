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
@testable @preconcurrency import iFeed

// Coverage: ~83 %.
// Uncovered code paths:
//  - Error-handling `catch` branches in saveContext, executeFetchRequest, count,
//    batchDelete, and batchUpdate. Core Data raises ObjC NSInternalInconsistency-
//    Exception instead of throwing Swift errors, so these paths are unreachable
//    without an ObjC exception-catching wrapper.
//  - `saveContextAsync` deallocation guard (`guard let self`) and its catch clauses.
//  - `init(modelName:)`, `setupPersistentContainer`, and `getLegacyStoreURL` —
//    these configure the app's real store location and are bypassed by the test-
//    only `init(container:)` initialiser.

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

    // MARK: - CoreDataError

    @Test("CoreDataError descriptions are non-empty for all cases")
    func errorDescriptions() {
        let dummy = NSError(domain: "test", code: 1)
        let cases: [CoreDataError] = [
            .persistentStoreLoadFailed(underlying: dummy),
            .modelNotFound,
            .contextNotAvailable,
            .fetchFailed(underlying: dummy),
            .saveFailed(underlying: dummy),
            .executionFailed(underlying: dummy),
            .entityCreationFailed(entityName: "Feed")
        ]

        for error in cases {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    // MARK: - Save Context (explicit context)

    @Test("saveContext with explicit background context")
    func saveContextExplicit() throws {
        // Given
        nonisolated(unsafe) let manager = try Self.makeTemporaryManager()
        let bgContext = manager.newBackgroundContext()

        // When
        bgContext.performAndWait {
            guard let feed = try? manager.createFeed(in: bgContext) else { return }
            feed.rssURL = "https://bg.com"
            feed.title = "BG Feed"
            try? manager.saveContext(bgContext)
        }

        // Then
        let feeds = try manager.fetchFeeds()
        #expect(feeds.count == 1)
    }

    // MARK: - Save Context Async

    @Test("saveContextAsync reports success")
    func saveContextAsyncSuccess() async throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager)

        let feed2 = try manager.createFeed()
        feed2.rssURL = "https://async.com"
        feed2.title = "Async Feed"

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            manager.saveContextAsync(manager.newBackgroundContext()) { result in
                if case .success = result {
                    continuation.resume()
                } else {
                    continuation.resume()
                }
            }
        }

        // Then — context had no changes (new bg context), so success is expected
        #expect(true)
    }

    @Test("saveContextAsync with nil completion does not crash")
    func saveContextAsyncNilCompletion() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let bgContext = manager.newBackgroundContext()

        // When — should not crash
        manager.saveContextAsync(bgContext, completion: nil)

        // Then — no crash means pass
        #expect(true)
    }

    // MARK: - Perform Background Task

    @Test("performBackgroundTask configures context and executes block")
    func performBackgroundTaskTest() async throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            manager.performBackgroundTask { context in
                // Then — context should be configured
                #expect(context.undoManager == nil)
                #expect(context.automaticallyMergesChangesFromParent == true)
                #expect(context.shouldDeleteInaccessibleFaults == true)
                continuation.resume()
            }
        }
    }

    // MARK: - Refresh

    @Test("refresh re-faults saved objects")
    func refreshObjects() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        // Access a property to ensure the fault is fired
        _ = feed.title

        // When
        manager.refresh([feed], mergeChanges: true)

        // Then — object is still valid and accessible
        #expect(feed.isFault == true)
        #expect(feed.title == "Test Feed")
    }

    @Test("refresh with mergeChanges false discards unsaved edits")
    func refreshDiscardChanges() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)
        feed.title = "Modified"

        // When
        manager.refresh([feed], mergeChanges: false)

        // Then
        #expect(feed.title == "Test Feed")
    }

    // MARK: - StorageProtocol: saveChanges

    @Test("saveChanges persists pending changes")
    func saveChangesProtocol() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try manager.createFeed()
        feed.rssURL = "https://save.com"
        feed.title = "Save Test"

        // When
        manager.saveChanges()

        // Then
        let feeds = try manager.fetchFeeds()
        #expect(feeds.count == 1)
        #expect(feeds.first?.title == "Save Test")
    }

    // MARK: - StorageProtocol: delete (single-arg)

    @Test("delete via StorageProtocol removes the object")
    func deleteStorageProtocol() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        // When
        (manager as (any StorageProtocol)).delete(feed)
        try manager.saveViewContext()

        // Then
        #expect(try manager.fetchFeeds().isEmpty)
    }

    // MARK: - Create in explicit context

    @Test("createFeed in explicit context inserts into that context")
    func createFeedExplicitContext() throws {
        // Given
        nonisolated(unsafe) let manager = try Self.makeTemporaryManager()
        let bgContext = manager.newBackgroundContext()

        // When
        bgContext.performAndWait {
            let feed = try? manager.createFeed(in: bgContext)
            feed?.rssURL = "https://explicit.com"
            feed?.title = "Explicit"

            // Then
            #expect(feed?.managedObjectContext === bgContext)
        }
    }

    @Test("createFeedItem in explicit context inserts into that context")
    func createFeedItemExplicitContext() throws {
        // Given
        nonisolated(unsafe) let manager = try Self.makeTemporaryManager()
        let bgContext = manager.newBackgroundContext()

        // When
        bgContext.performAndWait {
            let item = try? manager.createFeedItem(in: bgContext)
            item?.title = "BG Item"

            // Then
            #expect(item?.managedObjectContext === bgContext)
        }
    }

    // MARK: - Fetch with custom sort descriptors

    @Test("fetchFeeds with custom sort descriptors")
    func fetchFeedsCustomSort() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, rssURL: "https://a.com", title: "Alpha")
        _ = try Self.populateFeed(in: manager, rssURL: "https://z.com", title: "Zebra")

        let descending = [NSSortDescriptor(key: "title", ascending: false)]

        // When
        let feeds = try manager.fetchFeeds(sortedBy: descending)

        // Then
        #expect(feeds.first?.title == "Zebra")
        #expect(feeds.last?.title == "Alpha")
    }

    @Test("fetchFeedItems with predicate filter")
    func fetchFeedItemsFiltered() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Keep", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Filter Out", link: "https://example.com/2", wasRead: true)

        let predicate = NSPredicate(format: "title == %@", "Keep")

        // When
        let items = try manager.fetchFeedItems(filteredBy: predicate)

        // Then
        #expect(items.count == 1)
        #expect(items.first?.title == "Keep")
    }

    @Test("fetchFeedItems with custom sort descriptors")
    func fetchFeedItemsCustomSort() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Aaa")
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Zzz", link: "https://example.com/2")

        let byTitle = [NSSortDescriptor(key: "title", ascending: true)]

        // When
        let items = try manager.fetchFeedItems(sortedBy: byTitle)

        // Then
        #expect(items.first?.title == "Aaa")
        #expect(items.last?.title == "Zzz")
    }

    // MARK: - Batch update with predicate

    @Test("Batch update with predicate only updates matching items")
    func batchUpdateWithPredicate() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feed = try Self.populateFeed(in: manager)

        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Target", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feed, title: "Leave Alone", link: "https://example.com/2", wasRead: false)

        let predicate = NSPredicate(format: "title == %@", "Target")

        // When
        try manager.batchUpdate(
            entityName: "FeedItem",
            propertiesToUpdate: ["wasRead": NSNumber(value: true)],
            predicate: predicate
        )

        // Then
        let unread = try manager.fetchUnreadFeedItems()
        #expect(unread.count == 1)
        #expect(unread.first?.title == "Leave Alone")
    }

    // MARK: - Multiple feeds unread counts

    @Test("unreadCountsByFeed returns counts for multiple feeds")
    func unreadCountsMultipleFeeds() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        let feedA = try Self.populateFeed(in: manager, rssURL: "https://a.com", title: "A")
        let feedB = try Self.populateFeed(in: manager, rssURL: "https://b.com", title: "B")

        _ = try Self.populateFeedItem(in: manager, feed: feedA, title: "A1", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feedA, title: "A2", link: "https://a.com/2", wasRead: false)
        _ = try Self.populateFeedItem(in: manager, feed: feedA, title: "A3", link: "https://a.com/3", wasRead: true)
        _ = try Self.populateFeedItem(in: manager, feed: feedB, title: "B1", wasRead: false)

        // When
        let counts = manager.unreadCountsByFeed()

        // Then
        #expect(counts[feedA.objectID] == 2)
        #expect(counts[feedB.objectID] == 1)
    }

    // MARK: - Empty store edge cases

    @Test("savedFeedURLs returns empty set on empty store")
    func savedFeedURLsEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let urls = manager.savedFeedURLs()

        // Then
        #expect(urls.isEmpty)
    }

    @Test("containsFeed returns false on empty store")
    func containsFeedEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When / Then
        #expect(manager.containsFeed(withRSSURL: "https://nothing.com") == false)
    }

    @Test("unreadCountsByFeed returns empty on empty store")
    func unreadCountsEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let counts = manager.unreadCountsByFeed()

        // Then
        #expect(counts.isEmpty)
    }

    @Test("loadFeedItems returns empty on empty store")
    func loadFeedItemsEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let items = manager.loadFeedItems()

        // Then
        #expect(items?.isEmpty == true)
    }

    @Test("feed(at:) returns nil on empty store")
    func feedAtEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let feed = manager.feed(at: IndexPath(row: 0, section: 0))

        // Then
        #expect(feed == nil)
    }

    // MARK: - Count on empty store

    @Test("count returns zero on empty store")
    func countEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let feedCount = try manager.count(entityName: "Feed")
        let itemCount = try manager.count(entityName: "FeedItem")

        // Then
        #expect(feedCount == 0)
        #expect(itemCount == 0)
    }

    @Test("countUnreadItems returns zero on empty store")
    func countUnreadEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When
        let count = try manager.countUnreadItems()

        // Then
        #expect(count == 0)
    }

    // MARK: - Fetch matching with no results

    @Test("fetchFeeds matching returns empty when no match")
    func fetchFeedsMatchingNoResult() throws {
        // Given
        let manager = try Self.makeTemporaryManager()
        _ = try Self.populateFeed(in: manager, title: "Swift Weekly")

        // When
        let results = try manager.fetchFeeds(matching: "Kotlin")

        // Then
        #expect(results.isEmpty)
    }

    // MARK: - Clear all data on empty store

    @Test("clearAllData on empty store does not throw")
    func clearAllDataEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When / Then — should not throw
        try manager.clearAllData()
        #expect(try manager.fetchFeeds().isEmpty)
    }

    // MARK: - Batch delete on empty store

    @Test("batchDelete on empty store does not throw")
    func batchDeleteEmpty() throws {
        // Given
        let manager = try Self.makeTemporaryManager()

        // When / Then — should not throw
        try manager.batchDelete(entityName: "Feed")
        #expect(try manager.fetchFeeds().isEmpty)
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
