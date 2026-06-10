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

    // MARK: - FeedItem.htmlContent ↔ FeedItemContent bridging

    @Test("htmlContent is nil when no content child exists")
    func htmlContent_whenNoChild_isNil() throws {
        let container = try makeInMemoryContainer()
        let item = FeedItem(context: container.viewContext)

        #expect(item.htmlContent == nil)
        #expect(item.content == nil)
    }

    @Test("setting htmlContent creates the content child")
    func htmlContent_set_createsChild() throws {
        let container = try makeInMemoryContainer()
        let item = FeedItem(context: container.viewContext)

        item.htmlContent = "<p>Hello</p>"

        #expect(item.htmlContent == "<p>Hello</p>")
        #expect(item.content?.htmlContent == "<p>Hello</p>")
        #expect(item.content?.item === item)
    }

    @Test("overwriting htmlContent reuses the existing child")
    func htmlContent_overwrite_reusesChild() throws {
        let container = try makeInMemoryContainer()
        let item = FeedItem(context: container.viewContext)

        item.htmlContent = "<p>First</p>"
        let firstChild = item.content
        item.htmlContent = "<p>Second</p>"

        #expect(item.content === firstChild)
        #expect(item.htmlContent == "<p>Second</p>")
    }

    @Test("setting htmlContent to nil deletes the content child")
    func htmlContent_setNil_deletesChild() throws {
        let container = try makeInMemoryContainer()
        let item = FeedItem(context: container.viewContext)

        item.htmlContent = "<p>Hello</p>"
        let child = try #require(item.content)
        item.htmlContent = nil

        #expect(item.htmlContent == nil)
        #expect(item.content == nil)
        #expect(child.isDeleted)
    }

    @Test("deleting a feed cascades to items and their content")
    func deletingFeed_cascadesToContent() throws {
        let container = try makeInMemoryContainer()
        let context = container.viewContext

        let feed = Feed(context: context)
        feed.rssURL = "https://example.com/feed"

        let item = FeedItem(context: context)
        item.title = "Item"
        item.link = "https://example.com/item"
        item.publishDate = Date()
        item.feed = feed
        item.htmlContent = "<p>Body</p>"
        try context.save()

        context.delete(feed)
        try context.save()

        let itemCount = try context.count(for: NSFetchRequest<FeedItem>(entityName: "FeedItem"))
        let contentCount = try context.count(for: NSFetchRequest<FeedItemContent>(entityName: "FeedItemContent"))
        #expect(itemCount == 0)
        #expect(contentCount == 0)
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
