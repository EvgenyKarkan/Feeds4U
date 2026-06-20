//
//  StringExtTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

@Suite("String+Ext Tests")
struct StringExtTests {

    // MARK: - isValidURL

    // MARK: - Accepted web URLs

    @Test func httpsURL_isValid() {
        // Given
        let url = "https://www.example.com/rss"

        // When / Then
        #expect(url.isValidURL)
    }

    @Test func httpURL_isValid() {
        // Given — plain HTTP feeds are common; ATS provides the baseline protection.
        let url = "http://legacy.example.com/rss"

        // When / Then
        #expect(url.isValidURL)
    }

    @Test func schemeLessHost_isValid() {
        // Given — NSDataDetector normalises a bare host to an http URL.
        let url = "www.example.com/rss"

        // When / Then
        #expect(url.isValidURL)
    }

    // MARK: - Rejected non-web schemes

    @Test func javascriptScheme_isInvalid() {
        // Given
        let url = "javascript:alert(1)"

        // When / Then
        #expect(!url.isValidURL)
    }

    @Test func fileScheme_isInvalid() {
        // Given
        let url = "file:///etc/passwd"

        // When / Then
        #expect(!url.isValidURL)
    }

    @Test func dataScheme_isInvalid() {
        // Given
        let url = "data:text/html,<script>alert(1)</script>"

        // When / Then
        #expect(!url.isValidURL)
    }

    @Test func ftpScheme_isInvalid() {
        // Given
        let url = "ftp://files.example.com/feed.xml"

        // When / Then
        #expect(!url.isValidURL)
    }

    // MARK: - Empty / whitespace

    @Test func emptyString_isInvalid() {
        // Given
        let url = ""

        // When / Then
        #expect(!url.isValidURL)
    }

    @Test func whitespaceOnly_isInvalid() {
        // Given
        let url = "   "

        // When / Then
        #expect(!url.isValidURL)
    }

    // MARK: - localized(key:)

    @Test func unknownKey_returnsKeyItself() {
        // Given
        let key = "this.key.does.not.exist.\(UUID().uuidString)"

        // When
        let result = String.localized(key: key)

        // Then
        #expect(result == key)
    }

    @Test func emptyKey_returnsEmptyString() {
        // Given
        let key = ""

        // When
        let result = String.localized(key: key)

        // Then
        #expect(result == "")
    }

    // MARK: - collapsingWhitespace()

    @Test func plainString_unchanged() {
        // Given — fast path: no newlines, tabs, or double spaces.
        let input = "A normal feed title"

        // When
        let result = input.collapsingWhitespace()

        // Then
        #expect(result == "A normal feed title")
    }

    @Test func leadingAndTrailingWhitespace_trimmed() {
        // Given
        let input = "   trimmed me   "

        // When
        let result = input.collapsingWhitespace()

        // Then
        #expect(result == "trimmed me")
    }

    @Test func doubleSpaces_collapsedToSingle() {
        // Given
        let input = "too    many     spaces"

        // When
        let result = input.collapsingWhitespace()

        // Then
        #expect(result == "too many spaces")
    }

    @Test func newlinesAndTabs_collapsedToSingleSpace() {
        // Given
        let input = "line one\n\tline two\r\nline three"

        // When
        let result = input.collapsingWhitespace()

        // Then
        #expect(result == "line one line two line three")
    }

    @Test func emptyString_returnsEmpty() {
        // Given
        let input = ""

        // When
        let result = input.collapsingWhitespace()

        // Then
        #expect(result == "")
    }

    @Test func whitespaceOnly_returnsEmpty() {
        // Given
        let input = " \n\t  \r\n "

        // When
        let result = input.collapsingWhitespace()

        // Then
        #expect(result == "")
    }

    // MARK: - isCloudflareChallengePage

    @Test func keywordPhrase_isDetected() {
        // Given
        let html = "<html><body>Just a moment...</body></html>"

        // When / Then
        #expect(html.isCloudflareChallengePage)
    }

    @Test func keywordIsCaseInsensitive() {
        // Given
        let html = "VERIFY YOU ARE HUMAN by completing the action below."

        // When / Then
        #expect(html.isCloudflareChallengePage)
    }

    @Test func markerToken_isDetected() {
        // Given — markers are matched case-sensitively.
        let html = "<script>window._cf_chl_opt={};</script>"

        // When / Then
        #expect(html.isCloudflareChallengePage)
    }

    @Test func cdnCgiChallengePath_isDetected() {
        // Given
        let html = "<script src=\"/cdn-cgi/challenge-platform/h/g/orchestrate\"></script>"

        // When / Then
        #expect(html.isCloudflareChallengePage)
    }

    @Test func structuralHints_isDetected() {
        // Given — both noindex meta and the JS/cookies notice present.
        let html = """
        <meta name="robots" content="noindex,nofollow">
        <noscript>Enable JavaScript and cookies to continue</noscript>
        """

        // When / Then
        #expect(html.isCloudflareChallengePage)
    }

    @Test func rayIdPattern_isDetected() {
        // Given
        let html = "Ray ID: 8af1c2d3e4f5a6b7"

        // When / Then
        #expect(html.isCloudflareChallengePage)
    }

    @Test func plainHTML_isNotDetected() {
        // Given
        let html = "<html><body><h1>Welcome to my blog</h1></body></html>"

        // When / Then
        #expect(!html.isCloudflareChallengePage)
    }

    @Test func emptyString_isNotDetected() {
        // Given
        let html = ""

        // When / Then
        #expect(!html.isCloudflareChallengePage)
    }
}
