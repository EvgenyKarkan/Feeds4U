//
//  CoreDataManager.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/2/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import CoreData

#warning("FIX ENTITY NAME IDS")
let kFeed = "Feed"
let kFeedItem = "FeedItem"

final class CoreDataManager {

    // MARK: - Singleton
    static let manager = CoreDataManager()

    private init() {}

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file.
        // This code uses a directory named "com.EvgenyKarkan.iFeed" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application.
        // This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "iFeed", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application.
        // This implementation creates and return a coordinator, having added the store for the application to it.
        // This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = applicationDocumentsDirectory.appendingPathComponent("iFeed.sqlite")

        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict                               = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey]        = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            dict[NSUnderlyingErrorKey]             = error

            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")

            #if __DEBUG__
                abort()
            #endif
        } catch {
            fatalError()
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        // This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = persistentStoreCoordinator

        if coordinator == nil {
            return nil
        }

        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        return managedObjectContext
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
        if let moc = managedObjectContext {
            var error: NSError? = nil

            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")

                    #if __DEBUG__
                        abort()
                    #endif
                }
            }
        }
    }

    // MARK: - Public
    func createEntity(name: String) -> NSManagedObject {
        let foo = NSEntityDescription.insertNewObject(forEntityName: name, into: managedObjectContext!)

        return foo
    }

    func allFeeds() -> [Feed] {
        let request: NSFetchRequest = NSFetchRequest<Feed>(entityName: kFeed)

        var description: NSEntityDescription!
        description = NSEntityDescription.entity(forEntityName: kFeed, in: managedObjectContext!)!

        if description != nil {
            request.entity = description
        }

        var result: [Feed]?

        do {
            try result = managedObjectContext!.fetch(request)
        }
        catch let error1 as NSError {
            NSLog("Unresolved error \(error1), \(error1.userInfo)")

            #if __DEBUG__
                abort()
            #endif
        }

        assert(result != nil, "Found nil feed array")

        return result!
    }

    func allFeedItems() -> [FeedItem] {
        let request: NSFetchRequest = NSFetchRequest<FeedItem>(entityName: kFeedItem)

        var description: NSEntityDescription!
        description = NSEntityDescription.entity(forEntityName: kFeedItem, in: managedObjectContext!)!

        if description != nil {
            request.entity = description
        }

        var result: [FeedItem]?

        do {
            try result = managedObjectContext!.fetch(request)
        }
        catch let error1 as NSError {
            NSLog("Unresolved error \(error1), \(error1.userInfo)")

            #if __DEBUG__
                abort()
            #endif
        }

        assert(result != nil, "Found nil feed item array")

        return result!
    }

    func deleteObject(_ entityObject: NSManagedObject) {
        managedObjectContext?.delete(entityObject)
    }
}
