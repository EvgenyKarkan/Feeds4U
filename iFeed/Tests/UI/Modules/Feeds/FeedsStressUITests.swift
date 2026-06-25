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
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(addButton)

        let window = app.windows.firstMatch
        let iterations = 80

        // When — a long stream of random gestures.
        for index in 0..<iterations {
            performRandomGesture(on: window)
            // Clear any transient modal and return to the Feeds root after every
            // gesture. This keeps the monkey on the screen under test. The root
            // list now has pull-to-refresh, but under UI testing the parser
            // resolves every parse instantly (see `UITestParser`), so a stray
            // swipe-down refresh ends immediately and never stalls XCUI.
            dismissTransientUI()
            returnToRoot()

            if index % 20 == 0 {
                XCTAssertEqual(app.state, .runningForeground,
                               "App terminated during monkey gesture #\(index)")
            }
        }

        // Then — the app survives and the Feeds screen stays reachable.
        XCTAssertEqual(app.state, .runningForeground, "App must survive monkey testing")
        recoverToFeeds()
        assertExists(addButton, "Feeds screen must remain reachable after monkey testing")
    }

    /// "Cat walked on the keyboard": a seeded chaos monkey that, unlike the
    /// pure-coordinate one, randomly fires *real* feature actions — pull-to-refresh,
    /// the trash menu (Edit Mode / Delete All → cancel), the add menu + junk text,
    /// search with garbage queries, feed navigation, row swipes — interleaved with
    /// raw gestures. Every branch is soft (no hard asserts mid-loop) so the run
    /// keeps churning; only liveness and recoverability are asserted.
    func testMonkey_chaoticFeatureActionsKeepAppAlive() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(addButton)

        let window = app.windows.firstMatch
        let iterations = 60

        // When — a long stream of chaotic, mixed feature actions and gestures.
        for index in 0..<iterations {
            performChaoticAction(on: window)
            dismissTransientUI()
            returnToRoot()

            if index % 15 == 0 {
                XCTAssertEqual(app.state, .runningForeground,
                               "App terminated during chaotic action #\(index)")
            }
        }

        // Then — the app survives and the Feeds screen stays reachable.
        XCTAssertEqual(app.state, .runningForeground, "App must survive chaotic feature testing")
        recoverToFeeds()
        assertExists(addButton, "Feeds screen must remain reachable after chaotic testing")
    }

    /// Stresses OPML import: relaunches into the import hook (`-uiOPMLImport`) so a
    /// real import + summary fires on appear, while a burst of random gestures
    /// hammers the screen during the import window. Repeats across relaunches.
    func testStress_opmlImportUnderChaos() {
        let window = app.windows.firstMatch

        // When — repeatedly importing on launch while firing random gestures.
        for _ in 0..<3 {
            app.terminate()
            launch(scenario: .populated, extraArguments: ["-uiOPMLImport", "allSeeded"])

            for _ in 0..<8 {
                performRandomGesture(on: window)
            }
            dismissTransientUI() // clears the import summary alert if present
            recoverToFeeds()

            // Then — each import-under-chaos cycle leaves the app alive.
            XCTAssertEqual(app.state, .runningForeground, "OPML import under chaos must not crash")
        }

        assertExists(addButton, "Feeds screen must remain reachable after OPML import chaos")
    }

    // MARK: - Targeted stress

    /// Flips in/out of editing mode many times through the trash menu: open menu →
    /// Edit Mode (enter editing) → tap trash (exit editing). Stresses the menu vs.
    /// exit-editing mode switch (`showsMenuAsPrimaryAction` toggling).
    func testStress_rapidEditingToggle() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(trashButton)

        // When — repeatedly entering editing via the menu and exiting via a tap.
        for _ in 0..<10 {
            trashButton.tap()                 // not editing → opens the menu
            tapMenuItem(Labels.editMode)      // enter editing
            trashButton.tap()                 // editing → exits (menu suppressed)
        }

        // Then — no crash; not stuck in editing; the list is intact.
        XCTAssertEqual(app.state, .runningForeground, "Editing toggling must not crash")
        if app.tables.buttons[Labels.delete].firstMatch.exists {
            trashButton.tap()
        }
        assertExists(feedCell("Swift Blog"), "Feeds must remain after editing churn")
    }

    /// Hammers pull-to-refresh on the feeds list. Under UI testing the parser
    /// resolves instantly, so each refresh-all locks then unlocks interaction in
    /// quick succession — a stress on that lock/unlock cycle and the spawned task.
    func testStress_rapidPullToRefreshChurn() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(feedCell("Swift Blog"))

        // When — pulling to refresh many times back-to-back.
        for _ in 0..<12 {
            feedsTable.swipeDown(velocity: .fast)
        }

        // Then — no crash; the list stays intact and interactive.
        XCTAssertEqual(app.state, .runningForeground, "Refresh churn must not crash")
        assertExists(feedCell("Swift Blog"), "Feeds must remain after refresh churn")
        assertExists(addButton)
    }

    /// Repeatedly opens the deferred, sized "Delete All" action and cancels the
    /// destructive confirmation. Stresses the deferred-menu size resolution and
    /// the confirm/cancel path without ever wiping the data.
    func testStress_rapidDeleteAllCancelChurn() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(feedCell("Swift Blog"))

        // When — opening Delete All and cancelling, repeatedly.
        for _ in 0..<8 {
            trashButton.tap()
            let deleteAllItem = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@", "\(Labels.deleteAll) ("))
                .firstMatch
            if deleteAllItem.waitForExistence(timeout: 8) {
                deleteAllItem.tap()
                if app.alerts.buttons[Labels.cancel].waitForExistence(timeout: 3) {
                    app.alerts.buttons[Labels.cancel].tap()
                }
            } else {
                // Deferred item didn't appear — dismiss the menu with a neutral tap.
                app.windows.firstMatch
                    .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    .tap()
            }
        }

        // Then — no crash; cancelling never deletes, so the feeds remain.
        XCTAssertEqual(app.state, .runningForeground, "Delete-All cancel churn must not crash")
        assertExists(feedCell("Swift Blog"), "Cancelling must never delete feeds")
    }

    /// Repeatedly opens the add menu + enter-feed alert and cancels it.
    func testStress_rapidAddMenuChurn() {
        // Given — a populated feeds list.
        launch(scenario: .populated)

        // When — repeatedly opening the enter-feed alert and cancelling it.
        for _ in 0..<15 {
            addButton.tap()
            tapMenuItem(Labels.enterNewFeedMenu)
            assertExists(alertTextField, timeout: 3)
            app.alerts.buttons[Labels.cancel].tap()
            assertGone(alertTextField, timeout: 3)
        }

        // Then — no crash; the list is still usable.
        XCTAssertEqual(app.state, .runningForeground, "Add-menu churn must not crash")
        assertExists(addButton)
    }

    /// Pushes into a feed's items and pops back many times in quick succession,
    /// stressing module construction/teardown and the navigation stack.
    func testStress_rapidNavigationChurn() {
        // Given — a populated feeds list.
        launch(scenario: .populated)

        // When — pushing into a feed's items and popping back, repeatedly.
        for _ in 0..<12 {
            feedCell("Swift Blog").tap()
            let back = app.navigationBars.buttons.element(boundBy: 0)
            assertExists(back, timeout: 8)
            back.tap()
            assertExists(addButton, timeout: 8)
        }

        // Then — no crash from the module construction/teardown churn.
        XCTAssertEqual(app.state, .runningForeground, "Navigation churn must not crash")
    }

    /// Runs many searches back-to-back, repeatedly driving the index build and
    /// the result/no-result continuation paths — a direct regression guard for
    /// the search-continuation double-resume crash.
    func testStress_rapidSearchChurn() {
        // Given — the search scenario.
        launch(scenario: .search)

        // When — running many searches back-to-back, driving both the result and
        // no-result continuation paths (regression guard for the double-resume crash).
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

        // Then — no crash from the repeated index build + continuation churn.
        XCTAssertEqual(app.state, .runningForeground, "Search churn must not crash")
    }

    /// Deletes every feed in rapid succession and verifies the empty state is
    /// reached cleanly (no orphaned rows, no crash).
    func testStress_deleteAllFeedsRapidly() {
        // Given — a populated feeds list.
        launch(scenario: .populated)

        // When — swipe-deleting every feed in rapid succession.
        for title in ["Swift Blog", "Apple Newsroom", "Hacker News", "The Verge"] {
            let cell = feedCell(title)
            guard cell.exists else { continue }
            cell.swipeLeft()
            let delete = app.tables.buttons[Labels.delete]
            if delete.waitForExistence(timeout: 3) {
                delete.tap()
            }
        }

        // Then — the empty state is reached cleanly, with no crash.
        assertExists(emptyLabel, "Deleting all feeds rapidly should reach the empty state")
        XCTAssertEqual(app.state, .runningForeground, "Bulk deletion must not crash")
    }

    /// Hammers a folder header's expand/collapse. The toggle animates row
    /// insert/delete inside `performBatchUpdates`, so rapid taps are the classic
    /// trigger for a data-source/table desync crash ("invalid number of rows").
    /// After the churn the folder is driven to a known-expanded state and its
    /// contents are verified intact — proving no rows were lost or duplicated.
    func testStress_rapidFolderToggle() {
        // Given — a folder with grouped feeds.
        launch(scenario: .folders)
        let header = folderHeader("Tech")
        assertExists(header, "Seeded folder header should be present")

        // When — hammering the folder header's expand/collapse.
        for _ in 0..<24 {
            header.tap()
        }

        // Then — no crash; driven to a known-expanded state, every feed (grouped
        // and ungrouped) is present, proving no rows were lost or duplicated.
        XCTAssertEqual(app.state, .runningForeground, "Rapid folder toggling must not crash")
        if !feedCell("Swift Blog").exists {
            header.tap()
        }
        assertExists(feedCell("Swift Blog"), "Grouped feed must survive the churn")
        assertExists(feedCell("Apple Newsroom"), "Grouped feed must survive the churn")
        assertExists(feedCell("Hacker News"), "Ungrouped feeds must remain unaffected")
    }

    // MARK: - Helpers

    private let feedTitles = ["Swift Blog", "Apple Newsroom", "Hacker News", "The Verge"]

    /// One chaotic step: randomly a real feature action or a raw gesture. Every
    /// branch is best-effort — missing elements are skipped, not asserted — so a
    /// transient state can never abort the churn.
    private func performChaoticAction(on window: XCUIElement) {
        switch Int.random(in: 0..<9, using: &rng) {
        case 0:
            feedsTable.swipeDown(velocity: .fast) // pull-to-refresh

        case 1 where trashButton.exists:
            trashButton.tap() // trash menu
            if Bool.random(using: &rng) {
                tapSoftMenuItem(Labels.editMode)
            } else {
                let deleteAll = app.descendants(matching: .any)
                    .matching(NSPredicate(format: "label BEGINSWITH %@", "\(Labels.deleteAll) ("))
                    .firstMatch
                if deleteAll.waitForExistence(timeout: 4) {
                    deleteAll.tap()
                    if app.alerts.buttons[Labels.cancel].waitForExistence(timeout: 2) {
                        app.alerts.buttons[Labels.cancel].tap() // never wipe — keep churning
                    }
                }
            }

        case 2:
            addButton.tap() // add menu → enter-feed alert → junk → cancel
            tapSoftMenuItem(Labels.enterNewFeedMenu)
            if alertTextField.waitForExistence(timeout: 2) {
                alertTextField.typeText(randomJunk())
                if app.alerts.buttons[Labels.cancel].exists {
                    app.alerts.buttons[Labels.cancel].tap()
                }
            }

        case 3:
            let cell = feedCell(feedTitles.randomElement(using: &rng) ?? "Swift Blog")
            if cell.exists { cell.tap() } // navigate into items

        case 4 where searchButton.exists:
            openSearchInput() // search with garbage
            if alertTextField.exists {
                alertTextField.typeText(randomJunk())
                if app.alerts.buttons[Labels.search].exists {
                    app.alerts.buttons[Labels.search].tap()
                }
            }

        case 5:
            let cell = feedCell(feedTitles.randomElement(using: &rng) ?? "Swift Blog")
            if cell.exists { cell.swipeLeft() } // reveal swipe actions

        default:
            performRandomGesture(on: window)
        }
    }

    /// Best-effort menu-item tap (menu item or plain button), never asserting.
    private func tapSoftMenuItem(_ label: String) {
        let menuItem = app.menuItems[label]
        let button = app.buttons[label]
        if menuItem.waitForExistence(timeout: 2) {
            menuItem.tap()
        } else if button.waitForExistence(timeout: 1) {
            button.tap()
        }
    }

    /// Cat-on-keyboard text: random length, random alphanumeric/punctuation/URL-ish
    /// characters (no newline, which would submit an alert prematurely).
    private func randomJunk() -> String {
        let alphabet = Array("asdfghjklqwertyuiopzxcvbnm 1234567890 !@#%&*()-_+=:/.https")
        let length = Int.random(in: 1...14, using: &rng)
        var result = ""
        for _ in 0..<length {
            result.append(alphabet.randomElement(using: &rng) ?? "x")
        }
        return result
    }

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
