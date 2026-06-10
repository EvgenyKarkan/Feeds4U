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
final class FeedItem: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var link: String
    @NSManaged var publishDate: Date
    @NSManaged var wasRead: NSNumber

    /// Relationship
    @NSManaged var feed: Feed

    /// Relationship to the item's heavy article body.
    ///
    /// The HTML lives in a separate ``FeedItemContent`` row so that firing a
    /// `FeedItem` fault (lists, search, dedup) loads only the lightweight
    /// metadata columns — the article body is faulted in only when accessed.
    @NSManaged var content: FeedItemContent?

    /// HTML body of the article, if provided by the feed.
    ///
    /// Reads from / writes to the ``content`` child row. Reading fires the
    /// child's fault, so only touch this when the body is actually needed
    /// (e.g. opening the article reader) — never while configuring list cells.
    var htmlContent: String? {
        get {
            return content?.htmlContent
        }
        set {
            if let newValue {
                if content == nil, let context = managedObjectContext {
                    content = FeedItemContent(context: context)
                }
                content?.htmlContent = newValue
            } else if let existing = content {
                existing.managedObjectContext?.delete(existing)
                content = nil
            }
        }
    }
}
