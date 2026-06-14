//
//  CoordinatorTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 11.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

@Suite("Coordinator Tests")
@MainActor
struct CoordinatorTests {

    // MARK: - feedURL(fromDeepLink:)

    @Test func feedURLFromDeepLink_stripsSchemeAndSlashes_andPrependsHTTPS() throws {
        // Given — the canonical deep-link shape.
        let url = try #require(URL(string: "feed://www.swift.org/atom.xml"))

        // When / Then — `feed://` is a transport wrapper, the result must be
        // a fetchable absolute URL, not the raw "//www…" resource specifier.
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.swift.org/atom.xml")
    }

    @Test func feedURLFromDeepLink_keepsExplicitHTTPSScheme() throws {
        // Given — `feed://https://…` style links carry their own scheme.
        let url = try #require(URL(string: "feed://https://www.swift.org/atom.xml"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.swift.org/atom.xml")
    }

    @Test func feedURLFromDeepLink_keepsExplicitHTTPScheme() throws {
        // Given — a legacy plain-HTTP feed must not be force-upgraded.
        let url = try #require(URL(string: "feed://http://legacy.example.com/rss"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "http://legacy.example.com/rss")
    }

    @Test func feedURLFromDeepLink_withoutDoubleSlash_normalizesToo() throws {
        // Given — the `feed:host/path` form (no authority slashes).
        let url = try #require(URL(string: "feed:www.example.com/rss"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.example.com/rss")
    }

    @Test func feedURLFromDeepLink_withAppScheme_normalizes() throws {
        // Given — the app's own registered scheme behaves like `feed://`.
        let url = try #require(URL(string: "Feeds4U://www.example.com/rss"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.example.com/rss")
    }

    @Test func feedURLFromDeepLink_withEmptySpecifier_returnsNil() throws {
        // Given — a bare scheme with nothing to extract.
        let url = try #require(URL(string: "feed://"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == nil)
    }
}
