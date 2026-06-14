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
        openFeedItems()

        // Navigation title is the feed's title.
        assertExists(app.navigationBars[feedTitle], "Nav title should be the feed title")

        // Every seeded item renders.
        for title in itemTitles {
            assertExists(feedCell(title), "Item '\(title)' should be listed")
        }
    }

    func testBack_returnsToFeeds() {
        openFeedItems()

        assertExists(backButton)
        backButton.tap()

        assertExists(addButton, "Popping back should return to the Feeds screen")
        assertExists(feedCell(feedTitle), "The feed list should be shown again")
    }
}
