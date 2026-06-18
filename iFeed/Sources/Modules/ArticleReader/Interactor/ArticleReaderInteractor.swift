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

    private let summarizer: any SummarizationServiceProtocol

    // MARK: - Init
    init(title: String,
         htmlContent: String,
         articleURL: URL?,
         summarizer: any SummarizationServiceProtocol) {
        self.articleTitle = title
        self.htmlContent = htmlContent
        self.articleURL = articleURL
        self.summarizer = summarizer
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }
}

// MARK: - ArticleReaderInteractorProtocol
extension ArticleReaderInteractor: ArticleReaderInteractorProtocol {

    var isSummarizationAvailable: Bool {
        summarizer.isAvailable
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
    }

    func prewarmSummarization() {
        summarizer.prewarm()
    }

    func summarize() -> AsyncThrowingStream<ArticleSummary, any Error> {
        summarizer.summarize(title: articleTitle, htmlContent: htmlContent)
    }
}
