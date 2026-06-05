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
protocol DIContainerProtocol: FeedsDependencies, FeedItemsDependencies, ExploreFeedsDependencies, ArticleReaderDependencies {
    func parser() -> any ParserProtocol
    func localSearch() -> any Searchable
    func exploreService() -> any ExploreFeedsServiceProtocol
    func storage() -> any StorageProtocol
    func keyedStorage() -> any KeyedStorageProtocol
}

// MARK: - DIContainer
final class DIContainer: SharedInstancesContainer, @unchecked Sendable {

}

// MARK: - DIContainerProtocol
extension DIContainer: DIContainerProtocol {

    func parser() -> any ParserProtocol {
        return shared {
            return Parser()
        }
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
        return shared {
            return CoreDataManager()
        }
    }

    func foldersManager() -> any FeedFolderManaging {
        return shared {
            return FeedFolderManager()
        }
    }

    func keyedStorage() -> any KeyedStorageProtocol {
        return shared {
            return UserDefaults.standard
        }
    }
}
