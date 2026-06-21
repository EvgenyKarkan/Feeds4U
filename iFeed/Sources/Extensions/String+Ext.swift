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
    static let markAllAsRead = "markAllAsRead"
    static let confirmation = "confirmation"
    static let provideURL = "provideURL"

    enum Feed {
        static let addNew = "addNewFeed"
        static let addNewLite = "addNewFeed.lite"
        static let enterNew = "enterNewFeed"
        static let explore = "exploreFeed"
        static let importOPML = "importOPML"
    }

    enum Import {
        static let title = "import.title"
        static let summaryFormat = "import.summary"
        static let noFeeds = "import.noFeeds"
        static let fileUnreadable = "import.fileUnreadable"
    }

    enum Search {
        static let search = "search"
        static let description = "search.description"
        static let placeholder = "search.placeholder"
        static let newSearch = "New search"
        static let recentSearches = "Recent searches"
        static let clearRecent = "Clear recent searches"
    }

    enum Cloudflare {
        static let verifyHuman = "cloudflare.verifyHuman"
    }

    enum Errors {
        static let error = "error"
        static let cloudflareBlocked = "error.cloudflareBlocked"
        static let dataDecoding = "error.dataDecoding"
        static let feedCreationFailed = "error.feedCreationFailed"
        static let generic = "error.generic"
        static let invalidURL = "error.invalidURL"
        static let noFeedsDiscovered = "error.noFeedsDiscovered"
        static let noSearchResults = "error.noSearchResults"
        static let preExistedFeed = "error.preExistedFeed"
        static let service = "error.service"
        static let unreadableFeed = "error.unreadableFeed"
    }

    enum Folder {
        static let createTitle = "Create Folder"
        static let createMessage = "Enter a name for the new folder"
        static let namePlaceholder = "Folder name"
        static let create = "Create"
    }

    enum Accessibility {
        static let refresh = "Refresh"
        static let unread = "Unread"
        static let expanded = "Expanded"
        static let collapsed = "Collapsed"
        static let readingTheme = "Reading theme"
        static let openInSafari = "Open in Safari"
        static let summarize = "Summarize article"
        static let added = "Added"
    }

    enum ArticleReader {
        static let summaryTitle = "Summary"
        static let summarizing = "Summarizing…"
        static let keyPointsTitle = "Key points"
        static let summaryFailedTitle = "Summary unavailable"
        static let summaryFailedMessage = "The summary could not be generated. Please try again."
    }
}

extension String {

    /// Returns the localized string for the given key from the main bundle's `Localizable.xcstrings`.
    /// - Parameter key: The key used to look up the localized string.
    /// - Returns: The localized string, or `key` itself if no localization is found.
    static func localized(key: String) -> String {
        return NSLocalizedString(key, comment: String())
    }

    /// Cached pattern for ``collapsingWhitespace()``.
    ///
    /// `replacingOccurrences(options: .regularExpression)` compiles the pattern
    /// on every call — too expensive for a method that runs per cell during
    /// scrolling, so the compiled regex is created once and reused.
    private static let whitespaceRunRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: "\\s+")
    }()

    /// Whitespace characters other than a plain space — their presence (or a
    /// double space) is the only thing that makes collapsing necessary.
    private static let nonSpaceWhitespace = CharacterSet.whitespacesAndNewlines
        .subtracting(CharacterSet(charactersIn: " "))

    /// Collapses runs of whitespace/newlines into a single space and trims edges.
    ///
    /// Fast path: the vast majority of feed titles contain no newlines, tabs,
    /// or double spaces — those return after trimming without touching the
    /// regex at all, keeping cell configuration cheap during scrolling.
    func collapsingWhitespace() -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        let needsCollapsing = trimmed.contains("  ")
            || trimmed.rangeOfCharacter(from: Self.nonSpaceWhitespace) != nil
        guard needsCollapsing, let regex = Self.whitespaceRunRegex else {
            return trimmed
        }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return regex.stringByReplacingMatches(in: trimmed, range: range, withTemplate: " ")
    }

    private static let linkDetector: NSDataDetector? = {
        return try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    /// Whether the string is a valid **web** URL, as determined by `NSDataDetector`
    /// link checking, restricted to the `http`/`https` schemes.
    ///
    /// Returns `false` for empty or whitespace-only strings, and for links that
    /// resolve to any non-web scheme (`javascript:`, `file:`, `data:`, `ftp:`, …).
    /// `NSDataDetector` normalises a bare host such as `www.example.com` to an
    /// `http` URL, so scheme-less input that names a real host still passes.
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
        guard let scheme = matches.first?.url?.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
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
