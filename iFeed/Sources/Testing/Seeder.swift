//
//  Seeder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

#if DEBUG
import CoreData
import Foundation

/// Populates a UI-test in-memory store and isolated defaults with deterministic
/// fixtures. Writes feeds/items straight onto the container's view context
/// (synchronous, no background hops) and folders/recent-searches as the same
/// JSON/array shapes the app persists, so the seeded data is indistinguishable
/// from data created at runtime.
enum Seeder {

    /// A feed plus the titles of its (unread) items.
    private struct FeedSpec {
        let title: String
        let url: String
        let itemTitles: [String]
    }

    // Stable folder-storage key — must match `FeedFolderManager.storageKey`.
    private static let foldersKey = "feed_folders_v1"
    // Stable recent-searches key — must match `FeedsInteractor.Constants.recentSearchesKey`.
    private static let recentSearchesKey = "com.ifeed.recentSearches"

    private static let feeds: [FeedSpec] = [
        FeedSpec(title: "Swift Blog", url: "https://swift.org/feed.xml",
                 itemTitles: ["Swift 6 concurrency", "Embedded Swift", "Swift on Server"]),
        FeedSpec(title: "Apple Newsroom", url: "https://apple.com/feed.xml",
                 itemTitles: ["Apple announces WWDC", "New MacBook Pro"]),
        FeedSpec(title: "Hacker News", url: "https://news.ycombinator.com/rss",
                 itemTitles: ["Show HN: a tiny RSS reader", "Ask HN: best practices"]),
        FeedSpec(title: "The Verge", url: "https://theverge.com/rss",
                 itemTitles: ["Gadgets of the year", "Tech policy update"])
    ]

    static func seed(scenario: UITestScenario,
                     container: NSPersistentContainer,
                     defaults: UserDefaults) {
        switch scenario {
        case .empty:
            break

        case .populated:
            insert(feeds, into: container)

        case .singleFeed:
            insert(Array(feeds.prefix(1)), into: container)

        case .folders:
            let specs = Array(feeds.prefix(4))
            insert(specs, into: container)
            let folder = FeedFolder(name: "Tech", feedURLs: [specs[0].url, specs[1].url])
            persistFolders([folder], to: defaults)

        case .search:
            insert(feeds, into: container)
            defaults.set(["apple", "swift"], forKey: recentSearchesKey)
        }
    }

    // MARK: - Core Data
    private static func insert(_ specs: [FeedSpec], into container: NSPersistentContainer) {
        let context = container.viewContext

        for spec in specs {
            guard let feed = NSEntityDescription.insertNewObject(
                forEntityName: "Feed", into: context) as? Feed else {
                continue
            }
            feed.title = spec.title
            feed.rssURL = spec.url
            feed.summary = spec.title

            for (offset, itemTitle) in spec.itemTitles.enumerated() {
                guard let item = NSEntityDescription.insertNewObject(
                    forEntityName: "FeedItem", into: context) as? FeedItem else {
                    continue
                }
                item.title = itemTitle
                item.link = "\(spec.url)#item\(offset)"
                item.publishDate = Date(timeIntervalSince1970: TimeInterval(1_700_000_000 - offset * 3_600))
                item.wasRead = NSNumber(value: false)
                item.feed = feed
            }
        }

        do {
            try context.save()
        } catch {
            assertionFailure("UI-test seeding failed to save: \(error.localizedDescription)")
        }
    }

    // MARK: - Defaults
    private static func persistFolders(_ folders: [FeedFolder], to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(folders) else {
            return
        }
        defaults.set(data, forKey: foldersKey)
    }
}
#endif
