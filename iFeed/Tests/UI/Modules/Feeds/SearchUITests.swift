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
        // Given — seeded recent searches.
        launch(scenario: .search)
        assertExists(searchButton)

        // When — opening the search menu and choosing "New search".
        searchButton.tap()
        tapMenuItem(Labels.newSearch) // also proves the recent-searches menu opened

        // Then — the search-input alert appears.
        assertExists(app.staticTexts[Labels.searchDescription], "New-search input alert should appear")
        app.buttons[Labels.cancel].tap()
    }

    func testSearch_withMatches_navigatesToResults() {
        // Given — the search scenario, with the input alert open.
        launch(scenario: .search)
        openNewSearchInput()

        // When — searching a term that matches a single seeded item title
        // ("apple" scores a reliable fuzzy match, unlike a term shared across many
        // items). The nav search button also carries the label "Search", so scope
        // to the alert.
        alertTextField.typeText("apple")
        app.alerts.buttons[Labels.search].tap()

        // Then — a match pushes the results screen, so the Feeds controls go away.
        // The engine indexes the corpus on first query; allow a generous timeout so
        // a cold index build on a loaded simulator doesn't flake.
        assertGone(addButton, "A matching search should navigate to results", timeout: 45)
    }

    func testSearch_withoutMatches_showsNoResultsAlert() {
        // Given — the search scenario, with the input alert open.
        launch(scenario: .search)
        openNewSearchInput()

        // When — searching a term that matches nothing.
        alertTextField.typeText("zzzznomatchxyz")
        app.alerts.buttons[Labels.search].tap()

        // Then — the no-results alert is shown. The engine indexes the corpus on
        // the first query; allow a generous timeout so a cold index build on a
        // loaded simulator doesn't flake (mirrors testSearch_withMatches).
        assertExists(app.staticTexts[Labels.noSearchResults],
                     "Unmatched search should show the no-results alert", timeout: 45)
        app.alerts.buttons[Labels.confirmation].tap()
    }

    func testClearRecentSearches_emptiesTheMenu() {
        // Given — the search scenario with seeded recent searches.
        launch(scenario: .search)

        // When — clearing the recent searches.
        searchButton.tap()
        tapMenuItem(Labels.clearRecent)

        // Then — with no recent searches the button no longer shows a menu, so
        // tapping it opens the search input directly.
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
