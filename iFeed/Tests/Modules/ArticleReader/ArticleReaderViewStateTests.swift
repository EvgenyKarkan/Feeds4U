//
//  ArticleReaderViewStateTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 31.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Foundation
@testable import iFeed

struct ArticleReaderViewStateTests {

    // MARK: - Init

    @Test func init_setsAllProperties() {
        // Given
        let url = URL(string: "https://example.com")

        // When
        let sut = ArticleReaderViewState(
            title: "Test",
            fullHTML: "<p>Hello</p>",
            baseURL: url,
            isDarkMode: true,
            hasArticleURL: true
        )

        // Then
        #expect(sut.title == "Test")
        #expect(sut.fullHTML == "<p>Hello</p>")
        #expect(sut.baseURL == url)
        #expect(sut.isDarkMode == true)
        #expect(sut.hasArticleURL == true)
    }

    @Test func init_baseURLDefaultsToNil() {
        // When
        let sut = ArticleReaderViewState(
            title: "Title",
            fullHTML: "<p>Content</p>",
            isDarkMode: false,
            hasArticleURL: false
        )

        // Then
        #expect(sut.baseURL == nil)
    }

    @Test func init_whenDarkModeIsFalse_storesLightMode() {
        // When
        let sut = ArticleReaderViewState(
            title: "Title",
            fullHTML: "<p>Content</p>",
            isDarkMode: false,
            hasArticleURL: true
        )

        // Then
        #expect(sut.isDarkMode == false)
    }

    @Test func init_whenHasArticleURLIsFalse_storesFalse() {
        // When
        let sut = ArticleReaderViewState(
            title: "Title",
            fullHTML: "<p>Content</p>",
            isDarkMode: true,
            hasArticleURL: false
        )

        // Then
        #expect(sut.hasArticleURL == false)
    }
}
