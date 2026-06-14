//
//  ParsedFeedItemDataTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 12.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation
import Testing
@testable import iFeed

// MARK: - ParsedFeedItemDataTests

@Suite("ParsedFeedItemData Tests")
// Verifies that FeedKit RSS, Atom, and JSON Feed item models are converted into
// app-owned ParsedFeedItemData values, including fallbacks and skipped items.
struct ParsedFeedItemDataTests {

    // MARK: - RSS

    @Test("Normalize RSS feed item data")
    func testRSSFeedItemNormalization() throws {
        // Given: An RSS item with title, link, and publication date
        let item = try Self.rssItem(at: 0)

        // When: Normalizing the RSS item
        let data = try #require(ParsedFeedItemData(rssFeedItem: item))

        // Then: Item fields should be preserved
        #expect(data.title == "RSS Item One")
        #expect(data.link == "https://example.com/rss/one")
        #expect(data.publishDate == Self.expectedDate)
        #expect(data.htmlContent == "<p>RSS body</p>")
    }

    @Test("Normalize RSS feed item with missing title")
    func testRSSFeedItemMissingTitleFallback() throws {
        // Given: An RSS item with a link but no title
        let item = try Self.rssItem(at: 1)

        // When: Normalizing the RSS item
        let data = try #require(ParsedFeedItemData(rssFeedItem: item))

        // Then: The fallback title should be used
        #expect(data.title == "N/A")
        #expect(data.link == "https://example.com/rss/two")
        #expect(data.publishDate == Self.expectedDate)
        #expect(data.htmlContent == nil)
    }

    @Test("Return nil for RSS feed item without link")
    func testRSSFeedItemWithoutLinkReturnsNil() throws {
        // Given: An RSS item without a link
        let item = try Self.rssItem(at: 2)

        // When: Normalizing the RSS item
        let data = ParsedFeedItemData(rssFeedItem: item)

        // Then: The item should be skipped
        #expect(data == nil)
    }

    // MARK: - Atom

    @Test("Normalize Atom feed entry data")
    func testAtomFeedEntryNormalization() throws {
        // Given: An Atom entry with title, link, and publication date
        let entry = try Self.atomEntry(at: 0)

        // When: Normalizing the Atom entry
        let data = try #require(ParsedFeedItemData(atomFeedItem: entry))

        // Then: Entry fields should be preserved
        #expect(data.title == "Atom Entry One")
        #expect(data.link == "https://example.com/atom/one")
        #expect(data.publishDate == Self.expectedDate)
        #expect(data.htmlContent == "<p>Atom body</p>")
    }

    @Test("Normalize Atom feed entry with missing title")
    func testAtomFeedEntryMissingTitleFallback() throws {
        // Given: An Atom entry with a link but no title
        let entry = try Self.atomEntry(at: 1)

        // When: Normalizing the Atom entry
        let data = try #require(ParsedFeedItemData(atomFeedItem: entry))

        // Then: The fallback title should be used
        #expect(data.title == "N/A")
        #expect(data.link == "https://example.com/atom/two")
        #expect(data.publishDate == Self.expectedDate)
        #expect(data.htmlContent == nil)
    }

    @Test("Return nil for Atom feed entry without link")
    func testAtomFeedEntryWithoutLinkReturnsNil() throws {
        // Given: An Atom entry without a link
        let entry = try Self.atomEntry(at: 2)

        // When: Normalizing the Atom entry
        let data = ParsedFeedItemData(atomFeedItem: entry)

        // Then: The entry should be skipped
        #expect(data == nil)
    }

    // MARK: - JSON Feed

    @Test("Normalize JSON Feed item data")
    func testJSONFeedItemNormalization() throws {
        // Given: A JSON Feed item with title, URL, and publication date
        let item = try Self.jsonFeedItem(at: 0)

        // When: Normalizing the JSON Feed item
        let data = try #require(ParsedFeedItemData(jsonFeedItem: item))

        // Then: Item fields should be preserved
        #expect(data.title == "JSON Item One")
        #expect(data.link == "https://example.com/json/one")
        #expect(data.publishDate == Self.expectedDate)
        #expect(data.htmlContent == "<p>JSON body</p>")
    }

    @Test("Normalize JSON Feed item with missing title")
    func testJSONFeedItemMissingTitleFallback() throws {
        // Given: A JSON Feed item with a URL but no title
        let item = try Self.jsonFeedItem(at: 1)

        // When: Normalizing the JSON Feed item
        let data = try #require(ParsedFeedItemData(jsonFeedItem: item))

        // Then: The fallback title should be used
        #expect(data.title == "N/A")
        #expect(data.link == "https://example.com/json/two")
        #expect(data.publishDate == Self.expectedDate)
        #expect(data.htmlContent == nil)
    }

    @Test("Return nil for JSON Feed item without URL")
    func testJSONFeedItemWithoutURLReturnsNil() throws {
        // Given: A JSON Feed item without a URL
        let item = try Self.jsonFeedItem(at: 2)

        // When: Normalizing the JSON Feed item
        let data = ParsedFeedItemData(jsonFeedItem: item)

        // Then: The item should be skipped
        #expect(data == nil)
    }

    // MARK: - Edge Cases & Concurrency

    @Test("Fallback to 'now' when RSS publication date is missing")
    func testRSSFeedItemMissingDateFallback() throws {
        // Given: An RSS item with a link but no publication date
        let fixture = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <item>
                    <title>No Date</title>
                    <link>https://example.com/no-date</link>
                </item>
            </channel>
        </rss>
        """
        let feed = try Self.parsedFeed(from: fixture)
        guard case .rss(let rssFeed) = feed, let item = rssFeed.items?.first else {
            throw TestFixtureError.unexpectedFeedType
        }

        // When: Normalizing the RSS item
        let now = Date()
        let data = try #require(ParsedFeedItemData(rssFeedItem: item))

        // Then: The publication date should be close to 'now'
        #expect(abs(data.publishDate.timeIntervalSince(now)) < 1.0)
    }

    @Test("Fallback to 'now' when Atom publication date is missing")
    func testAtomFeedEntryMissingDateFallback() throws {
        // Given: An Atom entry with a link but no publication date
        let fixture = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
            <entry>
                <title>No Date</title>
                <link href="https://example.com/no-date" />
            </entry>
        </feed>
        """
        let feed = try Self.parsedFeed(from: fixture)
        guard case .atom(let atomFeed) = feed, let entry = atomFeed.entries?.first else {
            throw TestFixtureError.unexpectedFeedType
        }

        // When: Normalizing the Atom entry
        let now = Date()
        let data = try #require(ParsedFeedItemData(atomFeedItem: entry))

        // Then: The publication date should be close to 'now'
        #expect(abs(data.publishDate.timeIntervalSince(now)) < 1.0)
    }

    @Test("Fallback to 'now' when JSON Feed publication date is missing")
    func testJSONFeedItemMissingDateFallback() throws {
        // Given: A JSON Feed item with a URL but no publication date
        let fixture = """
        {
            "version": "https://jsonfeed.org/version/1.1",
            "items": [
                {
                    "id": "no-date",
                    "title": "No Date",
                    "url": "https://example.com/no-date"
                }
            ]
        }
        """
        let feed = try Self.parsedFeed(from: fixture)
        guard case .json(let jsonFeed) = feed, let item = jsonFeed.items?.first else {
            throw TestFixtureError.unexpectedFeedType
        }

        // When: Normalizing the JSON Feed item
        let now = Date()
        let data = try #require(ParsedFeedItemData(jsonFeedItem: item))

        // Then: The publication date should be close to 'now'
        #expect(abs(data.publishDate.timeIntervalSince(now)) < 1.0)
    }

    @Test("ParsedFeedItemData is Sendable")
    func testSendableConformance() async {
        // Given: A normalized item data
        let data = ParsedFeedItemData(
            title: "Title",
            link: "https://example.com",
            publishDate: Date(),
            htmlContent: "Content"
        )

        // Then: It can be passed into a Task (Sendable requirement)
        let result = await Task {
            let captured = data
            return captured.title
        }.value

        #expect(result == "Title")
    }
}

// MARK: - Helpers

// Shared FeedKit parsing helpers and fixed feed documents used by item tests.
// Glossary: A fixture is fixed sample input used by a test. Here, fixtures are
// inline RSS, Atom, and JSON Feed documents parsed by FeedKit.
private extension ParsedFeedItemDataTests {

    // All fixtures use 2024-01-01T00:00:00Z so date expectations stay readable.
    static let expectedDate = Date(timeIntervalSince1970: 1_704_067_200)

    // Parses an inline fixture through FeedKit so tests exercise the concrete
    // RSSFeedItem, AtomFeedEntry, and JSONFeedItem values used in production.
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

    static func rssItem(at index: Int) throws -> RSSFeedItem {
        let feed = try parsedFeed(from: rssFeedXML)

        guard case .rss(let rssFeed) = feed else {
            Issue.record("Expected RSS feed")
            throw TestFixtureError.unexpectedFeedType
        }

        return try #require(rssFeed.items?[index])
    }

    static func atomEntry(at index: Int) throws -> AtomFeedEntry {
        let feed = try parsedFeed(from: atomFeedXML)

        guard case .atom(let atomFeed) = feed else {
            Issue.record("Expected Atom feed")
            throw TestFixtureError.unexpectedFeedType
        }

        return try #require(atomFeed.entries?[index])
    }

    static func jsonFeedItem(at index: Int) throws -> JSONFeedItem {
        let feed = try parsedFeed(from: jsonFeed)

        guard case .json(let jsonFeed) = feed else {
            Issue.record("Expected JSON Feed")
            throw TestFixtureError.unexpectedFeedType
        }

        return try #require(jsonFeed.items?[index])
    }

    enum TestFixtureError: Error {
        case unexpectedFeedType
    }

    static let rssFeedXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel>
            <title>RSS Feed Title</title>
            <description>RSS Feed Description</description>
            <item>
                <title>RSS Item One</title>
                <link>https://example.com/rss/one</link>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
                <content:encoded>&lt;p&gt;RSS body&lt;/p&gt;</content:encoded>
            </item>
            <item>
                <link>https://example.com/rss/two</link>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
            </item>
            <item>
                <title>RSS Item Without Link</title>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
            </item>
        </channel>
    </rss>
    """

    static let atomFeedXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
        <title>Atom Feed Title</title>
        <entry>
            <title>Atom Entry One</title>
            <link href="https://example.com/atom/one" />
            <content type="html">&lt;p&gt;Atom body&lt;/p&gt;</content>
            <published>2024-01-01T00:00:00Z</published>
        </entry>
        <entry>
            <link href="https://example.com/atom/two" />
            <published>2024-01-01T00:00:00Z</published>
        </entry>
        <entry>
            <title>Atom Entry Without Link</title>
            <published>2024-01-01T00:00:00Z</published>
        </entry>
    </feed>
    """

    static let jsonFeed = """
    {
        "version": "https://jsonfeed.org/version/1.1",
        "title": "JSON Feed Title",
        "items": [
            {
                "id": "one",
                "title": "JSON Item One",
                "url": "https://example.com/json/one",
                "date_published": "2024-01-01T00:00:00Z",
                "content_html": "<p>JSON body</p>"
            },
            {
                "id": "two",
                "url": "https://example.com/json/two",
                "date_published": "2024-01-01T00:00:00Z"
            },
            {
                "id": "three",
                "title": "JSON Item Without URL",
                "date_published": "2024-01-01T00:00:00Z"
            }
        ]
    }
    """
}
