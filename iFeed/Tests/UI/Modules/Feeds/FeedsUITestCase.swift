//
//  FeedsUITestCase.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Shared base for the Feeds module UI tests.
///
/// Launches the app on a seeded **in-memory** store (see `UITestSupport` /
/// `Seeder` in the app target) selected by a named scenario, forces English so
/// system button titles are deterministic, and exposes typed element accessors
/// keyed off the shared `AccessibilityID` constants.
@MainActor
class FeedsUITestCase: XCTestCase {

    var app: XCUIApplication = XCUIApplication()

    /// English button/menu titles the app renders. Centralised so a copy change
    /// only needs updating once. Values mirror `Localizable.xcstrings` (en).
    enum Labels {
        static let add = "Add"
        static let cancel = "Cancel"
        static let confirmation = "OK"
        static let search = "Search"
        static let create = "Create"
        static let delete = "Delete"
        static let enterNewFeedMenu = "Enter a new feed"
        static let exploreFeedsMenu = "Explore feeds"
        static let enterFeedMessage = "Enter a new feed"
        static let exploreMessage = "Provide a webpage URL to search for its feeds"
        static let searchDescription = "Search works best when you enter more than one word."
        static let newFolderMessage = "Enter a name for the new folder"
        static let noSearchResults = "There aren't any results that match your search"
        static let newSearch = "New search"
        static let clearRecent = "Clear recent searches"
    }

    override func setUp() async throws {
        try await super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Launches the app into the given seeded scenario in a forced English locale.
    func launch(scenario: UITestScenario) {
        app.launchArguments = [
            "-uiTesting",
            "-uiScenario", scenario.rawValue,
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
    }

    // MARK: - Elements
    var feedsTable: XCUIElement { app.tables[AccessibilityID.feedsTable] }
    var emptyLabel: XCUIElement { app.staticTexts[AccessibilityID.feedsEmptyLabel] }
    var addButton: XCUIElement { app.buttons[AccessibilityID.addFeedButton] }
    var trashButton: XCUIElement { app.buttons[AccessibilityID.trashButton] }
    var searchButton: XCUIElement { app.buttons[AccessibilityID.searchButton] }
    var alertTextField: XCUIElement { app.textFields[AccessibilityID.alertTextField] }

    func feedCell(_ title: String) -> XCUIElement {
        return app.cells[AccessibilityID.feedCell(title: title)]
    }

    func folderHeader(_ name: String) -> XCUIElement {
        return app.otherElements[AccessibilityID.folderHeader(name: name)]
    }

    // MARK: - Helpers

    /// Taps an item in a `UIMenu` / `UIButton.menu`, which XCUI surfaces either
    /// as a menu item or a plain button depending on the OS build.
    func tapMenuItem(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let menuItem = app.menuItems[label]
        if menuItem.waitForExistence(timeout: 2) {
            menuItem.tap()
            return
        }
        let button = app.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 2),
                      "Menu item '\(label)' did not appear", file: file, line: line)
        button.tap()
    }

    func assertExists(_ element: XCUIElement, _ message: String = "",
                      timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message, file: file, line: line)
    }

    func assertGone(_ element: XCUIElement, _ message: String = "",
                    timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForNonExistence(timeout: timeout), message, file: file, line: line)
    }
}
