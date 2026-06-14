//
//  SearchResultsUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Search results are presented by the FeedItems module in a "search" mode:
/// titled with the query, with no mark-all-as-read action and no pull-to-refresh.
final class SearchResultsUITests: FeedItemsUITestCase {

    func testSearchResults_renderAsItemsListWithoutMarkAll() {
        launch(scenario: .search)

        searchButton.tap()
        tapMenuItem(Labels.newSearch)
        assertExists(alertTextField)
        alertTextField.typeText("apple")
        app.alerts.buttons[Labels.search].tap()

        // A match pushes the results list, so the Feeds add button goes away. The
        // engine indexes on first query, so allow generous time for the navigation.
        assertGone(addButton, "Search should navigate to a results list", timeout: 30)
        assertExists(feedCell("Apple announces WWDC"), "The matching item should be listed", timeout: 10)

        XCTAssertFalse(markAllAsReadButton.exists,
                       "Search results must not offer mark-all-as-read")
    }
}
