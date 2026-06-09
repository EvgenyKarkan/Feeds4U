//
//  ArticleReaderInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

@MainActor
final class ArticleReaderInteractor {
    // MARK: - Properties
    let articleTitle: String
    let htmlContent: String
    let articleURL: URL?

    private(set) var isDarkMode: Bool

    // MARK: - Init
    init(title: String,
         htmlContent: String,
         articleURL: URL?) {
        self.articleTitle = title
        self.htmlContent = htmlContent
        self.articleURL = articleURL
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }
}

// MARK: - ArticleReaderInteractorProtocol
extension ArticleReaderInteractor: ArticleReaderInteractorProtocol {

    func toggleDarkMode() {
        isDarkMode.toggle()
    }
}
