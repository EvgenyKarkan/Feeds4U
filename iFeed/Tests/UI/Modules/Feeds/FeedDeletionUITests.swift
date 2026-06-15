//
//  FeedDeletionUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

final class FeedDeletionUITests: FeedsUITestCase {

    func testSwipeToDelete_removesRow() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        let target = feedCell("Hacker News")
        assertExists(target)

        // When — swiping the row and confirming Delete (scoped to the table, since
        // the system trash bar button also carries the "Delete" label).
        target.swipeLeft()
        let deleteButton = app.tables.buttons[Labels.delete]
        assertExists(deleteButton, "Swipe should reveal a Delete action")
        deleteButton.tap()

        // Then — the feed is removed; the others remain.
        assertGone(target, "Deleted feed should disappear")
        assertExists(feedCell("Swift Blog"), "Other feeds must remain")
    }

    func testDeleteLastFeed_returnsToEmptyState() {
        // Given — a single seeded feed.
        launch(scenario: .singleFeed)
        let only = feedCell("Swift Blog")
        assertExists(only)

        // When — swipe-deleting the only feed.
        only.swipeLeft()
        let deleteButton = app.tables.buttons[Labels.delete]
        assertExists(deleteButton)
        deleteButton.tap()

        // Then — the empty state is restored.
        assertGone(only)
        assertExists(emptyLabel, "Deleting the last feed should reveal the empty prompt")
        assertGone(trashButton, "Trash button should disappear in the empty state")
        assertGone(searchButton, "Search button should disappear in the empty state")
    }

    func testTrashButton_entersEditingAndDeletes() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(trashButton)

        // When — entering editing mode and tapping a row's delete control.
        trashButton.tap()
        let minus = feedCell("Swift Blog").buttons.firstMatch
        assertExists(minus, "Editing mode should expose a per-row delete control")
        minus.tap()

        // When — confirming via the trailing "Delete" (scoped to the table so the
        // system trash bar button's identical label is excluded).
        let confirm = app.tables.buttons[Labels.delete]
        assertExists(confirm, "Tapping the delete control should reveal a Delete confirmation")
        confirm.tap()

        // Then — the feed is removed; the others remain.
        assertGone(feedCell("Swift Blog"))
        assertExists(feedCell("Apple Newsroom"), "Remaining feeds stay in the list")
    }
}
