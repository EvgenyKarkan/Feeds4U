//
//  NewCoreDataManager.swift
//  iFeed
//
//  Created on 4/28/26.
//  Modern Core Data manager addressing legacy issues
//

import CoreData
import Foundation

/// Errors that can occur during Core Data operations
enum CoreDataError: Error {
    case persistentStoreLoadFailed(underlying: any Error)
    case modelNotFound
    case contextNotAvailable
    case fetchFailed(underlying: any Error)
    case saveFailed(underlying: any Error)
    case entityCreationFailed(entityName: String)

    var localizedDescription: String {
        switch self {
        case .persistentStoreLoadFailed(let error):
            return "Failed to load persistent store: \(error.localizedDescription)"
        case .modelNotFound:
            return "Could not find Core Data model file"
        case .contextNotAvailable:
            return "Managed object context is not available"
        case .fetchFailed(let error):
            return "Fetch request failed: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save context: \(error.localizedDescription)"
        case .entityCreationFailed(let entityName):
            return "Failed to create entity: \(entityName)"
        }
    }
}

/// Entity names used in the Core Data model
private enum EntityNames: String {
    case feed = "Feed"
    case feedItem = "FeedItem"
}

/// Modern Core Data manager using NSPersistentContainer
final class NewCoreDataManager {

    // MARK: - Singleton (Optional - can be replaced with dependency injection) // TODO: - remove singleton
    static let shared = NewCoreDataManager()

    // MARK: - Properties

    /// The persistent container for the application
    private let persistentContainer: NSPersistentContainer

    /// Main queue context for UI operations
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Indicates whether the Core Data stack is ready
    private(set) var isStoreLoaded = false

    // MARK: - Initialization

    /// Initialize with dependency injection support
    /// - Parameter modelName: The name of the Core Data model (default: "iFeed")
    init(modelName: String = "iFeed") {
        persistentContainer = NSPersistentContainer(name: modelName)
        setupPersistentContainer()
    }

    /// Initialize with a custom persistent container (useful for testing)
    /// - Parameter container: A custom NSPersistentContainer
    init(container: NSPersistentContainer) {
        self.persistentContainer = container
        setupPersistentContainer()
    }

    // MARK: - Setup

    private func setupPersistentContainer() {
        // Get the legacy database URL to ensure compatibility
        let storeURL = getLegacyStoreURL()

        // Configure store description to use the same location as legacy CoreDataManager
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        persistentContainer.persistentStoreDescriptions = [storeDescription]

        // Load persistent stores
        persistentContainer.loadPersistentStores { [weak self] description, error in
            if let error = error {
                // Log the error but don't crash the app
                print("⚠️ Core Data store failed to load: \(error.localizedDescription)")
                if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? (any Error) {
                    print("Underlying error: \(underlyingError)")
                }
                self?.isStoreLoaded = false
            } else {
                print("✅ Core Data store loaded successfully at: \(description.url?.absoluteString ?? "unknown")")
                self?.isStoreLoaded = true
            }
        }

        // Configure merge policy to handle conflicts
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Get the legacy database URL for compatibility with old CoreDataManager
    private func getLegacyStoreURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[urls.count - 1]
        return documentsDirectory.appendingPathComponent("iFeed.sqlite")
    }

    // MARK: - Context Management

    /// Creates a new background context for performing work off the main queue
    /// - Returns: A new managed object context configured for background use
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Perform work on a background context
    /// - Parameter block: The work to perform
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Save Operations

    /// Save the view context (main queue)
    /// - Throws: CoreDataError.saveFailed if the save fails
    func saveViewContext() throws {
        try saveContext(viewContext)
    }

    /// Save a specific context with proper error handling
    /// - Parameter context: The context to save
    /// - Throws: CoreDataError.saveFailed if the save fails
    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else {
            print("ℹ️ Context has no changes, skipping save")
            return
        }

        do {
            try context.save()
            print("✅ Context saved successfully (\(context.insertedObjects.count) inserted, \(context.updatedObjects.count) updated, \(context.deletedObjects.count) deleted)")
        } catch {
            print("❌ Failed to save context: \(error.localizedDescription)")
            // Rollback changes on failure
            context.rollback()
            throw CoreDataError.saveFailed(underlying: error)
        }
    }

    /// Save a context asynchronously on a background queue
    /// - Parameters:
    ///   - context: The context to save
    ///   - completion: Completion handler called with the result
    func saveContextAsync(_ context: NSManagedObjectContext, completion: ((Result<Void, CoreDataError>) -> Void)? = nil) {
        context.perform {
            do {
                try self.saveContext(context)
                completion?(.success(()))
            } catch let error as CoreDataError {
                completion?(.failure(error))
            } catch {
                completion?(.failure(.saveFailed(underlying: error)))
            }
        }
    }

    // MARK: - Fetch Operations

    /// Fetch all feeds with optimized settings
    /// - Parameters:
    ///   - sortDescriptors: Optional sort descriptors (default: sorted by title)
    ///   - predicate: Optional predicate to filter results
    ///   - context: The context to fetch from (default: viewContext)
    /// - Returns: Array of Feed objects
    /// - Throws: CoreDataError if fetch fails
    func fetchFeeds(
        sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
        filteredBy predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) throws -> [Feed] {
        let request = NSFetchRequest<Feed>(entityName: EntityNames.feed.rawValue)

        // Performance optimizations
        request.fetchBatchSize = 20
        request.returnsObjectsAsFaults = true
        request.includesSubentities = false

        // Apply sorting (default to title if not specified)
        request.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "title", ascending: true)]

        // Apply predicate if provided
        request.predicate = predicate

        return try executeFetchRequest(request, context: context)
    }

    /// Fetch all feed items with optimized settings
    /// - Parameters:
    ///   - sortDescriptors: Optional sort descriptors (default: sorted by date descending)
    ///   - predicate: Optional predicate to filter results
    ///   - context: The context to fetch from (default: viewContext)
    /// - Returns: Array of FeedItem objects
    /// - Throws: CoreDataError if fetch fails
    func fetchFeedItems(
        sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
        filteredBy predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) throws -> [FeedItem] {
        let request = NSFetchRequest<FeedItem>(entityName: EntityNames.feedItem.rawValue)

        // Performance optimizations
        request.fetchBatchSize = 20
        request.returnsObjectsAsFaults = true
        request.includesSubentities = false

        // Apply sorting (default to date descending if not specified)
        // .publishDate is a property of FeedItem
        request.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "publishDate", ascending: false)]

        // Apply predicate if provided
        request.predicate = predicate

        return try executeFetchRequest(request, context: context)
    }

    /// Generic fetch request execution
    /// - Parameters:
    ///   - request: The fetch request to execute
    ///   - context: The context to use (default: viewContext)
    /// - Returns: Array of fetched objects
    /// - Throws: CoreDataError if fetch fails
    private func executeFetchRequest<T: NSManagedObject>(
        _ request: NSFetchRequest<T>,
        context: NSManagedObjectContext? = nil
    ) throws -> [T] {
        let contextToUse = context ?? viewContext

        do {
            let results = try contextToUse.fetch(request)
            // print("✅ Fetched \(results.count) \(T.self) objects")
            return results
        } catch {
            print("❌ Fetch failed for \(T.self): \(error.localizedDescription)")
            throw CoreDataError.fetchFailed(underlying: error)
        }
    }

    /// Count objects without loading them into memory
    /// - Parameters:
    ///   - entityName: The name of the entity
    ///   - predicate: Optional predicate to filter
    ///   - context: The context to use (default: viewContext)
    /// - Returns: Count of objects
    /// - Throws: CoreDataError if count fails
    func count(entityName: String, predicate: NSPredicate? = nil, context: NSManagedObjectContext? = nil) throws -> Int {
        let contextToUse = context ?? viewContext
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: entityName)
        request.predicate = predicate

        do {
            return try contextToUse.count(for: request)
        } catch {
            throw CoreDataError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Entity Creation

    /// Create a new Feed entity
    /// - Parameter context: The context to create in (default: viewContext)
    /// - Returns: A new Feed object
    /// - Throws: CoreDataError if creation fails
    @discardableResult
    func createFeed(in context: NSManagedObjectContext? = nil) throws -> Feed {
        let contextToUse = context ?? viewContext

        guard let entity = NSEntityDescription.insertNewObject(
            forEntityName: EntityNames.feed.rawValue,
            into: contextToUse
        ) as? Feed else {
            throw CoreDataError.entityCreationFailed(entityName: EntityNames.feed.rawValue)
        }

        return entity
    }

    /// Create a new FeedItem entity
    /// - Parameter context: The context to create in (default: viewContext)
    /// - Returns: A new FeedItem object
    /// - Throws: CoreDataError if creation fails
    @discardableResult
    func createFeedItem(in context: NSManagedObjectContext? = nil) throws -> FeedItem {
        let contextToUse = context ?? viewContext

        guard let entity = NSEntityDescription.insertNewObject(
            forEntityName: EntityNames.feedItem.rawValue,
            into: contextToUse
        ) as? FeedItem else {
            throw CoreDataError.entityCreationFailed(entityName: EntityNames.feedItem.rawValue)
        }

        return entity
    }

    // MARK: - Delete Operations

    /// Delete a single object
    /// - Parameters:
    ///   - object: The object to delete
    ///   - context: Optional context (uses object's context by default)
    func delete(_ object: NSManagedObject, from context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? object.managedObjectContext ?? viewContext
        contextToUse.delete(object)
        print("🗑️ Deleted object: \(type(of: object)): \(object)")
    }

    /// Delete multiple objects
    /// - Parameters:
    ///   - objects: Array of objects to delete
    ///   - context: The context to use
    func delete(_ objects: [NSManagedObject], from context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? viewContext
        objects.forEach { contextToUse.delete($0) }
        print("🗑️ Deleted \(objects.count) objects")
    }

    /// Batch delete objects matching a fetch request (more efficient for large deletions)
    /// - Parameters:
    ///   - entityName: The entity to delete from
    ///   - predicate: Optional predicate to filter what to delete
    ///   - context: The context to use (default: viewContext)
    /// - Throws: CoreDataError if deletion fails
    func batchDelete(entityName: String, predicate: NSPredicate? = nil, context: NSManagedObjectContext? = nil) throws {
        let contextToUse = context ?? viewContext
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate

        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try contextToUse.execute(batchDeleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [contextToUse])
            print("🗑️ Batch deleted \(objectIDArray.count) objects from \(entityName)")
        } catch {
            throw CoreDataError.saveFailed(underlying: error)
        }
    }

    // MARK: - Batch Operations

    /// Batch update objects (efficient for large updates without loading into memory)
    /// - Parameters:
    ///   - entityName: The entity to update
    ///   - propertiesToUpdate: Dictionary of properties and their new values
    ///   - predicate: Optional predicate to filter what to update
    ///   - context: The context to use (default: viewContext)
    /// - Throws: CoreDataError if update fails
    func batchUpdate(
        entityName: String,
        propertiesToUpdate: [String: Any],
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) throws {
        let contextToUse = context ?? viewContext
        let batchUpdateRequest = NSBatchUpdateRequest(entityName: entityName)
        batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
        batchUpdateRequest.predicate = predicate
        batchUpdateRequest.resultType = .updatedObjectIDsResultType

        do {
            let result = try contextToUse.execute(batchUpdateRequest) as? NSBatchUpdateResult
            let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
            let changes = [NSUpdatedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [contextToUse])
            print("✏️ Batch updated \(objectIDArray.count) objects in \(entityName)")
        } catch {
            throw CoreDataError.saveFailed(underlying: error)
        }
    }

    // MARK: - Memory Management

    /// Reset the view context to free up memory
    /// Warning: This will lose all unsaved changes
    func resetViewContext() {
        viewContext.reset()
        print("🔄 View context reset - all unsaved changes lost")
    }

    /// Refresh objects to reflect latest data from the persistent store
    /// - Parameters:
    ///   - objects: Objects to refresh
    ///   - mergeChanges: Whether to merge changes or just reload
    func refresh(_ objects: [NSManagedObject], mergeChanges: Bool = true) {
        objects.forEach { object in
            guard let context = object.managedObjectContext else { return }
            context.refresh(object, mergeChanges: mergeChanges)
        }
    }

    // MARK: - Utilities

    /// Clear all data from all entities (useful for testing or reset functionality)
    /// - Throws: CoreDataError if deletion fails
    func clearAllData() throws {
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }

        for entityName in entityNames {
            try batchDelete(entityName: entityName)
        }

        print("🧹 Cleared all data from Core Data")
    }

    /// Check if store is available and ready
    /// - Returns: True if store is loaded and ready
    func isReady() -> Bool {
        return isStoreLoaded
    }
}

// MARK: - Public APIs, StorageProtocol conformance
extension NewCoreDataManager: StorageProtocol {

    func createFeedEntity() -> NSManagedObject? {
        return try? createFeed()
    }

    func createFeedItemEntity() -> NSManagedObject? {
        return try? createFeedItem()
    }

    /// Delete an object from Core Data
    /// - Parameter entityObject: The managed object to delete
    func deleteObject(_ entityObject: NSManagedObject) {
        delete(entityObject)
    }

    /// Fetch all feeds (legacy-compatible method)
    /// Returns empty array on error to match legacy behavior
    /// - Returns: Array of all Feed objects
    func allFeeds() -> [Feed] {
        do {
            return try fetchFeeds()
        } catch {
            print("❌ Error fetching all feeds: \(error.localizedDescription)")
            return []
        }
    }

    /// Fetch all feed items
    /// Returns nil on error to match legacy behavior
    /// - Returns: Optional array of all FeedItem objects
    func allFeedItems() -> [FeedItem]? {
        do {
            return try fetchFeedItems()
        } catch {
            print("❌ Error fetching all feed items: \(error.localizedDescription)")
            return nil
        }
    }

    func saveContext() {
        try? saveViewContext()
    }

    func isAlreadySavedURL(_ rssURL: String) -> Bool {
        var returnValue: Bool = false
        let allItems: [Feed] = allFeeds()

        for item: Feed in allItems where item.rssURL == rssURL {
            returnValue = true
        }

        return returnValue
    }

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        let index = indexPath.row
        let allFeeds = allFeeds()

        guard !allFeeds.isEmpty, index < allFeeds.count else {
            return nil
        }

        return allFeeds[index]
    }
}

// MARK: - Convenience Methods
extension NewCoreDataManager {

    /// Fetch feeds for a specific category or criteria
    func fetchFeeds(matching searchText: String) throws -> [Feed] {
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
        return try fetchFeeds(filteredBy: predicate)
    }

    /// Fetch unread feed items
    func fetchUnreadFeedItems() throws -> [FeedItem] {
        let predicate = NSPredicate(format: "isRead == NO")
        return try fetchFeedItems(filteredBy: predicate)
    }

    /// Count unread items
    func countUnreadItems() throws -> Int {
        let predicate = NSPredicate(format: "isRead == NO")
        return try count(entityName: EntityNames.feedItem.rawValue, predicate: predicate)
    }
}
