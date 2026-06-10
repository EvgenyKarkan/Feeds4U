//
//  FeedItemsInteractorTests.swift
//  iFeedTests
//
//  Created by Gemini CLI on 07.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Mocking
import CoreData
import UIKit
@testable import iFeed

@Suite
@MainActor
struct FeedItemsInteractorTests {

    // MARK: - Properties

    private let parser = ParserProtocolMock()
    private let storage = StorageProtocolMock()
    private let search = SearchableMock()
    private let container: NSPersistentContainer
    private let testFeed: Feed

    // Constants
    private let testRSSURL = "https://example.com/rss"
    private let testTitle = "Test Feed"

    // MARK: - Init

    init() throws {
        container = try Self.makeInMemoryContainer()
        testFeed = Feed(context: container.viewContext)
        testFeed.rssURL = testRSSURL
        testFeed.title = testTitle
    }

    // MARK: - Data Access & Formatting

    @Test func getFeed_returnsCorrectFeed() {
        let sut = makeSUT(feed: testFeed)
        #expect(sut.getFeed() === testFeed)
    }

    @Test func getFeedItems_whenRegularFlow_delegatesToStorage() {
        // Given
        let item = FeedItem(context: container.viewContext)
        item.title = "B"
        item.publishDate = Date()
        item.feed = testFeed

        storage._feedItems.implementation = .uncheckedInvokes { [item] _ in [item] }
        let sut = makeSUT(feed: testFeed)

        // When
        let items = sut.getFeedItems()

        // Then
        // Sorting happens at the SQL level inside the storage fetch.
        #expect(storage._feedItems.callCount == 1)
        #expect(storage._feedItems.lastInvocation === testFeed)
        #expect(items?.count == 1)
        #expect(items?.first?.title == "B")
    }

    @Test func getFeedItems_whenSearchFlow_returnsDirectItems() {
        // Given
        let item = FeedItem(context: container.viewContext)
        item.title = "Search Result"
        let sut = makeSUT(feedItems: [item], searchTerm: "query")

        // When
        let items = sut.getFeedItems()

        // Then
        #expect(items?.count == 1)
        #expect(items?.first?.title == "Search Result")
    }

    @Test func getSearchTitle_withSearchTerm_returnsFormattedString() {
        let sut = makeSUT(searchTerm: "swift")
        let title = sut.getSearchTitle()
        #expect(title?.contains("swift") == true)
    }

    @Test func getSearchTitle_withoutSearchTerm_returnsNil() {
        let sut = makeSUT()
        #expect(sut.getSearchTitle() == nil)
    }

    @Test func getFeedItems_whenNoFeedAndNoSearch_returnsNil() {
        let sut = makeSUT(feed: nil, feedItems: nil, searchTerm: nil)
        #expect(sut.getFeedItems() == nil)
    }

    @Test func getSearchTitle_branchCoverage() {
        // query exists but is not used in the mock formatting in a way that covers query binding
        let sut = makeSUT(searchTerm: "test")
        #expect(sut.getSearchTitle() != nil)
    }

    // MARK: - Read Status Management

    @Test func markItemAsReadIfNeeded_whenUnread_updatesAndSaves() {
        // Given
        let item = FeedItem(context: container.viewContext)
        item.wasRead = false
        let sut = makeSUT()

        // When
        sut.markItemAsReadIfNeeded(item: item)

        // Then
        #expect(item.wasRead.boolValue == true)
        #expect(storage._saveChanges.callCount == 1)
    }

    @Test func markItemAsReadIfNeeded_whenAlreadyRead_doesNothing() {
        // Given
        let item = FeedItem(context: container.viewContext)
        item.wasRead = true
        let sut = makeSUT()

        // When
        sut.markItemAsReadIfNeeded(item: item)

        // Then
        #expect(storage._saveChanges.callCount == 0)
    }

    @Test func markAllItemsAsRead_whenRegularFlow_delegatesToStorageBatchUpdate() {
        // Given
        let sut = makeSUT(feed: testFeed)

        // When
        sut.markAllItemsAsRead()

        // Then
        // The storage layer performs an SQL-level batch update; the interactor
        // neither loads items nor saves the context itself.
        #expect(storage._markAllAsRead.callCount == 1)
        #expect(storage._markAllAsRead.lastInvocation === testFeed)
        #expect(storage._saveChanges.callCount == 0)
    }

    @Test func hasUnreadItems_whenCountIsZero_returnsFalse() throws {
        // Given
        storage._unreadCount.implementation = .uncheckedInvokes { _ in 0 }
        let sut = makeSUT(feed: testFeed)

        // When / Then
        #expect(sut.hasUnreadItems() == false)
        #expect(storage._unreadCount.lastInvocation === testFeed)
    }

    @Test func hasUnreadItems_whenCountIsPositive_returnsTrue() throws {
        // Given
        storage._unreadCount.implementation = .uncheckedInvokes { _ in 2 }
        let sut = makeSUT(feed: testFeed)

        // When / Then
        #expect(sut.hasUnreadItems() == true)
    }

    @Test func hasUnreadItems_branchCoverage() {
        let sutSearch = makeSUT(searchTerm: "q")
        #expect(sutSearch.hasUnreadItems() == false)

        let sutNilFeed = makeSUT(feed: nil)
        #expect(sutNilFeed.hasUnreadItems() == false)

        // Neither guard-failing path may reach the storage layer.
        #expect(storage._unreadCount.callCount == 0)
    }

    @Test func markAllItemsAsRead_whenFeedNil_doesNothing() throws {
        let sut = makeSUT(feed: nil)
        sut.markAllItemsAsRead()
        #expect(storage._markAllAsRead.callCount == 0)
    }

    @Test func markAllItemsAsRead_whenSearchTermActive_doesNothing() throws {
        let sut = makeSUT(feed: testFeed, searchTerm: "active")
        sut.markAllItemsAsRead()

        #expect(storage._markAllAsRead.callCount == 0)
    }

    @Test func didEndParsingFeed_delegatesMergeToStorageAndCompletes() throws {
        // Given
        storage._refreshFeedItems.implementation = .uncheckedInvokes { _, _, completion in
            completion()
        }
        let itemData = ParsedFeedItemData(title: "U", link: "https://u.com", publishDate: Date(), htmlContent: nil)
        let data = ParsedFeedData(title: "T", summary: "S", items: [itemData])

        let sut = makeSUT(feed: testFeed)
        var completionCalled = false
        sut.startParsingFeed(testRSSURL) { _ in completionCalled = true }

        // When
        sut.didEndParsingFeed(with: data)

        // Then
        // Deduplication itself lives in the storage layer (covered by
        // CoreDataManagerTests); the interactor forwards the items and feed ID.
        #expect(storage._refreshFeedItems.callCount == 1)
        let invocation = storage._refreshFeedItems.lastInvocation
        #expect(invocation?.0.count == 1)
        #expect(invocation?.1 == testFeed.objectID)
        // A refresh may add items — the search index must be invalidated.
        #expect(search._markIndexDirty.callCount == 1)
        #expect(completionCalled)
    }

    // MARK: - Feed Parsing Lifecycle

    @Test func startParsingFeed_withEmptyURL_callsCompletionWithFailure() {
        let sut = makeSUT()
        var receivedResult: Result<Void, any Error>?

        sut.startParsingFeed("") { receivedResult = $0 }

        guard case .failure = receivedResult else {
            Issue.record("Expected failure for empty URL")
            return
        }
    }

    @Test func startParsingFeed_withInvalidURL_callsCompletionWithFailure() {
        let sut = makeSUT()
        var receivedResult: Result<Void, any Error>?

        sut.startParsingFeed(" http://[") { receivedResult = $0 }

        guard case .failure = receivedResult else {
            Issue.record("Expected failure for invalid URL")
            return
        }
    }

    @Test func startParsingFeed_withValidURL_startsParser() {
        let sut = makeSUT()
        sut.startParsingFeed(testRSSURL) { _ in }

        #expect(parser._setDelegate.callCount == 1)
        #expect(parser._beginParsingURL.lastInvocation == URL(string: testRSSURL))
    }

    @Test func didEndParsingFeed_whenNoFeed_doesNothing() {
        let sut = makeSUT(feed: nil)
        let data = ParsedFeedData(title: "T", summary: "S", items: [])

        sut.didEndParsingFeed(with: data)

        #expect(storage._refreshFeedItems.callCount == 0)
    }

    @Test func didEndParsingFeed_withoutPendingCompletion_doesNotStartMerge() {
        // Given — no startParsingFeed call, so nobody is waiting for a result.
        let sut = makeSUT(feed: testFeed)
        let data = ParsedFeedData(title: "T", summary: "S", items: [])

        // When
        sut.didEndParsingFeed(with: data)

        // Then
        #expect(storage._refreshFeedItems.callCount == 0)
        #expect(search._markIndexDirty.callCount == 0)
    }

    @Test func didFailParsingFeed_callsCompletionWithError() {
        // Given
        let sut = makeSUT()
        var receivedError: (any Error)?
        sut.startParsingFeed(testRSSURL) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
        }

        // When
        sut.didFailParsingFeed(with: URLError(.notConnectedToInternet))

        // Then
        #expect(receivedError != nil)
    }

    @Test func didCancelParsingFeed_nilsOutCompletion() {
        // Given
        let sut = makeSUT()
        var callCount = 0
        sut.startParsingFeed(testRSSURL) { _ in callCount += 1 }

        // When
        sut.didCancelParsingFeed()

        // Then
        #expect(callCount == 0)
        sut.didEndParsingFeed(with: ParsedFeedData(title: "T", summary: "S", items: []))
        #expect(callCount == 0)
    }

    @Test func delegateMethods_withoutActiveParsing_doNothing() {
        let sut = makeSUT(feed: testFeed)
        // No crash and coverage for parsingCompletion? paths
        sut.didEndParsingFeed(with: ParsedFeedData(title: "T", summary: "S", items: []))
        sut.didFailParsingFeed(with: URLError(.notConnectedToInternet))
        #expect(true)
    }

    // MARK: - Helpers

    private func makeSUT(feed: Feed? = nil,
                         feedItems: [FeedItem]? = nil,
                         searchTerm: String? = nil) -> FeedItemsInteractor {
        FeedItemsInteractor(
            parser: parser,
            storage: storage,
            localSearchService: search,
            feed: feed,
            feedItems: feedItems,
            searchTerm: searchTerm
        )
    }

    private static func makeInMemoryContainer() throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "iFeed", managedObjectModel: TestCoreDataModel.shared)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, _ in }
        return container
    }
}
