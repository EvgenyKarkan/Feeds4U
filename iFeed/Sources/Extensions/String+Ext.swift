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
