//
//  CoreDataManager.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/2/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import CoreData

private enum EntityNames: String {
    case feed = "Feed"
    case feedItem = "FeedItem"
}

final class CoreDataManager {

    // MARK: - Singleton
    static let manager = CoreDataManager()

    private init() {}

    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file.
        // This code uses a directory named "com.EvgenyKarkan.iFeed" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel? = {
        // The managed object model for the application.
        guard let modelURL: URL = Bundle.main.url(forResource: "iFeed", withExtension: "momd") else {
            return nil
        }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            return nil
        }
        return model
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        guard let model = managedObjectModel else {
            return nil
        }
        // The persistent store coordinator for the application.
        // This implementation creates and return a coordinator, having added the store for the application to it.
        // This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: model)
        let url = applicationDocumentsDirectory.appendingPathComponent("iFeed.sqlite")

        var error: NSError?
        var failureReason = "There was an error creating or loading the application's saved data."

        do {
            try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil

            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            dict[NSUnderlyingErrorKey] = error

            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error:")
            dump(error)

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
            var error: NSError?

            if moc.hasChanges {
                print("CONTEXT HAS CHANGES!!! NEED TO SAVE")
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    print("Unresolved error:")
                    dump(error)

                    #if __DEBUG__
                        abort()
                    #endif
                }
            } else {
                print("CONTEXT HAS NO CHANGES...")
            }
        }
    }

    // MARK: - Public
    func allFeeds() -> [Feed] {
        guard let moc = managedObjectContext else {
            return []
        }

        let entityName: String = EntityNames.feed.rawValue
        let description: NSEntityDescription? = NSEntityDescription.entity(forEntityName: entityName, in: moc)

        let request: NSFetchRequest = NSFetchRequest<Feed>(entityName: entityName)
        request.entity = description

        var array: [Feed]?

        do {
            try array = managedObjectContext?.fetch(request)
        } catch let error as NSError {
            print("Unresolved error while getting all feeds:")
            dump(error)

            #if __DEBUG__
                abort()
            #endif
        }

        assert(array != nil, "Found nil feed array")

        return array ?? []
    }

    func allFeedItems() -> [FeedItem]? {
        guard let moc = managedObjectContext else {
            return nil
        }

        let entityName: String = EntityNames.feedItem.rawValue
        let description: NSEntityDescription? = NSEntityDescription.entity(forEntityName: entityName, in: moc)

        let request: NSFetchRequest = NSFetchRequest<FeedItem>(entityName: entityName)
        request.entity = description

        var array: [FeedItem]?

        do {
            try array = managedObjectContext?.fetch(request)
        } catch let error as NSError {
            print("Unresolved error while getting all feed items:")
            dump(error)

            #if __DEBUG__
                abort()
            #endif
        }

        assert(array != nil, "Found nil feed items array")

        return array
    }

    func deleteObject(_ entityObject: NSManagedObject) {
        managedObjectContext?.delete(entityObject)
    }
}

// MARK: - EntityCreatable
extension CoreDataManager: EntityCreatable {

    func createFeedEntity() -> NSManagedObject? {
        return createEntity(name: EntityNames.feed.rawValue)
    }

    func createFeedItemEntity() -> NSManagedObject? {
        return createEntity(name: EntityNames.feedItem.rawValue)
    }
}

// MARK: - Private
private extension CoreDataManager {

    func createEntity(name: String) -> NSManagedObject? {
        guard let moc = managedObjectContext else {
            return nil
        }

        let instance = NSEntityDescription.insertNewObject(forEntityName: name, into: moc)

        return instance
    }
}
