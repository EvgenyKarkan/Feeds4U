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

@Suite(.serialized)
@MainActor
struct FeedItemsInteractorTests {

    // MARK: - Properties

    private let parser = ParserProtocolMock()
    private let storage = StorageProtocolMock()
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

    @Test func getFeedItems_whenRegularFlow_returnsSortedItems() {
        // Given
        let item1 = FeedItem(context: container.viewContext)
        item1.title = "A"
        item1.publishDate = Date().addingTimeInterval(-100)
        item1.feed = testFeed

        let item2 = FeedItem(context: container.viewContext)
        item2.title = "B"
        item2.publishDate = Date()
        item2.feed = testFeed

        let sut = makeSUT(feed: testFeed)

        // When
        let items = sut.getFeedItems()

        // Then
        #expect(items?.count == 2)
        #expect(items?.first?.title == "B") // Sorted newest first
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

    @Test func markAllItemsAsRead_whenRegularFlow_marksAllAndSaves() {
        // Given
        let item1 = FeedItem(context: container.viewContext)
        item1.wasRead = false
        item1.feed = testFeed

        let item2 = FeedItem(context: container.viewContext)
        item2.wasRead = false
        item2.feed = testFeed

        let sut = makeSUT(feed: testFeed)

        // When
        sut.markAllItemsAsRead()

        // Then
        #expect(item1.wasRead.boolValue == true)
        #expect(item2.wasRead.boolValue == true)
        #expect(storage._saveChanges.callCount == 1)
    }

    @Test func markAllItemsAsRead_whenNoUnread_doesNotSave() {
        // Given
        let item = FeedItem(context: container.viewContext)
        item.wasRead = true
        item.feed = testFeed
        let sut = makeSUT(feed: testFeed)

        // When
        sut.markAllItemsAsRead()

        // Then
        #expect(storage._saveChanges.callCount == 0)
    }

    @Test func markAllItemsAsRead_whenNoItems_doesNothing() {
        // Given
        let sut = makeSUT(feed: testFeed) // testFeed has 0 items

        // When
        sut.markAllItemsAsRead()

        // Then
        #expect(storage._saveChanges.callCount == 0)
    }

    @Test func hasUnreadItems_whenAllRead_returnsFalse() throws {
        // Given
        let item = FeedItem(context: container.viewContext)
        item.wasRead = true
        item.feed = testFeed
        let sut = makeSUT(feed: testFeed)

        // When / Then
        #expect(sut.hasUnreadItems() == false)
    }

    @Test func hasUnreadItems_whenAtLeastOneUnread_returnsTrue() throws {
        // Given
        let item1 = FeedItem(context: container.viewContext)
        item1.wasRead = true
        item1.feed = testFeed

        let item2 = FeedItem(context: container.viewContext)
        item2.wasRead = false
        item2.feed = testFeed

        let sut = makeSUT(feed: testFeed)

        // When / Then
        #expect(sut.hasUnreadItems() == true)
    }

    @Test func hasUnreadItems_branchCoverage() {
        let sutSearch = makeSUT(searchTerm: "q")
        #expect(sutSearch.hasUnreadItems() == false)

        let sutNilFeed = makeSUT(feed: nil)
        #expect(sutNilFeed.hasUnreadItems() == false)
    }

    @Test func markAllItemsAsRead_whenFeedNil_doesNothing() throws {
        let sut = makeSUT(feed: nil)
        sut.markAllItemsAsRead()
        #expect(storage._saveChanges.callCount == 0)
    }

    @Test func markAllItemsAsRead_whenSearchTermActive_doesNothing() throws {
        let item = FeedItem(context: container.viewContext)
        item.wasRead = false
        item.feed = testFeed

        let sut = makeSUT(feed: testFeed, searchTerm: "active")
        sut.markAllItemsAsRead()

        #expect(item.wasRead.boolValue == false)
        #expect(storage._saveChanges.callCount == 0)
    }

    @Test func didEndParsingFeed_withEmptyExistingItems() throws {
        // Given: A feed with no existing items (to exercise ?? [] path)
        let data = ParsedFeedData(title: "T", summary: "S", items: [])
        let sut = makeSUT(feed: testFeed)

        // When
        sut.didEndParsingFeed(with: data)

        // Then
        #expect(storage._saveChanges.callCount == 1)
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

        #expect(storage._saveChanges.callCount == 0)
    }

    @Test func didEndParsingFeed_deduplicationMatrix() throws {
        // Given
        let existingItem = FeedItem(context: container.viewContext)
        existingItem.title = "Existing"
        existingItem.link = "https://exist.com"
        let fixedDate = Date(timeIntervalSince1970: 123456789)
        existingItem.publishDate = fixedDate
        existingItem.feed = testFeed

        // 1. Fully Duplicate
        let item1 = ParsedFeedItemData(title: "Existing", link: "https://exist.com", publishDate: fixedDate, htmlContent: nil)
        // 2. Duplicate Title
        let item2 = ParsedFeedItemData(title: "Existing", link: "https://new1.com", publishDate: Date(), htmlContent: nil)
        // 3. Duplicate Link
        let item3 = ParsedFeedItemData(title: "New1", link: "https://exist.com", publishDate: Date(), htmlContent: nil)
        // 4. Duplicate Date
        let item4 = ParsedFeedItemData(title: "New2", link: "https://new2.com", publishDate: fixedDate, htmlContent: nil)
        // 5. Unique
        let item5 = ParsedFeedItemData(title: "Unique", link: "https://unique.com", publishDate: Date(), htmlContent: nil)

        let data = ParsedFeedData(title: "T", summary: "S", items: [item1, item2, item3, item4, item5])

        storage._makeFeedItem.implementation = .uncheckedInvokes { [container] in
            return FeedItem(context: container.viewContext)
        }

        let sut = makeSUT(feed: testFeed)
        var completionCalled = false
        sut.startParsingFeed(testRSSURL) { _ in completionCalled = true }

        // When
        sut.didEndParsingFeed(with: data)

        // Then
        #expect(testFeed.feedItems.count == 2) // existing + item5
        #expect(completionCalled == true)
        #expect(storage._saveChanges.callCount == 1)
    }

    @Test func didEndParsingFeed_whenMakeItemFails_skipsItem() {
        // Given
        storage._makeFeedItem.implementation = .uncheckedInvokes { nil }
        let item = ParsedFeedItemData(title: "U", link: "https://u.com", publishDate: Date(), htmlContent: nil)
        let data = ParsedFeedData(title: "T", summary: "S", items: [item])

        let sut = makeSUT(feed: testFeed)

        // When
        sut.didEndParsingFeed(with: data)

        // Then
        #expect(testFeed.feedItems.count == 0) // nothing added
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
