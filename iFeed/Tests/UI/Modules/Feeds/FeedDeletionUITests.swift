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

        // When — opening the trash menu, choosing Edit Mode, and tapping a row's
        // delete control.
        trashButton.tap()
        tapMenuItem(Labels.editMode)
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

    func testTrashButton_whileEditing_exitsEditingInsteadOfShowingMenu() {
        // Given — a populated list put into editing mode via the trash menu.
        launch(scenario: .populated)
        assertExists(trashButton)
        trashButton.tap()
        tapMenuItem(Labels.editMode)
        let minus = feedCell("Swift Blog").buttons.firstMatch
        assertExists(minus, "Editing mode should expose a per-row delete control")

        // When — tapping the trash button again while editing.
        trashButton.tap()

        // Then — editing is turned off (no menu); the delete controls disappear.
        assertGone(minus, "Tapping trash while editing should exit editing mode")
    }

    func testDeleteAll_cancel_keepsAllFeeds() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(feedCell("Swift Blog"))

        // When — opening the sized Delete All action but cancelling the
        // destructive confirmation.
        trashButton.tap()
        let deleteAllItem = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "\(Labels.deleteAll) ("))
            .firstMatch
        assertExists(deleteAllItem, "Trash menu should offer a sized Delete All action", timeout: 10)
        deleteAllItem.tap()
        app.alerts.buttons[Labels.cancel].tap()

        // Then — nothing is deleted; the feeds remain.
        assertExists(feedCell("Swift Blog"))
        assertExists(feedCell("Apple Newsroom"))
    }

    func testDeleteAll_zerosTheCacheAndReturnsToEmptyState() {
        // Given — a populated feeds list.
        launch(scenario: .populated)
        assertExists(feedCell("Swift Blog"))

        // When — opening the trash menu and choosing the deferred, sized
        // "Delete All (… MB)" action (it appears once the cache size resolves).
        trashButton.tap()
        let deleteAllItem = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "\(Labels.deleteAll) ("))
            .firstMatch
        assertExists(deleteAllItem, "Trash menu should offer a sized Delete All action", timeout: 10)
        deleteAllItem.tap()

        // When — confirming the destructive alert.
        let confirm = app.alerts.buttons[Labels.deleteAll]
        assertExists(confirm, "A destructive confirmation should appear")
        confirm.tap()

        // Then — the whole cache is gone and the empty state returns.
        assertExists(emptyLabel, "Deleting everything should reveal the empty prompt", timeout: 10)
        assertGone(feedCell("Swift Blog"))
        assertGone(feedCell("Apple Newsroom"))
    }
}
