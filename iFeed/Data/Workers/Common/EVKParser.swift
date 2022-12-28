//
//  EVKParser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation

// MARK: - EVKParserDelegate
protocol EVKParserDelegate: AnyObject {
    func didStartParsingFeed()
    func didEndParsingFeed(_ feed: Feed)
    func didFailParsingFeed()
}

final class EVKParser {

    // MARK: - Singleton
    static let parser = EVKParser()
    
    // MARK: - properties
    weak var delegate: EVKParserDelegate?
   
    // MARK: - public API
    func beginParseURL(_ rssURL: URL) {
        delegate?.didStartParsingFeed()
    
        let parser = FeedParser(URL: rssURL)
    
        parser.parseAsync { (result) in
            DispatchQueue.main.async { [self] in
                switch result {
                    case .success(let parsedFeed):
                        guard let rssFeed = parsedFeed.rssFeed else {
                            delegate?.didFailParsingFeed()
                            return
                        }
                        guard let feed: Feed = EVKBrain.brain.createEntity(name: kFeed) as? Feed else {
                            delegate?.didFailParsingFeed()
                            return
                        }
                        
                        /// Create Feed
                        feed.title = rssFeed.title
                        feed.rssURL = rssURL.absoluteString
                        feed.summary = rssFeed.description
                        
                        /// Create Feed Items
                        rssFeed.items?.forEach({ rrsFeedItem in
                            if let feedItem: FeedItem = EVKBrain.brain.createEntity(name: kFeedItem) as? FeedItem {
                                feedItem.title = rrsFeedItem.title ?? String()
                                feedItem.link = rrsFeedItem.link ?? String()
                                feedItem.publishDate = rrsFeedItem.pubDate ?? Date()
                                
                                /// Set relationship
                                feedItem.feed = feed
                            }
                        })
                        
                        delegate?.didEndParsingFeed(feed)
                        
                    case .failure( _):
                        delegate?.didFailParsingFeed()
                    }
            }
        }
    }
}
