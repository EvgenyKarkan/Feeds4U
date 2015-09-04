//
//  EVKXMLParser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKXMLParser: NSObject, NSXMLParserDelegate {
    
    //MARK: - properties
    
   var feedChannel: EVKFeed = EVKFeed()

   var parserDelegate: EVKXMLParserProtocol?
    
   private var currentElement        = ""
   private var foundedCharacters     = ""
   private var feedItem: EVKFeedItem?
    
    
    var feedCD : Feed = EVKBrain.brain.createEntity(name: kFeed) as! Feed
    var feedItemCD: FeedItem?
    
    //MARK: - public API
    
    func beginParseURL(rssURL: NSURL) {
        
        assert(!rssURL.isEqual(nil), "URL is nil");
        
//        self.feedChannel.feedURL = rssURL.absoluteString!
        
        self.feedCD.rssURL = rssURL.absoluteString!
        
        let parser       = NSXMLParser(contentsOfURL: rssURL)
        parser!.delegate = self
        
        parser!.parse()
    }
    
    
    //MARK: - NSXMLParserDelegate API
    
    func parserDidEndDocument(parser: NSXMLParser) {
        
        if false {println("CHECK HOW TO HANDLE RESPONDING TO SELECTOR")}
        
        self.parserDelegate?.didEndParsingFeed(self.feedCD)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?,
                                             qualifiedName qName: String?,
                                        attributes attributeDict: [NSObject : AnyObject]) {
        //proxing the element
        self.currentElement = elementName
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        
        if (self.currentElement == "title" && self.feedCD.title.isEmpty) {
            
//            self.feedChannel.feedTitle = string!
            
            self.feedCD.title = string!
        }
        
        if (self.currentElement == "title" && string != self.feedCD.title) ||
            self.currentElement == "link" ||
            self.currentElement == "pubDate" {

            foundedCharacters += string!
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if !self.foundedCharacters.isEmpty && self.foundedCharacters != self.feedCD.title {

                if self.currentElement == "title" {
//                    self.feedItem        = EVKFeedItem()
//                    self.feedItem?.title = self.foundedCharacters
                    
                    self.feedItemCD        = EVKBrain.brain.createEntity(name: kFeedItem) as? FeedItem
                    self.feedItemCD?.title = self.foundedCharacters
                }
            
                if (self.feedItemCD != nil) {
                    if self.currentElement == "link" {
                        
                        self.feedItemCD?.link = self.foundedCharacters
                        
                        //self.feedChannel.feedItemsArray.append(self.feedItem!)
                        
                        self.feedItemCD?.feed = self.feedCD
                        
                        
                        self.feedItemCD = nil
                        
                        self.foundedCharacters = ""
                    }
                    
                    if self.currentElement == "pubDate" {
                        //self.feedItem?.publicDate = foundedCharacters
                    }
                }
        }
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        println(parseError.localizedDescription)
    }
    
    func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError) {
        println(validationError.localizedDescription)
    }
}


protocol EVKXMLParserProtocol {
    
    func didEndParsingFeed(feed: Feed)
}
