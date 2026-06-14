//
//  FeedFolderTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 30.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

@Suite("FeedFolder Tests")
struct FeedFolderTests {

    // MARK: - Init

    @Test("Default init sets isExpanded to true")
    func defaultInitIsExpanded() {
        // Given
        // When
        let folder = FeedFolder(name: "Tech", feedURLs: ["https://a.com"])

        // Then
        #expect(folder.isExpanded == true)
    }

    @Test("Default init generates a UUID")
    func defaultInitGeneratesID() {
        // Given
        // When
        let folder = FeedFolder(name: "Tech", feedURLs: ["https://a.com"])

        // Then
        #expect(folder.id.uuidString.isEmpty == false)
    }

    @Test("Init with explicit ID uses provided value")
    func initWithExplicitID() {
        // Given
        let expectedID = UUID()

        // When
        let folder = FeedFolder(id: expectedID, name: "News", feedURLs: ["https://b.com"])

        // Then
        #expect(folder.id == expectedID)
    }

    @Test("Init stores name correctly")
    func initStoresName() {
        // Given
        let expectedName = "Sports"

        // When
        let folder = FeedFolder(name: expectedName, feedURLs: [])

        // Then
        #expect(folder.name == expectedName)
    }

    @Test("Init stores feedURLs correctly")
    func initStoresFeedURLs() {
        // Given
        let urls = ["https://a.com/rss", "https://b.com/rss"]

        // When
        let folder = FeedFolder(name: "Tech", feedURLs: urls)

        // Then
        #expect(folder.feedURLs == urls)
    }

    @Test("Init with empty feedURLs")
    func initWithEmptyFeedURLs() {
        // Given
        // When
        let folder = FeedFolder(name: "Empty", feedURLs: [])

        // Then
        #expect(folder.feedURLs.isEmpty)
    }

    // MARK: - Equatable

    @Test("Folders with same properties are equal")
    func equalFolders() {
        // Given
        let id = UUID()
        let folder1 = FeedFolder(id: id, name: "Tech", feedURLs: ["https://a.com"])
        var folder2 = FeedFolder(id: id, name: "Tech", feedURLs: ["https://a.com"])
        folder2.isExpanded = true

        // When
        let areEqual = folder1 == folder2

        // Then
        #expect(areEqual)
    }

    @Test("Folders with different IDs are not equal")
    func notEqualDifferentIDs() {
        // Given
        let folder1 = FeedFolder(name: "Tech", feedURLs: ["https://a.com"])
        let folder2 = FeedFolder(name: "Tech", feedURLs: ["https://a.com"])

        // When
        let areEqual = folder1 == folder2

        // Then
        #expect(areEqual == false)
    }

    @Test("Folders with different isExpanded are not equal")
    func notEqualDifferentExpanded() {
        // Given
        let id = UUID()
        var folder1 = FeedFolder(id: id, name: "Tech", feedURLs: ["https://a.com"])
        var folder2 = FeedFolder(id: id, name: "Tech", feedURLs: ["https://a.com"])
        folder1.isExpanded = true
        folder2.isExpanded = false

        // When
        let areEqual = folder1 == folder2

        // Then
        #expect(areEqual == false)
    }

    // MARK: - Codable

    @Test("Encode and decode preserves all properties")
    func codableRoundTrip() throws {
        // Given
        let original = FeedFolder(name: "Tech", feedURLs: ["https://a.com", "https://b.com"])

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FeedFolder.self, from: data)

        // Then
        #expect(decoded == original)
    }

    @Test("Encode and decode preserves isExpanded false")
    func codablePreservesExpandedFalse() throws {
        // Given
        var original = FeedFolder(name: "News", feedURLs: ["https://c.com"])
        original.isExpanded = false

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FeedFolder.self, from: data)

        // Then
        #expect(decoded.isExpanded == false)
        #expect(decoded == original)
    }

    // MARK: - Mutability

    @Test("Name is mutable")
    func nameMutable() {
        // Given
        var folder = FeedFolder(name: "Old", feedURLs: [])

        // When
        folder.name = "New"

        // Then
        #expect(folder.name == "New")
    }

    @Test("feedURLs is mutable")
    func feedURLsMutable() {
        // Given
        var folder = FeedFolder(name: "Tech", feedURLs: ["https://a.com"])

        // When
        folder.feedURLs.append("https://b.com")

        // Then
        #expect(folder.feedURLs == ["https://a.com", "https://b.com"])
    }

    @Test("isExpanded is mutable")
    func isExpandedMutable() {
        // Given
        var folder = FeedFolder(name: "Tech", feedURLs: [])

        // When
        folder.isExpanded = false

        // Then
        #expect(folder.isExpanded == false)
    }
}
