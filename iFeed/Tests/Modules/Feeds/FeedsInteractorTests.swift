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

@Suite(.serialized)
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
            keyedStorage: keyedStorage
        )
    }

    // MARK: - Helpers

    /// Creates an in-memory Core Data stack;
    /// the `name` only locates the `.xcdatamodeld` schema — no SQLite file is written to disk.
    private static func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "iFeed")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
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

    private func stubStorageMakeFeed() {
        storage._makeFeed.implementation = .uncheckedInvokes { [container] in
            return Feed(context: container.viewContext)
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
        stubStorageMakeFeed()
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

    @Test func startParsingFeed_afterCompletion_nilsOutCompletion() {
        // Given
        stubStorageMakeFeed()
        var callCount = 0

        sut.startParsingFeed(testFeedURL) { _ in
            callCount += 1
        }

        // When
        sut.didEndParsingFeed(with: makeParsedFeedData())
        sut.didEndParsingFeed(with: makeParsedFeedData())

        // Then
        #expect(callCount == 1)
    }

    // MARK: - fillSearchMatchingEngine

    @Test func fillSearchMatchingEngine_delegatesToSearchService() {
        // Given
        var completionCalled = false
        search._fillMatchingEngine.implementation = .invokes { completion in
            completion()
        }

        // When
        sut.fillSearchMatchingEngine {
            completionCalled = true
        }

        // Then
        #expect(completionCalled)
        #expect(search._fillMatchingEngine.callCount == 1)
    }

    // MARK: - performSearch

    @Test func performSearch_delegatesToSearchService() {
        // Given
        var receivedResults: [FeedItem]?
        search._search.implementation = .invokes { _, resultsFound in
            resultsFound(nil)
        }

        // When
        sut.performSearch(by: "swift") { results in
            receivedResults = results
        }

        // Then
        #expect(receivedResults == nil)
        #expect(search._search.callCount == 1)
        #expect(search._search.lastInvocation?.0 == "swift")
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
