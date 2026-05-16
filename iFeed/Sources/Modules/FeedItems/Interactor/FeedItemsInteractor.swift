//
//  FeedItemsInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

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

    func didEndParsingFeed(_ feed: Feed) {
        guard let currentFeed = self.feed else {
            return
        }

        // TODO: - Detect if new feed_items appeared on the feed in comparision with exsisting ones
        // if appeared - indicate to the caller side so it can skip doing safari prewarming

        /// Existed feed items
        let existFeedItems: [FeedItem] = (currentFeed.feedItems.allObjects as? [FeedItem]) ?? []
        let existedTitles: Set<String> = Set(existFeedItems.map(\.title))
        let existedLinks: Set<String> = Set(existFeedItems.map(\.link))
        let existedDates: Set<TimeInterval> = Set(existFeedItems.map(\.publishDate.timeIntervalSince1970))

        print("existFeedItems ---- \(existFeedItems.count)")

        /// Incoming feed items
        let incomingItems: [FeedItem] = (feed.feedItems.allObjects as? [FeedItem]) ?? []

        print("incomingItems ---- \(incomingItems.count)")

        /// Delete temporary incoming `feed`
        storage.delete(feed)

        /// Iterate over incoming feed items to find a new item to add to existing feed object
        for item: FeedItem in incomingItems {
            let isUniqueTitle = !existedTitles.contains(item.title)
            let isUniqueLink = !existedLinks.contains(item.link)
            let isUniqueDate = !existedDates.contains(item.publishDate.timeIntervalSince1970)

            let isUniqueItem = isUniqueTitle && isUniqueLink && isUniqueDate

            if isUniqueItem {
                /// Create a relationship
                item.feed = currentFeed
            } else {
                storage.delete(item)
            }
        }

        storage.saveChanges()

        parsingCompletion?(.success(()))
        parsingCompletion = nil
    }

    func didFailParsingFeed() {
        let error = NSError(domain: #function, code: #line)
        parsingCompletion?(.failure(error))
        parsingCompletion = nil
    }
}
