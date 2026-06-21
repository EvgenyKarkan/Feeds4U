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

    /// Canned OPML payload requested via `-uiOPMLImport <key>`, used to drive the
    /// import-outcome UI without the system document picker (which XCUITest cannot
    /// reliably operate). `nil` when the argument is absent or names no known key.
    ///
    /// - `allSeeded` — every entry matches a `.populated` feed, so the import loop
    ///   skips them all (no network) and the summary reports only "Skipped".
    /// - `noFeeds` — well-formed OPML with outlines but no `xmlUrl`, exercising the
    ///   "no feeds found" alert.
    static var pendingOPMLImport: Data? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-uiOPMLImport"),
              args.indices.contains(index + 1) else {
            return nil
        }

        switch args[index + 1] {
        case "allSeeded":
            let outlines = Seeder.populatedFeedURLs
                .map { "<outline type=\"rss\" text=\"Seeded\" xmlUrl=\"\($0)\"/>" }
                .joined(separator: "\n")
            return opml(body: outlines).data(using: .utf8)
        case "noFeeds":
            return opml(body: "<outline text=\"A folder with no feeds\"/>").data(using: .utf8)
        default:
            return nil
        }
    }

    private static func opml(body: String) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0"><head><title>UITest</title></head><body>
        \(body)
        </body></opml>
        """
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

    /// Dedicated, self-cleaning directory (under the app's temporary directory)
    /// that holds the single UI-test SQLite store. Living under `tmp` keeps it out
    /// of the user-visible Documents/Application Support areas, and wiping it on
    /// every launch (see ``inMemoryContainer()``) means at most one store ever
    /// exists on disk and it never accumulates across runs.
    private static var storeDirectory: URL {
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("iFeedUITestStore", isDirectory: true)
    }

    /// An `NSPersistentContainer` backed by an **ephemeral, wiped-on-launch**
    /// SQLite store, loaded synchronously so seeding and the first UI read see a
    /// ready store.
    ///
    /// A real (tiny) SQLite file is used rather than `NSInMemoryStoreType` or a
    /// `/dev/null` store: the in-memory store does not support `GROUP BY` (the
    /// unread-count aggregate uses one), and a `/dev/null` store does not reliably
    /// share writes with the private-queue context the search index fetch runs on.
    /// To avoid polluting the disk, the store lives in a single fixed location
    /// (``storeDirectory``) that is **deleted and recreated on every launch** — so
    /// each run starts from a cleared store and nothing is left to pile up.
    private static func inMemoryContainer() -> NSPersistentContainer {
        let fileManager = FileManager.default

        // Clear any store left by a previous run (.sqlite plus its -wal/-shm
        // sidecars), then recreate the directory fresh.
        try? fileManager.removeItem(at: storeDirectory)
        try? fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

        // Self-heal: sweep stores left by the earlier UUID-per-launch
        // implementation so any pre-existing debris is cleared too. A no-op once
        // those are gone.
        if let leftovers = try? fileManager.contentsOfDirectory(
            at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil) {
            for url in leftovers where url.lastPathComponent.hasPrefix("ui-tests-") {
                try? fileManager.removeItem(at: url)
            }
        }

        let container = NSPersistentContainer(name: "iFeed")
        let storeURL = storeDirectory.appendingPathComponent("store.sqlite")

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
