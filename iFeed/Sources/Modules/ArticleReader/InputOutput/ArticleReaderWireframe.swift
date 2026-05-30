//
//  ArticleReaderWireframe.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

final class ArticleReaderWireframe {

    // MARK: - Properties
    weak var viewController: ArticleReaderViewController?
}

// MARK: - ArticleReaderWireframeProtocol
extension ArticleReaderWireframe: @MainActor ArticleReaderWireframeProtocol {

    @MainActor func openInSafari(url: URL) {
        UIApplication.shared.open(url)
    }
}
