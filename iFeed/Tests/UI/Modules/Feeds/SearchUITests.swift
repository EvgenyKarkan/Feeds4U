//
//  SearchUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Local search runs entirely over the seeded in-memory items, so both the
/// matching and the no-results paths are deterministic offline.
final class SearchUITests: FeedsUITestCase {

    func testSearchButton_showsRecentSearchesMenu() {
        launch(scenario: .search)

        assertExists(searchButton)
        searchButton.tap()

        tapMenuItem(Labels.newSearch) // also proves the recent-searches menu opened
        assertExists(app.staticTexts[Labels.searchDescription], "New-search input alert should appear")
        app.buttons[Labels.cancel].tap()
    }

    func testSearch_withMatches_navigatesToResults() {
        launch(scenario: .search)

        openNewSearchInput()
        // "apple" appears in a single seeded item title, so it scores a reliable
        // fuzzy match (unlike a term shared across many items).
        alertTextField.typeText("apple")
        // Scope to the alert: the nav search button also carries the label "Search".
        app.alerts.buttons[Labels.search].tap()

        // A match pushes the results screen, so the Feeds controls go away. The
        // engine indexes the corpus on first query, so allow generous time for a
        // cold index build under a loaded simulator.
        assertGone(addButton, "A matching search should navigate to results", timeout: 30)
    }

    func testSearch_withoutMatches_showsNoResultsAlert() {
        launch(scenario: .search)

        openNewSearchInput()
        alertTextField.typeText("zzzznomatchxyz")
        app.alerts.buttons[Labels.search].tap()

        assertExists(app.staticTexts[Labels.noSearchResults], "Unmatched search should show the no-results alert")
        app.alerts.buttons[Labels.confirmation].tap()
    }

    func testClearRecentSearches_emptiesTheMenu() {
        launch(scenario: .search)

        searchButton.tap()
        tapMenuItem(Labels.clearRecent)

        // With no recent searches the button no longer shows a menu — tapping it
        // opens the search input directly.
        searchButton.tap()
        assertExists(app.staticTexts[Labels.searchDescription],
                     "After clearing, the search button should open the input directly")
        app.buttons[Labels.cancel].tap()
    }

    // MARK: - Helpers
    private func openNewSearchInput() {
        searchButton.tap()
        tapMenuItem(Labels.newSearch)
        assertExists(alertTextField)
    }
}
