//
//  MarkAllAsReadUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

final class MarkAllAsReadUITests: FeedItemsUITestCase {

    func testMarkAllAsRead_hidesTheButton() {
        openFeedItems()

        // Seeded items are unread, so the action is offered.
        assertExists(markAllAsReadButton, "Mark-all-as-read should be available with unread items")

        markAllAsReadButton.tap()
        tapMenuItem(ItemLabels.markAllAsRead)

        // Once everything is read the action disappears.
        assertGone(markAllAsReadButton, "Mark-all-as-read should hide once nothing is unread")
        assertExists(feedCell(itemTitles[0]), "Items remain listed after being marked read")
    }
}
