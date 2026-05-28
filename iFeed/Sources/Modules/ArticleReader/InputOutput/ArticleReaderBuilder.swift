//
//  ArticleReaderBuilder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

enum ArticleReaderBuilder {

    static func viewController(title: String,
                               htmlContent: String,
                               articleURL: URL?) -> ArticleReaderViewController {
        /// Interactor
        let interactor = ArticleReaderInteractor(
            title: title,
            htmlContent: htmlContent,
            articleURL: articleURL
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
