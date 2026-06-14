//
//  UITestSupport.swift
//  iFeed
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

#if DEBUG
import CoreData
import Foundation

/// DEBUG-only launch hook that boots the app on a deterministic, **in-memory**
/// Core Data store plus an isolated `UserDefaults` suite, pre-seeded per scenario.
///
/// Activated only when the process is launched with `-uiTesting` (an XCUITest
/// run); the production launch path is never touched. `DIContainer` reads the
/// overrides exposed here instead of building the real storage services.
@MainActor
enum UITestSupport {

    /// UserDefaults suite kept separate from the app's real defaults so a UI-test
    /// run never reads or mutates the user's folders / recent searches.
    static let suiteName = "com.ifeed.uitests"

    private(set) static var storageOverride: (any StorageProtocol)?
    private(set) static var keyedStorageOverride: (any KeyedStorageProtocol)?
    private(set) static var foldersDefaultsOverride: UserDefaults?

    /// `true` when launched by an XCUITest run (the test harness passes `-uiTesting`).
    static var isUITesting: Bool {
        return ProcessInfo.processInfo.arguments.contains("-uiTesting")
    }

    /// Builds the in-memory store + isolated defaults, seeds the requested
    /// scenario, and publishes them as the DI overrides. Call once, before the
    /// window is built.
    static func bootstrap() {
        let scenario = currentScenario()
        let defaults = isolatedDefaults()
        let container = inMemoryContainer()

        Seeder.seed(scenario: scenario, container: container, defaults: defaults)

        storageOverride = CoreDataManager(container: container)
        keyedStorageOverride = defaults
        foldersDefaultsOverride = defaults
    }

    // MARK: - Private
    private static func currentScenario() -> UITestScenario {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-uiScenario"),
              args.indices.contains(index + 1),
              let scenario = UITestScenario(rawValue: args[index + 1]) else {
            return .empty
        }
        return scenario
    }

    /// A wiped, test-private `UserDefaults` suite. Falls back to `.standard`
    /// only if the suite cannot be created (never expected in practice).
    private static func isolatedDefaults() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// An `NSPersistentContainer` backed by an ephemeral store, loaded
    /// **synchronously** so seeding and the first UI read see a ready store.
    ///
    /// Uses a real SQLite store at a fresh temp-file URL (wiped first) rather
    /// than `NSInMemoryStoreType` or a `/dev/null` store: the in-memory store
    /// does not support `GROUP BY` (the unread-count aggregate uses one), and a
    /// `/dev/null` store does not reliably share writes with the private-queue
    /// context the search index fetch runs on. A temp-file SQLite store has full
    /// query support and is shared across all of the coordinator's contexts.
    private static func inMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "iFeed")

        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ui-tests-\(UUID().uuidString).sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("UI-test store failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }
}
#endif
