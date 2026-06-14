//
//  AddFeedUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Covers the "+" menu and its two alerts. Network completion is intentionally
/// out of scope (the suite runs offline) — these tests assert the alert UI,
/// validation, and dismissal only.
final class AddFeedUITests: FeedsUITestCase {

    func testAddMenu_enterFeedAlert_validatesAndCancels() {
        launch(scenario: .populated)

        addButton.tap()
        tapMenuItem(Labels.enterNewFeedMenu)

        assertExists(app.staticTexts[Labels.enterFeedMessage], "Enter-feed alert should appear")
        assertExists(alertTextField)

        let addAction = app.buttons[Labels.add]
        XCTAssertFalse(addAction.isEnabled, "Submit should be disabled with no URL")

        alertTextField.typeText("https://example.com/rss")
        XCTAssertTrue(addAction.isEnabled, "Submit should enable for a valid URL")

        app.buttons[Labels.cancel].tap()
        assertGone(alertTextField, "Cancel should dismiss the alert")
    }

    func testAddMenu_exploreAlert_appearsAndCancels() {
        launch(scenario: .populated)

        addButton.tap()
        tapMenuItem(Labels.exploreFeedsMenu)

        assertExists(app.staticTexts[Labels.exploreMessage], "Explore alert should appear")
        assertExists(alertTextField)

        app.buttons[Labels.cancel].tap()
        assertGone(alertTextField, "Cancel should dismiss the alert")
    }
}
