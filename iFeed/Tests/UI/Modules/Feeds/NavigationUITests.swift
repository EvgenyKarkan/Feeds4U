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
        launch(scenario: .populated)

        assertExists(feedCell("Swift Blog"))
        feedCell("Swift Blog").tap()

        // Navigated away from the Feeds list.
        assertGone(addButton, "Feeds controls should disappear after navigating into a feed")

        // Pop back to the Feeds list.
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        assertExists(backButton)
        backButton.tap()

        assertExists(addButton, "Feeds controls should return after popping back")
        assertExists(feedCell("Swift Blog"))
    }
}
