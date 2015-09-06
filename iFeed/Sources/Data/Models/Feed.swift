//
//  Feed.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/2/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData


@objc(Feed)

class Feed: NSManagedObject {

    @NSManaged var rssURL: String
    @NSManaged var title: String!
    @NSManaged var summary: String
    @NSManaged var feedItems: NSSet
    
    //sorted 'feedItems' by publish date
    func sortedItems() -> [FeedItem] {
        
        var unsortedItems: [FeedItem] = (self.feedItems.allObjects as? [FeedItem])!
        
        let sortedArray = sorted(unsortedItems, {
            (item1: FeedItem, item2: FeedItem) -> Bool in
            
            return item1.publishDate.timeIntervalSince1970 > item2.publishDate.timeIntervalSince1970
        })
        
        return sortedArray
    }
}
