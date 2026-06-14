//
//  DIContainer.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

// MARK: - DIContainerProtocol

/// Conforms to `FeedsDependencies`, `FeedItemsDependencies`, `ExploreFeedsDependencies`
/// per the Interface Segregation Principle, Dependency Narrowing
@MainActor
protocol DIContainerProtocol: FeedsDependencies, FeedItemsDependencies, ExploreFeedsDependencies {
    func parser() -> any ParserProtocol
    func localSearch() -> any Searchable
    func exploreService() -> any ExploreFeedsServiceProtocol
    func storage() -> any StorageProtocol
    func keyedStorage() -> any KeyedStorageProtocol
}

// MARK: - DIContainer
@MainActor
final class DIContainer: SharedInstancesContainer {

}

// MARK: - DIContainerProtocol
extension DIContainer: DIContainerProtocol {

    /// Intentionally NOT shared: `Parser` holds a single weak delegate and cancels
    /// any in-flight parse when a new one begins. A shared instance would let one
    /// module hijack another module's active parse (and deliver its cancel callback
    /// to the wrong delegate), e.g. adding a feed while a pull-to-refresh is running.
    func parser() -> any ParserProtocol {
        return Parser()
    }

    func localSearch() -> any Searchable {
        return shared {
            return Search(storage: storage())
        }
    }

    func exploreService() -> any ExploreFeedsServiceProtocol {
        return shared {
            return ExploreFeedsService()
        }
    }

    func storage() -> any StorageProtocol {
        #if DEBUG
        if let override = UITestSupport.storageOverride {
            return override
        }
        #endif
        return shared {
            return CoreDataManager()
        }
    }

    func foldersManager() -> any FeedFolderManaging {
        #if DEBUG
        if let defaults = UITestSupport.foldersDefaultsOverride {
            return shared {
                return FeedFolderManager(defaults: defaults)
            }
        }
        #endif
        return shared {
            return FeedFolderManager()
        }
    }

    func keyedStorage() -> any KeyedStorageProtocol {
        #if DEBUG
        if let override = UITestSupport.keyedStorageOverride {
            return override
        }
        #endif
        return shared {
            return UserDefaults.standard
        }
    }
}
