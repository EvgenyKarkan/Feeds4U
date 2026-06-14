//
//  ArticleReaderInteractorTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 31.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import UIKit
@testable import iFeed

@Suite
@MainActor
struct ArticleReaderInteractorTests {

    // MARK: - Constants

    private let testTitle = "Test Article"
    private let testHTML = "<p>Hello</p>"
    private let testURL = URL(string: "https://example.com/article")

    // MARK: - Helpers

    private func makeSUT() -> ArticleReaderInteractor {
        ArticleReaderInteractor(
            title: testTitle,
            htmlContent: testHTML,
            articleURL: testURL
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
}
