//
//  DIContainer.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

// MARK: - DIContainerProtocol

/// Conforms to `FeedsDependencies`, `FeedItemsDependencies` per the Interface Segregation Principle, Dependency Narrowing
protocol DIContainerProtocol: FeedsDependencies, FeedItemsDependencies {
    func parser() -> any ParserProtocol
    func localSearch() -> any Searchable
    func exploreService() -> any ExploreFeedsServiceProtocol
    func storage() -> any StorageProtocol
}

// MARK: - DIContainer
final class DIContainer: SharedInstancesContainer, @unchecked Sendable {

}

// MARK: - DIContainerProtocol
extension DIContainer: DIContainerProtocol {

    func parser() -> any ParserProtocol {
        return shared {
            return Parser(storage: storage())
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
            return CoreDataManager.shared
        }
    }
}
