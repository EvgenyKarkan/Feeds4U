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
    var channel: String?
    
    var topLevelTitle = ""
    
    
    //MARK: - public API
    func beginParseURL(rssURL: NSURL) {
        
        assert(!rssURL.isEqual(nil), "URL is nil");
        
        let parser       = NSXMLParser(contentsOfURL: rssURL)
        parser!.delegate = self
        
        parser!.parse()
    }
    
    //MARL: - NSXMLParserDelegate API
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?,
                                             qualifiedName qName: String?,
                                        attributes attributeDict: [NSObject : AnyObject]) {
        
        self.channel = elementName
                                            
                                            //println(elementName)
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        
        if (self.channel == "title") {
            if (self.topLevelTitle.isEmpty) {
                self.topLevelTitle = string!
                
                println(self.topLevelTitle)
            }
        }
        
        
    }

   
}
