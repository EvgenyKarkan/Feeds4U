//
//  String+Ext.swift
//  iFeed
//
//  Created by Evgeny Karkan on 27.03.2024.
//  Copyright © 2024 Evgeny Karkan. All rights reserved.
//

import Foundation

enum LocalizableKeys {
    static let add = "add"
    static let cancel = "cancel"
    static let confirmation = "confirmation"
    static let provideURL = "provideURL"

    enum Feed {
        static let addNew = "addNewFeed"
        static let addNewLite = "addNewFeed.lite"
        static let enterNew = "enterNewFeed"
        static let explore = "exploreFeed"
    }

    enum Search {
        static let search = "search"
        static let description = "search.description"
        static let placeholder = "search.placeholder"
    }

    enum Errors {
        static let error = "error"
        static let dataDecoding = "error.dataDecoding"
        static let generic = "error.generic"
        static let invalidURL = "error.invalidURL"
        static let noSearchResults = "error.noSearchResults"
        static let preExistedFeed = "error.preExistedFeed"
        static let service = "error.service"
        static let unreadableFeed = "error.unreadableFeed"
    }
}

extension String {

    /// Returns the localized string for the given key from the main bundle's `Localizable.xcstrings`.
    /// - Parameter key: The key used to look up the localized string.
    /// - Returns: The localized string, or `key` itself if no localization is found.
    static func localized(key: String) -> String {
        return NSLocalizedString(key, comment: String())
    }

    /// Collapses runs of whitespace/newlines into a single space and trims edges.
    /// Single-pass via regex — avoids intermediate array allocations.
    func collapsingWhitespace() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static let linkDetector: NSDataDetector? = {
        return try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    /// Whether the string contains a valid URL, as determined by `NSDataDetector` link checking.
    /// Returns `false` for empty or whitespace-only strings.
    var isValidURL: Bool {
        guard !isEmpty, !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        guard let detector = Self.linkDetector else {
            return false
        }

        let matches = detector.matches(
            in: self,
            options: [],
            range: NSRange(location: .zero, length: utf16.count)
        )
        return !matches.isEmpty
    }
}

extension String {

    /// Detects Cloudflare anti-bot / challenge pages
    var isCloudflareChallengePage: Bool {

        let lowercased = self.lowercased()

        // 1. Common Cloudflare challenge phrases
        let cloudflareKeywords = [
            "just a moment",
            "checking your browser",
            "verify you are human",
            "enable javascript and cookies",
            "cf-challenge",
            "cloudflare",
            "attention required",
            "ray id",
            "ddos protection by cloudflare",
            "challenge-platform"
        ]

        let keywordMatch = cloudflareKeywords.contains { lowercased.contains($0) }

        // 2. Cloudflare-specific HTML/JS markers
        let cloudflareMarkers = [
            "cf_chl_opt",
            "cRay",
            "cZone",
            "/cdn-cgi/challenge-platform/",
            "window._cf_chl_opt",
            "challenge-platform/h/g/orchestrate",
            "cf-browser-verification"
        ]

        let markerMatch = cloudflareMarkers.contains { self.contains($0) }

        // 3. Meta / structural indicators
        let structuralHints =
            self.contains("content=\"noindex,nofollow\"") &&
            self.contains("Enable JavaScript and cookies")

        // 4. Ray ID pattern (very common in Cloudflare pages)
        let rayIdMatch = self.range(
            of: #"(?i)ray id:\s*[a-f0-9]{16,}"#,
            options: .regularExpression
        ) != nil

        return keywordMatch || markerMatch || structuralHints || rayIdMatch
    }
}
