//
//  FeedsRefreshUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 22.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Pull-to-refresh on the feeds list. Under UI testing the parser resolves every
/// parse immediately (see `UITestParser`), so refresh-all ends right away and the
/// seeded list is left unchanged — the test verifies the gesture is wired and the
/// list stays responsive rather than hanging on the (fake) seeded URLs.
final class FeedsRefreshUITests: FeedsUITestCase {

    func testPullToRefresh_keepsFeedsListResponsive() {
        // Given — a populated feed list.
        launch(scenario: .populated)
        assertExists(feedCell("Swift Blog"))

        // When — pulling the list down to refresh every saved feed.
        feedsTable.swipeDown(velocity: .slow)

        // Then — the refresh completes and the list stays intact and interactive.
        assertExists(feedCell("Swift Blog"))
        assertExists(feedCell("Apple Newsroom"))
        assertExists(addButton)
    }
}
