//
//  EVKXMLParser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKXMLParser: NSObject, MWFeedParserDelegate {
    
    // MARK: - properties

   weak var parserDelegate: EVKXMLParserProtocol?
   private var feed : Feed!
   
    
    // MARK: - public API
    
   func beginParseURL(rssURL: NSURL) {
        
        assert(!rssURL.isEqual(nil), "URL is nil");
    
        var parser            = MWFeedParser(feedURL: rssURL)
        parser.delegate       = self
        parser.feedParseType  = ParseTypeFull
        parser.connectionType = ConnectionTypeAsynchronously
        parser.parse()
    }

    // MARK: - MWFeedParserDelegate API
    
    func feedParserDidStart(parser: MWFeedParser!) {
        
        self.feed = EVKBrain.brain.createEntity(name: kFeed) as? Feed
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {

        self.feed!.title  = info.title
        self.feed!.rssURL = info.url.absoluteString!
        self.feed.summary = info.summary
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        
        var feedItem: FeedItem?
        feedItem              = EVKBrain.brain.createEntity(name: kFeedItem) as? FeedItem
        feedItem?.title       = item.title
        feedItem?.link        = item.link
        feedItem?.publishDate = item.date
                
        //relationship
        feedItem?.feed = self.feed!
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        println("Error on parsing ------- \(error)")
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        
        self.parserDelegate?.didEndParsingFeed(self.feed!)
    }
}

// MARK: - EVKXMLParserProtocol

protocol EVKXMLParserProtocol: class {
    
    func didEndParsingFeed(feed: Feed)
}
