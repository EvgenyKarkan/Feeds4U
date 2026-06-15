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
        // Given — a feed's items, all unread, so the action is offered.
        openFeedItems()
        assertExists(markAllAsReadButton, "Mark-all-as-read should be available with unread items")

        // When — marking everything as read.
        markAllAsReadButton.tap()
        tapMenuItem(ItemLabels.markAllAsRead)

        // Then — the action disappears; the items remain listed.
        assertGone(markAllAsReadButton, "Mark-all-as-read should hide once nothing is unread")
        assertExists(feedCell(itemTitles[0]), "Items remain listed after being marked read")
    }
}
