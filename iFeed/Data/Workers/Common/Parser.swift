//
//  Parser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation

// MARK: - ParserDelegateProtocol
protocol ParserDelegateProtocol: AnyObject {
    func didStartParsingFeed()
    func didEndParsingFeed(_ feed: Feed)
    func didFailParsingFeed()
}

extension ParserDelegateProtocol {
    func didStartParsingFeed() {}
}

final class Parser {

    // MARK: - Singleton
    static let parser = Parser()

    // MARK: - Properties
    weak var delegate: ParserDelegateProtocol?

    // MARK: - Public API
    func beginParsingURL(_ url: URL) {
        delegate?.didStartParsingFeed()

        let parser = FeedParser(URL: url)
        let backgroundQueue = DispatchQueue(label: #function, qos: .background)

        parser.parseAsync(queue: backgroundQueue) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                    case .success(let parsedFeed):
                        switch parsedFeed {
                        case .rss(let rssFeed):
                            self?.finishRSSParsing(rssFeed: rssFeed, url: url)
                        case .atom(let atomFeed):
                            self?.finishAtomParsing(atomFeed: atomFeed, url: url)
                        case .json(let jsonFeed):
                            self?.finishJsonParsing(jsonFeed: jsonFeed, url: url)
                        }
                    case .failure(let error):
                        print("GOT PARSING ERROR ---> \(error.localizedDescription)")
                        self?.delegate?.didFailParsingFeed()
                    }
            }
        }
    }

    private func finishRSSParsing(rssFeed: RSSFeed, url: URL) {
        guard let feed: Feed = Brain.brain.createFeedEntity() as? Feed else {
            delegate?.didFailParsingFeed()
            return
        }

        /// dump(rssFeed)

        /// Create Feed
        feed.title = rssFeed.title
        feed.rssURL = url.absoluteString
        feed.summary = rssFeed.description

        /// Create Feed Items
        rssFeed.items?.forEach({ rrsFeedItem in
            guard let link = rrsFeedItem.link,
                let feedItem = Brain.brain.createFeedItemEntity() as? FeedItem else {
                return
            }
            feedItem.title = rrsFeedItem.title ?? "N/A"
            feedItem.link = link
            feedItem.publishDate = rrsFeedItem.pubDate ?? Date()

            /// Set relationship
            feedItem.feed = feed
        })

        delegate?.didEndParsingFeed(feed)
    }

    private func finishAtomParsing(atomFeed: AtomFeed, url: URL) {
        guard let feed: Feed = Brain.brain.createFeedEntity() as? Feed else {
            delegate?.didFailParsingFeed()
            return
        }

        /// dump(atomFeed)

        /// Create Feed
        feed.title = atomFeed.title
        feed.rssURL = url.absoluteString
        feed.summary = (atomFeed.subtitle?.value ?? atomFeed.rights) ?? String()

        /// Create Feed Items
        atomFeed.entries?.forEach({ atomFeedItem in
            guard let link = atomFeedItem.links?.first?.attributes?.href,
                let feedItem = Brain.brain.createFeedItemEntity() as? FeedItem else {
                return
            }
            feedItem.title = atomFeedItem.title ?? "N/A"
            feedItem.link = link
            feedItem.publishDate = atomFeedItem.published ?? Date()

            /// Set relationship
            feedItem.feed = feed
        })

        delegate?.didEndParsingFeed(feed)
    }

    private func finishJsonParsing(jsonFeed: JSONFeed, url: URL) {
        guard let feed: Feed = Brain.brain.createFeedEntity() as? Feed else {
            delegate?.didFailParsingFeed()
            return
        }

        /// dump(jsonFeed)

        /// Create Feed
        feed.title = jsonFeed.title
        feed.rssURL = url.absoluteString
        feed.summary = jsonFeed.description

        /// Create Feed Items
        jsonFeed.items?.forEach({ jsonFeedItem in
            guard let link = jsonFeedItem.url,
                let feedItem = Brain.brain.createFeedItemEntity() as? FeedItem else {
                return
            }
            feedItem.title = jsonFeedItem.title ?? "N/A"
            feedItem.link = link
            feedItem.publishDate = jsonFeedItem.datePublished ?? Date()

            /// Set relationship
            feedItem.feed = feed
        })

        delegate?.didEndParsingFeed(feed)
    }
}
