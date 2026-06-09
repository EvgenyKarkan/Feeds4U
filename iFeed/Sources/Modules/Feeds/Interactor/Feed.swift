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
final class Feed: NSManagedObject {

    @NSManaged var rssURL: String
    @NSManaged var title: String?
    @NSManaged var summary: String?
    @NSManaged var feedItems: NSSet

    /// Sorted `feedItems` by publish date (newest first)
    func sortedItems() -> [FeedItem] {
        guard var items = feedItems.allObjects as? [FeedItem] else {
            return []
        }
        // sort() mutates in-place (no extra copy), vs sorted() which allocates a new array.
        items.sort { $0.publishDate > $1.publishDate }

        return items
    }
}
