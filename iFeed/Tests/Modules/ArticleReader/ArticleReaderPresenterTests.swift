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

@Suite(.serialized)
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
    }

    @Test func onViewDidLoad_wrapsHTMLInReaderTemplate() {
        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._configureInitialState.lastInvocation
        let expectedHTML = ReaderHTMLTemplate.wrapInReaderTemplate(testHTML, isDarkMode: false)
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

    @Test func onToggleThemeTapped_persistsThemePreference() {
        // When
        sut.onToggleThemeTapped()

        // Then
        #expect(interactor._persistThemePreference.callCount == 1)
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
}
