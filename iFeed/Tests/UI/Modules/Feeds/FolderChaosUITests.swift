//
//  FolderChaosUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Chaos coverage for the folder expand/collapse state machine — the prime
/// `performBatchUpdates` "invalid number of rows" crash site. Interleaves
/// toggling with deletion (the cross-operation most likely to drift the
/// section's row counts) and verifies the app neither crashes nor loses data.
final class FolderChaosUITests: FeedsUITestCase {

    func testChaos_toggleWhileDeletingGroupedFeeds_staysConsistent() {
        // Given — a folder with grouped feeds.
        launch(scenario: .folders)
        let header = folderHeader("Tech")
        assertExists(header, "Seeded folder header should be present")

        // When — collapsing/expanding the folder and deleting a grouped feed in
        // tight rotation. As grouped feeds disappear the folder eventually
        // self-removes, so every interaction is existence-guarded.
        for _ in 0..<5 {
            if header.exists { header.tap() }
            if header.exists { header.tap() }

            let grouped = feedCell("Swift Blog")
            if grouped.exists {
                grouped.swipeLeft()
                let delete = app.tables.buttons[Labels.delete]
                if delete.waitForExistence(timeout: 2) {
                    delete.tap()
                }
            }
        }

        // Then — no crash, and the ungrouped feeds remain consistent.
        XCTAssertEqual(app.state, .runningForeground,
                       "Interleaved folder toggling and deletion must not crash")
        assertExists(feedCell("Hacker News"),
                     "Ungrouped feeds must remain consistent after the churn")
    }

    func testChaos_rapidToggleThenReloadOnReappear_keepsRowsConsistent() {
        // Given — a folder, expanded by default.
        launch(scenario: .folders)
        let header = folderHeader("Tech")
        assertExists(header)

        // When — rapidly toggling, then forcing a full reload by leaving and
        // returning (navigating into a feed and back triggers viewWillAppear's
        // reload). The animated toggle and the full reload must agree on the counts.
        for _ in 0..<10 {
            header.tap()
        }
        if !feedCell("Swift Blog").exists {
            header.tap()
        }

        feedCell("Hacker News").tap()
        assertExists(app.navigationBars.buttons.element(boundBy: 0))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Then — the folder contents survive the toggle + reload, with no crash.
        assertExists(addButton, "Should return to the Feeds list")
        assertExists(feedCell("Swift Blog"), "Folder contents must survive toggle + reload")
        XCTAssertEqual(app.state, .runningForeground, "Toggle + reload must not crash")
    }
}
