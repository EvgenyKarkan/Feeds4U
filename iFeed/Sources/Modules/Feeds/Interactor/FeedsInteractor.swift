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
    /// Cap on simultaneous feed parses during a refresh-all. Keeps a large
    /// library from opening dozens of network requests at once while still
    /// parallelising enough to be much faster than a sequential refresh.
    static let maxConcurrentRefreshes = 6
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

    func refreshAllFeeds() async {
        /// Snapshot the (Sendable) URL + object-ID pairs on the main actor before
        /// fanning out — `Feed` managed objects must not cross task boundaries.
        let targets: [(url: URL, id: NSManagedObjectID)] = storage.loadFeeds().compactMap { feed in
            guard feed.rssURL.isValidURL, let url = URL(string: feed.rssURL) else {
                return nil
            }
            return (url, feed.objectID)
        }

        guard !targets.isEmpty else {
            return
        }

        /// Bounded fan-out: keep at most `maxConcurrentRefreshes` parses in flight,
        /// starting the next as each finishes. Each child parses its feed off the
        /// main thread (the parser bridges to a background queue) and merges new
        /// items via storage's background context, so the refresh runs in parallel.
        await withTaskGroup(of: Void.self) { group in
            let limit = min(Constants.maxConcurrentRefreshes, targets.count)
            var next = 0

            for _ in 0..<limit {
                let target = targets[next]
                next += 1
                group.addTask { [weak self] in
                    await self?.refreshFeed(url: target.url, id: target.id)
                }
            }

            while await group.next() != nil {
                guard next < targets.count else {
                    continue
                }
                let target = targets[next]
                next += 1
                group.addTask { [weak self] in
                    await self?.refreshFeed(url: target.url, id: target.id)
                }
            }
        }

        /// New items may have landed across any number of feeds — rebuild the
        /// search index before the next query.
        localSearchService.markIndexDirty()
    }

    /// Parses a single feed and merges its items, awaiting the background save.
    /// Failures (network, malformed feed) are swallowed: one bad feed must not
    /// abort the rest of a refresh-all.
    private func refreshFeed(url: URL, id: NSManagedObjectID) async {
        guard case .success(let data) = await parser.parse(url) else {
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            storage.refreshFeedItems(with: data.items, forFeedWith: id) {
                continuation.resume()
            }
        }
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
