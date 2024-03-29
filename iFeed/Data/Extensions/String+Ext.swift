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

    static func localized(key: String) -> String {
        return NSLocalizedString(key, comment: String())
    }
}
