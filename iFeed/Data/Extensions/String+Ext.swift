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
    static let addNewFeed = "addNewFeed"
    static let addNewFeedLite = "addNewFeed.lite"
    static let cancel = "cancel"
    static let confirmation = "confirmation"
    static let enterNewFeed = "enterNewFeed"
    static let exploreFeed = "exploreFeed"
    static let provideURL = "provideURL"

    static let search = "search"
    static let searchDescription = "search.description"
    static let searchPlaceholder = "search.placeholder"

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

    static func localized(key: String) -> String {
        return NSLocalizedString(key, comment: String())
    }
}
