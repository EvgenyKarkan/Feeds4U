//
//  FeedsViewStateTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 31.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import CoreData
@testable import iFeed

@Suite
struct FeedsViewStateTests {

    // MARK: - Properties

    private let container: NSPersistentContainer

    // MARK: - Init

    init() {
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

    private func makeFeed(rssURL: String = "https://example.com/feed", title: String = "Test") -> Feed {
        let feed = Feed(context: container.viewContext)
        feed.rssURL = rssURL
        feed.title = title
        feed.feedItems = NSSet()
        return feed
    }

    private func makeFolder(name: String = "Folder", feedURLs: [String] = []) -> FeedFolder {
        return FeedFolder(name: name, feedURLs: feedURLs)
    }
}

// MARK: - FeedsSection Tests

extension FeedsViewStateTests {

    @Test func section_initWithFolder_storesFolderAndFeeds() {
        // Given
        let folder = makeFolder(name: "Tech")
        let feed = makeFeed()

        // When
        let section = FeedsSection(folder: folder, feeds: [feed])

        // Then
        #expect(section.folder?.name == "Tech")
        #expect(section.feeds.count == 1)
    }

    @Test func section_initWithoutFolder_folderIsNil() {
        // Given
        let feed = makeFeed()

        // When
        let section = FeedsSection(folder: nil, feeds: [feed])

        // Then
        #expect(section.folder == nil)
        #expect(section.feeds.count == 1)
    }

    @Test func section_initWithEmptyFeeds_feedsArrayIsEmpty() {
        // When
        let section = FeedsSection(folder: nil, feeds: [])

        // Then
        #expect(section.feeds.isEmpty)
    }

    @Test func section_initWithMultipleFeeds_preservesOrder() {
        // Given
        let feedA = makeFeed(rssURL: "https://a.com", title: "A")
        let feedB = makeFeed(rssURL: "https://b.com", title: "B")
        let feedC = makeFeed(rssURL: "https://c.com", title: "C")

        // When
        let section = FeedsSection(folder: nil, feeds: [feedA, feedB, feedC])

        // Then
        #expect(section.feeds.count == 3)
        #expect(section.feeds[0].title == "A")
        #expect(section.feeds[1].title == "B")
        #expect(section.feeds[2].title == "C")
    }
}

// MARK: - FeedsViewState Tests

extension FeedsViewStateTests {

    @Test func init_defaultValues_sectionsAndUnreadCountsAreEmpty() {
        // When
        let sut = FeedsViewState()

        // Then
        #expect(sut.sections.isEmpty)
        #expect(sut.unreadCounts.isEmpty)
    }

    @Test func init_withSections_storesSections() {
        // Given
        let feed = makeFeed()
        let section = FeedsSection(folder: nil, feeds: [feed])

        // When
        let sut = FeedsViewState(sections: [section])

        // Then
        #expect(sut.sections.count == 1)
        #expect(sut.sections[0].feeds.count == 1)
    }

    @Test func init_withUnreadCounts_storesCounts() {
        // Given
        let feed = makeFeed()
        let counts: [NSManagedObjectID: Int] = [feed.objectID: 5]

        // When
        let sut = FeedsViewState(unreadCounts: counts)

        // Then
        #expect(sut.unreadCounts[feed.objectID] == 5)
    }

    @Test func allFeeds_withNoSections_returnsEmptyArray() {
        // Given
        let sut = FeedsViewState()

        // When
        let result = sut.allFeeds

        // Then
        #expect(result.isEmpty)
    }

    @Test func allFeeds_withSingleSection_returnsFeedsFromThatSection() {
        // Given
        let feedA = makeFeed(title: "A")
        let feedB = makeFeed(title: "B")
        let section = FeedsSection(folder: nil, feeds: [feedA, feedB])
        let sut = FeedsViewState(sections: [section])

        // When
        let result = sut.allFeeds

        // Then
        #expect(result.count == 2)
        #expect(result[0].title == "A")
        #expect(result[1].title == "B")
    }

    @Test func allFeeds_withMultipleSections_flatMapsAllFeeds() {
        // Given
        let feedA = makeFeed(title: "A")
        let feedB = makeFeed(title: "B")
        let feedC = makeFeed(title: "C")

        let section1 = FeedsSection(folder: makeFolder(name: "Folder1"), feeds: [feedA])
        let section2 = FeedsSection(folder: nil, feeds: [feedB, feedC])

        let sut = FeedsViewState(sections: [section1, section2])

        // When
        let result = sut.allFeeds

        // Then
        #expect(result.count == 3)
        #expect(result[0].title == "A")
        #expect(result[1].title == "B")
        #expect(result[2].title == "C")
    }

    @Test func allFeeds_withEmptySection_skipsItGracefully() {
        // Given
        let feed = makeFeed(title: "Only")
        let emptySection = FeedsSection(folder: makeFolder(name: "Empty"), feeds: [])
        let populatedSection = FeedsSection(folder: nil, feeds: [feed])

        let sut = FeedsViewState(sections: [emptySection, populatedSection])

        // When
        let result = sut.allFeeds

        // Then
        #expect(result.count == 1)
        #expect(result[0].title == "Only")
    }
}
