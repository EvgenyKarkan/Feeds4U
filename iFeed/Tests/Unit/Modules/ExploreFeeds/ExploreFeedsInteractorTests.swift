//
//  ExploreFeedsInteractorTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
import Mocking
import CoreData
@testable import iFeed

@Suite("ExploreFeeds Interactor Tests")
@MainActor
struct ExploreFeedsInteractorTests {

    private let parser = ParserProtocolMock()
    private let storage = StorageProtocolMock()
    private let search = SearchableMock()
    private let container: NSPersistentContainer
    private let webPage = "https://example.com"

    init() {
        container = Self.makeInMemoryContainer()
        storage._savedFeedURLs.implementation = .returns([])
    }

    // MARK: - Helpers

    private func makeSUT(results: ExploreFeedsDTO = []) -> ExploreFeedsInteractor {
        ExploreFeedsInteractor(
            results: results,
            webPage: webPage,
            parser: parser,
            storage: storage,
            localSearchService: search
        )
    }

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

    private func makeElement(rssURL: String?) -> ExploreFeedsElement {
        ExploreFeedsElement(description: nil, favicon: nil, selfURL: rssURL,
                            siteName: nil, siteURL: nil, title: nil, url: nil)
    }

    private func makeParsedFeedData(title: String = "Test Feed") -> ParsedFeedData {
        ParsedFeedData(title: title, summary: nil, items: [])
    }

    private func stubStorageImportFeed() {
        storage._importFeed.implementation = .uncheckedInvokes { [container] data, rssURL, completion in
            let feed = Feed(context: container.viewContext)
            feed.title = data.title
            feed.rssURL = rssURL
            completion(feed.objectID)
        }
        storage._loadFeed.implementation = .uncheckedInvokes { [container] id in
            (try? container.viewContext.existingObject(with: id)) as? Feed
        }
    }

    // MARK: - getWebPageTitle

    @Test func getWebPageTitle_returnsWebPage() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.getWebPageTitle() == webPage)
    }

    // MARK: - getResultsWithSavedStatus

    @Test func getResultsWithSavedStatus_marksSavedElementsAsAdded() {
        // Given — one element is already stored, the other is not.
        storage._savedFeedURLs.implementation = .returns(["https://a.com/rss"])
        let sut = makeSUT(results: [makeElement(rssURL: "https://a.com/rss"),
                                    makeElement(rssURL: "https://b.com/rss")])

        // When
        let results = sut.getResultsWithSavedStatus()

        // Then
        #expect(results.count == 2)
        #expect(results[0].isAdded == true)
        #expect(results[1].isAdded == false)
    }

    // MARK: - checkIfFeedIsAlreadySaved

    @Test func checkIfFeedIsAlreadySaved_delegatesToStorage() {
        // Given
        storage._containsFeed.implementation = .returns(true)
        let sut = makeSUT()

        // When
        let saved = sut.checkIfFeedIsAlreadySaved(with: "https://a.com/rss")

        // Then
        #expect(saved == true)
        #expect(storage._containsFeed.lastInvocation == "https://a.com/rss")
    }

    // MARK: - saveContext

    @Test func saveContext_callsStorageSaveChanges() throws {
        // Given
        let sut = makeSUT()

        // When
        try sut.saveContext()

        // Then
        #expect(storage._saveChanges.callCount == 1)
    }

    // MARK: - startParsingFeed

    @Test func startParsingFeed_withEmptyURL_callsFailureAndSkipsParser() {
        // Given
        let sut = makeSUT()
        var receivedResult: Result<Feed, any Error>?

        // When
        sut.startParsingFeed("") { receivedResult = $0 }

        // Then
        guard case .failure = receivedResult else {
            Issue.record("Expected failure for empty URL")
            return
        }
        #expect(parser._setDelegate.callCount == 0)
        #expect(parser._beginParsingURL.callCount == 0)
    }

    @Test func startParsingFeed_withValidURL_setsDelegateAndBeginsParsing() {
        // Given
        let sut = makeSUT()
        let url = "https://example.com/rss"

        // When
        sut.startParsingFeed(url) { _ in }

        // Then
        #expect(parser._setDelegate.callCount == 1)
        #expect(parser._beginParsingURL.lastInvocation == URL(string: url))
    }

    // MARK: - ParserDelegate callbacks

    @Test func didEndParsingFeed_onSuccess_completesWithFeedAndMarksIndexDirty() {
        // Given
        stubStorageImportFeed()
        let sut = makeSUT()
        var receivedResult: Result<Feed, any Error>?
        sut.startParsingFeed("https://example.com/rss") { receivedResult = $0 }

        // When
        sut.didEndParsingFeed(with: makeParsedFeedData())

        // Then
        guard case .success = receivedResult else {
            Issue.record("Expected a feed on success")
            return
        }
        #expect(search._markIndexDirty.callCount == 1)
    }

    @Test func didEndParsingFeed_whenFeedCreationFails_completesWithFailure() {
        // Given — import reports no feed ID, so creation is considered failed.
        storage._importFeed.implementation = .uncheckedInvokes { _, _, completion in completion(nil) }
        let sut = makeSUT()
        var receivedResult: Result<Feed, any Error>?
        sut.startParsingFeed("https://example.com/rss") { receivedResult = $0 }

        // When
        sut.didEndParsingFeed(with: makeParsedFeedData())

        // Then
        guard case .failure = receivedResult else {
            Issue.record("Expected failure when no feed ID is returned")
            return
        }
        #expect(search._markIndexDirty.callCount == 0)
    }

    @Test func didFailParsingFeed_completesWithError() {
        // Given
        enum TestError: Error { case boom }
        let sut = makeSUT()
        var receivedResult: Result<Feed, any Error>?
        sut.startParsingFeed("https://example.com/rss") { receivedResult = $0 }

        // When
        sut.didFailParsingFeed(with: TestError.boom)

        // Then
        guard case .failure = receivedResult else {
            Issue.record("Expected failure to be forwarded")
            return
        }
    }

    @Test func didCancelParsingFeed_doesNotInvokeCompletion() {
        // Given
        let sut = makeSUT()
        var completionCalls = 0
        sut.startParsingFeed("https://example.com/rss") { _ in completionCalls += 1 }

        // When — cancel, then a late failure should find no completion to call.
        sut.didCancelParsingFeed()
        sut.didFailParsingFeed(with: StorageError.feedCreationFailed)

        // Then
        #expect(completionCalls == 0)
    }
}
