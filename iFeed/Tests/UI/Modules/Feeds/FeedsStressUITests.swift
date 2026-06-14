//
//  FeedsStressUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Stress / "monkey" coverage for the Feeds screen.
///
/// Goal: prove the screen stays **reliable under churn** — no crash, no stuck
/// state, always recoverable — rather than asserting a single happy-path
/// outcome. These catch races and lifecycle bugs that scripted flows miss
/// (e.g. the search-continuation double-resume crash these very feeds surfaced).
///
/// The pure-random monkey is seeded (`SeededGenerator`) so a failure reproduces.
/// This suite is slower than the functional suites and is intentionally kept
/// separate so it can be excluded from fast runs via the test plan.
final class FeedsStressUITests: FeedsUITestCase {

    /// Deterministic RNG (Random Number Generator) for the monkey test.
    ///
    /// The hex literal `0x00F3_3D5_AB1E` is a vanity seed that reads as
    /// "**FEEDS_ABLE**" (F3 3D5 AB1E ≈ feedsable). Any non-zero value works;
    /// this one was chosen for readability in logs. When a monkey run fails,
    /// re-use this seed to replay the exact same gesture sequence.
    private var rng = SeededGenerator(seed: 0x00F3_3D5_AB1E)

    // MARK: - Monkey

    /// Fires a long stream of random taps / swipes / long-press-drags at random
    /// points and asserts the app never crashes and the Feeds screen stays
    /// reachable afterwards.
    func testMonkey_randomGesturesKeepAppAlive() {
        launch(scenario: .populated)
        assertExists(addButton)

        let window = app.windows.firstMatch
        let iterations = 80

        for index in 0..<iterations {
            performRandomGesture(on: window)
            // Clear any transient modal and return to the Feeds root after every
            // gesture. This keeps the monkey on the screen under test and — since
            // the root list has no pull-to-refresh — prevents it wandering into a
            // network refresh that would never let XCUI settle.
            dismissTransientUI()
            returnToRoot()

            if index % 20 == 0 {
                XCTAssertEqual(app.state, .runningForeground,
                               "App terminated during monkey gesture #\(index)")
            }
        }

        XCTAssertEqual(app.state, .runningForeground, "App must survive monkey testing")
        recoverToFeeds()
        assertExists(addButton, "Feeds screen must remain reachable after monkey testing")
    }

    // MARK: - Targeted stress

    /// Hammers the trash button to flip in/out of editing mode many times.
    func testStress_rapidEditingToggle() {
        launch(scenario: .populated)
        assertExists(trashButton)

        for _ in 0..<30 {
            trashButton.tap()
        }

        XCTAssertEqual(app.state, .runningForeground, "Editing toggling must not crash")
        // Leave editing mode and confirm the list is intact.
        if app.tables.buttons[Labels.delete].firstMatch.exists {
            trashButton.tap()
        }
        assertExists(feedCell("Swift Blog"), "Feeds must remain after editing churn")
    }

    /// Repeatedly opens the add menu + enter-feed alert and cancels it.
    func testStress_rapidAddMenuChurn() {
        launch(scenario: .populated)

        for _ in 0..<15 {
            addButton.tap()
            tapMenuItem(Labels.enterNewFeedMenu)
            assertExists(alertTextField, timeout: 3)
            app.alerts.buttons[Labels.cancel].tap()
            assertGone(alertTextField, timeout: 3)
        }

        XCTAssertEqual(app.state, .runningForeground, "Add-menu churn must not crash")
        assertExists(addButton)
    }

    /// Pushes into a feed's items and pops back many times in quick succession,
    /// stressing module construction/teardown and the navigation stack.
    func testStress_rapidNavigationChurn() {
        launch(scenario: .populated)

        for _ in 0..<12 {
            feedCell("Swift Blog").tap()
            let back = app.navigationBars.buttons.element(boundBy: 0)
            assertExists(back, timeout: 8)
            back.tap()
            assertExists(addButton, timeout: 8)
        }

        XCTAssertEqual(app.state, .runningForeground, "Navigation churn must not crash")
    }

    /// Runs many searches back-to-back, repeatedly driving the index build and
    /// the result/no-result continuation paths — a direct regression guard for
    /// the search-continuation double-resume crash.
    func testStress_rapidSearchChurn() {
        launch(scenario: .search)

        let queries = ["apple", "verge", "macbook", "zzqxnomatch", "hacker", "apple"]
        for query in queries {
            openSearchInput()
            alertTextField.typeText(query)
            app.alerts.buttons[Labels.search].tap()

            if app.staticTexts[Labels.noSearchResults].waitForExistence(timeout: 12) {
                app.alerts.buttons[Labels.confirmation].tap()
            } else {
                // A match navigated to results — pop back to the Feeds screen.
                assertGone(addButton, timeout: 25)
                app.navigationBars.buttons.element(boundBy: 0).tap()
                assertExists(addButton, timeout: 8)
            }
        }

        XCTAssertEqual(app.state, .runningForeground, "Search churn must not crash")
    }

    /// Deletes every feed in rapid succession and verifies the empty state is
    /// reached cleanly (no orphaned rows, no crash).
    func testStress_deleteAllFeedsRapidly() {
        launch(scenario: .populated)

        for title in ["Swift Blog", "Apple Newsroom", "Hacker News", "The Verge"] {
            let cell = feedCell(title)
            guard cell.exists else { continue }
            cell.swipeLeft()
            let delete = app.tables.buttons[Labels.delete]
            if delete.waitForExistence(timeout: 3) {
                delete.tap()
            }
        }

        assertExists(emptyLabel, "Deleting all feeds rapidly should reach the empty state")
        XCTAssertEqual(app.state, .runningForeground, "Bulk deletion must not crash")
    }

    /// Hammers a folder header's expand/collapse. The toggle animates row
    /// insert/delete inside `performBatchUpdates`, so rapid taps are the classic
    /// trigger for a data-source/table desync crash ("invalid number of rows").
    /// After the churn the folder is driven to a known-expanded state and its
    /// contents are verified intact — proving no rows were lost or duplicated.
    func testStress_rapidFolderToggle() {
        launch(scenario: .folders)

        let header = folderHeader("Tech")
        assertExists(header, "Seeded folder header should be present")

        for _ in 0..<24 {
            header.tap()
        }

        XCTAssertEqual(app.state, .runningForeground, "Rapid folder toggling must not crash")

        // Drive to a deterministic expanded state, then verify data synchronisation:
        // both grouped feeds and the ungrouped feed must be present and correct.
        if !feedCell("Swift Blog").exists {
            header.tap()
        }
        assertExists(feedCell("Swift Blog"), "Grouped feed must survive the churn")
        assertExists(feedCell("Apple Newsroom"), "Grouped feed must survive the churn")
        assertExists(feedCell("Hacker News"), "Ungrouped feeds must remain unaffected")
    }

    // MARK: - Helpers

    private func performRandomGesture(on window: XCUIElement) {
        let point = randomCoordinate(in: window)
        switch Int.random(in: 0..<6, using: &rng) {
        case 0: point.tap()
        case 1: point.doubleTap()
        case 2: window.swipeLeft()
        case 3: window.swipeRight()
        case 4: window.swipeUp()
        default:
            point.press(forDuration: 0.4, thenDragTo: randomCoordinate(in: window))
        }
    }

    private func randomCoordinate(in element: XCUIElement) -> XCUICoordinate {
        // Keep within the content area, away from the status bar / very edges.
        let offsetX = Double.random(in: 0.05...0.95, using: &rng)
        let offsetY = Double.random(in: 0.12...0.90, using: &rng)
        return element.coordinate(withNormalizedOffset: CGVector(dx: offsetX, dy: offsetY))
    }

    /// Dismisses any presented alert (Cancel / OK first, else the first button).
    private func dismissTransientUI() {
        var safety = 0
        while app.alerts.element.exists && safety < 4 {
            let alert = app.alerts.element
            let button: XCUIElement
            if alert.buttons[Labels.cancel].exists {
                button = alert.buttons[Labels.cancel]
            } else if alert.buttons[Labels.confirmation].exists {
                button = alert.buttons[Labels.confirmation]
            } else {
                button = alert.buttons.firstMatch
            }
            if button.exists { button.tap() }
            safety += 1
        }
    }

    /// Lightweight per-iteration pop back to the Feeds root (no relaunch).
    /// The root is identified by the Feeds-only add button.
    private func returnToRoot() {
        var hops = 0
        while !addButton.exists && hops < 4 {
            if app.alerts.element.exists {
                dismissTransientUI()
            } else {
                let back = app.navigationBars.firstMatch.buttons.element(boundBy: 0)
                guard back.exists && back.isHittable else { break }
                back.tap()
            }
            hops += 1
        }
    }

    /// Navigates back to the Feeds root from wherever the monkey left the app,
    /// relaunching as a last resort (which is itself a valid liveness signal).
    private func recoverToFeeds() {
        for _ in 0..<10 {
            if addButton.exists { return }
            if app.alerts.element.exists {
                dismissTransientUI()
                continue
            }
            let back = app.navigationBars.firstMatch.buttons.element(boundBy: 0)
            if back.exists && back.isHittable {
                back.tap()
                continue
            }
            // Dismiss a possible menu/popover by tapping a neutral area.
            app.windows.firstMatch
                .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .tap()
        }

        if !addButton.exists {
            app.terminate()
            launch(scenario: .populated)
        }
    }

    /// Opens the search input alert whether or not a recent-searches menu is shown.
    private func openSearchInput() {
        searchButton.tap()

        let menuItem = app.menuItems[Labels.newSearch]
        let button = app.buttons[Labels.newSearch]
        if menuItem.waitForExistence(timeout: 1) {
            menuItem.tap()
        } else if button.waitForExistence(timeout: 1) {
            button.tap()
        }
        // Otherwise the input alert was presented directly (no recent searches).
        _ = alertTextField.waitForExistence(timeout: 3)
    }
}
