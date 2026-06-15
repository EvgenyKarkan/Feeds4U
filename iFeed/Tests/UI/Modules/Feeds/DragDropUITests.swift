//
//  DragDropUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// Drag-and-drop reorganization. XCUI table drags are inherently timing
/// sensitive; the assertion is kept to the create-folder prompt that the drop
/// triggers. If the gesture proves unstable on CI it can be skipped via the
/// test plan without affecting the rest of the suite.
final class DragDropUITests: FeedsUITestCase {

    func testDragFeedOntoFeed_promptsToCreateFolder() {
        // Given — two ungrouped feeds.
        launch(scenario: .populated)
        let source = feedCell("Swift Blog")
        let destination = feedCell("Apple Newsroom")
        assertExists(source)
        assertExists(destination)

        // When — dragging one feed onto another.
        source.press(forDuration: 1.0, thenDragTo: destination)

        // Then — the create-folder prompt appears.
        assertExists(app.staticTexts[Labels.newFolderMessage],
                     "Dropping a feed onto another should prompt to create a folder")
        app.buttons[Labels.cancel].tap()
    }
}
