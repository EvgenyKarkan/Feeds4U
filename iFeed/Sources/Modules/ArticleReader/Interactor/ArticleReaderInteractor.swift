//
//  ArticleReaderInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

private enum Constants {
    static let readerThemeKey = "ArticleReaderDarkMode"
}

final class ArticleReaderInteractor {
    // MARK: - Properties
    let articleTitle: String
    let htmlContent: String
    let articleURL: URL?
    let keyedStorage: any KeyedStorageProtocol

    private(set) var isDarkMode: Bool

    // MARK: - Init
    init(title: String,
         htmlContent: String,
         articleURL: URL?,
         keyedStorage: any KeyedStorageProtocol) {
        self.articleTitle = title
        self.htmlContent = htmlContent
        self.articleURL = articleURL
        self.keyedStorage = keyedStorage

        if keyedStorage.object(forKey: Constants.readerThemeKey) != nil {
            self.isDarkMode = keyedStorage.bool(forKey: Constants.readerThemeKey)
        } else {
            self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
}

// MARK: - ArticleReaderInteractorProtocol
extension ArticleReaderInteractor: ArticleReaderInteractorProtocol {

    func toggleDarkMode() {
        isDarkMode.toggle()
    }

    func persistThemePreference() {
        keyedStorage.set(isDarkMode, forKey: Constants.readerThemeKey)
    }
}
