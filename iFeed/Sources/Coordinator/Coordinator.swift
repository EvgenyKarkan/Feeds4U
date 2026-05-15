//
//  Coordinator.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit

/// Defines the basic requirements for a coordinator, which is responsible for coordinating the navigation
/// flow within the application.
protocol Coordinating {
    /// Starts a flow and creates an initial screen of a flow.
    @MainActor func start()
}

/// Aggregates all module-level coordinating delegates that the app coordinator must handle.
protocol AppCoordinating: FeedsCoordinatingDelegate {}

final class Coordinator {
    // MARK: - Properties
    private let moduleFactory: any ModuleFactoryProtocol
    private(set) weak var navigationController: UINavigationController?

    // MARK: - Init
    init(container: any DIContainerProtocol, controller: UINavigationController?) {
        navigationController = controller

        moduleFactory = ModuleFactory(container: container)
    }
}

// MARK: - Coordinating
extension Coordinator: Coordinating {

    @MainActor func start() {
        let feedsVC = moduleFactory.makeFeedsModule(delegate: self)
        navigationController?.viewControllers = [feedsVC]
    }
}

// MARK: - AppCoordinating
extension Coordinator: AppCoordinating {

    func onNeedToShowFeedDetails(for feed: Feed) {
        let feedItemsVC = moduleFactory.makeFeedItemsModule(for: feed, delegate: self)
        navigationController?.pushViewController(feedItemsVC, animated: true)
    }
}
