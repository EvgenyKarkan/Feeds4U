//
//  ArticleReaderProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
#if DEBUG
import Mocking
#endif

/// Presenter ---> Wireframe
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ArticleReaderWireframeProtocol: AnyObject {
    func openInSafari(url: URL)
}

/// Presenter ---> Interactor
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ArticleReaderInteractorProtocol: AnyObject {
    var articleTitle: String { get }
    var htmlContent: String { get }
    var articleURL: URL? { get }
    var isDarkMode: Bool { get }
    /// `true` when on-device summarization can run; drives whether the View
    /// offers the TL;DR action.
    var isSummarizationAvailable: Bool { get }
    func toggleDarkMode()
    /// Warms the summarization model so the first request avoids cold-start cost.
    func prewarmSummarization()
    /// Streams growing snapshots of the article summary as the model generates it.
    func summarize() -> AsyncThrowingStream<ArticleSummary, any Error>
}

/// Presenter ---> View
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ArticleReaderViewProtocol: AnyObject {
    func configureInitialState(with viewState: ArticleReaderViewState)
    func applyThemeChange(isDarkMode: Bool)
    /// Toggles the loading affordance shown before the first summary tokens arrive.
    func setSummaryLoading(_ isLoading: Bool)
    /// Inserts or updates the summary card in place. Called repeatedly with
    /// growing snapshots as the model streams its output.
    func renderSummary(_ summary: ArticleSummary)
    /// Surfaces a non-fatal failure when summarization could not complete.
    func showSummaryError()
}

/// View ---> Presenter
@MainActor
protocol ArticleReaderViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewWillAppear()
    func onToggleThemeTapped()
    func onOpenInSafariTapped()
    func onLinkActivated(url: URL)
    func onSummarizeTapped()
}
