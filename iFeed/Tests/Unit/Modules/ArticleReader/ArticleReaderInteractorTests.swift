//
//  ArticleReaderInteractorTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 31.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Mocking
import UIKit
@testable import iFeed

@Suite
@MainActor
struct ArticleReaderInteractorTests {

    // MARK: - Constants

    private let testTitle = "Test Article"
    private let testHTML = "<p>Hello</p>"
    private let testURL = URL(string: "https://example.com/article")

    // MARK: - Mocks

    private let summarizer = SummarizationServiceProtocolMock()

    // MARK: - Helpers

    private func makeSUT() -> ArticleReaderInteractor {
        ArticleReaderInteractor(
            title: testTitle,
            htmlContent: testHTML,
            articleURL: testURL,
            summarizer: summarizer
        )
    }

    // MARK: - Init properties

    @Test func init_setsArticleTitle() {
        // Given
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.articleTitle == testTitle)
    }

    @Test func init_setsHtmlContent() {
        // Given
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.htmlContent == testHTML)
    }

    @Test func init_setsArticleURL() {
        // Given
        // When
        let sut = makeSUT()

        // Then
        #expect(sut.articleURL == testURL)
    }

    @Test func init_defaultsToSystemAppearance() {
        // Given
        let expectedDark = UITraitCollection.current.userInterfaceStyle == .dark

        // When
        let sut = makeSUT()

        // Then
        #expect(sut.isDarkMode == expectedDark)
    }

    // MARK: - toggleDarkMode

    @Test func toggleDarkMode_togglesValue() {
        // Given
        let sut = makeSUT()
        let initial = sut.isDarkMode

        // When
        sut.toggleDarkMode()

        // Then
        #expect(sut.isDarkMode == !initial)
    }

    @Test func toggleDarkMode_twiceRestoresOriginal() {
        // Given
        let sut = makeSUT()
        let initial = sut.isDarkMode

        // When
        sut.toggleDarkMode()
        sut.toggleDarkMode()

        // Then
        #expect(sut.isDarkMode == initial)
    }

    // MARK: - isSummarizationAvailable

    @Test func isSummarizationAvailable_whenServiceAvailable_isTrue() {
        // Given
        summarizer._isAvailable.getter.implementation = .returns(true)
        let sut = makeSUT()

        // When / Then
        #expect(sut.isSummarizationAvailable == true)
    }

    @Test func isSummarizationAvailable_whenServiceUnavailable_isFalse() {
        // Given
        summarizer._isAvailable.getter.implementation = .returns(false)
        let sut = makeSUT()

        // When / Then
        #expect(sut.isSummarizationAvailable == false)
    }

    // MARK: - prewarmSummarization

    @Test func prewarmSummarization_forwardsToService() {
        // Given
        let sut = makeSUT()

        // When
        sut.prewarmSummarization()

        // Then
        #expect(summarizer._prewarm.callCount == 1)
    }

    // MARK: - summarize

    @Test func summarize_streamsServiceSnapshotsForTitleAndHTML() async throws {
        // Given
        let expected = ArticleSummary(summary: "Overview", keyPoints: ["a", "b"])
        let stream = AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            continuation.yield(expected)
            continuation.finish()
        }
        summarizer._summarize.implementation = .returns(stream)
        let sut = makeSUT()

        // When
        var snapshots: [ArticleSummary] = []
        for try await snapshot in sut.summarize() {
            snapshots.append(snapshot)
        }

        // Then
        #expect(snapshots == [expected])
        #expect(summarizer._summarize.callCount == 1)
        #expect(summarizer._summarize.lastInvocation?.0 == testTitle)
        #expect(summarizer._summarize.lastInvocation?.1 == testHTML)
    }

    @Test func summarize_whenServiceStreamFails_propagatesError() async {
        // Given
        let stream = AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            continuation.finish(throwing: SummarizationError.unavailable)
        }
        summarizer._summarize.implementation = .returns(stream)
        let sut = makeSUT()

        // When / Then
        await #expect(throws: SummarizationError.unavailable) {
            for try await _ in sut.summarize() {}
        }
    }
}
