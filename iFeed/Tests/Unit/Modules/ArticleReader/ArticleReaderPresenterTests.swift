//
//  ArticleReaderPresenterTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 31.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Mocking
import Foundation
@testable import iFeed

private enum TestError: Error {
    case boom
}

@Suite
@MainActor
struct ArticleReaderPresenterTests {

    // MARK: - Properties

    private let interactor = ArticleReaderInteractorProtocolMock()
    private let wireframe = ArticleReaderWireframeProtocolMock()
    private let view = ArticleReaderViewProtocolMock()
    private let sut: ArticleReaderPresenter

    // Constants
    private let testTitle = "Test Article"
    private let testHTML = "<p>Hello</p>"
    private let testURL = URL(string: "https://example.com/article")

    // MARK: - Init

    init() {
        interactor._articleTitle.getter.implementation = .returns(testTitle)
        interactor._htmlContent.getter.implementation = .returns(testHTML)
        interactor._articleURL.getter.implementation = .returns(testURL)
        interactor._isDarkMode.getter.implementation = .returns(false)
        interactor._isSummarizationAvailable.getter.implementation = .returns(true)

        sut = ArticleReaderPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: view
        )
    }

    // MARK: - onViewDidLoad

    @Test func onViewDidLoad_configuresViewWithViewState() {
        // When
        sut.onViewDidLoad()

        // Then
        #expect(view._configureInitialState.callCount == 1)
        let viewState = view._configureInitialState.lastInvocation
        #expect(viewState?.title == testTitle)
        #expect(viewState?.baseURL == testURL)
        #expect(viewState?.isDarkMode == false)
        #expect(viewState?.hasArticleURL == true)
        #expect(viewState?.isSummarizationAvailable == true)
    }

    @Test func onViewDidLoad_whenSummarizationUnavailable_setsFlagFalse() {
        // Given
        interactor._isSummarizationAvailable.getter.implementation = .returns(false)

        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._configureInitialState.lastInvocation
        #expect(viewState?.isSummarizationAvailable == false)
    }

    @Test func onViewDidLoad_whenSummarizationAvailable_prewarmsModel() {
        // Given
        interactor._isSummarizationAvailable.getter.implementation = .returns(true)

        // When
        sut.onViewDidLoad()

        // Then — the model is warmed eagerly so the first tap is fast.
        #expect(interactor._prewarmSummarization.callCount == 1)
    }

    @Test func onViewDidLoad_whenSummarizationUnavailable_doesNotPrewarm() {
        // Given
        interactor._isSummarizationAvailable.getter.implementation = .returns(false)

        // When
        sut.onViewDidLoad()

        // Then
        #expect(interactor._prewarmSummarization.callCount == 0)
    }

    @Test func onViewDidLoad_wrapsHTMLInReaderTemplate() {
        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._configureInitialState.lastInvocation
        let expectedHTML = ReaderHTMLTemplate.wrapInReaderTemplate(testHTML, title: testTitle, isDarkMode: false)
        #expect(viewState?.fullHTML == expectedHTML)
    }

    @Test func onViewDidLoad_whenDarkMode_passesCorrectTheme() {
        // Given
        interactor._isDarkMode.getter.implementation = .returns(true)

        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._configureInitialState.lastInvocation
        #expect(viewState?.isDarkMode == true)
    }

    @Test func onViewDidLoad_whenNoArticleURL_setsHasArticleURLToFalse() {
        // Given
        interactor._articleURL.getter.implementation = .returns(nil)

        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._configureInitialState.lastInvocation
        #expect(viewState?.baseURL == nil)
        #expect(viewState?.hasArticleURL == false)
    }

    // MARK: - onViewWillAppear

    @Test func onViewWillAppear_appliesThemeChange() {
        // Given
        interactor._isDarkMode.getter.implementation = .returns(true)

        // When
        sut.onViewWillAppear()

        // Then
        #expect(view._applyThemeChange.callCount == 1)
        #expect(view._applyThemeChange.lastInvocation == true)
    }

    @Test func onViewWillAppear_whenLightMode_appliesLightTheme() {
        // Given
        interactor._isDarkMode.getter.implementation = .returns(false)

        // When
        sut.onViewWillAppear()

        // Then
        #expect(view._applyThemeChange.lastInvocation == false)
    }

    // MARK: - onToggleThemeTapped

    @Test func onToggleThemeTapped_togglesDarkModeOnInteractor() {
        // When
        sut.onToggleThemeTapped()

        // Then
        #expect(interactor._toggleDarkMode.callCount == 1)
    }

    @Test func onToggleThemeTapped_appliesThemeChangeToView() {
        // When
        sut.onToggleThemeTapped()

        // Then
        #expect(view._applyThemeChange.callCount == 1)
    }

    // MARK: - onOpenInSafariTapped

    @Test func onOpenInSafariTapped_whenArticleURLExists_opensInSafari() {
        // Given
        let url = URL(string: "https://example.com/article")
        interactor._articleURL.getter.implementation = .returns(url)

        // When
        sut.onOpenInSafariTapped()

        // Then
        #expect(wireframe._openInSafari.callCount == 1)
        #expect(wireframe._openInSafari.lastInvocation == url)
    }

    @Test func onOpenInSafariTapped_whenNoArticleURL_doesNotOpenSafari() {
        // Given
        interactor._articleURL.getter.implementation = .returns(nil)

        // When
        sut.onOpenInSafariTapped()

        // Then
        #expect(wireframe._openInSafari.callCount == 0)
    }

    // MARK: - onLinkActivated

    @Test func onLinkActivated_opensURLInSafari() throws {
        // Given
        let url = try #require(URL(string: "https://example.com/link"))

        // When
        sut.onLinkActivated(url: url)

        // Then
        #expect(wireframe._openInSafari.callCount == 1)
        #expect(wireframe._openInSafari.lastInvocation == url)
    }

    // MARK: - onSummarizeTapped

    @Test func onSummarizeTapped_streamsSnapshotsAndTogglesLoading() async throws {
        // Given — two growing snapshots, as the model would stream them.
        let first = ArticleSummary(summary: "Over", keyPoints: [])
        let final = ArticleSummary(summary: "Overview", keyPoints: ["x"])
        let stream = AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            continuation.yield(first)
            continuation.yield(final)
            continuation.finish()
        }
        interactor._summarize.implementation = .returns(stream)

        // When
        sut.onSummarizeTapped()
        await sut.summarizationTask?.value

        // Then — the card updates per snapshot; loading is raised then dropped
        // on the first snapshot.
        #expect(interactor._summarize.callCount == 1)
        #expect(view._renderSummary.callCount == 2)
        #expect(view._renderSummary.lastInvocation == final)
        #expect(view._setSummaryLoading.callCount == 2)
        #expect(view._setSummaryLoading.lastInvocation == false)
        #expect(view._showSummaryError.callCount == 0)
    }

    @Test func onSummarizeTapped_coalescesRapidSnapshots() async throws {
        // Given — many snapshots emitted in a burst, far faster than the render
        // throttle interval.
        let snapshotCount = 20
        let final = ArticleSummary(summary: "final overview", keyPoints: ["x"])
        let stream = AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            for index in 0..<(snapshotCount - 1) {
                continuation.yield(ArticleSummary(summary: "partial \(index)", keyPoints: []))
            }
            continuation.yield(final)
            continuation.finish()
        }
        interactor._summarize.implementation = .returns(stream)

        // When
        sut.onSummarizeTapped()
        await sut.summarizationTask?.value

        // Then — the throttle collapses the burst into far fewer renders, yet the
        // final snapshot is always flushed.
        #expect(view._renderSummary.callCount < snapshotCount)
        #expect(view._renderSummary.lastInvocation == final)
        #expect(view._showSummaryError.callCount == 0)
    }

    @Test func onSummarizeTapped_whenStreamFails_showsErrorAndStopsLoading() async throws {
        // Given
        let stream = AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            continuation.finish(throwing: SummarizationError.generationFailed(underlying: TestError.boom))
        }
        interactor._summarize.implementation = .returns(stream)

        // When
        sut.onSummarizeTapped()
        await sut.summarizationTask?.value

        // Then
        #expect(view._showSummaryError.callCount == 1)
        #expect(view._renderSummary.callCount == 0)
        #expect(view._setSummaryLoading.lastInvocation == false)
    }

    @Test func onSummarizeTapped_whenStreamEmpty_showsError() async throws {
        // Given — a stream that finishes without ever yielding.
        let stream = AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            continuation.finish()
        }
        interactor._summarize.implementation = .returns(stream)

        // When
        sut.onSummarizeTapped()
        await sut.summarizationTask?.value

        // Then
        #expect(view._renderSummary.callCount == 0)
        #expect(view._showSummaryError.callCount == 1)
        #expect(view._setSummaryLoading.lastInvocation == false)
    }

    @Test func onSummarizeTapped_whileInFlight_ignoresSecondTap() async throws {
        // Given — a slow stream so the second tap lands mid-flight.
        let stream = AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            Task {
                try? await Task.sleep(for: .milliseconds(80))
                continuation.yield(ArticleSummary(summary: "Overview", keyPoints: []))
                continuation.finish()
            }
        }
        interactor._summarize.implementation = .returns(stream)

        // When
        sut.onSummarizeTapped()
        sut.onSummarizeTapped()
        await sut.summarizationTask?.value

        // Then — the re-entrancy guard collapses the duplicate request.
        #expect(interactor._summarize.callCount == 1)
    }
}
