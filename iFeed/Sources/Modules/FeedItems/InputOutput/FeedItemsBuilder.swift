//
//  FeedItemsBuilder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit

@MainActor
enum FeedItemsBuilder {

    static func viewController(feed: Feed,
                               container: any FeedItemsDependencies,
                               delegate: any FeedItemsCoordinatingDelegate) -> FeedItemsViewController {
        /// Interactor
        let interactor = FeedItemsInteractor(
            parser: container.parser(),
            storage: container.storage(),
            feed: feed
        )

        /// Wireframe
        let wireframe = FeedItemsWireframe()
        wireframe.delegate = delegate

        /// View
        let viewController = FeedItemsViewController()

        /// Presenter
        let presenter = FeedItemsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: viewController
        )

        viewController.presenter = presenter
        wireframe.viewController = viewController

        return viewController
    }

    static func searchResultsViewController(for query: String,
                                            items: [FeedItem],
                                            container: any FeedItemsDependencies) -> FeedItemsViewController {
        /// Interactor
        let interactor = FeedItemsInteractor(
            parser: container.parser(),
            storage: container.storage(),
            feedItems: items,
            searchTerm: query
        )

        /// Wireframe
        let wireframe = FeedItemsWireframe()

        /// View
        let viewController = FeedItemsViewController()

        /// Presenter
        let presenter = FeedItemsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: viewController
        )

        viewController.presenter = presenter
        wireframe.viewController = viewController

        return viewController
    }
}
