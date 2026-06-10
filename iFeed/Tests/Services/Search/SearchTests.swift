//
//  SearchTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 06.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import CoreData
import Foundation
import Mocking
@testable @preconcurrency import SimpleSimilarity
import Testing
@testable import iFeed

@Suite("Search Tests")
@MainActor
struct SearchTests {

    // MARK: - Properties

    private let storageMock: StorageProtocolMock
    private let textMatchingMock: TextMatchingMock
    private let container: NSPersistentContainer

    // MARK: - Init

    init() {
        storageMock = StorageProtocolMock()
        textMatchingMock = TextMatchingMock()
        container = Self.makeInMemoryContainer()
    }

    // MARK: - Helpers

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

    private func makeSUT() -> Search {
        let mock = textMatchingMock
        return Search(storage: storageMock, matchingEngineFactory: { mock })
    }

    private func makeFeedItem(
        title: String,
        link: String = "https://example.com",
        publishDate: Date = Date()
    ) -> FeedItem {
        let feed = Feed(context: container.viewContext)
        feed.rssURL = "https://example.com/feed"
        feed.title = "Test Feed"
        feed.feedItems = NSSet()

        let item = FeedItem(context: container.viewContext)
        item.title = title
        item.link = link
        item.publishDate = publishDate
        item.wasRead = NSNumber(value: false)
        item.feed = feed
        return item
    }

    private func fillSUT(_ sut: Search) async {
        textMatchingMock._fillMatchingEngine.implementation = .invokes { _, _, completion in
            completion()
        }
        textMatchingMock._isFilled.getter.implementation = .returns(true)
        await sut.fillMatchingEngine()
    }

    // MARK: - fillMatchingEngine — nil storage

    @Test func fillMatchingEngine_whenStorageReturnsNil_returnsImmediately() async {
        // Given
        storageMock._loadFeedItemIndex.implementation = .returns(nil)
        let sut = makeSUT()

        // When
        await sut.fillMatchingEngine()

        // Then
        #expect(textMatchingMock._fillMatchingEngine.callCount == 0)
    }

    // MARK: - fillMatchingEngine — empty storage

    @Test func fillMatchingEngine_whenStorageReturnsEmpty_returnsImmediately() async {
        // Given
        storageMock._loadFeedItemIndex.implementation = .returns([])
        let sut = makeSUT()

        // When
        await sut.fillMatchingEngine()

        // Then
        #expect(textMatchingMock._fillMatchingEngine.callCount == 0)
    }

    // MARK: - fillMatchingEngine — dirty-flag lifecycle

    @Test func fillMatchingEngine_whenIndexIsClean_skipsReindexing() async {
        // Given
        let item = makeFeedItem(title: "Test Article")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test Article", objectID: item.objectID)
        ])
        textMatchingMock._fillMatchingEngine.implementation = .invokes { _, _, completion in
            completion()
        }
        let sut = makeSUT()

        // When — second fill must be a no-op: the corpus has not been marked dirty.
        await sut.fillMatchingEngine()
        await sut.fillMatchingEngine()

        // Then
        #expect(textMatchingMock._fillMatchingEngine.callCount == 1)
        #expect(storageMock._loadFeedItemIndex.callCount == 1)
    }

    @Test func markIndexDirty_forcesRebuildOnNextFill() async {
        // Given
        let item = makeFeedItem(title: "Test Article")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test Article", objectID: item.objectID)
        ])
        textMatchingMock._fillMatchingEngine.implementation = .invokes { _, _, completion in
            completion()
        }
        let sut = makeSUT()
        await sut.fillMatchingEngine()

        // When
        sut.markIndexDirty()
        await sut.fillMatchingEngine()

        // Then
        #expect(textMatchingMock._fillMatchingEngine.callCount == 2)
    }

    // MARK: - fillMatchingEngine — with items

    @Test func fillMatchingEngine_whenItemsExist_createsEngineAndFillsIt() async {
        // Given
        let item = makeFeedItem(title: "Test Article")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test Article", objectID: item.objectID)
        ])
        textMatchingMock._fillMatchingEngine.implementation = .invokes { _, _, completion in
            completion()
        }
        let sut = makeSUT()

        // When
        await sut.fillMatchingEngine()

        // Then
        #expect(textMatchingMock._fillMatchingEngine.callCount == 1)
    }

    @Test func fillMatchingEngine_passesCorrectTextualDataAndStopwordsFlag() async {
        // Given
        let item1 = makeFeedItem(title: "Article One")
        let item2 = makeFeedItem(title: "Article Two")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Article One", objectID: item1.objectID),
            (title: "Article Two", objectID: item2.objectID)
        ])

        nonisolated(unsafe) var capturedCorpus: [TextualData]?
        nonisolated(unsafe) var capturedStopwordsFlag: Bool?
        textMatchingMock._fillMatchingEngine.implementation = .invokes { corpus, stopwords, completion in
            capturedCorpus = corpus
            capturedStopwordsFlag = stopwords
            completion()
        }
        let sut = makeSUT()

        // When
        await sut.fillMatchingEngine()

        // Then
        #expect(capturedCorpus?.count == 2)
        #expect(capturedCorpus?[0].inputString == "Article One")
        #expect(capturedCorpus?[1].inputString == "Article Two")
        #expect(capturedCorpus?[0].originObject === item1.objectID)
        #expect(capturedCorpus?[1].originObject === item2.objectID)
        #expect(capturedStopwordsFlag == true)
    }

    // MARK: - search — engine not created

    @Test func search_whenEngineNotCreated_returnsNil() async {
        // Given
        let sut = makeSUT()

        // When
        let result = await sut.search(for: "test")

        // Then
        #expect(result == nil)
    }

    // MARK: - search — engine exists but not filled

    @Test func search_whenEngineExistsButNotFilled_returnsNil() async {
        // Given
        let item = makeFeedItem(title: "Test")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test", objectID: item.objectID)
        ])
        textMatchingMock._fillMatchingEngine.implementation = .invokes { _, _, completion in
            completion()
        }
        textMatchingMock._isFilled.getter.implementation = .returns(false)

        let sut = makeSUT()
        await sut.fillMatchingEngine()

        // When
        let result = await sut.search(for: "test")

        // Then
        #expect(result == nil)
    }

    // MARK: - search — engine returns nil results

    @Test func search_whenEngineReturnsNilResults_returnsNil() async {
        // Given
        let item = makeFeedItem(title: "Test")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test", objectID: item.objectID)
        ])
        textMatchingMock._results.implementation = .invokes { _, _, resultsFound in
            resultsFound(nil)
        }

        let sut = makeSUT()
        await fillSUT(sut)

        // When
        let result = await sut.search(for: "test")

        // Then
        #expect(result == nil)
    }

    // MARK: - search — engine returns empty results

    @Test func search_whenEngineReturnsEmptyResults_returnsNil() async {
        // Given
        let item = makeFeedItem(title: "Test")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test", objectID: item.objectID)
        ])
        textMatchingMock._results.implementation = .invokes { _, _, resultsFound in
            resultsFound([])
        }

        let sut = makeSUT()
        await fillSUT(sut)

        // When
        let result = await sut.search(for: "test")

        // Then
        #expect(result == nil)
    }

    // MARK: - search — engine returns valid results

    @Test func search_whenEngineReturnsResults_returnsFeedItems() async {
        // Given
        let feedItem = makeFeedItem(title: "Swift Article", publishDate: Date())
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Swift Article", objectID: feedItem.objectID)
        ])

        let textualData = TextualData(
            inputString: "Swift Article",
            origin: nil,
            originObject: feedItem.objectID
        )
        let searchResult = SimpleSimilarity.Result(
            textualResults: [textualData],
            quality: 0.9
        )
        textMatchingMock._results.implementation = .invokes { _, _, resultsFound in
            resultsFound([searchResult])
        }
        storageMock._loadFeedItemsWithIDsObjectIDs.implementation = .uncheckedInvokes { _ in [feedItem] }

        let sut = makeSUT()
        await fillSUT(sut)

        // When
        let result = await sut.search(for: "Swift")

        // Then
        #expect(result?.count == 1)
        #expect(result?.first?.title == "Swift Article")
    }

    // MARK: - search — sorting by publish date

    @Test func search_sortsByPublishDateDescending() async {
        // Given
        let now = Date()
        let older = makeFeedItem(title: "Older", publishDate: now.addingTimeInterval(-3600))
        let newer = makeFeedItem(title: "Newer", publishDate: now)
        let oldest = makeFeedItem(title: "Oldest", publishDate: now.addingTimeInterval(-7200))

        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Older", objectID: older.objectID),
            (title: "Newer", objectID: newer.objectID),
            (title: "Oldest", objectID: oldest.objectID)
        ])

        let results = [older, newer, oldest].map { item in
            SimpleSimilarity.Result(
                textualResults: [TextualData(
                    inputString: item.title,
                    origin: nil,
                    originObject: item.objectID
                )],
                quality: 0.5
            )
        }
        textMatchingMock._results.implementation = .invokes { _, _, resultsFound in
            resultsFound(results)
        }
        storageMock._loadFeedItemsWithIDsObjectIDs.implementation = .uncheckedInvokes { objectIDs in
            [older, newer, oldest].filter { objectIDs.contains($0.objectID) }
        }

        let sut = makeSUT()
        await fillSUT(sut)

        // When
        let result = await sut.search(for: "article")

        // Then
        #expect(result?.count == 3)
        #expect(result?[0].title == "Newer")
        #expect(result?[1].title == "Older")
        #expect(result?[2].title == "Oldest")
    }

    // MARK: - search — deduplication

    @Test func search_deduplicatesByObjectID() async {
        // Given
        let feedItem = makeFeedItem(title: "Duplicate", publishDate: Date())
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Duplicate", objectID: feedItem.objectID)
        ])

        let textualData = TextualData(
            inputString: "Duplicate",
            origin: nil,
            originObject: feedItem.objectID
        )
        let result1 = SimpleSimilarity.Result(textualResults: [textualData], quality: 0.9)
        let result2 = SimpleSimilarity.Result(textualResults: [textualData], quality: 0.8)
        textMatchingMock._results.implementation = .invokes { _, _, resultsFound in
            resultsFound([result1, result2])
        }
        storageMock._loadFeedItemsWithIDsObjectIDs.implementation = .uncheckedInvokes { _ in [feedItem, feedItem] }

        let sut = makeSUT()
        await fillSUT(sut)

        // When
        let result = await sut.search(for: "Duplicate")

        // Then
        #expect(result?.count == 1)
        #expect(result?.first?.title == "Duplicate")
    }

    // MARK: - search — no valid objectIDs in results

    @Test func search_whenNoValidObjectIDsInResults_returnsNil() async {
        // Given
        let item = makeFeedItem(title: "Test")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test", objectID: item.objectID)
        ])

        let textualData = TextualData(inputString: "Test", origin: nil, originObject: nil)
        let searchResult = SimpleSimilarity.Result(textualResults: [textualData], quality: 0.5)
        textMatchingMock._results.implementation = .invokes { _, _, resultsFound in
            resultsFound([searchResult])
        }

        let sut = makeSUT()
        await fillSUT(sut)

        // When
        let result = await sut.search(for: "Test")

        // Then
        #expect(result == nil)
    }

    // MARK: - search — storage returns empty matched items

    @Test func search_whenStorageReturnsNoMatchedItems_returnsNil() async {
        // Given
        let item = makeFeedItem(title: "Test")
        storageMock._loadFeedItemIndex.implementation = .returns([
            (title: "Test", objectID: item.objectID)
        ])

        let textualData = TextualData(
            inputString: "Test",
            origin: nil,
            originObject: item.objectID
        )
        let searchResult = SimpleSimilarity.Result(textualResults: [textualData], quality: 0.5)
        textMatchingMock._results.implementation = .invokes { _, _, resultsFound in
            resultsFound([searchResult])
        }
        storageMock._loadFeedItemsWithIDsObjectIDs.implementation = .uncheckedInvokes { _ in [] }

        let sut = makeSUT()
        await fillSUT(sut)

        // When
        let result = await sut.search(for: "Test")

        // Then
        #expect(result == nil)
    }
}
