//
//  NavigationUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

final class NavigationUITests: FeedsUITestCase {

    func testTappingFeed_pushesItemsAndBackReturns() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(feedCell("Swift Blog"))

        // When — tapping a feed.
        feedCell("Swift Blog").tap()

        // Then — the app navigates into the feed's items (Feeds controls go away).
        assertGone(addButton, "Feeds controls should disappear after navigating into a feed")

        // When — popping back.
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        assertExists(backButton)
        backButton.tap()

        // Then — the Feeds list is shown again.
        assertExists(addButton, "Feeds controls should return after popping back")
        assertExists(feedCell("Swift Blog"))
    }
}
