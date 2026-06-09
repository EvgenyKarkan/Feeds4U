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

    // MARK: - Properties

    private let keyedStorage = KeyedStorageProtocolMock()

    // Constants
    private let testTitle = "Test Article"
    private let testHTML = "<p>Hello</p>"
    private let testURL = URL(string: "https://example.com/article")
    private let themeKey = "ArticleReaderDarkMode"

    // MARK: - Helpers

    private func makeSUT() -> ArticleReaderInteractor {
        ArticleReaderInteractor(
            title: testTitle,
            htmlContent: testHTML,
            articleURL: testURL,
            keyedStorage: keyedStorage
        )
    }

    // MARK: - Init properties

    @Test func init_setsArticleTitle() {
        // Given
        keyedStorage._object.implementation = .returns(nil)

        // When
        let sut = makeSUT()

        // Then
        #expect(sut.articleTitle == testTitle)
    }

    @Test func init_setsHtmlContent() {
        // Given
        keyedStorage._object.implementation = .returns(nil)

        // When
        let sut = makeSUT()

        // Then
        #expect(sut.htmlContent == testHTML)
    }

    @Test func init_setsArticleURL() {
        // Given
        keyedStorage._object.implementation = .returns(nil)

        // When
        let sut = makeSUT()

        // Then
        #expect(sut.articleURL == testURL)
    }

    // MARK: - Init theme

    @Test func init_whenSavedThemeIsDark_setsDarkMode() {
        // Given
        keyedStorage._object.implementation = .returns(true)
        keyedStorage._bool.implementation = .returns(true)

        // When
        let sut = makeSUT()

        // Then
        #expect(sut.isDarkMode == true)
        #expect(keyedStorage._object.callCount == 1)
        #expect(keyedStorage._object.lastInvocation == themeKey)
        #expect(keyedStorage._bool.callCount == 1)
        #expect(keyedStorage._bool.lastInvocation == themeKey)
    }

    @Test func init_whenSavedThemeIsLight_setsLightMode() {
        // Given
        keyedStorage._object.implementation = .returns(false)
        keyedStorage._bool.implementation = .returns(false)

        // When
        let sut = makeSUT()

        // Then
        #expect(sut.isDarkMode == false)
        #expect(keyedStorage._object.callCount == 1)
        #expect(keyedStorage._object.lastInvocation == themeKey)
        #expect(keyedStorage._bool.callCount == 1)
        #expect(keyedStorage._bool.lastInvocation == themeKey)
    }

    @Test func init_whenNoSavedTheme_doesNotQueryBool() {
        // Given
        keyedStorage._object.implementation = .returns(nil)

        // When
        _ = makeSUT()

        // Then
        #expect(keyedStorage._object.callCount == 1)
        #expect(keyedStorage._object.lastInvocation == themeKey)
        #expect(keyedStorage._bool.callCount == 0)
    }

    // MARK: - toggleDarkMode

    @Test func toggleDarkMode_fromLightToDark() {
        // Given
        keyedStorage._object.implementation = .returns(false)
        keyedStorage._bool.implementation = .returns(false)
        let sut = makeSUT()

        // When
        sut.toggleDarkMode()

        // Then
        #expect(sut.isDarkMode == true)
    }

    @Test func toggleDarkMode_fromDarkToLight() {
        // Given
        keyedStorage._object.implementation = .returns(true)
        keyedStorage._bool.implementation = .returns(true)
        let sut = makeSUT()

        // When
        sut.toggleDarkMode()

        // Then
        #expect(sut.isDarkMode == false)
    }

    // MARK: - persistThemePreference

    @Test func persistThemePreference_savesCurrentThemeToStorage() {
        // Given
        keyedStorage._object.implementation = .returns(true)
        keyedStorage._bool.implementation = .returns(true)
        let sut = makeSUT()

        // When
        sut.persistThemePreference()

        // Then
        #expect(keyedStorage._setBool.callCount == 1)
        #expect(keyedStorage._setBool.lastInvocation?.0 == true)
        #expect(keyedStorage._setBool.lastInvocation?.1 == themeKey)
    }

    @Test func persistThemePreference_afterToggle_savesUpdatedTheme() {
        // Given
        keyedStorage._object.implementation = .returns(true)
        keyedStorage._bool.implementation = .returns(true)
        let sut = makeSUT()
        sut.toggleDarkMode()

        // When
        sut.persistThemePreference()

        // Then
        #expect(keyedStorage._setBool.callCount == 1)
        #expect(keyedStorage._setBool.lastInvocation?.0 == false)
        #expect(keyedStorage._setBool.lastInvocation?.1 == themeKey)
    }
}
