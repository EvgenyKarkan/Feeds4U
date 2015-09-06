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
    
   private var currentElement    = ""
   private var foundedCharacters = ""

   private var feedCD : Feed!
   
    
    // MARK: - public API
    
   func beginParseURL(rssURL: NSURL) {
        
        assert(!rssURL.isEqual(nil), "URL is nil");

        self.feedCD         = EVKBrain.brain.createEntity(name: kFeed) as? Feed
        self.feedCD!.rssURL = rssURL.absoluteString!
    
        var parser2            = MWFeedParser(feedURL: rssURL)
        parser2.delegate       = self
        parser2.feedParseType  = ParseTypeFull
        parser2.connectionType = ConnectionTypeAsynchronously
        parser2.parse()
    }

    // MARK: - MWFeedParserDelegate API
    
    func feedParserDidStart(parser: MWFeedParser!) {
        
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        
        println("TITLE  ------- \(info.title)")
        println("LINK  ------- \(info.link)")
        println("SUMMARY  ------- \(info.summary)")
        println("URL  ------- \(info.url)")
        
        self.feedCD!.title = info.title
        
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        println("ITEM ------- \(item)")
        
//        NSString *identifier; // Item identifier
//        NSString *title; // Item title
//        NSString *link; // Item URL
//        NSDate *date; // Date the item was published
//        NSDate *updated; // Date the item was updated if available
//        NSString *summary; // Description of item
//        NSString *content; // More detailed content (if available)
//        NSString *author; // Item author
        
        var feedItemCD: FeedItem?
        feedItemCD = EVKBrain.brain.createEntity(name: kFeedItem) as? FeedItem
        
        //relationship
        feedItemCD?.feed = self.feedCD!
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        println("Error on parsing ------- \(error)")
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        
        //self.parserDelegate?.didEndParsingFeed(self.feedCD!)
    }
    
}


protocol EVKXMLParserProtocol: class {
    
    func didEndParsingFeed(feed: Feed)
}
