//
//  ListUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

final class ListUITests: FeedsUITestCase {

    func testPopulatedList_rendersFeedsAndAllControls() {
        // Given / When — the app launches with seeded feeds.
        launch(scenario: .populated)

        // Then — every feed renders, alongside all list controls.
        assertExists(feedsTable)
        assertExists(feedCell("Swift Blog"))
        assertExists(feedCell("Apple Newsroom"))
        assertExists(feedCell("Hacker News"))
        assertExists(feedCell("The Verge"))

        assertExists(addButton, "Add button should be visible when feeds exist")
        assertExists(trashButton, "Trash button should be visible when feeds exist")
        assertExists(searchButton, "Search button should be visible when feeds exist")

        XCTAssertFalse(emptyLabel.isHittable, "Empty prompt should not be shown when feeds exist")
    }
}
