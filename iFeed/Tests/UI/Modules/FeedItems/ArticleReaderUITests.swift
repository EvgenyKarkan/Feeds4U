//
//  ArticleReaderUITests.swift
//  iFeedUITests
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import XCTest

/// The seeded items carry inline HTML (>300 chars), so a row tap opens the
/// in-app `ArticleReader` (a `WKWebView`) rather than an SFSafariViewController.
final class ArticleReaderUITests: FeedItemsUITestCase {

    func testTapItem_opensReaderThenBackReturnsToList() {
        // Given — a feed's items.
        openFeedItems()
        let item = feedCell(itemTitles[0])

        // When — tapping an item.
        item.tap()

        // Then — the in-app reader's web view appears, titled with the article.
        assertExists(articleReader, "Tapping an item should open the in-app article reader")
        assertExists(app.navigationBars[itemTitles[0]], "Reader nav title should be the article title")

        // When — going back.
        backButton.tap()

        // Then — the reader is dismissed and the items list is shown again.
        assertGone(articleReader, "Leaving the reader should dismiss the web view")
        assertExists(feedCell(itemTitles[0]), "Back should return to the items list")
    }
}
