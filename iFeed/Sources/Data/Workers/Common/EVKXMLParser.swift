//
//  EVKXMLParser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


class EVKXMLParser: NSObject, MWFeedParserDelegate {
    
   // MARK: - properties
   weak var parserDelegate: EVKXMLParserProtocol?
   fileprivate var feed : Feed!
   
   // MARK: - public API
   func beginParseURL(_ rssURL: URL) {
        let parser             = MWFeedParser(feedURL: rssURL)
        parser?.delegate       = self
        parser?.feedParseType  = ParseTypeFull
        parser?.connectionType = ConnectionTypeAsynchronously
        parser?.parse()
    }

    // MARK: - MWFeedParserDelegate API
    func feedParserDidStart(_ parser: MWFeedParser!) {
        self.feed = EVKBrain.brain.createEntity(name: kFeed) as? Feed
    }
    
    func feedParser(_ parser: MWFeedParser!, didParseFeedInfo info: MWFeedInfo!) {
        self.feed?.title   = info.title
        self.feed?.rssURL  = info.url.absoluteString
        self.feed?.summary = (info.summary != nil) ? info.summary : self.feed?.rssURL
    }
    
    func feedParser(_ parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        var feedItem: FeedItem?
        feedItem = EVKBrain.brain.createEntity(name: kFeedItem) as? FeedItem
        
        if item.title != nil { feedItem?.title       = item.title }
        if item.link  != nil { feedItem?.link        = item.link }
        if item.date  != nil { feedItem?.publishDate = item.date }
        
        //relationship
        feedItem?.feed = self.feed!
    }
    
    func feedParser(_ parser: MWFeedParser!, didFailWithError error: Error!) {
        self.parserDelegate?.didFailParsingFeed()
    }
    
    func feedParserDidFinish(_ parser: MWFeedParser!) {
        self.parserDelegate?.didEndParsingFeed(self.feed!)
    }
}

// MARK: - EVKXMLParserProtocol
protocol EVKXMLParserProtocol: class {
    func didEndParsingFeed(_ feed: Feed)
    func didFailParsingFeed()
}
