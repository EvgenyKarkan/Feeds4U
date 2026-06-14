//
//  ParsedFeedDataTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 12.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation
import Testing
@testable import iFeed

// MARK: - ParsedFeedDataTests

@Suite("ParsedFeedData Tests")
// Verifies that FeedKit RSS, Atom, and JSON Feed models are converted into
// app-owned ParsedFeedData values with normalized metadata and item lists.
struct ParsedFeedDataTests {

    // MARK: - RSS

    @Test("Normalize RSS feed data")
    func testRSSFeedNormalization() throws {
        // Given: An RSS feed with two linked items and one item without a link
        let feed = try Self.parsedFeed(from: Self.rssFeedXML)

        // When: Normalizing the parsed FeedKit model
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Feed-level data and linkable items should be preserved
        #expect(data.title == "RSS Feed Title")
        #expect(data.summary == "RSS Feed Description")
        #expect(data.items.count == 2)
        #expect(data.items[0].title == "RSS Item One")
        #expect(data.items[0].link == "https://example.com/rss/one")
        #expect(data.items[0].publishDate == Self.rssItemDate)
        #expect(data.items[1].title == "N/A")
        #expect(data.items[1].link == "https://example.com/rss/two")
    }

    // MARK: - Atom

    @Test("Normalize Atom feed data")
    func testAtomFeedNormalization() throws {
        // Given: An Atom feed with one linked entry and one entry without a link
        let feed = try Self.parsedFeed(from: Self.atomFeedXML)

        // When: Normalizing the parsed FeedKit model
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Atom title, subtitle, and linkable entries should be preserved
        #expect(data.title == "Atom Feed Title")
        #expect(data.summary == "Atom Feed Subtitle")
        #expect(data.items.count == 1)
        #expect(data.items[0].title == "Atom Entry One")
        #expect(data.items[0].link == "https://example.com/atom/one")
        #expect(data.items[0].publishDate == Self.atomEntryDate)
    }

    @Test("Use Atom rights when subtitle is missing")
    func testAtomRightsSummaryFallback() throws {
        // Given: An Atom feed without subtitle but with rights text
        let feed = try Self.parsedFeed(from: Self.atomFeedWithRightsXML)

        // When: Normalizing the parsed FeedKit model
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Rights should be used as the summary fallback
        #expect(data.title == "Atom Rights Feed")
        #expect(data.summary == "Copyright Example")
        #expect(data.items.isEmpty)
    }

    // MARK: - JSON Feed

    @Test("Normalize JSON Feed data")
    func testJSONFeedNormalization() throws {
        // Given: A JSON Feed with one URL-backed item and one item without a URL
        let feed = try Self.parsedFeed(from: Self.jsonFeed)

        // When: Normalizing the parsed FeedKit model
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: JSON Feed metadata and URL-backed items should be preserved
        #expect(data.title == "JSON Feed Title")
        #expect(data.summary == "JSON Feed Description")
        #expect(data.items.count == 1)
        #expect(data.items[0].title == "JSON Item One")
        #expect(data.items[0].link == "https://example.com/json/one")
        #expect(data.items[0].publishDate == Self.jsonItemDate)
    }

    // MARK: - Edge Cases & Concurrency

    @Test("Normalize RSS feed with missing metadata")
    func testRSSFeedMissingMetadata() throws {
        // Given: An RSS feed with no channel title or description
        let fixture = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <item>
                    <link>https://example.com/item</link>
                </item>
            </channel>
        </rss>
        """
        let feed = try Self.parsedFeed(from: fixture)

        // When: Normalizing
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Title and summary should be nil
        #expect(data.title == nil)
        #expect(data.summary == nil)
        #expect(data.items.count == 1)
    }

    @Test("Normalize Atom feed with no summary source")
    func testAtomFeedNoSummarySource() throws {
        // Given: An Atom feed with no subtitle and no rights
        let fixture = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
            <title>Title</title>
        </feed>
        """
        let feed = try Self.parsedFeed(from: fixture)

        // When: Normalizing
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Summary should be an empty string (as per implementation)
        #expect(data.summary == "")
    }

    @Test("Normalize JSON Feed with missing metadata")
    func testJSONFeedMissingMetadata() throws {
        // Given: A JSON Feed with no title or description
        let fixture = """
        {
            "version": "https://jsonfeed.org/version/1.1",
            "items": []
        }
        """
        let feed = try Self.parsedFeed(from: fixture)

        // When: Normalizing
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Title and summary should be nil
        #expect(data.title == nil)
        #expect(data.summary == nil)
        #expect(data.items.isEmpty)
    }

    @Test("ParsedFeedData is Sendable")
    func testSendableConformance() async {
        // Given: A normalized feed data
        let data = ParsedFeedData(
            title: "Title",
            summary: "Summary",
            items: []
        )

        // Then: It can be passed into a Task (Sendable requirement)
        let result = await Task {
            let captured = data
            return captured.title
        }.value

        #expect(result == "Title")
    }

    @Test("Normalize RSS feed with nil items")
    func testRSSFeedNilItems() throws {
        // Given: An RSS feed XML without any items
        let fixture = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <title>No Items</title>
            </channel>
        </rss>
        """
        let feed = try Self.parsedFeed(from: fixture)

        // When: Normalizing
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Items should be empty array (covered by ?? [])
        #expect(data.items.isEmpty)
    }

    @Test("Normalize Atom feed with nil entries")
    func testAtomFeedNilEntries() throws {
        // Given: An Atom feed XML without any entries
        let fixture = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
            <title>No Entries</title>
        </feed>
        """
        let feed = try Self.parsedFeed(from: fixture)

        // When: Normalizing
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Items should be empty array (covered by ?? [])
        #expect(data.items.isEmpty)
    }

    @Test("Normalize JSON Feed with nil items")
    func testJSONFeedNilItems() throws {
        // Given: A JSON Feed without items key
        let fixture = """
        {
            "version": "https://jsonfeed.org/version/1.1",
            "title": "No Items"
        }
        """
        let feed = try Self.parsedFeed(from: fixture)

        // When: Normalizing
        let data = ParsedFeedData(parsedFeed: feed)

        // Then: Items should be empty array (covered by ?? [])
        #expect(data.items.isEmpty)
    }
}

// MARK: - Helpers

// Shared parser fixtures and expected values used by the normalization tests.
// Glossary: A fixture is fixed sample input used by a test.
// Here, fixtures are inline RSS, Atom, and JSON Feed documents parsed by FeedKit.
private extension ParsedFeedDataTests {

    // All fixtures use 2024-01-01T00:00:00Z so date expectations stay readable.
    static let rssItemDate = Date(timeIntervalSince1970: 1_704_067_200)
    static let atomEntryDate = Date(timeIntervalSince1970: 1_704_067_200)
    static let jsonItemDate = Date(timeIntervalSince1970: 1_704_067_200)

    // Parses inline RSS, Atom, or JSON Feed fixtures through FeedKit so tests
    // exercise the same input shape used by ParsedFeedData in production.
    static func parsedFeed(from fixture: String) throws -> FeedKit.Feed {
        let parser = FeedParser(data: Data(fixture.utf8))
        let result = parser.parse()

        switch result {
        case .success(let feed):
            return feed
        case .failure(let error):
            throw error
        }
    }

    static let rssFeedXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
        <channel>
            <title>RSS Feed Title</title>
            <description>RSS Feed Description</description>
            <item>
                <title>RSS Item One</title>
                <link>https://example.com/rss/one</link>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
            </item>
            <item>
                <title>RSS Item Without Link</title>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
            </item>
            <item>
                <link>https://example.com/rss/two</link>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
            </item>
        </channel>
    </rss>
    """

    static let atomFeedXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Atom Feed Title</title>
        <subtitle>Atom Feed Subtitle</subtitle>
        <entry>
            <title>Atom Entry One</title>
            <link href="https://example.com/atom/one" />
            <published>2024-01-01T00:00:00Z</published>
        </entry>
        <entry>
            <title>Atom Entry Without Link</title>
            <published>2024-01-01T00:00:00Z</published>
        </entry>
    </feed>
    """

    static let atomFeedWithRightsXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Atom Rights Feed</title>
        <rights>Copyright Example</rights>
    </feed>
    """

    static let jsonFeed = """
    {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "JSON Feed Title",
        "description": "JSON Feed Description",
        "items": [
            {
                "id": "one",
                "title": "JSON Item One",
                "url": "https://example.com/json/one",
                "date_published": "2024-01-01T00:00:00Z"
            },
            {
                "id": "two",
                "title": "JSON Item Without URL",
                "date_published": "2024-01-01T00:00:00Z"
            }
        ]
    }
    """
}
