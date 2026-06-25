//
//  FeedsInteractorTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 30.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Mocking
import CoreData
import UIKit
@testable import iFeed

@Suite
@MainActor
struct FeedsInteractorTests {

    // MARK: - Properties

    private let parser = ParserProtocolMock()
    private let storage = StorageProtocolMock()
    private let search = SearchableMock()
    private let explore = ExploreFeedsServiceProtocolMock()
    private let folders = FeedFolderManagingMock()
    private let container: NSPersistentContainer
    private let sut: FeedsInteractor
    private let keyedStorage = KeyedStorageProtocolMock()
    private let opmlParser = OPMLParsingMock()

    // Constants
    private let testFeedURL = "https://example.com/feed"
    private let testRSSURL = "https://example.com/rss"
    private let testWebPageURL = "https://example.com"
    private let recentSearchesKey = "com.ifeed.recentSearches"

    // MARK: - Init

    init() {
        container = Self.makeInMemoryContainer()

        sut = FeedsInteractor(
            parser: parser,
            storage: storage,
            localSearchService: search,
            exploreFeedsService: explore,
            folderManager: folders,
            keyedStorage: keyedStorage,
            opmlParser: opmlParser
        )
    }

    // MARK: - Helpers

    /// Creates an in-memory Core Data stack;
    /// the `name` only locates the `.xcdatamodeld` schema — no SQLite file is written to disk.
    private static func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "iFeed", managedObjectModel: TestCoreDataModel.shared)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        return container
    }

    private func makeFeed(rssURL: String = "https://example.com/feed", title: String = "Test Feed") -> Feed {
        let feed = Feed(context: container.viewContext)
        feed.rssURL = rssURL
        feed.title = title
        feed.feedItems = NSSet()
        return feed
    }

    private func makeParsedFeedData(title: String = "Test Feed") -> ParsedFeedData {
        return ParsedFeedData(title: title, summary: nil, items: [])
    }

    /// Stubs `importFeed` to synchronously build a feed from the passed data and
    /// report its object ID through the completion, mimicking a successful
    /// background import; `loadFeed(withID:)` resolves the ID back to the feed.
    private func stubStorageImportFeed() {
        storage._importFeed.implementation = .uncheckedInvokes { [container] data, rssURL, completion in
            let feed = Feed(context: container.viewContext)
            feed.title = data.title
            feed.rssURL = rssURL
            feed.summary = data.summary
            completion(feed.objectID)
        }
        storage._loadFeed.implementation = .uncheckedInvokes { [container] id in
            return (try? container.viewContext.existingObject(with: id)) as? Feed
        }
    }

    // MARK: - getAllFeeds

    @Test func getAllFeeds_delegatesToStorage() {
        // Given
        storage._loadFeeds.implementation = .uncheckedInvokes { [] }

        // When
        let feeds = sut.getAllFeeds()

        // Then
        #expect(feeds.isEmpty)
        #expect(storage._loadFeeds.callCount == 1)
    }

    // MARK: - refreshAllFeeds

    /// Stubs the parse + merge pair so a refresh-all resolves synchronously:
    /// every parse succeeds with empty data and every merge invokes its completion.
    private func stubSuccessfulRefresh() {
        parser._parse.implementation = .returns(.success(makeParsedFeedData()))
        storage._refreshFeedItems.implementation = .uncheckedInvokes { _, _, completion in
            completion()
        }
    }

    @Test func refreshAllFeeds_parsesEachFeedAndMergesItems() async {
        // Given
        storage._loadFeeds.implementation = .uncheckedInvokes { [makeFeed] in
            [makeFeed("https://a.com/feed", "A"),
             makeFeed("https://b.com/feed", "B"),
             makeFeed("https://c.com/feed", "C")]
        }
        stubSuccessfulRefresh()

        // When
        await sut.refreshAllFeeds()

        // Then
        #expect(parser._parse.callCount == 3)
        #expect(storage._refreshFeedItems.callCount == 3)
        #expect(search._markIndexDirty.callCount == 1)
    }

    @Test func refreshAllFeeds_skipsFeedsWithInvalidURL() async {
        // Given — one valid feed, one with an unparseable URL.
        storage._loadFeeds.implementation = .uncheckedInvokes { [makeFeed] in
            [makeFeed("https://valid.com/feed", "Valid"),
             makeFeed("not a url", "Invalid")]
        }
        stubSuccessfulRefresh()

        // When
        await sut.refreshAllFeeds()

        // Then — only the valid feed is parsed and merged.
        #expect(parser._parse.callCount == 1)
        #expect(storage._refreshFeedItems.callCount == 1)
        #expect(search._markIndexDirty.callCount == 1)
    }

    @Test func refreshAllFeeds_withNoFeeds_doesNothing() async {
        // Given
        storage._loadFeeds.implementation = .uncheckedInvokes { [] }

        // When
        await sut.refreshAllFeeds()

        // Then — no parse, no merge, and the index is left alone.
        #expect(parser._parse.callCount == 0)
        #expect(storage._refreshFeedItems.callCount == 0)
        #expect(search._markIndexDirty.callCount == 0)
    }

    @Test func refreshAllFeeds_continuesPastAParseFailure() async {
        // Given — the first feed fails to parse, the second succeeds.
        storage._loadFeeds.implementation = .uncheckedInvokes { [makeFeed] in
            [makeFeed("https://bad.com/feed", "Bad"),
             makeFeed("https://good.com/feed", "Good")]
        }
        enum RefreshError: Error { case boom }
        nonisolated(unsafe) var calls = 0
        parser._parse.implementation = .uncheckedInvokes { _ in
            calls += 1
            return calls == 1 ? .failure(RefreshError.boom) : .success(self.makeParsedFeedData())
        }
        storage._refreshFeedItems.implementation = .uncheckedInvokes { _, _, completion in
            completion()
        }

        // When
        await sut.refreshAllFeeds()

        // Then — both feeds are attempted; only the successful one is merged.
        #expect(parser._parse.callCount == 2)
        #expect(storage._refreshFeedItems.callCount == 1)
        #expect(search._markIndexDirty.callCount == 1)
    }

    @Test func refreshAllFeeds_withMoreFeedsThanConcurrencyLimit_refreshesEvery() async {
        // Given — more feeds than the bounded fan-out limit, forcing the task
        // group's "start the next as each finishes" re-add path to run.
        storage._loadFeeds.implementation = .uncheckedInvokes { [makeFeed] in
            (0..<8).map { makeFeed("https://example.com/feed\($0)", "Feed \($0)") }
        }
        stubSuccessfulRefresh()

        // When
        await sut.refreshAllFeeds()

        // Then — all eight are parsed and merged despite the in-flight cap.
        #expect(parser._parse.callCount == 8)
        #expect(storage._refreshFeedItems.callCount == 8)
        #expect(search._markIndexDirty.callCount == 1)
    }

    // MARK: - storageSize

    @Test func storageSize_delegatesToStorage() async {
        // Given
        storage._storageSizeBytes.implementation = .returns(2_048)

        // When
        let bytes = await sut.storageSize()

        // Then
        #expect(bytes == 2_048)
        #expect(storage._storageSizeBytes.callCount == 1)
    }

    // MARK: - deleteAllData

    @Test func deleteAllData_clearsStorageAndMarksIndexDirty() async {
        // When
        await sut.deleteAllData()

        // Then — the store is zeroed and the now-empty corpus is flagged for reindex.
        #expect(storage._clearAllData.callCount == 1)
        #expect(search._markIndexDirty.callCount == 1)
    }

    // MARK: - performWhenStorageReady

    @Test func performWhenStorageReady_delegatesToStorageAndForwardsCallback() {
        // Given
        storage._performWhenStoreReady.implementation = .uncheckedInvokes { callback in
            callback()
        }
        nonisolated(unsafe) var callbackRan = false

        // When
        sut.performWhenStorageReady {
            callbackRan = true
        }

        // Then
        #expect(storage._performWhenStoreReady.callCount == 1)
        #expect(callbackRan)
    }

    // MARK: - checkIfFeedIsAlreadySaved

    @Test func checkIfFeedIsAlreadySaved_whenFeedExists_returnsTrue() {
        // Given
        storage._containsFeed.implementation = .returns(true)

        // When
        let result = sut.checkIfFeedIsAlreadySaved(with: testFeedURL)

        // Then
        #expect(result == true)
        #expect(storage._containsFeed.callCount == 1)
        #expect(storage._containsFeed.lastInvocation == testFeedURL)
    }

    @Test func checkIfFeedIsAlreadySaved_whenFeedDoesNotExist_returnsFalse() {
        // Given
        storage._containsFeed.implementation = .returns(false)

        // When
        let result = sut.checkIfFeedIsAlreadySaved(with: testFeedURL)

        // Then
        #expect(result == false)
        #expect(storage._containsFeed.lastInvocation == testFeedURL)
    }

    // MARK: - startParsingFeed

    @Test func startParsingFeed_withEmptyURL_callsCompletionWithFailure() {
        // Given
        var receivedResult: Result<Feed, any Error>?

        // When
        sut.startParsingFeed("") { result in
            receivedResult = result
        }

        // Then
        guard case .failure = receivedResult else {
            Issue.record("Expected failure result for empty URL")
            return
        }
        #expect(parser._setDelegate.callCount == 0)
        #expect(parser._beginParsingURL.callCount == 0)
    }

    @Test func startParsingFeed_withNonWebScheme_callsCompletionWithFailure() {
        // Given — a dangerous non-web scheme must never reach the parser.
        var receivedResult: Result<Feed, any Error>?

        // When
        sut.startParsingFeed("file:///etc/passwd") { result in
            receivedResult = result
        }

        // Then
        guard case .failure = receivedResult else {
            Issue.record("Expected failure result for non-web scheme")
            return
        }
        #expect(parser._setDelegate.callCount == 0)
        #expect(parser._beginParsingURL.callCount == 0)
    }

    @Test func startParsingFeed_withValidURL_setsParserDelegateAndBeginsParsingURL() {
        // Given
        let urlString = testFeedURL

        // When
        sut.startParsingFeed(urlString) { _ in }

        // Then
        #expect(parser._setDelegate.callCount == 1)
        #expect(parser._beginParsingURL.callCount == 1)
        #expect(parser._beginParsingURL.lastInvocation == URL(string: urlString))
    }

    @Test func startParsingFeed_onParsingSuccess_callsCompletionWithFeed() {
        // Given
        stubStorageImportFeed()
        let parsedData = makeParsedFeedData(title: "Parsed Feed")
        var receivedResult: Result<Feed, any Error>?

        sut.startParsingFeed(testFeedURL) { result in
            receivedResult = result
        }

        // When
        sut.didEndParsingFeed(with: parsedData)

        // Then
        guard case .success(let receivedFeed) = receivedResult else {
            Issue.record("Expected success result")
            return
        }
        #expect(receivedFeed.rssURL == testFeedURL)
        #expect(receivedFeed.title == "Parsed Feed")
        // Creation and persistence happen inside the storage import; a successful
        // import must also invalidate the search index.
        #expect(storage._importFeed.callCount == 1)
        #expect(search._markIndexDirty.callCount == 1)
    }

    @Test func startParsingFeed_onParsingFailure_callsCompletionWithError() {
        // Given
        let testError = NSError(domain: "TestDomain", code: 42)
        var receivedResult: Result<Feed, any Error>?

        sut.startParsingFeed(testFeedURL) { result in
            receivedResult = result
        }

        // When
        sut.didFailParsingFeed(with: testError)

        // Then
        guard case .failure(let error) = receivedResult else {
            Issue.record("Expected failure result")
            return
        }
        #expect((error as NSError).domain == "TestDomain")
        #expect((error as NSError).code == 42)
    }

    @Test func startParsingFeed_withInvalidURL_callsCompletionWithFailure() {
        // Given
        var receivedResult: Result<Feed, any Error>?

        // When
        sut.startParsingFeed("not a valid url") { result in
            receivedResult = result
        }

        // Then
        // Note: URL(string:) on iOS is very permissive, but empty or spaces usually fail or we want to ensure coverage.
        // If "not a valid url" actually parses, we should use a truly invalid one like " http://["
        sut.startParsingFeed(" http://[") { result in
            receivedResult = result
        }

        guard case .failure = receivedResult else {
            Issue.record("Expected failure result for invalid URL")
            return
        }
    }

    @Test func didEndParsingFeed_whenImportFails_callsCompletionWithFailure() {
        // Given
        storage._importFeed.implementation = .uncheckedInvokes { _, _, completion in
            completion(nil)
        }
        var receivedResult: Result<Feed, any Error>?

        sut.startParsingFeed(testFeedURL) { result in
            receivedResult = result
        }

        // When
        sut.didEndParsingFeed(with: makeParsedFeedData())

        // Then
        guard case .failure(let error) = receivedResult else {
            Issue.record("Expected failure result")
            return
        }
        #expect(error is StorageError)
        // A failed import must not invalidate the search index.
        #expect(search._markIndexDirty.callCount == 0)
    }

    @Test func didEndParsingFeed_passesDataAndURLToStorage() {
        // Given
        stubStorageImportFeed()

        let itemData = ParsedFeedItemData(
            title: "Item 1",
            link: "https://item.com",
            publishDate: Date(),
            htmlContent: "Content"
        )
        let parsedData = ParsedFeedData(title: "Feed", summary: "Summary", items: [itemData])

        var receivedResult: Result<Feed, any Error>?
        sut.startParsingFeed(testFeedURL) { result in
            receivedResult = result
        }

        // When
        sut.didEndParsingFeed(with: parsedData)

        // Then
        // Object-graph creation lives in the storage layer (covered by
        // CoreDataManagerTests); the interactor must forward the parsed payload as-is.
        #expect(storage._importFeed.callCount == 1)
        let invocation = storage._importFeed.lastInvocation
        #expect(invocation?.0.title == "Feed")
        #expect(invocation?.0.summary == "Summary")
        #expect(invocation?.0.items.count == 1)
        #expect(invocation?.1 == testFeedURL)

        guard case .success(let feed) = receivedResult else {
            Issue.record("Expected success")
            return
        }
        #expect(feed.title == "Feed")
        #expect(feed.rssURL == testFeedURL)
    }

    @Test func didCancelParsingFeed_nilsOutProperties() {
        // Given
        var callCount = 0
        sut.startParsingFeed(testFeedURL) { _ in
            callCount += 1
        }

        // When
        sut.didCancelParsingFeed()

        // Then
        // completion should NOT be called
        #expect(callCount == 0)

        // Verify it is indeed nilled out by calling didEndParsingFeed and seeing no callback —
        // with no pending completion the interactor must not even start an import.
        sut.didEndParsingFeed(with: makeParsedFeedData())
        #expect(callCount == 0)
        #expect(storage._importFeed.callCount == 0)
    }

    // MARK: - fillSearchMatchingEngine

    @Test func fillSearchMatchingEngine_delegatesToSearchService() async {
        // When
        await sut.fillSearchMatchingEngine()

        // Then
        #expect(search._fillMatchingEngine.callCount == 1)
    }

    // MARK: - performSearch

    @Test func performSearch_delegatesToSearchService() async {
        // Given
        search._search.implementation = .uncheckedInvokes { _ in nil }

        // When
        let results = await sut.performSearch(by: "swift")

        // Then
        #expect(results == nil)
        #expect(search._search.callCount == 1)
        #expect(search._search.lastInvocation == "swift")
    }

    // MARK: - exploreFeeds

    @Test func exploreFeeds_delegatesToExploreService() {
        // When
        sut.exploreFeeds(on: testWebPageURL) { _ in }

        // Then
        #expect(explore._searchFeedsOnWebPageCompletion.callCount == 1)
        #expect(explore._searchFeedsOnWebPageCompletion.lastInvocation?.0 == testWebPageURL)
    }

    // MARK: - feedForIndexPath

    @Test func feedForIndexPath_delegatesToStorage() {
        // Given
        storage._feed.implementation = .uncheckedInvokes { _ in nil }
        let indexPath = IndexPath(row: 0, section: 0)

        // When
        let feed = sut.feedForIndexPath(indexPath)

        // Then
        #expect(feed == nil)
        #expect(storage._feed.callCount == 1)
        #expect(storage._feed.lastInvocation == indexPath)
    }

    // MARK: - unreadCountsByFeed

    @Test func unreadCountsByFeed_delegatesToStorage() {
        // Given
        storage._unreadCountsByFeed.implementation = .returns([:])

        // When
        let counts = sut.unreadCountsByFeed()

        // Then
        #expect(counts.isEmpty)
        #expect(storage._unreadCountsByFeed.callCount == 1)
    }

    // MARK: - itemCount

    @Test func itemCount_delegatesToStorage() {
        // Given
        let feed = makeFeed()
        storage._itemCount.implementation = .uncheckedInvokes { _ in 7 }

        // When
        let count = sut.itemCount(for: feed)

        // Then
        #expect(count == 7)
        #expect(storage._itemCount.callCount == 1)
        #expect(storage._itemCount.lastInvocation === feed)
    }

    // MARK: - saveContext

    @Test func saveContext_delegatesToStorage() throws {
        // When
        try sut.saveContext()

        // Then
        #expect(storage._saveChanges.callCount == 1)
    }

    // MARK: - deleteFeed

    @Test func deleteFeed_removesFromFolderDeletesFromStorageAndSaves() {
        // Given
        let feed = makeFeed(rssURL: testRSSURL)

        // When
        sut.deleteFeed(feed)

        // Then
        #expect(folders._removeFeed.callCount == 1)
        #expect(folders._removeFeed.lastInvocation == testRSSURL)
        #expect(storage._delete.callCount == 1)
        #expect(storage._delete.lastInvocation === feed)
        #expect(storage._saveChanges.callCount == 1)
        // Removing a feed shrinks the search corpus — the index must be invalidated.
        #expect(search._markIndexDirty.callCount == 1)
    }

    // MARK: - Folder operations

    @Test func getAllFolders_delegatesToFolderManager() {
        // Given
        folders._loadFolders.implementation = .returns([])

        // When
        let allFolders = sut.getAllFolders()

        // Then
        #expect(allFolders.isEmpty)
        #expect(folders._loadFolders.callCount == 1)
    }

    @Test func createFolder_delegatesToFolderManager() {
        // Given
        let folder = FeedFolder(name: "Tech", feedURLs: [testRSSURL])
        folders._createFolder.implementation = .returns(folder)

        // When
        let created = sut.createFolder(name: "Tech", feedURLs: [testRSSURL])

        // Then
        #expect(created.name == "Tech")
        #expect(created.feedURLs == [testRSSURL])
        #expect(folders._createFolder.callCount == 1)
        #expect(folders._createFolder.lastInvocation?.0 == "Tech")
        #expect(folders._createFolder.lastInvocation?.1 == [testRSSURL])
    }

    @Test func addFeedToFolder_delegatesToFolderManager() {
        // Given
        let folderId = UUID()

        // When
        sut.addFeedToFolder(url: testRSSURL, folderId: folderId)

        // Then
        #expect(folders._addFeed.callCount == 1)
        #expect(folders._addFeed.lastInvocation?.0 == testRSSURL)
        #expect(folders._addFeed.lastInvocation?.1 == folderId)
    }

    @Test func removeFeedFromFolder_delegatesToFolderManager() {
        // When
        sut.removeFeedFromFolder(url: testRSSURL)

        // Then
        #expect(folders._removeFeed.callCount == 1)
        #expect(folders._removeFeed.lastInvocation == testRSSURL)
    }

    @Test func toggleFolderExpanded_delegatesToFolderManager() {
        // Given
        let folderId = UUID()

        // When
        sut.toggleFolderExpanded(id: folderId)

        // Then
        #expect(folders._toggleExpanded.callCount == 1)
        #expect(folders._toggleExpanded.lastInvocation == folderId)
    }

    @Test func cleanupFolders_delegatesToFolderManager() {
        // Given
        let urls: Set<String> = [testRSSURL]

        // When
        sut.cleanupFolders(existingFeedURLs: urls)

        // Then
        #expect(folders._cleanupDeletedFeeds.callCount == 1)
        #expect(folders._cleanupDeletedFeeds.lastInvocation == urls)
    }

    // MARK: - Recent searches

    @Test func recentSearches_whenStorageReturnsNil_returnsEmptyArray() {
        // Given
        keyedStorage._stringArray.implementation = .returns(nil)

        // When
        let searches = sut.recentSearches()

        // Then
        #expect(searches.isEmpty)
        #expect(keyedStorage._stringArray.callCount == 1)
        #expect(keyedStorage._stringArray.lastInvocation == recentSearchesKey)
    }

    @Test func recentSearches_whenStorageReturnsValues_returnsThem() {
        // Given
        keyedStorage._stringArray.implementation = .returns(["swift", "kotlin"])

        // When
        let searches = sut.recentSearches()

        // Then
        #expect(searches == ["swift", "kotlin"])
        #expect(keyedStorage._stringArray.callCount == 1)
        #expect(keyedStorage._stringArray.lastInvocation == recentSearchesKey)
    }

    @Test func saveRecentSearch_addsSearchToList() {
        // Given
        keyedStorage._stringArray.implementation = .returns(nil)

        // When
        sut.saveRecentSearch("swift")

        // Then
        let saved = keyedStorage._setAny.lastInvocation?.0 as? [String]
        #expect(saved == ["swift"])
        #expect(keyedStorage._setAny.lastInvocation?.1 == recentSearchesKey)
        #expect(keyedStorage._stringArray.callCount == 1)
        #expect(keyedStorage._setAny.callCount == 1)
    }

    @Test func saveRecentSearch_deduplicatesAndMovesToEnd() {
        // Given
        keyedStorage._stringArray.implementation = .returns(["swift", "kotlin"])

        // When
        sut.saveRecentSearch("swift")

        // Then
        let saved = keyedStorage._setAny.lastInvocation?.0 as? [String]
        #expect(saved == ["kotlin", "swift"])
    }

    @Test func saveRecentSearch_dropsOldestWhenExceedingMax() {
        // Given
        let existing = (1...10).map { "search\($0)" }
        keyedStorage._stringArray.implementation = .returns(existing)

        // When
        sut.saveRecentSearch("search11")

        // Then
        let saved = keyedStorage._setAny.lastInvocation?.0 as? [String]
        #expect(saved?.count == 10)
        #expect(saved?.first == "search2")
        #expect(saved?.last == "search11")
    }

    @Test func clearRecentSearches_delegatesToKeyedStorage() {
        // When
        sut.clearRecentSearches()

        // Then
        #expect(keyedStorage._removeObject.callCount == 1)
        #expect(keyedStorage._removeObject.lastInvocation == recentSearchesKey)
    }

    @Test func parseOPML_delegatesToOPMLParser_andReturnsItsURLs() {
        // Given
        let expected = ["https://a.example.com/rss", "https://b.example.com/rss"]
        opmlParser._feedURLs.implementation = .returns(expected)
        let data = Data("<opml/>".utf8)

        // When
        let result = sut.parseOPML(data)

        // Then
        #expect(result == expected)
        #expect(opmlParser._feedURLs.callCount == 1)
        #expect(opmlParser._feedURLs.lastInvocation == data)
    }
}

// MARK: - KeyedStorageProtocolMock
@MockedMembers
final class KeyedStorageProtocolMock: KeyedStorageProtocol {
    func object(forKey defaultName: String) -> Any?

    @MockableMethod(mockMethodName: "setAny")
    func set(_ value: Any?, forKey defaultName: String)

    func bool(forKey defaultName: String) -> Bool

    @MockableMethod(mockMethodName: "setBool")
    func set(_ value: Bool, forKey defaultName: String)

    func stringArray(forKey defaultName: String) -> [String]?

    func removeObject(forKey defaultName: String)
}
