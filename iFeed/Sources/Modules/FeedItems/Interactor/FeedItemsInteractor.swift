//
//  FeedItemsInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

@MainActor
final class FeedItemsInteractor {
    // MARK: - Properties
    private let parser: any ParserProtocol
    private let storage: any StorageProtocol
    private let localSearchService: any Searchable
    private let feed: Feed?
    private let feedItems: [FeedItem]?
    private let searchTerm: String?

    private var parsingCompletion: ((Result<Void, any Error>) -> Void)?

    // MARK: - Init
    init(parser: any ParserProtocol,
         storage: any StorageProtocol,
         localSearchService: any Searchable,
         feed: Feed? = nil,
         feedItems: [FeedItem]? = nil,
         searchTerm: String? = nil) {
        self.parser = parser
        self.storage = storage
        self.localSearchService = localSearchService
        self.feed = feed
        self.feedItems = feedItems
        self.searchTerm = searchTerm
    }
}

// MARK: - FeedItemsInteractorProtocol
extension FeedItemsInteractor: FeedItemsInteractorProtocol {

    func getFeed() -> Feed? {
        return feed
    }

    func getFeedItems() -> [FeedItem]? {
        guard searchTerm == nil else {
            return feedItems
        }
        guard let feed else {
            return nil
        }
        /// SQL-level sort + batching — the feed's relationship is never fully materialised.
        return storage.feedItems(for: feed)
    }

    func getSearchTitle() -> String? {
        guard let query = searchTerm else {
            return nil
        }
        return "\(String.localized(key: LocalizableKeys.Search.search))\(":") \(query)"
    }

    func markItemAsReadIfNeeded(item: FeedItem) {
        if !item.wasRead.boolValue {
            item.wasRead = NSNumber(value: true)

            storage.saveChanges()
        }
    }

    func markAllItemsAsRead() {
        guard searchTerm == nil, let feed else {
            return
        }
        /// Batch update at the SQL level — no items are loaded or saved on the main thread.
        storage.markAllAsRead(in: feed)
    }

    func hasUnreadItems() -> Bool {
        guard searchTerm == nil, let feed else {
            return false
        }
        /// `COUNT(*)` query — no items are materialised just to check for unread ones.
        return storage.unreadCount(for: feed) > 0
    }

    func releaseHTMLContent(of item: FeedItem) {
        storage.releaseContent(of: item)
    }

    func startParsingFeed(_ url: String, completion: @escaping (Result<Void, any Error>) -> Void) {
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
}

// MARK: - ParserDelegateProtocol
extension FeedItemsInteractor: ParserDelegateProtocol {

    /// Merges freshly parsed feed items into the existing feed, persisting only new (unique) entries.
    ///
    /// Called by the parser on the main actor once remote feed data has been fetched and normalized.
    /// The deduplication and persistence themselves run inside the storage layer on a background
    /// context (see `StorageProtocol.refreshFeedItems(with:forFeedWith:completion:)`), so large
    /// refreshes never stall the main thread. Only the feed's (Sendable) object ID is handed across.
    ///
    /// **Flow:**
    /// 1. Bail out early if the interactor has no feed reference (e.g. showing search results)
    ///    or the parse was cancelled and nobody is waiting for the result.
    /// 2. Delegate the three-field dedup merge (title + link + publish date) to storage.
    /// 3. On completion, invalidate the search index and signal success to the caller.
    ///
    /// - Parameter data: Normalized, `Sendable` representation of the remote feed content.
    func didEndParsingFeed(with data: ParsedFeedData) {
        guard let currentFeed = self.feed, parsingCompletion != nil else {
            return
        }

        // Enhancement: - Detect if new feed_items appeared on the feed in comparision with exsisting ones
        // if appeared - indicate to the caller side so it can skip doing safari prewarming

        storage.refreshFeedItems(with: data.items, forFeedWith: currentFeed.objectID) { [weak self] in
            /// Storage contractually delivers this callback on the main actor
            /// (see `StorageProtocol.refreshFeedItems`).
            MainActor.assumeIsolated {
                guard let self else {
                    return
                }

                /// Items may have been added — the search index must be rebuilt before the next query.
                self.localSearchService.markIndexDirty()

                self.parsingCompletion?(.success(()))
                self.parsingCompletion = nil
            }
        }
    }

    func didFailParsingFeed(with error: any Error) {
        parsingCompletion?(.failure(error))
        parsingCompletion = nil
    }

    func didCancelParsingFeed() {
        parsingCompletion = nil
    }
}
