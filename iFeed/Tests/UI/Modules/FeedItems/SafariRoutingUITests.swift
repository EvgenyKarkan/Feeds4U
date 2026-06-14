//
//  SafariRoutingUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// An item seeded without inline HTML routes to `SFSafariViewController` rather
/// than the in-app reader. This test stays shallow — it only verifies the route,
/// not page content — because Safari is out-of-process system UI loading a live URL.
final class SafariRoutingUITests: FeedItemsUITestCase {

    func testTapBodylessItem_routesToSafari() {
        launch(scenario: .populated)

        feedCell("The Verge").tap()
        assertGone(addButton)

        let item = feedCell("Open in Safari")
        assertExists(item)
        item.tap()

        // SFSafariViewController is system UI hosting an out-of-process web view;
        // its chrome (the top browser bar + address button) is what XCUI can see.
        assertExists(app.otherElements["TopBrowserBar"],
                     "Tapping a body-less item should route to Safari")
        XCTAssertTrue(app.buttons["URL"].exists, "Safari's address bar should be present")
        XCTAssertFalse(articleReader.exists,
                       "The in-app reader must not be used for a body-less item")
    }
}
