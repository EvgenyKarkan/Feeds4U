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
        // Given — a folder ("Tech") expanded by default, with its feeds visible.
        launch(scenario: .folders)
        let header = folderHeader("Tech")
        assertExists(header, "Seeded folder header should be visible")
        assertExists(feedCell("Swift Blog"))
        assertExists(feedCell("Apple Newsroom"))

        // When — collapsing the folder.
        header.tap()

        // Then — its feeds hide; ungrouped feeds stay put.
        assertGone(feedCell("Swift Blog"), "Collapsing should hide the folder's feeds")
        assertGone(feedCell("Apple Newsroom"))
        assertExists(feedCell("Hacker News"))

        // When — expanding it again.
        header.tap()

        // Then — its feeds are restored.
        assertExists(feedCell("Swift Blog"), "Expanding should restore the folder's feeds")
        assertExists(feedCell("Apple Newsroom"))
    }
}
