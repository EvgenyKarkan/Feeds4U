//
//  FolderUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

final class FolderUITests: FeedsUITestCase {

    func testFolderHeader_collapsesAndExpandsItsFeeds() {
        launch(scenario: .folders)

        let header = folderHeader("Tech")
        assertExists(header, "Seeded folder header should be visible")

        // Folders start expanded — their grouped feeds are visible.
        assertExists(feedCell("Swift Blog"))
        assertExists(feedCell("Apple Newsroom"))

        // Collapse.
        header.tap()
        assertGone(feedCell("Swift Blog"), "Collapsing should hide the folder's feeds")
        assertGone(feedCell("Apple Newsroom"))

        // Ungrouped feeds stay put.
        assertExists(feedCell("Hacker News"))

        // Expand again.
        header.tap()
        assertExists(feedCell("Swift Blog"), "Expanding should restore the folder's feeds")
        assertExists(feedCell("Apple Newsroom"))
    }
}
