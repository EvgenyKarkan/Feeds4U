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
///
protocol Coordinating: AnyObject {
    /// Starts a flow and creates an initial screen of a flow.
    ///
    /// - Parameters:
    ///  - onFinished: A closure can notify a sender about flow completion.
    @MainActor func start(onFinished: (() -> Void)?)
}

extension Coordinating {

    @MainActor func start() {
        start(onFinished: nil)
    }
}

protocol AppCoordinating {
    func makeFeedsViewController() -> UIViewController
}

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

// MARK: - AppCoordinating
extension Coordinator: AppCoordinating {

    func makeFeedsViewController() -> UIViewController {
        return moduleFactory.makeFeedsModule()
    }
}
