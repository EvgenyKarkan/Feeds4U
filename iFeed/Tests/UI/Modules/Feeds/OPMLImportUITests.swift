//
//  OPMLImportUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 21.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// OPML import UX. The system document picker cannot be driven reliably from
/// XCUITest, so the import outcomes are exercised through the app's
/// `-uiOPMLImport <key>` launch hook, which feeds canned OPML straight into the
/// presenter. Only the menu entry-point is verified through the real UI.
final class OPMLImportUITests: FeedsUITestCase {

    func testAddMenu_offersImportFromOPML() {
        // Given — the populated feed list.
        launch(scenario: .populated)
        assertExists(addButton)

        // When — opening the "+" menu.
        addButton.tap()

        // Then — the OPML import action is offered (alongside add / explore).
        let menuItem = app.menuItems[Labels.importMenu]
        let button = app.buttons[Labels.importMenu]
        XCTAssertTrue(menuItem.waitForExistence(timeout: 2) || button.waitForExistence(timeout: 2),
                      "The + menu should offer an Import from OPML action")
    }

    func testImport_allSeededFeeds_reportsSkippedSummary() {
        // Given — every OPML entry matches an already-seeded feed, so the import
        // skips them all without any network access.
        launch(scenario: .populated, extraArguments: ["-uiOPMLImport", "allSeeded"])

        // When — the canned import runs on launch.
        // Then — the summary reports the four feeds as skipped.
        let summary = "Added 0 · Skipped 4 · Failed 0"
        assertExists(app.staticTexts[summary],
                     "Importing already-seeded feeds should report them all as skipped",
                     timeout: 15)
        app.alerts.buttons[Labels.confirmation].tap()
    }

    func testImport_fileWithoutFeeds_showsNoFeedsAlert() {
        // Given — OPML that is well-formed but contains no feed URLs.
        launch(scenario: .populated, extraArguments: ["-uiOPMLImport", "noFeeds"])

        // When — the canned import runs on launch.
        // Then — the "no feeds found" alert is shown.
        assertExists(app.staticTexts[Labels.importNoFeeds],
                     "An OPML file with no feeds should show the no-feeds alert")
        app.alerts.buttons[Labels.confirmation].tap()
    }
}
