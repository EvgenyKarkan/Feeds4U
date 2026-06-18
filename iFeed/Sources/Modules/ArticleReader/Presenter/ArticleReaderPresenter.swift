//
//  ArticleReaderPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import os

@MainActor
final class ArticleReaderPresenter {
    // MARK: - Properties
    private let interactor: any ArticleReaderInteractorProtocol
    private let wireframe: any ArticleReaderWireframeProtocol
    private weak var view: (any ArticleReaderViewProtocol)?

    /// Minimum gap between streamed summary renders. Caps how often the card is
    /// rebuilt while the model streams, so per-token snapshots don't flood the
    /// web view.
    private static let minRenderInterval: Duration = .milliseconds(120)

    /// Guards against overlapping summarization requests: a second tap while a
    /// summary is still generating is ignored rather than spawning a parallel run.
    private var isSummarizing = false

    /// The in-flight summarization Task. Exposed so tests can deterministically
    /// await completion instead of polling, and `nil` when none is running.
    private(set) var summarizationTask: Task<Void, Never>?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "iFeed",
                                category: "ArticleReader.Summarization")

    // MARK: - Init
    init(interactor: any ArticleReaderInteractorProtocol,
         wireframe: any ArticleReaderWireframeProtocol,
         view: any ArticleReaderViewProtocol) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.view = view
    }
}

// MARK: - ArticleReaderViewDelegate
extension ArticleReaderPresenter: ArticleReaderViewDelegate {

    func onViewDidLoad() {
        let fullHTML = ReaderHTMLTemplate.wrapInReaderTemplate(
            interactor.htmlContent,
            title: interactor.articleTitle,
            isDarkMode: interactor.isDarkMode
        )

        let viewState = ArticleReaderViewState(
            title: interactor.articleTitle,
            fullHTML: fullHTML,
            baseURL: interactor.articleURL,
            isDarkMode: interactor.isDarkMode,
            hasArticleURL: interactor.articleURL != nil,
            isSummarizationAvailable: interactor.isSummarizationAvailable
        )

        view?.configureInitialState(with: viewState)

        // Warm the model now so the first tap skips the cold-start cost.
        if interactor.isSummarizationAvailable {
            interactor.prewarmSummarization()
        }
    }

    func onViewWillAppear() {
        view?.applyThemeChange(isDarkMode: interactor.isDarkMode)
    }

    func onToggleThemeTapped() {
        interactor.toggleDarkMode()
        view?.applyThemeChange(isDarkMode: interactor.isDarkMode)
    }

    func onOpenInSafariTapped() {
        guard let url = interactor.articleURL else {
            return
        }
        wireframe.openInSafari(url: url)
    }

    func onLinkActivated(url: URL) {
        wireframe.openInSafari(url: url)
    }

    func onSummarizeTapped() {
        guard !isSummarizing else {
            return
        }
        isSummarizing = true
        view?.setSummaryLoading(true)

        summarizationTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                self.isSummarizing = false
                self.summarizationTask = nil
            }

            var didRenderFirstSnapshot = false
            var lastRenderedAt = ContinuousClock.now
            var pendingSnapshot: ArticleSummary?
            do {
                for try await snapshot in self.interactor.summarize() {
                    // Render the first snapshot immediately for perceived speed, then
                    // coalesce the rest: the model emits many small snapshots per
                    // second and pushing every one through the JS bridge / a DOM
                    // rebuild would flood the main thread. Throttling to one render
                    // per interval keeps it smooth; the trailing snapshot is always
                    // flushed after the loop so the final text is never dropped.
                    if !didRenderFirstSnapshot {
                        didRenderFirstSnapshot = true
                        self.view?.setSummaryLoading(false)
                        self.view?.renderSummary(snapshot)
                        lastRenderedAt = .now
                        pendingSnapshot = nil
                        continue
                    }

                    let now = ContinuousClock.now
                    if now - lastRenderedAt >= Self.minRenderInterval {
                        self.view?.renderSummary(snapshot)
                        lastRenderedAt = now
                        pendingSnapshot = nil
                    } else {
                        pendingSnapshot = snapshot
                    }
                }

                // Flush the final snapshot if it was throttled.
                if let pendingSnapshot {
                    self.view?.renderSummary(pendingSnapshot)
                }

                // A stream that produced nothing still has to clear the spinner.
                if !didRenderFirstSnapshot {
                    self.view?.setSummaryLoading(false)
                    self.view?.showSummaryError()
                }
            } catch {
                self.logger.error("Article summarization failed: \(String(describing: error), privacy: .public)")
                self.view?.setSummaryLoading(false)
                self.view?.showSummaryError()
            }
        }
    }
}
