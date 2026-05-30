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
struct FeedsInteractorTests {

    // MARK: - Properties

    private let parser = ParserProtocolMock()
    private let storage = StorageProtocolMock()
    private let search = SearchableMock()
    private let explore = ExploreFeedsServiceProtocolMock()
    private let folders = FeedFolderManagingMock()
    private let container: NSPersistentContainer
    private let sut: FeedsInteractor

    // MARK: - Init

    init() {
        container = Self.makeInMemoryContainer()

        sut = FeedsInteractor(
            parser: parser,
            storage: storage,
            localSearchService: search,
            exploreFeedsService: explore,
            folderManager: folders
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
        let result = sut.checkIfFeedIsAlreadySaved(with: "https://example.com/feed")

        // Then
        #expect(result == true)
        #expect(storage._containsFeed.callCount == 1)
    }

    @Test func checkIfFeedIsAlreadySaved_whenFeedDoesNotExist_returnsFalse() {
        // Given
        storage._containsFeed.implementation = .returns(false)

        // When
        let result = sut.checkIfFeedIsAlreadySaved(with: "https://example.com/feed")

        // Then
        #expect(result == false)
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
        let urlString = "https://example.com/feed"

        // When
        sut.startParsingFeed(urlString) { _ in }

        // Then
        #expect(parser._setDelegate.callCount == 1)
        #expect(parser._beginParsingURL.callCount == 1)
    }

    @Test func startParsingFeed_onParsingSuccess_callsCompletionWithFeed() {
        // Given
        let feed = makeFeed()
        var receivedResult: Result<Feed, any Error>?

        sut.startParsingFeed("https://example.com/feed") { result in
            receivedResult = result
        }

        // When
        sut.didEndParsingFeed(feed)

        // Then
        guard case .success(let receivedFeed) = receivedResult else {
            Issue.record("Expected success result")
            return
        }
        #expect(receivedFeed.rssURL == feed.rssURL)
    }

    @Test func startParsingFeed_onParsingFailure_callsCompletionWithError() {
        // Given
        var receivedResult: Result<Feed, any Error>?

        sut.startParsingFeed("https://example.com/feed") { result in
            receivedResult = result
        }

        // When
        sut.didFailParsingFeed()

        // Then
        guard case .failure = receivedResult else {
            Issue.record("Expected failure result")
            return
        }
    }

    @Test func startParsingFeed_afterCompletion_nilsOutCompletion() {
        // Given
        var callCount = 0

        sut.startParsingFeed("https://example.com/feed") { _ in
            callCount += 1
        }

        // When
        sut.didEndParsingFeed(makeFeed())
        sut.didEndParsingFeed(makeFeed())

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
    }

    // MARK: - exploreFeeds

    @Test func exploreFeeds_delegatesToExploreService() {
        // When
        sut.exploreFeeds(on: "https://example.com") { _ in }

        // Then
        #expect(explore._searchFeedsOnWebPageCompletion.callCount == 1)
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
        let feed = makeFeed(rssURL: "https://example.com/rss")

        // When
        sut.deleteFeed(feed)

        // Then
        #expect(folders._removeFeed.callCount == 1)
        #expect(storage._delete.callCount == 1)
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
        let folder = FeedFolder(name: "Tech", feedURLs: ["https://example.com/rss"])
        folders._createFolder.implementation = .returns(folder)

        // When
        let created = sut.createFolder(name: "Tech", feedURLs: ["https://example.com/rss"])

        // Then
        #expect(created.name == "Tech")
        #expect(created.feedURLs == ["https://example.com/rss"])
        #expect(folders._createFolder.callCount == 1)
    }

    @Test func addFeedToFolder_delegatesToFolderManager() {
        // Given
        let folderId = UUID()

        // When
        sut.addFeedToFolder(url: "https://example.com/rss", folderId: folderId)

        // Then
        #expect(folders._addFeed.callCount == 1)
    }

    @Test func removeFeedFromFolder_delegatesToFolderManager() {
        // When
        sut.removeFeedFromFolder(url: "https://example.com/rss")

        // Then
        #expect(folders._removeFeed.callCount == 1)
    }

    @Test func toggleFolderExpanded_delegatesToFolderManager() {
        // Given
        let folderId = UUID()

        // When
        sut.toggleFolderExpanded(id: folderId)

        // Then
        #expect(folders._toggleExpanded.callCount == 1)
    }

    @Test func cleanupFolders_delegatesToFolderManager() {
        // Given
        let urls: Set<String> = ["https://example.com/rss"]

        // When
        sut.cleanupFolders(existingFeedURLs: urls)

        // Then
        #expect(folders._cleanupDeletedFeeds.callCount == 1)
    }

    // MARK: - Recent searches

    @Test func recentSearches_whenEmpty_returnsEmptyArray() {
        // Given
        sut.clearRecentSearches()

        // When
        let searches = sut.recentSearches()

        // Then
        #expect(searches.isEmpty)
    }

    @Test func saveRecentSearch_addsSearchToList() {
        // Given
        sut.clearRecentSearches()

        // When
        sut.saveRecentSearch("swift")

        // Then
        #expect(sut.recentSearches() == ["swift"])
    }

    @Test func saveRecentSearch_deduplicatesAndMovesToEnd() {
        // Given
        sut.clearRecentSearches()
        sut.saveRecentSearch("swift")
        sut.saveRecentSearch("kotlin")

        // When
        sut.saveRecentSearch("swift")

        // Then
        #expect(sut.recentSearches() == ["kotlin", "swift"])
    }

    @Test func saveRecentSearch_dropsOldestWhenExceedingMax() {
        // Given
        sut.clearRecentSearches()
        for index in 1...10 {
            sut.saveRecentSearch("search\(index)")
        }

        // When
        sut.saveRecentSearch("search11")

        // Then
        let searches = sut.recentSearches()
        #expect(searches.count == 10)
        #expect(searches.first == "search2")
        #expect(searches.last == "search11")
    }

    @Test func clearRecentSearches_removesAllSearches() {
        // Given
        sut.saveRecentSearch("swift")
        sut.saveRecentSearch("kotlin")

        // When
        sut.clearRecentSearches()

        // Then
        #expect(sut.recentSearches().isEmpty)
    }
}
