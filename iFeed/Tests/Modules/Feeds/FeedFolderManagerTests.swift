//
//  FeedFolderManagerTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 30.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

private enum TestError: Error {
    case userDefaultsInitFailed
}

@Suite("FeedFolderManager Tests", .serialized)
struct FeedFolderManagerTests {

    // MARK: - Properties
    private static let suiteName = "com.ifeed.tests.FeedFolderManager"
    private let defaults: UserDefaults
    private let sut: FeedFolderManager

    // MARK: - Init
    init() throws {
        guard let defaults = UserDefaults(suiteName: Self.suiteName) else {
            throw TestError.userDefaultsInitFailed
        }
        defaults.removePersistentDomain(forName: Self.suiteName)
        self.defaults = defaults
        self.sut = FeedFolderManager(defaults: defaults)
    }

    // MARK: - loadFolders

    @Test("Load folders returns empty array when nothing is persisted")
    func testLoadFoldersReturnsEmptyByDefault() {
        // Given
        // When
        let folders = sut.loadFolders()

        // Then
        #expect(folders.isEmpty)
    }

    @Test("Load folders returns previously created folders")
    func testLoadFoldersReturnsSavedFolders() {
        // Given
        sut.createFolder(name: "Tech", feedURLs: ["https://a.com/rss"])
        sut.createFolder(name: "News", feedURLs: ["https://b.com/rss"])

        // When
        let folders = sut.loadFolders()

        // Then
        #expect(folders.count == 2)
        #expect(folders[0].name == "Tech")
        #expect(folders[1].name == "News")
    }

    // MARK: - createFolder

    @Test("Create folder returns folder with correct properties")
    func testCreateFolderProperties() {
        // Given
        // When
        let folder = sut.createFolder(name: "Sports", feedURLs: ["https://espn.com/rss"])

        // Then
        #expect(folder.name == "Sports")
        #expect(folder.feedURLs == ["https://espn.com/rss"])
        #expect(folder.isExpanded == true)
    }

    @Test("Create folder persists immediately")
    func testCreateFolderPersists() {
        // Given
        sut.createFolder(name: "Saved", feedURLs: ["https://x.com/rss"])

        // When
        let freshManager = FeedFolderManager(defaults: defaults)
        let folders = freshManager.loadFolders()

        // Then
        #expect(folders.count == 1)
        #expect(folders[0].name == "Saved")
    }

    @Test("Create folder assigns unique IDs")
    func testCreateFolderUniqueIDs() {
        // Given
        // When
        let folder1 = sut.createFolder(name: "A", feedURLs: ["https://a.com"])
        let folder2 = sut.createFolder(name: "B", feedURLs: ["https://b.com"])

        // Then
        #expect(folder1.id != folder2.id)
    }

    // MARK: - addFeed

    @Test("Add feed to folder appends URL")
    func testAddFeedAppendsURL() {
        // Given
        let folder = sut.createFolder(name: "Tech", feedURLs: ["https://a.com"])

        // When
        sut.addFeed(url: "https://b.com", toFolderWithId: folder.id)

        // Then
        let folders = sut.loadFolders()
        #expect(folders[0].feedURLs == ["https://a.com", "https://b.com"])
    }

    @Test("Add feed removes it from previous folder")
    func testAddFeedMovesFromOtherFolder() {
        // Given
        let folder1 = sut.createFolder(name: "Old", feedURLs: ["https://a.com", "https://shared.com"])
        let folder2 = sut.createFolder(name: "New", feedURLs: ["https://b.com"])

        // When
        sut.addFeed(url: "https://shared.com", toFolderWithId: folder2.id)

        // Then
        let folders = sut.loadFolders()
        let old = folders.first(where: { $0.id == folder1.id })
        let new = folders.first(where: { $0.id == folder2.id })
        #expect(old?.feedURLs == ["https://a.com"])
        #expect(new?.feedURLs == ["https://b.com", "https://shared.com"])
    }

    @Test("Add feed deletes source folder when it becomes empty")
    func testAddFeedDeletesEmptySourceFolder() {
        // Given
        sut.createFolder(name: "Solo", feedURLs: ["https://only.com"])
        let folder2 = sut.createFolder(name: "Target", feedURLs: ["https://b.com"])

        // When
        sut.addFeed(url: "https://only.com", toFolderWithId: folder2.id)

        // Then
        let folders = sut.loadFolders()
        #expect(folders.count == 1)
        #expect(folders[0].id == folder2.id)
        #expect(folders[0].feedURLs.contains("https://only.com"))
    }

    @Test("Add feed with nonexistent folder ID does not crash")
    func testAddFeedToNonexistentFolder() {
        // Given
        sut.createFolder(name: "Existing", feedURLs: ["https://a.com"])

        // When
        sut.addFeed(url: "https://a.com", toFolderWithId: UUID())

        // Then
        let folders = sut.loadFolders()
        #expect(folders.isEmpty)
    }

    // MARK: - removeFeed

    @Test("Remove feed strips URL from its folder")
    func testRemoveFeedStripsURL() {
        // Given
        sut.createFolder(name: "Tech", feedURLs: ["https://a.com", "https://b.com"])

        // When
        sut.removeFeed(url: "https://a.com")

        // Then
        let folders = sut.loadFolders()
        #expect(folders[0].feedURLs == ["https://b.com"])
    }

    @Test("Remove feed deletes folder when it becomes empty")
    func testRemoveFeedDeletesEmptyFolder() {
        // Given
        sut.createFolder(name: "Solo", feedURLs: ["https://only.com"])

        // When
        sut.removeFeed(url: "https://only.com")

        // Then
        let folders = sut.loadFolders()
        #expect(folders.isEmpty)
    }

    @Test("Remove feed that does not exist in any folder is a no-op")
    func testRemoveFeedNoOp() {
        // Given
        sut.createFolder(name: "Tech", feedURLs: ["https://a.com"])

        // When
        sut.removeFeed(url: "https://nonexistent.com")

        // Then
        let folders = sut.loadFolders()
        #expect(folders.count == 1)
        #expect(folders[0].feedURLs == ["https://a.com"])
    }

    // MARK: - toggleExpanded

    @Test("Toggle expanded flips the flag")
    func testToggleExpanded() {
        // Given
        let folder = sut.createFolder(name: "Tech", feedURLs: ["https://a.com"])
        #expect(folder.isExpanded == true)

        // When
        sut.toggleExpanded(folderId: folder.id)

        // Then
        let afterFirst = sut.loadFolders()[0]
        #expect(afterFirst.isExpanded == false)

        // When
        sut.toggleExpanded(folderId: folder.id)

        // Then
        let afterSecond = sut.loadFolders()[0]
        #expect(afterSecond.isExpanded == true)
    }

    @Test("Toggle expanded with nonexistent ID does not crash")
    func testToggleExpandedNonexistentID() {
        // Given
        sut.createFolder(name: "Tech", feedURLs: ["https://a.com"])

        // When
        sut.toggleExpanded(folderId: UUID())

        // Then
        let folders = sut.loadFolders()
        #expect(folders.count == 1)
        #expect(folders[0].isExpanded == true)
    }

    // MARK: - cleanupDeletedFeeds

    @Test("Cleanup removes URLs not in the existing set")
    func testCleanupRemovesDeletedURLs() {
        // Given
        sut.createFolder(name: "Mixed", feedURLs: ["https://alive.com", "https://dead.com"])

        // When
        sut.cleanupDeletedFeeds(existingURLs: Set(["https://alive.com"]))

        // Then
        let folders = sut.loadFolders()
        #expect(folders[0].feedURLs == ["https://alive.com"])
    }

    @Test("Cleanup deletes folder when all its URLs are gone")
    func testCleanupDeletesEmptyFolder() {
        // Given
        sut.createFolder(name: "AllDead", feedURLs: ["https://dead1.com", "https://dead2.com"])
        sut.createFolder(name: "Alive", feedURLs: ["https://alive.com"])

        // When
        sut.cleanupDeletedFeeds(existingURLs: Set(["https://alive.com"]))

        // Then
        let folders = sut.loadFolders()
        #expect(folders.count == 1)
        #expect(folders[0].name == "Alive")
    }

    @Test("Cleanup with all URLs existing is a no-op")
    func testCleanupNoOp() {
        // Given
        sut.createFolder(name: "Tech", feedURLs: ["https://a.com", "https://b.com"])

        // When
        sut.cleanupDeletedFeeds(existingURLs: Set(["https://a.com", "https://b.com"]))

        // Then
        let folders = sut.loadFolders()
        #expect(folders[0].feedURLs.count == 2)
    }

    @Test("Cleanup with empty existing set removes all folders")
    func testCleanupEmptySetRemovesAll() {
        // Given
        sut.createFolder(name: "A", feedURLs: ["https://a.com"])
        sut.createFolder(name: "B", feedURLs: ["https://b.com"])

        // When
        sut.cleanupDeletedFeeds(existingURLs: Set())

        // Then
        let folders = sut.loadFolders()
        #expect(folders.isEmpty)
    }
}
