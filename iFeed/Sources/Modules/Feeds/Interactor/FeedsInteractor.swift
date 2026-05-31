//
//  FeedsInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData.NSManagedObjectID

private enum Constants {
    static let recentSearchesKey = "com.ifeed.recentSearches"
    static let maxRecentSearches = 10
}

final class FeedsInteractor {
    // MARK: - Properties
    private let parser: any ParserProtocol
    private let storage: any StorageProtocol
    private var localSearchService: any Searchable
    private let exploreFeedsService: any ExploreFeedsServiceProtocol
    private let folderManager: any FeedFolderManaging
    private let keyedStorage: any KeyedStorageProtocol

    private var parsingCompletion: ((Result<Feed, any Error>) -> Void)?

    // MARK: - Init
    init(parser: any ParserProtocol,
         storage: any StorageProtocol,
         localSearchService: any Searchable,
         exploreFeedsService: any ExploreFeedsServiceProtocol,
         folderManager: any FeedFolderManaging,
         keyedStorage: any KeyedStorageProtocol) {
        self.parser = parser
        self.storage = storage
        self.localSearchService = localSearchService
        self.exploreFeedsService = exploreFeedsService
        self.folderManager = folderManager
        self.keyedStorage = keyedStorage
    }
}

// MARK: - FeedsInteractorProtocol
extension FeedsInteractor: FeedsInteractorProtocol {

    func getAllFeeds() -> [Feed] {
        return storage.loadFeeds()
    }

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool {
        return storage.containsFeed(withRSSURL: url)
    }

    func startParsingFeed(_ url: String, completion: @escaping (Result<Feed, any Error>) -> Void) {
        enum ParsingError: Error {
            case invalidURL
        }

        guard !url.isEmpty, let feedURL = URL(string: url) else {
            completion(.failure(ParsingError.invalidURL))
            return
        }

        parsingCompletion = completion

        parser.setDelegate(self)
        parser.beginParsingURL(feedURL)
    }

    func fillSearchMatchingEngine(completion: @escaping () -> Void) {
        localSearchService.fillMatchingEngine(completion: completion)
    }

    func performSearch(by searchTerm: String,
                       completion: @escaping ([FeedItem]?) -> Void) {
        localSearchService.search(for: searchTerm, resultsFound: completion)
    }

    // MARK: - Recent searches
    func recentSearches() -> [String] {
        return keyedStorage.stringArray(forKey: Constants.recentSearchesKey) ?? []
    }

    func saveRecentSearch(_ query: String) {
        var searches = recentSearches()
        searches.removeAll { $0 == query }
        searches.append(query)

        if searches.count > Constants.maxRecentSearches {
            searches.removeFirst()
        }
        keyedStorage.set(searches, forKey: Constants.recentSearchesKey)
    }

    func clearRecentSearches() {
        keyedStorage.removeObject(forKey: Constants.recentSearchesKey)
    }

    func exploreFeeds(on webSite: String,
                      completion: @escaping ExploreFeedsServiceResultCompletion) {
        exploreFeedsService.searchFeeds(on: webSite, completion: completion)
    }

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        return storage.feed(at: indexPath)
    }

    func unreadCountsByFeed() -> [NSManagedObjectID: Int] {
        return storage.unreadCountsByFeed()
    }

    func saveContext() throws {
        storage.saveChanges()
    }

    func deleteFeed(_ feed: Feed) {
        folderManager.removeFeed(url: feed.rssURL)
        storage.delete(feed)
        try? saveContext()
    }

    // MARK: - Folder operations
    func getAllFolders() -> [FeedFolder] {
        return folderManager.loadFolders()
    }

    @discardableResult
    func createFolder(name: String, feedURLs: [String]) -> FeedFolder {
        return folderManager.createFolder(name: name, feedURLs: feedURLs)
    }

    func addFeedToFolder(url: String, folderId: UUID) {
        folderManager.addFeed(url: url, toFolderWithId: folderId)
    }

    func removeFeedFromFolder(url: String) {
        folderManager.removeFeed(url: url)
    }

    func toggleFolderExpanded(id: UUID) {
        folderManager.toggleExpanded(folderId: id)
    }

    func cleanupFolders(existingFeedURLs: Set<String>) {
        folderManager.cleanupDeletedFeeds(existingURLs: existingFeedURLs)
    }
}

// MARK: - ParserDelegateProtocol
extension FeedsInteractor: ParserDelegateProtocol {

    func didEndParsingFeed(_ feed: Feed) {
        parsingCompletion?(.success(feed))
        parsingCompletion = nil
    }

    func didFailParsingFeed() {
        let error = NSError(domain: #function, code: #line)
        parsingCompletion?(.failure(error))
        parsingCompletion = nil
    }
}
