//
//  FeedItem.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/2/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData


@objc(FeedItem)

class FeedItem: NSManagedObject {

    @NSManaged var title:                    String
    @NSManaged var preprocessedTitle:        String
    @NSManaged var link:                     String
    @NSManaged var publishDate:              Date
    @NSManaged var wasRead:                  NSNumber
    
    //relationship
    @NSManaged var feed: Feed
}
