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

@Suite("String+Ext isValidURL Tests")
struct StringExtTests {

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
}
