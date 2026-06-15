//
//  FeedItemsListUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

final class FeedItemsListUITests: FeedItemsUITestCase {

    func testList_rendersItemsAndFeedTitle() {
        // Given / When — open a seeded feed's items.
        openFeedItems()

        // Then — the nav title is the feed title and every item renders.
        assertExists(app.navigationBars[feedTitle], "Nav title should be the feed title")
        for title in itemTitles {
            assertExists(feedCell(title), "Item '\(title)' should be listed")
        }
    }

    func testBack_returnsToFeeds() {
        // Given — a feed's items are shown.
        openFeedItems()
        assertExists(backButton)

        // When — popping back.
        backButton.tap()

        // Then — the Feeds list is shown again.
        assertExists(addButton, "Popping back should return to the Feeds screen")
        assertExists(feedCell(feedTitle), "The feed list should be shown again")
    }
}
