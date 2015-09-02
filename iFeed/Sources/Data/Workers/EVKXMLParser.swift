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
    
   var feedChannel: EVKFeed  = EVKFeed()

   var parserDelegate: EVKXMLParserProtocol?
    
   private var currentElement        = ""
   private var foundedCharacters     = ""
   private var feedItem: EVKFeedItem?
    
    
    //MARK: - public API
    
    func beginParseURL(rssURL: NSURL) {
        
        assert(!rssURL.isEqual(nil), "URL is nil");
        
        self.feedChannel.feedURL = rssURL.absoluteString!
        
        let parser       = NSXMLParser(contentsOfURL: rssURL)
        parser!.delegate = self
        
        parser!.parse()
    }
    
    
    //MARK: - NSXMLParserDelegate API
    
    func parserDidEndDocument(parser: NSXMLParser) {
        
        self.parserDelegate?.didEndParsingFeed(self.feedChannel)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?,
                                             qualifiedName qName: String?,
                                        attributes attributeDict: [NSObject : AnyObject]) {
        //proxing the element
        self.currentElement = elementName
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        
        if (self.currentElement == "title" && self.feedChannel.feedTitle.isEmpty) {
            
            self.feedChannel.feedTitle = string!
        }
        
        if (self.currentElement == "title" && string != self.feedChannel.feedTitle) ||
            self.currentElement == "link" ||
            self.currentElement == "pubDate" {

            foundedCharacters += string!
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if !self.foundedCharacters.isEmpty && self.foundedCharacters != self.feedChannel.feedTitle {

                if self.currentElement == "title" {
                    self.feedItem        = EVKFeedItem()
                    self.feedItem?.title = self.foundedCharacters
                }
            
                if (self.feedItem != nil) {
                    if self.currentElement == "link" {
                        
                        self.feedItem?.link = self.foundedCharacters
                        
                        self.feedChannel.feedItemsArray.append(self.feedItem!)
                        
                        self.feedItem = nil
                        
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
    
    func didEndParsingFeed(feed: EVKFeed)
}
