//
//  FeedsBuilder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit

enum FeedsBuilder {

    @MainActor
    static func viewController(container: any FeedsDependencies,
                               delegate: any FeedsCoordinatingDelegate) -> FeedsViewController {
        /// Interactor
        let interactor = FeedsInteractor(
            parser: container.parser(),
            storage: container.storage(),
            localSearchService: container.localSearch(),
            exploreFeedsService: container.exploreService(),
            folderManager: container.foldersManager(),
            keyedStorage: container.keyedStorage()
        )

        /// Wireframe
        let wireframe = FeedsWireframe()
        wireframe.delegate = delegate

        /// View
        let viewController = FeedsViewController()

        /// Presenter
        let presenter = FeedsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: viewController
        )

        viewController.presenter = presenter
        wireframe.viewController = viewController

        return viewController
    }
}
