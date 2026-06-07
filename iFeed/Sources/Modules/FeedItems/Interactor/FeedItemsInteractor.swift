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
    private let feed: Feed?
    private let feedItems: [FeedItem]?
    private let searchTerm: String?

    private var parsingCompletion: ((Result<Void, any Error>) -> Void)?

    // MARK: - Init
    init(parser: any ParserProtocol,
         storage: any StorageProtocol,
         feed: Feed? = nil,
         feedItems: [FeedItem]? = nil,
         searchTerm: String? = nil) {
        self.parser = parser
        self.storage = storage
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
        return feed?.sortedItems()
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
        guard searchTerm == nil, let items = feed?.feedItems.allObjects as? [FeedItem] else {
            return
        }

        let unreadItems = items.filter { !$0.wasRead.boolValue }
        guard !unreadItems.isEmpty else { return }

        for item in unreadItems {
            item.wasRead = NSNumber(value: true)
        }

        storage.saveChanges()
    }

    func hasUnreadItems() -> Bool {
        guard searchTerm == nil, let items = feed?.feedItems.allObjects as? [FeedItem] else {
            return false
        }
        return items.contains { !$0.wasRead.boolValue }
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
    /// Called by the parser on the main thread once remote feed data has been fetched and normalized.
    /// The method performs a **three-field deduplication** — an incoming item is considered unique only
    /// when its title, link, AND publish date are all absent from the current feed's items.
    /// This strict check prevents both exact duplicates and partial matches (e.g. same link with an
    /// updated title) from creating duplicate entries.
    ///
    /// **Flow:**
    /// 1. Bail out early if the interactor has no feed reference (e.g. showing search results).
    /// 2. Build O(1)-lookup sets of titles, links, and dates from the feed's existing items.
    /// 3. Iterate over each parsed item; skip any that match on ANY of the three fields.
    /// 4. For truly unique items, create a Core Data `FeedItem`, populate it from the parsed data,
    ///    and assign it to the current feed (establishing the Core Data relationship).
    /// 5. Persist all new items to disk and signal success to the caller.
    ///
    /// - Parameter data: Normalized, `Sendable` representation of the remote feed content.
    func didEndParsingFeed(with data: ParsedFeedData) {
        guard let currentFeed = self.feed else {
            return
        }

        // Enhancement: - Detect if new feed_items appeared on the feed in comparision with exsisting ones
        // if appeared - indicate to the caller side so it can skip doing safari prewarming

        // Step 1: Snapshot the existing feed items into O(1)-lookup sets for deduplication.
        let existFeedItems: [FeedItem] = (currentFeed.feedItems.allObjects as? [FeedItem]) ?? []
        let existedTitles: Set<String> = Set(existFeedItems.map(\.title))
        let existedLinks: Set<String> = Set(existFeedItems.map(\.link))
        let existedDates: Set<TimeInterval> = Set(existFeedItems.map(\.publishDate.timeIntervalSince1970))

        // Step 2: Compare each incoming parsed item against the three dedup sets.
        // An item must differ in ALL three fields to be considered unique.
        for itemData in data.items {
            let isUniqueTitle = !existedTitles.contains(itemData.title)
            let isUniqueLink = !existedLinks.contains(itemData.link)
            let isUniqueDate = !existedDates.contains(itemData.publishDate.timeIntervalSince1970)

            let isUniqueItem = isUniqueTitle && isUniqueLink && isUniqueDate

            // Step 3: Create a Core Data entity only for items not already in the feed.
            if isUniqueItem {
                guard let feedItem = storage.makeFeedItem() else {
                    continue
                }

                feedItem.title = itemData.title
                feedItem.link = itemData.link
                feedItem.htmlContent = itemData.htmlContent
                feedItem.publishDate = itemData.publishDate

                /// Create a relationship
                feedItem.feed = currentFeed
            }
        }

        // Step 4: Persist newly added items and notify the caller.
        storage.saveChanges()

        parsingCompletion?(.success(()))
        parsingCompletion = nil
    }

    func didFailParsingFeed(with error: any Error) {
        parsingCompletion?(.failure(error))
        parsingCompletion = nil
    }

    func didCancelParsingFeed() {
        parsingCompletion = nil
    }
}
