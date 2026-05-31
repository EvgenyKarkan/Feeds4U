//
//  ArticleReaderBuilder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

@MainActor
enum ArticleReaderBuilder {

    static func viewController(title: String,
                               htmlContent: String,
                               articleURL: URL?,
                               container: any ArticleReaderDependencies) -> ArticleReaderViewController {
        /// Interactor
        let interactor = ArticleReaderInteractor(
            title: title,
            htmlContent: htmlContent,
            articleURL: articleURL,
            keyedStorage: container.keyedStorage()
        )

        /// Wireframe
        let wireframe = ArticleReaderWireframe()

        /// View
        let viewController = ArticleReaderViewController()

        /// Presenter
        let presenter = ArticleReaderPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: viewController
        )

        viewController.presenter = presenter
        wireframe.viewController = viewController

        return viewController
    }
}
