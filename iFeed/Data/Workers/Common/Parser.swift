//
//  Parser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation

// MARK: - ParserDelegate
protocol ParserDelegate: AnyObject {
    func didStartParsingFeed()
    func didEndParsingFeed(_ feed: Feed)
    func didFailParsingFeed()
}

final class Parser {

    // MARK: - Singleton
    static let parser = Parser()
    
    // MARK: - Properties
    weak var delegate: ParserDelegate?
   
    // MARK: - Public API
    func beginParseURL(_ url: URL) {
        delegate?.didStartParsingFeed()
    
        let parser = FeedParser(URL: url)
    
        parser.parseAsync { (result) in
            DispatchQueue.main.async { [weak self] in
                switch result {
                    case .success(let parsedFeed):
                        switch parsedFeed {
                        case .rss(let rssFeed):
                            self?.finishRSSParsing(rssFeed: rssFeed, url: url)
                        case .atom(let atomFeed):
                            self?.finishAtomParsing(atomFeed: atomFeed, url: url)
                        default:
                            self?.delegate?.didFailParsingFeed()
                            break
                        }
                    case .failure(let error):
                        print("GOT PARSING ERROR ---> \(error.localizedDescription)")
                        self?.delegate?.didFailParsingFeed()
                    }
            }
        }
    }

    private func finishRSSParsing(rssFeed: RSSFeed, url: URL) {
        guard let feed: Feed = Brain.brain.createEntity(name: kFeed) as? Feed else {
            delegate?.didFailParsingFeed()
            return
        }

        //dump(rssFeed)

        /// Create Feed
        feed.title = rssFeed.title
        feed.rssURL = url.absoluteString
        feed.summary = rssFeed.description

        /// Create Feed Items
        rssFeed.items?.forEach({ rrsFeedItem in
            guard let feedItem = Brain.brain.createEntity(name: kFeedItem) as? FeedItem else {
                return
            }
            feedItem.title = rrsFeedItem.title ?? String()
            feedItem.link = rrsFeedItem.link ?? String()
            feedItem.publishDate = rrsFeedItem.pubDate ?? Date()

            /// Set relationship
            feedItem.feed = feed
        })

        delegate?.didEndParsingFeed(feed)
    }

    private func finishAtomParsing(atomFeed: AtomFeed, url: URL) {
        guard let feed: Feed = Brain.brain.createEntity(name: kFeed) as? Feed else {
            delegate?.didFailParsingFeed()
            return
        }

        //dump(atomFeed)

        /// Create Feed
        feed.title = atomFeed.title
        feed.rssURL = url.absoluteString
        feed.summary = (atomFeed.subtitle?.value ?? atomFeed.rights) ?? "N/A"

        /// Create Feed Items
        atomFeed.entries?.forEach({ atomFeedItem in
            guard let feedItem = Brain.brain.createEntity(name: kFeedItem) as? FeedItem else {
                return
            }
            feedItem.title = atomFeedItem.title ?? String()
            feedItem.link = atomFeedItem.links?.first?.attributes?.href ?? String()
            feedItem.publishDate = atomFeedItem.published ?? Date()

            /// Set relationship
            feedItem.feed = feed
        })

        delegate?.didEndParsingFeed(feed)
    }
}
