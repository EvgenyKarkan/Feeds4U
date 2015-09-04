//
//  Feed.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/2/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData

class Feed: NSManagedObject {

    @NSManaged var rssURL: String
    @NSManaged var title: String
    @NSManaged var feedItems: NSSet
}
