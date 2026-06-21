//
//  OPMLParserTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 20.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

@Suite("OPMLParser Tests")
struct OPMLParserTests {

    private func data(_ xml: String) throws -> Data {
        try #require(xml.data(using: .utf8))
    }

    @Test func flatOPML_returnsAllFeedURLs() throws {
        // Given
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <body>
            <outline type="rss" text="A" xmlUrl="https://a.example.com/rss"/>
            <outline type="rss" text="B" xmlUrl="https://b.example.com/feed"/>
          </body>
        </opml>
        """
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls == ["https://a.example.com/rss", "https://b.example.com/feed"])
    }

    @Test func nestedFolders_areFlattened_allURLsReturned() throws {
        // Given — feeds live at different nesting depths; grouping is ignored.
        let xml = """
        <opml version="2.0"><body>
          <outline text="Tech">
            <outline type="rss" text="A" xmlUrl="https://a.example.com/rss"/>
            <outline text="Apple">
              <outline type="rss" text="B" xmlUrl="https://b.example.com/rss"/>
            </outline>
          </outline>
          <outline type="rss" text="C" xmlUrl="https://c.example.com/rss"/>
        </body></opml>
        """
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls == [
            "https://a.example.com/rss",
            "https://b.example.com/rss",
            "https://c.example.com/rss"
        ])
    }

    @Test func duplicateURLs_areDeduplicated_firstWins() throws {
        // Given
        let xml = """
        <opml><body>
          <outline type="rss" xmlUrl="https://a.example.com/rss"/>
          <outline type="rss" xmlUrl="https://a.example.com/rss"/>
        </body></opml>
        """
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls == ["https://a.example.com/rss"])
    }

    @Test func caseInsensitiveAttribute_isAccepted() throws {
        // Given — some exporters write XMLURL / xmlurl instead of xmlUrl.
        let xml = """
        <opml><body>
          <outline type="rss" XMLURL="https://a.example.com/rss"/>
        </body></opml>
        """
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls == ["https://a.example.com/rss"])
    }

    @Test func folderOutlinesWithoutXmlUrl_areIgnored() throws {
        // Given
        let xml = """
        <opml><body>
          <outline text="Folder only, no feed"/>
          <outline type="rss" xmlUrl="https://a.example.com/rss"/>
        </body></opml>
        """
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls == ["https://a.example.com/rss"])
    }

    @Test func invalidURLs_areFilteredOut() throws {
        // Given — non-web schemes and garbage must not be imported.
        let xml = """
        <opml><body>
          <outline type="rss" xmlUrl="not a url"/>
          <outline type="rss" xmlUrl="javascript:alert(1)"/>
          <outline type="rss" xmlUrl="https://good.example.com/rss"/>
        </body></opml>
        """
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls == ["https://good.example.com/rss"])
    }

    @Test func whitespaceAroundURL_isTrimmed() throws {
        // Given
        let xml = """
        <opml><body>
          <outline type="rss" xmlUrl="  https://a.example.com/rss  "/>
        </body></opml>
        """
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls == ["https://a.example.com/rss"])
    }

    @Test func malformedXML_returnsEmpty() throws {
        // Given
        let xml = "<opml><body><outline xmlUrl=\"https://a.example.com/rss\""
        let sut = OPMLParser()

        // When
        let urls = try sut.feedURLs(from: data(xml))

        // Then
        #expect(urls.isEmpty)
    }

    @Test func emptyData_returnsEmpty() {
        // Given
        let sut = OPMLParser()

        // When
        let urls = sut.feedURLs(from: Data())

        // Then
        #expect(urls.isEmpty)
    }
}
