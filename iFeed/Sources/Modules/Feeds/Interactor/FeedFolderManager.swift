//
//  FeedFolder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 25.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

struct FeedFolder: Codable, Equatable {

    // MARK: - Properties
    let id: UUID
    var name: String
    var feedURLs: [String]
    var isExpanded: Bool

    // MARK: - Init
    // TODO: - enhance testability
    init(name: String, feedURLs: [String]) {
        self.id = UUID()
        self.name = name
        self.feedURLs = feedURLs
        self.isExpanded = true
    }
}

/// Manages feed folder persistence via UserDefaults.
///
/// Folders group feeds by URL. Each folder has a unique ID, a display name,
/// an ordered list of feed URLs, and an expanded/collapsed state.
/// Empty folders are automatically removed after any mutation that could leave them empty.
final class FeedFolderManager {

    // MARK: - Properties
    private static let storageKey = "feed_folders_v1"
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Read

    /// Returns all persisted folders, or an empty array if none exist.
    func loadFolders() -> [FeedFolder] {
        guard let data = defaults.data(forKey: Self.storageKey) else {
            return []
        }
        return (try? JSONDecoder().decode([FeedFolder].self, from: data)) ?? []
    }

    // MARK: - Write

    /// Creates a new folder with the given name and initial feed URLs.
    ///
    /// 1. Loads current folders from UserDefaults.
    /// 2. Appends a new `FeedFolder` (auto-generated UUID, expanded by default).
    /// 3. Persists the updated list.
    @discardableResult
    func createFolder(name: String, feedURLs: [String]) -> FeedFolder {
        var folders = loadFolders()
        let folder = FeedFolder(name: name, feedURLs: feedURLs)
        folders.append(folder)
        persist(folders)
        return folder
    }

    /// Moves a feed into the specified folder, removing it from any other folder first.
    ///
    /// 1. Loads current folders.
    /// 2. Strips the feed URL from **every** folder (ensures a feed belongs to at most one folder).
    /// 3. Appends the URL to the target folder.
    /// 4. Removes any folders that became empty after step 2, then persists.
    func addFeed(url: String, toFolderWithId folderId: UUID) {
        var folders = loadFolders()

        for index in folders.indices {
            folders[index].feedURLs.removeAll { $0 == url }
        }

        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].feedURLs.append(url)
        }

        removeEmptyAndPersist(&folders)
    }

    /// Removes a feed from whichever folder contains it. Deletes the folder if it becomes empty.
    ///
    /// 1. Loads current folders.
    /// 2. Strips the feed URL from every folder.
    /// 3. Removes any folders that became empty, then persists.
    func removeFeed(url: String) {
        var folders = loadFolders()

        for index in folders.indices {
            folders[index].feedURLs.removeAll { $0 == url }
        }

        removeEmptyAndPersist(&folders)
    }

    /// Toggles the expanded/collapsed state of the folder with the given ID.
    ///
    /// 1. Loads current folders.
    /// 2. Finds the folder by ID and flips its `isExpanded` flag.
    /// 3. Persists immediately (no empty-folder cleanup needed).
    func toggleExpanded(folderId: UUID) {
        var folders = loadFolders()

        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].isExpanded.toggle()
        }

        persist(folders)
    }

    /// Removes feed URLs that no longer exist in Core Data. Deletes any folders left empty.
    ///
    /// 1. Loads current folders.
    /// 2. For each folder, removes URLs not present in the `existingURLs` set.
    /// 3. Early-returns if nothing changed (avoids unnecessary write).
    /// 4. Removes any folders that became empty, then persists.
    func cleanupDeletedFeeds(existingURLs: Set<String>) {
        var folders = loadFolders()
        var changed = false

        for index in folders.indices {
            let before = folders[index].feedURLs.count
            folders[index].feedURLs.removeAll { !existingURLs.contains($0) }

            if folders[index].feedURLs.count != before {
                changed = true
            }
        }

        guard changed else {
            return
        }
        removeEmptyAndPersist(&folders)
    }
}

// MARK: - Private
private extension FeedFolderManager {

    /// Encodes the folder array to JSON and writes it to UserDefaults.
    func persist(_ folders: [FeedFolder]) {
        guard let data = try? JSONEncoder().encode(folders) else {
            return
        }
        defaults.set(data, forKey: Self.storageKey)
    }

    /// Strips any folders with zero feed URLs, then persists the result.
    func removeEmptyAndPersist(_ folders: inout [FeedFolder]) {
        folders.removeAll { $0.feedURLs.isEmpty }
        persist(folders)
    }
}
