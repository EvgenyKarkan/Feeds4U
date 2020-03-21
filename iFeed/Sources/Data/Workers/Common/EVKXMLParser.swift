//
//  EVKXMLParser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import FeedKit

// MARK: - EVKXMLParserProtocol
protocol EVKXMLParserProtocol: class {
    func didEndParsingFeed(_ feed: Feed)
    func didFailParsingFeed()
}


final class EVKXMLParser: NSObject {
    
   // MARK: - properties
   weak var parserDelegate: EVKXMLParserProtocol?
   private var feed : Feed!
   
   // MARK: - public API
   func beginParseURL(_ rssURL: URL) {
        let parser = FeedParser(URL: rssURL)
    
        parser.parseAsync { (result) in
            
            DispatchQueue.main.async {
                switch result {
                    case .success(let feed):
                        guard let rssFeed = feed.rssFeed else {
                            self.parserDelegate?.didFailParsingFeed()
                            return
                        }
                        
                        // Create Feed
                        self.feed = EVKBrain.brain.createEntity(name: kFeed) as? Feed
                        self.feed.title   = rssFeed.title
                        self.feed.rssURL  = rssURL.absoluteString
                        self.feed.summary = rssFeed.description
                        
                        // Create Feeds
                        rssFeed.items?.forEach({ rrsFeedItem in
                            if let feedItem: FeedItem = EVKBrain.brain.createEntity(name: kFeedItem) as? FeedItem {
                                feedItem.title = rrsFeedItem.title ?? ""
                                feedItem.link = rrsFeedItem.link ?? ""
                                feedItem.publishDate = rrsFeedItem.pubDate ?? Date()
                                
                                //relationship
                                feedItem.feed = self.feed
                            }
                        })
                        
                        self.parserDelegate?.didEndParsingFeed(self.feed)
                        
                    case .failure( _):
                        self.parserDelegate?.didFailParsingFeed()
                    }
            }
        }
    }
}

