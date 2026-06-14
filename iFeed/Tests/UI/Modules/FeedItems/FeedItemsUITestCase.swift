//
//  FeedItemsUITestCase.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Base for the FeedItems module UI tests.
///
/// Reuses the Feeds harness (seeded in-memory store, English locale, shared
/// `AccessibilityID` accessors) and adds navigation into the items list plus
/// FeedItems / ArticleReader element accessors. Item rows reuse `FeedCell`, so
/// they are located with the same `feedCell(_:)` helper as feeds.
@MainActor
class FeedItemsUITestCase: FeedsUITestCase {

    /// English menu titles specific to FeedItems (mirror `Localizable.xcstrings`).
    enum ItemLabels {
        static let markAllAsRead = "Mark All As Read"
    }

    /// Seeded feed opened by the tests and the titles of its items.
    /// Must match the `populated` fixture in `Seeder`.
    let feedTitle = "Swift Blog"
    let itemTitles = ["Swift 6 concurrency", "Embedded Swift", "Swift on Server"]

    var markAllAsReadButton: XCUIElement { app.buttons[AccessibilityID.markAllAsReadButton] }
    var articleReader: XCUIElement { app.webViews[AccessibilityID.articleReaderWebView] }
    var backButton: XCUIElement { app.navigationBars.buttons.element(boundBy: 0) }

    /// Launches the populated scenario and opens the seeded feed's items list.
    func openFeedItems(file: StaticString = #filePath, line: UInt = #line) {
        launch(scenario: .populated)

        let feed = feedCell(feedTitle)
        assertExists(feed, "Seeded feed should be present", file: file, line: line)
        feed.tap()

        // On the FeedItems screen the Feeds-only add button is gone and the
        // feed's items are shown.
        assertGone(addButton, "Should navigate into the feed's items", file: file, line: line)
        assertExists(feedCell(itemTitles[0]), "Feed items should render", file: file, line: line)
    }
}
