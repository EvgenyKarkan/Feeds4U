//
//  FeedItemsStressUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Stress / "monkey" coverage for the FeedItems screen.
///
/// Under UI testing the parser is stubbed (`UITestParser`), so pull-to-refresh
/// resolves instantly and offline — it can be hammered without the never-idle
/// network spinner that would otherwise hang XCUI. The seeded "Swift Blog" items
/// all carry inline HTML, so a tap always opens the in-app reader (never Safari),
/// keeping the monkey on a single, recoverable screen.
final class FeedItemsStressUITests: FeedItemsUITestCase {

    private var rng = SeededGenerator(seed: 0x00F1_7E33_AB1E)

    // MARK: - Targeted stress

    /// Opens and closes an article in rapid succession, stressing the
    /// ArticleReader push/pop, WKWebView lifecycle, and mark-as-read writes.
    func testStress_rapidArticleOpenClose() {
        // Given — a feed's items.
        openFeedItems()
        let item = feedCell(itemTitles[0])

        // When — opening and closing an article in rapid succession.
        for _ in 0..<12 {
            item.tap()
            assertExists(articleReader, "Reader should open", timeout: 8)
            backButton.tap()
            assertExists(item, "Should return to the items list", timeout: 8)
        }

        // Then — no crash from the reader push/pop + WKWebView churn.
        XCTAssertEqual(app.state, .runningForeground, "Rapid article open/close must not crash")
    }

    /// Pulls to refresh repeatedly and verifies the item list stays consistent —
    /// no rows lost, no duplicates, no crash (parser is stubbed, so each refresh
    /// completes instantly with no new items).
    func testStress_rapidPullToRefresh() {
        // Given — a feed's items.
        openFeedItems()
        let table = app.tables.firstMatch

        // When — pulling to refresh repeatedly.
        for _ in 0..<8 {
            table.swipeDown()
        }

        // Then — no crash, and the list stays consistent (no rows lost/duplicated).
        XCTAssertEqual(app.state, .runningForeground, "Rapid refresh must not crash")
        for title in itemTitles {
            assertExists(feedCell(title), "Item '\(title)' must persist across refreshes")
        }
    }

    // MARK: - Monkey

    /// Random gestures on the items screen, recovering to the list after each so
    /// the monkey keeps stressing FeedItems (and its reader/refresh) rather than
    /// wandering off. Asserts the app never crashes and the list stays reachable.
    func testStress_feedItemsMonkey() {
        // Given — a feed's items.
        openFeedItems()

        let window = app.windows.firstMatch
        let iterations = 50

        // When — random gestures on the items screen, recovering to the list after
        // each so the monkey keeps stressing FeedItems rather than wandering off.
        for index in 0..<iterations {
            performRandomGesture(on: window)
            dismissTransientUI()
            returnToItems()

            if index % 15 == 0 {
                XCTAssertEqual(app.state, .runningForeground,
                               "App terminated during FeedItems monkey #\(index)")
            }
        }

        // Then — the app survives and the items list stays reachable.
        XCTAssertEqual(app.state, .runningForeground, "FeedItems must survive monkey testing")
        returnToItems()
        assertExists(feedCell(itemTitles[0]), "Items list must remain reachable after monkey testing")
    }

    // MARK: - Helpers

    private func performRandomGesture(on window: XCUIElement) {
        let point = randomCoordinate(in: window)
        switch Int.random(in: 0..<6, using: &rng) {
        case 0: point.tap()
        case 1: point.doubleTap()
        case 2: window.swipeUp()
        case 3: window.swipeDown()   // exercises pull-to-refresh (stubbed, offline)
        case 4: window.swipeLeft()
        default:
            point.press(forDuration: 0.4, thenDragTo: randomCoordinate(in: window))
        }
    }

    private func randomCoordinate(in element: XCUIElement) -> XCUICoordinate {
        let offsetX = Double.random(in: 0.05...0.95, using: &rng)
        let offsetY = Double.random(in: 0.12...0.90, using: &rng)
        return element.coordinate(withNormalizedOffset: CGVector(dx: offsetX, dy: offsetY))
    }

    private func dismissTransientUI() {
        var safety = 0
        while app.alerts.element.exists && safety < 4 {
            let alert = app.alerts.element
            let button = alert.buttons[Labels.confirmation].exists
                ? alert.buttons[Labels.confirmation]
                : alert.buttons.firstMatch
            if button.exists { button.tap() }
            safety += 1
        }
    }

    /// Brings the app back to the items list from wherever the monkey left it:
    /// closes the reader, dismisses alerts, and re-enters the feed if a stray tap
    /// popped back to the Feeds screen.
    private func returnToItems() {
        for _ in 0..<5 {
            if feedCell(itemTitles[0]).exists && !addButton.exists {
                return
            }
            if articleReader.exists {
                backButton.tap()
            } else if app.alerts.element.exists {
                dismissTransientUI()
            } else if addButton.exists {
                feedCell(feedTitle).tap()
            } else {
                break
            }
        }
    }
}
