//
//  ArticleReaderViewState.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

struct ArticleReaderViewState {
    let title: String
    let fullHTML: String
    let baseURL: URL?
    let isDarkMode: Bool
    let hasArticleURL: Bool
}
