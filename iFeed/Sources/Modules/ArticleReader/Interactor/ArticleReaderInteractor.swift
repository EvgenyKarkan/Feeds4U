//
//  ArticleReaderInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

final class ArticleReaderInteractor {

    // MARK: - Properties
    let articleTitle: String
    let htmlContent: String
    let articleURL: URL?
    var isDarkMode: Bool

    private static let readerThemeKey = "ArticleReaderDarkMode"

    // MARK: - Init
    init(title: String, htmlContent: String, articleURL: URL?) {
        self.articleTitle = title
        self.htmlContent = htmlContent
        self.articleURL = articleURL

        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.readerThemeKey) != nil {
            self.isDarkMode = defaults.bool(forKey: Self.readerThemeKey)
        } else {
            self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
}

// MARK: - ArticleReaderInteractorProtocol
extension ArticleReaderInteractor: ArticleReaderInteractorProtocol {

    func persistThemePreference() {
        UserDefaults.standard.set(isDarkMode, forKey: Self.readerThemeKey)
    }
}
