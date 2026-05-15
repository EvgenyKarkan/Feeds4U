//
//  NewCoreDataManager.swift
//  iFeed
//
//  Created on 4/28/26.
//  Modern Core Data manager addressing legacy issues
//

import CoreData
import Foundation

enum CoreDataError: LocalizedError {
    case persistentStoreLoadFailed(underlying: any Error)
    case modelNotFound
    case contextNotAvailable
    case fetchFailed(underlying: any Error)
    case saveFailed(underlying: any Error)
    case executionFailed(underlying: any Error)
    case entityCreationFailed(entityName: String)

    var errorDescription: String? {
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
        case .executionFailed(let error):
            return "Batch operation failed: \(error.localizedDescription)"
        case .entityCreationFailed(let entityName):
            return "Failed to create entity: \(entityName)"
        }
    }
}

private enum EntityNames: String {
    case feed = "Feed"
    case feedItem = "FeedItem"
}

final class NewCoreDataManager {

    // MARK: - Singleton // TODO: - remove singleton
    static let shared = NewCoreDataManager()

    // MARK: - Properties

    private let persistentContainer: NSPersistentContainer

    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Cached sort descriptors — avoids allocation on every fetch
    nonisolated(unsafe) private static let feedSortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    nonisolated(unsafe) private static let feedItemSortDescriptors = [NSSortDescriptor(key: "publishDate", ascending: false)]

    // Predicate templates — avoids format string parsing on every call
    nonisolated(unsafe) private static let rssURLPredicateTemplate = NSPredicate(format: "rssURL == $URL")
    nonisolated(unsafe) private static let titleSearchPredicateTemplate = NSPredicate(format: "title CONTAINS[cd] $SEARCH_TEXT")
    nonisolated(unsafe) private static let unreadPredicate = NSPredicate(format: "wasRead == NO OR wasRead == nil")

    private let storeLock = NSLock()
    private var _isStoreLoaded = false
    private(set) var isStoreLoaded: Bool {
        get { storeLock.lock(); defer { storeLock.unlock() }; return _isStoreLoaded }
        set { storeLock.lock(); defer { storeLock.unlock() }; _isStoreLoaded = newValue }
    }

    // MARK: - Initialization

    init(modelName: String = "iFeed") {
        persistentContainer = NSPersistentContainer(name: modelName)
        setupPersistentContainer()
    }

    init(container: NSPersistentContainer) {
        self.persistentContainer = container
        setupPersistentContainer()
    }

    // MARK: - Setup

    private func setupPersistentContainer() {
        let storeURL = getLegacyStoreURL()

        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        persistentContainer.persistentStoreDescriptions = [storeDescription]

        persistentContainer.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.isStoreLoaded = false
                assertionFailure("Core Data store failed to load: \(error.localizedDescription)")
            } else {
                self?.isStoreLoaded = true
            }
        }

        configureContext(persistentContainer.viewContext)
    }

    private func configureContext(_ context: NSManagedObjectContext) {
        context.undoManager = nil
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.shouldDeleteInaccessibleFaults = true
    }

    private func getLegacyStoreURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1].appendingPathComponent("iFeed.sqlite")
    }

    // MARK: - Context Management

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        configureContext(context)
        return context
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { [weak self] context in
            self?.configureContext(context)
            block(context)
        }
    }

    // MARK: - Save Operations

    func saveViewContext() throws {
        try saveContext(viewContext)
    }

    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw CoreDataError.saveFailed(underlying: error)
        }
    }

    func saveContextAsync(_ context: NSManagedObjectContext, completion: ((Result<Void, CoreDataError>) -> Void)? = nil) {
        context.perform { [weak self] in
            guard let self else {
                completion?(.failure(.contextNotAvailable))
                return
            }
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

    func fetchFeeds(
        sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
        filteredBy predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) throws -> [Feed] {
        let request = NSFetchRequest<Feed>(entityName: EntityNames.feed.rawValue)
        request.fetchBatchSize = 20
        request.includesSubentities = false
        request.sortDescriptors = sortDescriptors ?? Self.feedSortDescriptors
        request.predicate = predicate
        return try executeFetchRequest(request, context: context)
    }

    func fetchFeedItems(
        sortedBy sortDescriptors: [NSSortDescriptor]? = nil,
        filteredBy predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) throws -> [FeedItem] {
        let request = NSFetchRequest<FeedItem>(entityName: EntityNames.feedItem.rawValue)
        request.fetchBatchSize = 20
        request.includesSubentities = false
        request.sortDescriptors = sortDescriptors ?? Self.feedItemSortDescriptors
        request.predicate = predicate
        return try executeFetchRequest(request, context: context)
    }

    private func executeFetchRequest<T: NSManagedObject>(
        _ request: NSFetchRequest<T>,
        context: NSManagedObjectContext? = nil
    ) throws -> [T] {
        let contextToUse = context ?? viewContext
        do {
            return try contextToUse.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(underlying: error)
        }
    }

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

    func delete(_ object: NSManagedObject, from context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? object.managedObjectContext ?? viewContext
        contextToUse.delete(object)
    }

    func delete(_ objects: [NSManagedObject], from context: NSManagedObjectContext? = nil) {
        for object in objects {
            let contextToUse = context ?? object.managedObjectContext ?? viewContext
            contextToUse.delete(object)
        }
    }

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
        } catch {
            throw CoreDataError.executionFailed(underlying: error)
        }
    }

    // MARK: - Batch Operations

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
        } catch {
            throw CoreDataError.executionFailed(underlying: error)
        }
    }

    // MARK: - Memory Management

    func resetViewContext() {
        viewContext.reset()
    }

    func refresh(_ objects: [NSManagedObject], mergeChanges: Bool = true) {
        for object in objects {
            guard let context = object.managedObjectContext else { continue }
            context.refresh(object, mergeChanges: mergeChanges)
        }
    }

    // MARK: - Utilities

    func clearAllData() throws {
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        for entityName in entityNames {
            try batchDelete(entityName: entityName)
        }
    }

    func isReady() -> Bool {
        return isStoreLoaded
    }
}

// MARK: - StorageProtocol conformance
extension NewCoreDataManager: StorageProtocol {

    func makeFeed() -> NSManagedObject? {
        return try? createFeed()
    }

    func makeFeedItem() -> NSManagedObject? {
        return try? createFeedItem()
    }

    func delete(_ object: NSManagedObject) {
        delete(object, from: nil)
    }

    func loadFeeds() -> [Feed] {
        return (try? fetchFeeds()) ?? []
    }

    func loadFeedItems() -> [FeedItem]? {
        return try? fetchFeedItems()
    }

    func saveChanges() {
        try? saveViewContext()
    }

    func containsFeed(withRSSURL rssURL: String) -> Bool {
        let predicate = Self.rssURLPredicateTemplate.withSubstitutionVariables(["URL": rssURL])
        let request = NSFetchRequest<Feed>(entityName: EntityNames.feed.rawValue)
        request.predicate = predicate
        return (try? viewContext.count(for: request)) ?? 0 > 0
    }

    func feed(at indexPath: IndexPath) -> Feed? {
        let request = NSFetchRequest<Feed>(entityName: EntityNames.feed.rawValue)
        request.sortDescriptors = Self.feedSortDescriptors
        request.fetchOffset = indexPath.row
        request.fetchLimit = 1
        request.includesSubentities = false
        request.includesPropertyValues = false
        return try? viewContext.fetch(request).first
    }

    func unreadCountsByFeed() -> [NSManagedObjectID: Int] {
        let request = NSFetchRequest<NSDictionary>(entityName: EntityNames.feedItem.rawValue)
        request.resultType = .dictionaryResultType
        request.predicate = Self.unreadPredicate

        let countExpression = NSExpressionDescription()
        countExpression.name = "count"
        countExpression.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "title")])
        countExpression.expressionResultType = .integer64AttributeType

        request.propertiesToFetch = ["feed", countExpression]
        request.propertiesToGroupBy = ["feed"]

        guard let results = try? viewContext.fetch(request) else { return [:] }

        var counts: [NSManagedObjectID: Int] = [:]
        for dict in results {
            if let feedID = dict["feed"] as? NSManagedObjectID,
               let count = dict["count"] as? Int {
                counts[feedID] = count
            }
        }
        return counts
    }

    /// Single-fetch bulk lookup: returns all saved RSS URLs so callers can do O(1) Set membership
    /// checks instead of N individual database queries (e.g., in cellForRowAt).
    func savedFeedURLs() -> Set<String> {
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: EntityNames.feed.rawValue)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["rssURL"]

        guard let results = try? viewContext.fetch(request) as? [NSDictionary] else { return [] }

        var urls = Set<String>(minimumCapacity: results.count)
        for dict in results {
            if let url = dict["rssURL"] as? String {
                urls.insert(url)
            }
        }
        return urls
    }
}

// MARK: - Convenience Methods
extension NewCoreDataManager {

    func fetchFeeds(matching searchText: String) throws -> [Feed] {
        let predicate = Self.titleSearchPredicateTemplate.withSubstitutionVariables(["SEARCH_TEXT": searchText])
        return try fetchFeeds(filteredBy: predicate)
    }

    func fetchUnreadFeedItems() throws -> [FeedItem] {
        return try fetchFeedItems(filteredBy: Self.unreadPredicate)
    }

    func countUnreadItems() throws -> Int {
        return try count(entityName: EntityNames.feedItem.rawValue, predicate: Self.unreadPredicate)
    }
}
