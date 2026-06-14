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
        launch(scenario: .populated)

        let target = feedCell("Hacker News")
        assertExists(target)

        target.swipeLeft()
        // Scope to the table: the system trash bar button also carries the
        // accessibility label "Delete".
        let deleteButton = app.tables.buttons[Labels.delete]
        assertExists(deleteButton, "Swipe should reveal a Delete action")
        deleteButton.tap()

        assertGone(target, "Deleted feed should disappear")
        assertExists(feedCell("Swift Blog"), "Other feeds must remain")
    }

    func testDeleteLastFeed_returnsToEmptyState() {
        launch(scenario: .singleFeed)

        let only = feedCell("Swift Blog")
        assertExists(only)

        only.swipeLeft()
        let deleteButton = app.tables.buttons[Labels.delete]
        assertExists(deleteButton)
        deleteButton.tap()

        assertGone(only)
        assertExists(emptyLabel, "Deleting the last feed should reveal the empty prompt")
        assertGone(trashButton, "Trash button should disappear in the empty state")
        assertGone(searchButton, "Search button should disappear in the empty state")
    }

    func testTrashButton_entersEditingAndDeletes() {
        launch(scenario: .populated)

        assertExists(trashButton)
        trashButton.tap()

        // Editing mode exposes a leading delete control (a red minus) on each row.
        let minus = feedCell("Swift Blog").buttons.firstMatch
        assertExists(minus, "Editing mode should expose a per-row delete control")
        minus.tap()

        // The trailing confirmation is labelled "Delete"; scope to the table so the
        // system trash bar button's identical label is excluded.
        let confirm = app.tables.buttons[Labels.delete]
        assertExists(confirm, "Tapping the delete control should reveal a Delete confirmation")
        confirm.tap()

        assertGone(feedCell("Swift Blog"))
        assertExists(feedCell("Apple Newsroom"), "Remaining feeds stay in the list")
    }
}
