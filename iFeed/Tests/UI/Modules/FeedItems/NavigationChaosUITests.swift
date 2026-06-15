//
//  NavigationChaosUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Chaos coverage for re-entrant navigation: a "double-trigger" of a row that
/// pushes a screen. Oracle: after entering a pushed screen exactly once, a single
/// Back must land on the previous screen. If the tap double-pushed, one Back
/// leaves a duplicate copy on the stack and the previous screen is NOT reached.
final class NavigationChaosUITests: FeedItemsUITestCase {

    func testChaos_doubleTapFeed_doesNotDoublePushItems() {
        // Given — a populated feeds list.
        launch(scenario: .populated)

        // When — double-tapping a feed (the re-entrant double-trigger).
        feedCell(feedTitle).doubleTap()

        // Then — we are inside the items list exactly once: a single Back reaches
        // Feeds (a double-push would leave a duplicate copy on the stack).
        assertExists(backButton, "Expected to navigate into the feed's items")
        backButton.tap()
        assertExists(addButton,
                     "A double-tap must not push FeedItems twice — one Back should reach Feeds")
        XCTAssertEqual(app.state, .runningForeground, "Re-entrant navigation must not crash")
    }

    func testChaos_doubleTapItem_doesNotDoublePushReader() {
        // Given — a feed's items.
        openFeedItems()

        // When — double-tapping an item.
        feedCell(itemTitles[0]).doubleTap()

        // Then — the reader is pushed exactly once: a single Back closes it and
        // returns to the items list (not a second stacked reader).
        assertExists(articleReader, "Expected to open the article reader")
        backButton.tap()
        assertGone(articleReader,
                   "A double-tap must not push the reader twice — one Back should close it")
        assertExists(feedCell(itemTitles[0]), "Should be back on the items list")
        XCTAssertEqual(app.state, .runningForeground, "Re-entrant navigation must not crash")
    }
}
