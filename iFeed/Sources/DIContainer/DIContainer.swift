//
//  DIContainer.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

// MARK: - DIContainerProtocol

/// Confroms to `FeedsDependencies` for Dependency Narrowing
protocol DIContainerProtocol: FeedsDependencies {
    func parser() -> any ParserProtocol
    func localSearch() -> any Searchable
    func exploreService() -> any FeedExploreServiceProtocol
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

    func exploreService() -> any FeedExploreServiceProtocol {
        return shared {
            return FeedExploreService()
        }
    }

    func storage() -> any StorageProtocol {
        return shared {
            return NewCoreDataManager.shared
        }
    }
}
