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
    @NSManaged var summary: String?
    @NSManaged var feedItems: NSSet
    
    //sorted 'feedItems' by publish date
    func sortedItems() -> [FeedItem] {
        guard let unsortedItems: [FeedItem] = feedItems.allObjects as? [FeedItem] else {
            return []
        }
        
        let sortedArray = unsortedItems.sorted(by: { (item1: FeedItem, item2: FeedItem) -> Bool in
            return item1.publishDate.timeIntervalSince1970 > item2.publishDate.timeIntervalSince1970
        })
        
        return sortedArray
    }
    
    //unread 'feedItems'
    func unreadItems() -> [FeedItem] {
        guard let items: [FeedItem] = feedItems.allObjects as? [FeedItem] else {
            return []
        }
        
        let unReadItem = items.filter({ (item: FeedItem) -> Bool in
            return item.wasRead.boolValue == false
        })
        
        return unReadItem
    }
}
