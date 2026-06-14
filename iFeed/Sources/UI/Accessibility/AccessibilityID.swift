//
//  AccessibilityID.swift
//  iFeed
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Stable accessibility identifiers shared between the app and the UI-test target.
///
/// Compiled into both targets so tests and views reference the exact same
/// strings — there is no risk of identifier drift between the two sides.
/// Identifiers are namespaced by module/screen to stay unique across the app.
enum AccessibilityID {

    // MARK: - Feeds list
    static let feedsTable = "feeds.table"
    static let feedsEmptyLabel = "feeds.emptyLabel"
    static let addFeedButton = "feeds.addButton"
    static let trashButton = "feeds.trashButton"
    static let searchButton = "feeds.searchButton"

    // MARK: - Feeds alerts
    static let enterFeedAlert = "feeds.alert.enterFeed"
    static let exploreFeedAlert = "feeds.alert.exploreFeed"
    static let searchInputAlert = "feeds.alert.searchInput"
    static let noSearchResultsAlert = "feeds.alert.noSearchResults"
    static let noFeedsDiscoveredAlert = "feeds.alert.noFeedsDiscovered"
    static let createFolderAlert = "feeds.alert.createFolder"
    static let alertTextField = "feeds.alert.textField"

    // MARK: - Dynamic
    /// Identifier for a feed row, derived from the feed's title.
    static func feedCell(title: String) -> String {
        return "feeds.cell.\(title)"
    }

    /// Identifier for a collapsible folder section header, derived from the folder name.
    static func folderHeader(name: String) -> String {
        return "feeds.folderHeader.\(name)"
    }
}
