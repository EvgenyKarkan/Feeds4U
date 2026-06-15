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
        // Given — a populated feeds list.
        launch(scenario: .populated)

        // When — opening the "+" menu and choosing "Enter a new feed".
        addButton.tap()
        tapMenuItem(Labels.enterNewFeedMenu)

        // Then — the enter-feed alert appears and validates input.
        assertExists(app.staticTexts[Labels.enterFeedMessage], "Enter-feed alert should appear")
        assertExists(alertTextField)

        let addAction = app.buttons[Labels.add]
        XCTAssertFalse(addAction.isEnabled, "Submit should be disabled with no URL")

        alertTextField.typeText("https://example.com/rss")
        XCTAssertTrue(addAction.isEnabled, "Submit should enable for a valid URL")

        // When — cancelling.
        app.buttons[Labels.cancel].tap()

        // Then — the alert is dismissed.
        assertGone(alertTextField, "Cancel should dismiss the alert")
    }

    func testAddMenu_exploreAlert_appearsAndCancels() {
        // Given — a populated feeds list.
        launch(scenario: .populated)

        // When — opening the "+" menu and choosing "Explore feeds".
        addButton.tap()
        tapMenuItem(Labels.exploreFeedsMenu)

        // Then — the explore alert appears.
        assertExists(app.staticTexts[Labels.exploreMessage], "Explore alert should appear")
        assertExists(alertTextField)

        // When — cancelling.
        app.buttons[Labels.cancel].tap()

        // Then — the alert is dismissed.
        assertGone(alertTextField, "Cancel should dismiss the alert")
    }
}
