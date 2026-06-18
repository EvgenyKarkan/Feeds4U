//
//  ArticleReaderViewState.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

struct ArticleReaderViewState {
    // MARK: - Properties
    let title: String
    let fullHTML: String
    let baseURL: URL?
    let isDarkMode: Bool
    let hasArticleURL: Bool
    let isSummarizationAvailable: Bool

    // MARK: - Init
    init(title: String, fullHTML: String, baseURL: URL? = nil, isDarkMode: Bool,
         hasArticleURL: Bool, isSummarizationAvailable: Bool) {
        self.title = title
        self.fullHTML = fullHTML
        self.baseURL = baseURL
        self.isDarkMode = isDarkMode
        self.hasArticleURL = hasArticleURL
        self.isSummarizationAvailable = isSummarizationAvailable
    }
}
