//
//  FeedTests.swift
//  iFeedTests
//
//  Created by Gemini CLI on 07.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import CoreData
@testable import iFeed

@Suite("Feed Entity Tests")
struct FeedTests {

    @Test("sortedItems handles empty items")
    func sortedItems_empty() throws {
        let container = try makeInMemoryContainer()
        let feed = Feed(context: container.viewContext)

        #expect(feed.sortedItems().isEmpty)
    }

    @Test("sortedItems sorts by date descending")
    func sortedItems_sorting() throws {
        let container = try makeInMemoryContainer()
        let feed = Feed(context: container.viewContext)

        let item1 = FeedItem(context: container.viewContext)
        item1.publishDate = Date(timeIntervalSince1970: 1000)
        item1.feed = feed

        let item2 = FeedItem(context: container.viewContext)
        item2.publishDate = Date(timeIntervalSince1970: 2000)
        item2.feed = feed

        let sorted = feed.sortedItems()
        #expect(sorted.count == 2)
        #expect(sorted[0].publishDate.timeIntervalSince1970 == 2000)
        #expect(sorted[1].publishDate.timeIntervalSince1970 == 1000)
    }

    private func makeInMemoryContainer() throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "iFeed", managedObjectModel: TestCoreDataModel.shared)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, _ in }
        return container
    }
}
