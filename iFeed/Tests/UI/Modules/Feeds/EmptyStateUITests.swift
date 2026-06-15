//
//  EmptyStateUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

final class EmptyStateUITests: FeedsUITestCase {

    func testEmptyState_showsOnlyAddButtonAndPrompt() {
        // Given / When — the app launches with no feeds.
        launch(scenario: .empty)

        // Then — only the add affordance and the empty prompt are shown.
        assertExists(addButton, "Add button should be visible in the empty state")
        assertExists(emptyLabel, "Empty-state prompt should be visible")

        XCTAssertFalse(trashButton.exists, "Trash button must be hidden with no feeds")
        XCTAssertFalse(searchButton.exists, "Search button must be hidden with no feeds")
        XCTAssertFalse(feedsTable.cells.firstMatch.exists, "No feed rows should be present")
    }
}
