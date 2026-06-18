//
//  HTMLPlainTextTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Foundation
@testable import iFeed

@Suite
struct HTMLPlainTextTests {

    // MARK: - Tag stripping

    @Test func extract_removesTags() {
        // Given
        let html = "<p>Hello <strong>world</strong></p>"

        // When
        let text = HTMLPlainText.extract(from: html)

        // Then
        #expect(text == "Hello world")
    }

    @Test func extract_dropsScriptBodies() {
        // Given
        let html = "<p>Visible</p><script>var secret = 1; alert('x');</script>"

        // When
        let text = HTMLPlainText.extract(from: html)

        // Then — script contents must not leak into the prompt.
        #expect(text == "Visible")
    }

    @Test func extract_dropsStyleBodies() {
        // Given
        let html = "<style>p { color: red; }</style><p>Body</p>"

        // When
        let text = HTMLPlainText.extract(from: html)

        // Then
        #expect(text == "Body")
    }

    // MARK: - Whitespace

    @Test func extract_collapsesWhitespace() {
        // Given
        let html = "<p>One</p>\n\n   <p>Two</p>"

        // When
        let text = HTMLPlainText.extract(from: html)

        // Then
        #expect(text == "One Two")
    }

    @Test func extract_trimsEdges() {
        // Given
        let html = "   <p>Trimmed</p>   "

        // When
        let text = HTMLPlainText.extract(from: html)

        // Then
        #expect(text == "Trimmed")
    }

    // MARK: - Entities

    @Test func extract_decodesCommonEntities() {
        // Given
        let html = "<p>Tom &amp; Jerry &lt;3 &quot;quotes&quot;</p>"

        // When
        let text = HTMLPlainText.extract(from: html)

        // Then
        #expect(text == "Tom & Jerry <3 \"quotes\"")
    }

    // MARK: - Truncation

    @Test func extract_truncatesToMaxLength() {
        // Given
        let html = "<p>" + String(repeating: "a", count: 100) + "</p>"

        // When
        let text = HTMLPlainText.extract(from: html, maxLength: 10)

        // Then
        #expect(text.count == 10)
    }

    @Test func extract_doesNotTruncateBelowMaxLength() {
        // Given
        let html = "<p>short</p>"

        // When
        let text = HTMLPlainText.extract(from: html, maxLength: 1000)

        // Then
        #expect(text == "short")
    }

    @Test func extract_clipsHugeInputAndStillHonoursMaxLength() {
        // Given — a document far larger than the raw clip window; the early clip
        // must not break the maxLength contract on the returned text.
        let html = "<p>" + String(repeating: "word ", count: 100_000) + "</p>"

        // When
        let text = HTMLPlainText.extract(from: html, maxLength: 500)

        // Then
        #expect(text.count == 500)
    }

    // MARK: - Edge cases

    @Test func extract_withNoText_returnsEmpty() {
        // Given
        let html = "<div><span></span></div>"

        // When
        let text = HTMLPlainText.extract(from: html)

        // Then
        #expect(text.isEmpty)
    }
}
