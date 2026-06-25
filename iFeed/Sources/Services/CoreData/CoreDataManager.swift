//
//  CoreDataManager.swift
//  iFeed
//
//  Created on 4/28/26.
//  Modern Core Data manager addressing legacy issues
//

import CoreData
import Foundation
import SQLite3
import Synchronization

/// Typed errors surfaced by ``CoreDataManager`` operations.
///
/// Each case wraps the underlying system error so callers can inspect
/// or log the root cause while pattern-matching on the high-level category.
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

/// Centralises Core Data entity name strings to avoid scattering literals.
private enum EntityNames: String {
    case feed = "Feed"
    case feedItem = "FeedItem"
}

/// Central Core Data facade for the iFeed app.
///
/// Owns an `NSPersistentContainer` and exposes CRUD helpers for `Feed` and
/// `FeedItem` entities. All view-context work happens on the main queue;
/// background work should go through ``newBackgroundContext()`` or
/// ``performBackgroundTask(_:)``.
///
/// Thread-safety: ``isStoreLoaded`` is guarded by a `Mutex` so it can be
/// read from any thread. Everything else must be called from the context's
/// owning queue (main queue for the view context).
///
/// `@unchecked Sendable`: the persistent container is thread-safe, the cached
/// sort descriptors/predicates are immutable, and the only mutable stored
/// property (`storeLoaded`) is `Mutex`-guarded — so the manager can be captured
/// by the `@Sendable` background-task closures used for imports.
final class CoreDataManager: @unchecked Sendable {
    // MARK: - Properties

    private let persistentContainer: NSPersistentContainer

    /// Shorthand for the container's main-queue context.
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Cached sort descriptors — allocated once, reused by every fetch.
    nonisolated(unsafe) private static let feedSortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    nonisolated(unsafe) private static let feedItemSortDescriptors = [NSSortDescriptor(key: "publishDate", ascending: false)]
    /// Newest first; equal dates tie-break by `link` so the order is deterministic across fetches.
    nonisolated(unsafe) private static let feedItemListSortDescriptors = [
        NSSortDescriptor(key: "publishDate", ascending: false),
        NSSortDescriptor(key: "link", ascending: true)
    ]

    // Predicate templates — `withSubstitutionVariables` creates a bound copy
    // without re-parsing the format string on every call.
    nonisolated(unsafe) private static let rssURLPredicateTemplate = NSPredicate(format: "rssURL == $URL")
    nonisolated(unsafe) private static let titleSearchPredicateTemplate = NSPredicate(format: "title CONTAINS[cd] $SEARCH_TEXT")
    nonisolated(unsafe) private static let unreadPredicate = NSPredicate(format: "wasRead == NO OR wasRead == nil")
    nonisolated(unsafe) private static let itemsOfFeedPredicateTemplate = NSPredicate(format: "feed == $FEED")
    nonisolated(unsafe) private static let unreadItemsOfFeedPredicateTemplate =
        NSPredicate(format: "feed == $FEED AND (wasRead == NO OR wasRead == nil)")

    /// Cached expression for ``unreadCountsByFeed()``'s grouped aggregate fetch.
    nonisolated(unsafe) private static let unreadCountExpression: NSExpressionDescription = {
        let expr = NSExpressionDescription()
        expr.name = "count"
        expr.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "title")])
        expr.expressionResultType = .integer64AttributeType
        return expr
    }()

    /// Mutex-guarded flag set once the persistent store finishes loading.
    private let storeLoaded = Mutex(false)
    private(set) var isStoreLoaded: Bool {
        get { storeLoaded.withLock { $0 } }
        set { storeLoaded.withLock { $0 = newValue } }
    }

    /// Callbacks waiting for the asynchronous store load, drained on the main queue.
    private let pendingStoreReadyCallbacks = Mutex<[@Sendable () -> Void]>([])

    // MARK: - Initialization

    /// Creates a manager that loads the named Core Data model from the main bundle.
    ///
    /// - Parameter modelName: `.xcdatamodeld` file name (without extension).
    init(modelName: String = "iFeed") {
        persistentContainer = NSPersistentContainer(name: modelName)
        setupPersistentContainer()
    }

    /// Creates a manager around a persistent container.
    ///
    /// If the container already has loaded stores, the manager uses it as-is. This
    /// is how tests inject a temporary SQLite store. If it has no loaded stores,
    /// this initializer preserves the default setup path and loads the app store.
    init(container: NSPersistentContainer) {
        self.persistentContainer = container

        if container.persistentStoreCoordinator.persistentStores.isEmpty {
            setupPersistentContainer()
        } else {
            isStoreLoaded = true
            Self.configureContext(persistentContainer.viewContext)
        }
    }

    // MARK: - Setup

    /// Configures the persistent store description with lightweight-migration
    /// options, loads the store **asynchronously** (so a slow disk or migration
    /// never blocks the launch path on the main thread), and configures the
    /// view context. Callers waiting on the store use ``performWhenStoreReady(_:)``.
    private func setupPersistentContainer() {
        let storeURL = getLegacyStoreURL()

        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        storeDescription.shouldAddStoreAsynchronously = true

        persistentContainer.persistentStoreDescriptions = [storeDescription]

        persistentContainer.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.isStoreLoaded = false
                assertionFailure("Core Data store failed to load: \(error.localizedDescription)")
            } else {
                self?.isStoreLoaded = true
            }
            /// Drained in both branches so queued callers are never stranded;
            /// on failure they simply observe an empty store.
            self?.drainStoreReadyCallbacks()
        }

        Self.configureContext(persistentContainer.viewContext)
    }

    /// Applies the app's standard context settings:
    /// - Removes the undo manager to save memory (the app has no undo UI).
    /// - Enables automatic merge so background saves propagate to the view context.
    /// - Uses object-trump merge policy so in-memory edits win over store values.
    /// - Deletes inaccessible faults instead of throwing, preventing crashes when
    ///   a referenced object has been deleted by another context.
    private static func configureContext(_ context: NSManagedObjectContext) {
        context.undoManager = nil
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.shouldDeleteInaccessibleFaults = true
    }

    /// Returns the SQLite store URL in the app's Documents directory.
    ///
    /// Uses the same path the app has always used so existing user data is
    /// picked up without a migration step.
    private func getLegacyStoreURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1].appendingPathComponent("iFeed.sqlite")
    }

    // MARK: - Context Management

    /// Returns a new private-queue context parented to the persistent store coordinator.
    ///
    /// Use this when you need to hold onto a background context across multiple
    /// operations (e.g., a long-running import). For one-shot work prefer
    /// ``performBackgroundTask(_:)``.
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        Self.configureContext(context)
        return context
    }

    /// Executes `block` on a freshly created private-queue context.
    ///
    /// The context is configured with the same merge policy and settings as
    /// the view context. Ideal for one-shot background writes.
    func performBackgroundTask(_ block: @escaping @Sendable (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            Self.configureContext(context)
            block(context)
        }
    }

    // MARK: - Save Operations

    /// Persists pending changes in the view context.
    ///
    /// No-op when the context has no changes.
    /// Rolls back and throws ``CoreDataError/saveFailed(underlying:)`` on failure.
    func saveViewContext() throws {
        try saveContext(viewContext)
    }

    /// Persists pending changes in the given context.
    ///
    /// Skips the save when `hasChanges` is `false` to avoid unnecessary I/O.
    /// On failure the context is rolled back to its last consistent state so
    /// callers never observe a half-applied changeset.
    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw CoreDataError.saveFailed(underlying: error)
        }
    }

    /// Asynchronously saves `context` on its own queue.
    ///
    /// Uses `context.perform` to ensure the save happens on the correct queue,
    /// then reports success or failure through `completion`.
    func saveContextAsync(_ context: NSManagedObjectContext, completion: (@Sendable (Result<Void, CoreDataError>) -> Void)? = nil) {
        context.perform {
            do {
                guard context.hasChanges else {
                    completion?(.success(()))
                    return
                }
                try context.save()
                completion?(.success(()))
            } catch {
                context.rollback()
                completion?(.failure(.saveFailed(underlying: error)))
            }
        }
    }

    /// Asynchronously saves `context` on its own queue using the native `async` overload.
    ///
    /// Prefer this overload when calling from an `async` context — it suspends the caller
    /// rather than requiring a completion closure.
    func saveContextAsync(_ context: NSManagedObjectContext) async throws {
        try await context.perform {
            guard context.hasChanges else {
                return
            }

            do {
                try context.save()
            } catch {
                context.rollback()
                throw CoreDataError.saveFailed(underlying: error)
            }
        }
    }

    // MARK: - Fetch Operations

    /// Fetches `Feed` entities sorted by title (ascending) by default.
    ///
    /// Results are returned in batches of 20 to limit peak memory when the
    /// caller iterates lazily (e.g., table view data source).
    ///
    /// - Parameters:
    ///   - sortDescriptors: Custom ordering. Pass `nil` to sort by title A-Z.
    ///   - predicate: Optional filter. Pass `nil` to fetch all feeds.
    ///   - context: Context to fetch from. Defaults to the view context.
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

    /// Fetches `FeedItem` entities sorted by publish date (newest first) by default.
    ///
    /// - Parameters:
    ///   - sortDescriptors: Custom ordering. Pass `nil` to sort newest-first.
    ///   - predicate: Optional filter. Pass `nil` to fetch all items.
    ///   - context: Context to fetch from. Defaults to the view context.
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

    /// Executes a typed fetch request and wraps Core Data errors.
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

    /// Returns the number of objects matching `entityName` and an optional predicate.
    ///
    /// Uses `count(for:)` which translates to `SELECT COUNT(*)` — no managed
    /// objects are materialised.
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

    /// Inserts and returns a new unsaved `Feed` in the given context.
    ///
    /// - Parameter context: Target context. Defaults to the view context.
    /// - Throws: ``CoreDataError/entityCreationFailed(entityName:)`` if the
    ///   model does not contain a `Feed` entity (should never happen at runtime).
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

    /// Inserts and returns a new unsaved `FeedItem` in the given context.
    ///
    /// - Parameter context: Target context. Defaults to the view context.
    /// - Throws: ``CoreDataError/entityCreationFailed(entityName:)`` if the
    ///   model does not contain a `FeedItem` entity.
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

    /// Marks a single managed object for deletion.
    ///
    /// The deletion is staged in the object's own context (or an explicit one)
    /// and only persisted when the context is saved.
    func delete(_ object: NSManagedObject, from context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? object.managedObjectContext ?? viewContext
        contextToUse.delete(object)
    }

    /// Marks multiple managed objects for deletion.
    ///
    /// Each object is deleted from its own context unless an explicit context is
    /// provided. Changes are not persisted until the context is saved.
    func delete(_ objects: [NSManagedObject], from context: NSManagedObjectContext? = nil) {
        for object in objects {
            let contextToUse = context ?? object.managedObjectContext ?? viewContext
            contextToUse.delete(object)
        }
    }

    /// Deletes all objects of `entityName` (optionally filtered by `predicate`)
    /// using an `NSBatchDeleteRequest`.
    ///
    /// Batch deletes execute directly against the SQLite store, bypassing the
    /// context for maximum speed. The affected object IDs are then merged back
    /// into `context` so its in-memory state stays consistent.
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

    /// Updates properties on all matching rows using an `NSBatchUpdateRequest`.
    ///
    /// Like ``batchDelete(entityName:predicate:context:)``, this operates at
    /// the SQL level for speed and merges the affected object IDs back into
    /// the context so in-memory objects reflect the new values.
    ///
    /// - Parameters:
    ///   - entityName: Core Data entity to update.
    ///   - propertiesToUpdate: Key-value pairs of attribute names and new values.
    ///   - predicate: Optional filter. Pass `nil` to update every row.
    ///   - context: Context to merge results into. Defaults to the view context.
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

    /// Discards all unsaved changes and faults in the view context.
    ///
    /// After this call every managed object obtained from the view context
    /// becomes invalid. Use sparingly — primarily useful when the UI needs
    /// a full reload from the store.
    func resetViewContext() {
        viewContext.reset()
    }

    /// Re-faults managed objects to release their in-memory property data.
    ///
    /// When `mergeChanges` is `true` (default), unsaved changes on each object
    /// are preserved. When `false`, the object reverts to its last-saved state.
    /// Useful after displaying a large list to free memory held by row objects
    /// that scrolled off screen.
    func refresh(_ objects: [NSManagedObject], mergeChanges: Bool = true) {
        for object in objects {
            guard let context = object.managedObjectContext else { continue }
            context.refresh(object, mergeChanges: mergeChanges)
        }
    }

    // MARK: - Utilities

    /// Batch-deletes every object of every entity in the model.
    ///
    /// Iterates the model's entity list and issues one ``batchDelete(entityName:predicate:context:)``
    /// per entity. Intended for development/testing resets, not normal user flows.
    func clearAllData() throws {
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap { $0.name }
        for entityName in entityNames {
            try batchDelete(entityName: entityName)
        }
    }

    /// Bytes of live data the local store holds.
    ///
    /// Measuring the raw `.sqlite` file is misleading: in WAL mode the file never
    /// shrinks on delete (SQLite keeps freed pages on a free list for reuse) and
    /// the `-wal` sidecar grows on every write — so a delete can leave the file
    /// size flat or even larger. Instead of the physical file, this reports the
    /// *used* size from SQLite's own page accounting:
    ///
    ///     (page_count − freelist_count) × page_size
    ///
    /// Deleting feeds moves their pages onto the free list, so this figure drops
    /// straight away — no `VACUUM` (which a second connection can't run while Core
    /// Data holds the store) and no file rewrite. The pragmas are read-only, so
    /// they never contend with Core Data's connection.
    ///
    /// Returns 0 for a store with no file backing (e.g. an in-memory store) or if
    /// the database cannot be opened.
    func storageSizeBytes() -> Int64 {
        guard let storeURL = persistentContainer.persistentStoreCoordinator
            .persistentStores.first?.url, storeURL.isFileURL else {
            return 0
        }

        var database: OpaquePointer?
        guard sqlite3_open(storeURL.path, &database) == SQLITE_OK else {
            sqlite3_close(database)
            return 0
        }
        defer {
            sqlite3_close(database)
        }

        let pageSize = pragmaInt(database, "PRAGMA page_size;")
        let pageCount = pragmaInt(database, "PRAGMA page_count;")
        let freeCount = pragmaInt(database, "PRAGMA freelist_count;")

        return max(0, pageCount - freeCount) * pageSize
    }

    /// Runs a single-row, single-column integer `PRAGMA` and returns its value
    /// (0 if the statement cannot be prepared or yields no row).
    private func pragmaInt(_ database: OpaquePointer?, _ sql: String) -> Int64 {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        defer {
            sqlite3_finalize(statement)
        }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }
        return sqlite3_column_int64(statement, 0)
    }

    /// Returns `true` once the persistent store has finished loading.
    ///
    /// Callers can check this before issuing fetches to avoid operating on
    /// an unloaded store. Thread-safe (backed by ``storeLoaded``).
    func isReady() -> Bool {
        return isStoreLoaded
    }

    /// Runs `callback` once the persistent store is available.
    ///
    /// Invoked synchronously on the caller's thread when the store is already
    /// loaded; otherwise queued and delivered on the main queue right after the
    /// asynchronous store load finishes (also on failure, so callers are never
    /// stranded — they simply observe an empty store).
    func performWhenStoreReady(_ callback: @escaping @Sendable () -> Void) {
        guard !isStoreLoaded else {
            callback()
            return
        }

        pendingStoreReadyCallbacks.withLock { $0.append(callback) }

        /// The store may have finished loading between the check above and the
        /// append — drain again so the callback cannot be stranded.
        if isStoreLoaded {
            drainStoreReadyCallbacks()
        }
    }

    /// Removes all queued store-ready callbacks and invokes them on the main queue.
    private func drainStoreReadyCallbacks() {
        let callbacks = pendingStoreReadyCallbacks.withLock { pending -> [@Sendable () -> Void] in
            let drained = pending
            pending = []
            return drained
        }

        guard !callbacks.isEmpty else {
            return
        }

        DispatchQueue.main.async {
            for callback in callbacks {
                callback()
            }
        }
    }
}

// MARK: - StorageProtocol conformance
//
// These methods bridge the throwing/typed Core Data API above to the
// non-throwing `StorageProtocol` contract used by presenters and interactors.
// Errors are intentionally swallowed (returning nil / empty) because the
// callers treat storage failures as empty state.

extension CoreDataManager: StorageProtocol {

    func makeFeed() -> Feed? {
        return try? createFeed()
    }

    func makeFeedItem() -> FeedItem? {
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

    /// Materialises the items for `objectIDs` with a single `self IN %@` fetch —
    /// `existingObject(with:)` per ID was one SQLite round-trip per match on the
    /// main thread. Deleted IDs are silently omitted and duplicate IDs collapse
    /// into one object; results arrive newest-first like every item fetch, and
    /// callers needing a specific order apply their own sort.
    func loadFeedItems(withIDs objectIDs: [NSManagedObjectID]) -> [FeedItem] {
        guard !objectIDs.isEmpty else {
            return []
        }
        let predicate = NSPredicate(format: "self IN %@", objectIDs)
        return (try? fetchFeedItems(filteredBy: predicate)) ?? []
    }

    /// Runs the title/objectID projection fetch on a background context so
    /// building the search index never blocks the main thread, and hands the
    /// result back on the main actor. `NSManagedObjectID`s are `Sendable` and
    /// valid across contexts, so no managed objects cross the boundary.
    func fetchFeedItemIndex(_ completion: @escaping @Sendable ([(title: String, objectID: NSManagedObjectID)]?) -> Void) {
        performBackgroundTask { context in
            let request = NSFetchRequest<NSDictionary>(entityName: EntityNames.feedItem.rawValue)
            request.resultType = .dictionaryResultType

            let idExpression = NSExpressionDescription()
            idExpression.name = "objectID"
            idExpression.expression = NSExpression(format: "self")
            idExpression.expressionResultType = .objectIDAttributeType

            request.propertiesToFetch = ["title", idExpression]
            request.includesSubentities = false

            let index: [(title: String, objectID: NSManagedObjectID)]? = (try? context.fetch(request)).map { results in
                results.compactMap { dict in
                    guard let title = dict["title"] as? String,
                          let objectID = dict["objectID"] as? NSManagedObjectID else {
                        return nil
                    }
                    return (title, objectID)
                }
            }

            Task { @MainActor in
                completion(index)
            }
        }
    }

    func saveChanges() {
        try? saveViewContext()
    }

    /// Checks existence via `COUNT(*)` — no managed objects are materialised.
    ///
    /// Uses a cached predicate template with variable substitution so the
    /// format string is parsed only once across all calls.
    func containsFeed(withRSSURL rssURL: String) -> Bool {
        let predicate = Self.rssURLPredicateTemplate.withSubstitutionVariables(["URL": rssURL])
        let request = NSFetchRequest<Feed>(entityName: EntityNames.feed.rawValue)
        request.predicate = predicate
        request.includesSubentities = false
        return (try? viewContext.count(for: request)) ?? 0 > 0
    }

    /// Returns the feed at a table-view index path using `fetchOffset`/`fetchLimit`
    /// so SQLite skips rows at the database level instead of loading them all.
    func feed(at indexPath: IndexPath) -> Feed? {
        let request = NSFetchRequest<Feed>(entityName: EntityNames.feed.rawValue)
        request.sortDescriptors = Self.feedSortDescriptors
        request.fetchOffset = indexPath.row
        request.fetchLimit = 1
        request.includesSubentities = false
        return try? viewContext.fetch(request).first
    }

    /// Returns a dictionary mapping each feed's `NSManagedObjectID` to its
    /// unread item count using a single grouped aggregate fetch.
    ///
    /// The query runs entirely in SQLite (`GROUP BY feed WHERE wasRead == NO`)
    /// and returns one dictionary row per feed — no `FeedItem` objects are
    /// materialised. Feeds with zero unread items are absent from the result.
    func unreadCountsByFeed() -> [NSManagedObjectID: Int] {
        let request = NSFetchRequest<NSDictionary>(entityName: EntityNames.feedItem.rawValue)
        request.resultType = .dictionaryResultType
        request.predicate = Self.unreadPredicate
        request.propertiesToFetch = ["feed", Self.unreadCountExpression]
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

    /// Loads one feed's items sorted newest-first (link as tie-break) at the SQL
    /// level, in batches of 20 — the relationship is never materialised in full.
    func feedItems(for feed: Feed) -> [FeedItem] {
        let predicate = Self.itemsOfFeedPredicateTemplate.withSubstitutionVariables(["FEED": feed])
        return (try? fetchFeedItems(sortedBy: Self.feedItemListSortDescriptors, filteredBy: predicate)) ?? []
    }

    /// Counts unread items of a single feed via `COUNT(*)` — no objects are materialised.
    func unreadCount(for feed: Feed) -> Int {
        let predicate = Self.unreadItemsOfFeedPredicateTemplate.withSubstitutionVariables(["FEED": feed])
        return (try? count(entityName: EntityNames.feedItem.rawValue, predicate: predicate)) ?? 0
    }

    /// Counts all items of a single feed via `COUNT(*)` — unlike reading
    /// `feed.feedItems.count`, this never fires the to-many relationship fault,
    /// so checking item presence stays O(1) in memory regardless of feed size.
    func itemCount(for feed: Feed) -> Int {
        let predicate = Self.itemsOfFeedPredicateTemplate.withSubstitutionVariables(["FEED": feed])
        return (try? count(entityName: EntityNames.feedItem.rawValue, predicate: predicate)) ?? 0
    }

    /// Re-faults the item's ``FeedItemContent`` row, releasing the article HTML
    /// it holds in memory.
    ///
    /// Reading `htmlContent` fires the content fault; without this call, every
    /// article opened from a list keeps its full body resident for as long as
    /// the list (whose snapshot retains the item) stays on screen. Skipped when
    /// the content has unsaved changes — `refresh(_:mergeChanges: false)` would
    /// silently discard them.
    func releaseContent(of item: FeedItem) {
        guard let content = item.content,
              !content.isFault,
              !content.hasChanges,
              let context = content.managedObjectContext else {
            return
        }
        context.refresh(content, mergeChanges: false)
    }

    /// Marks all unread items of a feed as read with an `NSBatchUpdateRequest`.
    ///
    /// Runs at the SQL level — no `FeedItem` objects are loaded or saved — and
    /// ``batchUpdate(entityName:propertiesToUpdate:predicate:context:)`` merges
    /// the updated object IDs back so any loaded items reflect the change.
    func markAllAsRead(in feed: Feed) {
        let predicate = Self.unreadItemsOfFeedPredicateTemplate.withSubstitutionVariables(["FEED": feed])
        try? batchUpdate(
            entityName: EntityNames.feedItem.rawValue,
            propertiesToUpdate: ["wasRead": true],
            predicate: predicate
        )
    }

    /// Returns the feed with the given object ID from the view context, or `nil`.
    func loadFeed(withID id: NSManagedObjectID) -> Feed? {
        return (try? viewContext.existingObject(with: id)) as? Feed
    }

    /// Imports a parsed feed with all its items on a background context.
    ///
    /// Entity creation and the save happen off the main thread — large feeds
    /// (hundreds of items with article HTML) no longer stall the UI right as
    /// the loading indicator dismisses. `completion` is delivered on the main
    /// actor with the saved feed's (permanent, `Sendable`) object ID, or `nil`
    /// when creation or the save fails; callers rematerialise the feed via
    /// ``loadFeed(withID:)``.
    func importFeed(_ data: ParsedFeedData,
                    rssURL: String,
                    completion: @escaping @Sendable (NSManagedObjectID?) -> Void) {
        performBackgroundTask { [weak self] context in
            guard let self,
                  let feed = try? self.createFeed(in: context) else {
                Task { @MainActor in completion(nil) }
                return
            }

            feed.title = data.title
            feed.rssURL = rssURL
            feed.summary = data.summary

            for itemData in data.items {
                guard let feedItem = try? self.createFeedItem(in: context) else {
                    continue
                }
                feedItem.title = itemData.title
                feedItem.link = itemData.link
                feedItem.htmlContent = itemData.htmlContent
                feedItem.publishDate = itemData.publishDate

                /// Create a relationship
                feedItem.feed = feed
            }

            do {
                try self.saveContext(context)
            } catch {
                Task { @MainActor in completion(nil) }
                return
            }

            /// Only the (Sendable) object ID crosses the actor boundary.
            let feedID = feed.objectID
            Task { @MainActor in
                completion(feedID)
            }
        }
    }

    /// Merges freshly parsed feed items into an existing feed on a background
    /// context, persisting only new (unique) entries.
    ///
    /// Performs a **link-identity deduplication** — the link is an article's
    /// canonical identity, so an incoming item is skipped when its link is
    /// already stored (covers exact duplicates and "same link with an updated
    /// title"). An item with a new link is additionally skipped only when its
    /// title AND publish date both match existing values — the signature of an
    /// article republished under a new URL. Requiring all three fields to be
    /// new (the previous rule) silently dropped real articles: a second item
    /// published at the same date-only timestamp, or a recurring title like
    /// "Weekly digest", could never be inserted.
    ///
    /// The existing-item snapshot is a `dictionaryResultType` projection of just
    /// the three dedup fields — no `FeedItem` objects (and no article HTML) are
    /// materialised, and all work including the save happens off the main thread.
    ///
    /// - Parameters:
    ///   - items: Normalized, `Sendable` representations of the remote items.
    ///   - feedID: Object ID of the feed to merge into.
    ///   - completion: Called on the main actor once the merge has finished
    ///     (also when the feed no longer exists and nothing was merged).
    func refreshFeedItems(with items: [ParsedFeedItemData],
                          forFeedWith feedID: NSManagedObjectID,
                          completion: @escaping @Sendable () -> Void) {
        performBackgroundTask { [weak self] context in
            /// The caller is always notified — even on the early-return paths.
            defer {
                Task { @MainActor in completion() }
            }

            guard let self,
                  let feed = (try? context.existingObject(with: feedID)) as? Feed else {
                return
            }

            // Step 1: Snapshot the existing items' dedup fields into O(1)-lookup sets.
            let request = NSFetchRequest<NSDictionary>(entityName: EntityNames.feedItem.rawValue)
            request.resultType = .dictionaryResultType
            request.predicate = Self.itemsOfFeedPredicateTemplate.withSubstitutionVariables(["FEED": feed])
            request.propertiesToFetch = ["title", "link", "publishDate"]
            let existing = (try? context.fetch(request)) ?? []

            var existedTitles = Set<String>(minimumCapacity: existing.count)
            var existedLinks = Set<String>(minimumCapacity: existing.count)
            var existedDates = Set<TimeInterval>(minimumCapacity: existing.count)
            for dict in existing {
                if let title = dict["title"] as? String {
                    existedTitles.insert(title)
                }
                if let link = dict["link"] as? String {
                    existedLinks.insert(link)
                }
                if let date = dict["publishDate"] as? Date {
                    existedDates.insert(date.timeIntervalSince1970)
                }
            }

            // Step 2: Compare each incoming parsed item against the dedup sets.
            // The link is the article's identity: a known link is always a duplicate.
            // A new link is rejected only when title AND date both match — the
            // signature of the same article republished under a new URL.
            for itemData in items {
                let isDuplicateLink = existedLinks.contains(itemData.link)
                let isRepublished = existedTitles.contains(itemData.title)
                    && existedDates.contains(itemData.publishDate.timeIntervalSince1970)

                guard !isDuplicateLink && !isRepublished else {
                    continue
                }

                // Step 3: Create a Core Data entity only for items not already in the feed.
                guard let feedItem = try? self.createFeedItem(in: context) else {
                    continue
                }
                feedItem.title = itemData.title
                feedItem.link = itemData.link
                feedItem.htmlContent = itemData.htmlContent
                feedItem.publishDate = itemData.publishDate

                /// Create a relationship
                feedItem.feed = feed

                // Track the inserted item's fields so a duplicate appearing
                // later in the same incoming batch is also rejected.
                existedTitles.insert(itemData.title)
                existedLinks.insert(itemData.link)
                existedDates.insert(itemData.publishDate.timeIntervalSince1970)
            }

            // Step 4: Persist newly added items; the view context picks the changes
            // up through `automaticallyMergesChangesFromParent`.
            try? self.saveContext(context)
        }
    }

    /// Returns all saved RSS URLs in a single fetch so callers can do O(1) `Set`
    /// membership checks instead of N individual database queries.
    ///
    /// Uses `dictionaryResultType` with a single-property projection to avoid
    /// materialising full `Feed` managed objects.
    func savedFeedURLs() -> Set<String> {
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: EntityNames.feed.rawValue)
        request.resultType = .dictionaryResultType
        request.includesSubentities = false
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
extension CoreDataManager {

    /// Fetches feeds whose title contains `searchText` (case- and diacritic-insensitive).
    func fetchFeeds(matching searchText: String) throws -> [Feed] {
        let predicate = Self.titleSearchPredicateTemplate.withSubstitutionVariables(["SEARCH_TEXT": searchText])
        return try fetchFeeds(filteredBy: predicate)
    }

    /// Fetches feed items where `wasRead` is `false` or `nil`.
    func fetchUnreadFeedItems() throws -> [FeedItem] {
        return try fetchFeedItems(filteredBy: Self.unreadPredicate)
    }

    /// Returns the total number of unread items across all feeds.
    ///
    /// Uses `COUNT(*)` — no managed objects are materialised.
    func countUnreadItems() throws -> Int {
        return try count(entityName: EntityNames.feedItem.rawValue, predicate: Self.unreadPredicate)
    }
}
