//
//  ExploreFeedsBuilder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit

@MainActor
enum ExploreFeedsBuilder {

    static func viewController(with data: ExploreFeedsDTO,
                               webPage: String,
                               container: any ExploreFeedsDependencies) -> ExploreFeedsResultsViewController {
        /// Interactor
        let interactor = ExploreFeedsInteractor(
            results: data,
            webPage: webPage,
            parser: container.parser(),
            storage: container.storage(),
            localSearchService: container.localSearch()
        )

        /// Wireframe
        let wireframe = ExploreFeedsWireframe()

        /// View
        let nibName = String(describing: ExploreFeedsResultsViewController.self)
        let viewController = ExploreFeedsResultsViewController(nibName: nibName, bundle: nil)

        /// Presenter
        let presenter = ExploreFeedsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: viewController
        )

        viewController.presenter = presenter
        wireframe.viewController = viewController

        return viewController
    }
}
