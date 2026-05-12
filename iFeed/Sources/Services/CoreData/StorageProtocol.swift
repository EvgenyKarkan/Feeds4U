//
//  StorageProtocol.swift
//  iFeed
//
//  Created by Evgeny Karkan on 26.03.2024.
//  Copyright © 2024 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData.NSManagedObject

protocol EntityCreatable {
    func createFeedEntity() -> NSManagedObject?
    func createFeedItemEntity() -> NSManagedObject?
}

protocol EntityDeleteable {
    func deleteObject(_ entityObject: NSManagedObject)
}

protocol StorageProtocol: EntityCreatable, EntityDeleteable {
    func allFeeds() -> [Feed]
    func allFeedItems() -> [FeedItem]?

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed?

    func saveContext()

    func isAlreadySavedURL(_ rssURL: String) -> Bool
}
