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

@MainActor
final class FeedsInteractor {
    // MARK: - Properties
    private let parser: any ParserProtocol
    private let storage: any StorageProtocol
    private let localSearchService: any Searchable
    private let exploreFeedsService: any ExploreFeedsServiceProtocol
    private let folderManager: any FeedFolderManaging
    private let keyedStorage: any KeyedStorageProtocol
    private let opmlParser: any OPMLParsing

    private var parsingCompletion: ((Result<Feed, any Error>) -> Void)?
    private var parsingURL: String?

    // MARK: - Init
    init(parser: any ParserProtocol,
         storage: any StorageProtocol,
         localSearchService: any Searchable,
         exploreFeedsService: any ExploreFeedsServiceProtocol,
         folderManager: any FeedFolderManaging,
         keyedStorage: any KeyedStorageProtocol,
         opmlParser: any OPMLParsing) {
        self.parser = parser
        self.storage = storage
        self.localSearchService = localSearchService
        self.exploreFeedsService = exploreFeedsService
        self.folderManager = folderManager
        self.keyedStorage = keyedStorage
        self.opmlParser = opmlParser
    }
}

// MARK: - FeedsInteractorProtocol
extension FeedsInteractor: FeedsInteractorProtocol {

    func getAllFeeds() -> [Feed] {
        return storage.loadFeeds()
    }

    func performWhenStorageReady(_ completion: @escaping @Sendable () -> Void) {
        storage.performWhenStoreReady(completion)
    }

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool {
        return storage.containsFeed(withRSSURL: url)
    }

    func startParsingFeed(_ url: String, completion: @escaping (Result<Feed, any Error>) -> Void) {
        enum ParsingError: Error {
            case invalidURL
        }

        guard !url.isEmpty, url.isValidURL, let feedURL = URL(string: url) else {
            completion(.failure(ParsingError.invalidURL))
            return
        }

        parsingCompletion = completion
        parsingURL = url

        parser.setDelegate(self)
        parser.beginParsingURL(feedURL)
    }

    func parseOPML(_ data: Data) -> [String] {
        return opmlParser.feedURLs(from: data)
    }

    func fillSearchMatchingEngine() async {
        await localSearchService.fillMatchingEngine()
    }

    func performSearch(by searchTerm: String) async -> [FeedItem]? {
        return await localSearchService.search(for: searchTerm)
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

    func itemCount(for feed: Feed) -> Int {
        return storage.itemCount(for: feed)
    }

    func saveContext() throws {
        storage.saveChanges()
    }

    func deleteFeed(_ feed: Feed) {
        folderManager.removeFeed(url: feed.rssURL)
        storage.delete(feed)
        try? saveContext()

        /// The corpus shrank — the search index must be rebuilt before the next query.
        localSearchService.markIndexDirty()
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

    /// Hands the parsed data to storage, which creates and saves the feed with
    /// all its items on a background context — large imports no longer stall
    /// the main thread. The completion fires back on the main actor.
    func didEndParsingFeed(with data: ParsedFeedData) {
        /// Nobody is waiting for the result (e.g. the parse was cancelled) — skip the import.
        /// The URL is unwrapped here rather than defaulted: `rssURL` is the feed's
        /// identity, and persisting a feed with an empty URL would silently break
        /// refresh, duplicate detection, and folder membership. If the invariant
        /// "completion and URL are set together" ever breaks, fail loudly instead.
        guard parsingCompletion != nil, let rssURL = parsingURL else {
            parsingCompletion?(.failure(StorageError.feedCreationFailed))
            parsingCompletion = nil
            parsingURL = nil
            return
        }

        storage.importFeed(data, rssURL: rssURL) { [weak self] feedID in
            /// Storage contractually delivers this callback on the main actor
            /// (see `StorageProtocol.importFeed`).
            MainActor.assumeIsolated {
                guard let self else {
                    return
                }

                if let feedID, let feed = self.storage.loadFeed(withID: feedID) {
                    /// The corpus changed — the search index must be rebuilt before the next query.
                    self.localSearchService.markIndexDirty()
                    self.parsingCompletion?(.success(feed))
                } else {
                    self.parsingCompletion?(.failure(StorageError.feedCreationFailed))
                }
                self.parsingCompletion = nil
                self.parsingURL = nil
            }
        }
    }

    func didFailParsingFeed(with error: any Error) {
        parsingCompletion?(.failure(error))
        parsingCompletion = nil
        parsingURL = nil
    }

    func didCancelParsingFeed() {
        parsingCompletion = nil
        parsingURL = nil
    }
}
