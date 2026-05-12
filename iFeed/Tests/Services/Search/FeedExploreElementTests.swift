//
//  FeedExploreElementTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 21.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

// MARK: - FeedExploreElementTests

@Suite("FeedExploreElement Tests")
struct FeedExploreElementTests {

    // MARK: - Decoding Success Cases

    @Test("Decode FeedExploreElement with all fields populated")
    func testDecodeWithAllFields() async throws {
        // Given: JSON with all fields
        let json = """
        {
            "description": "A comprehensive RSS feed",
            "favicon": "https://example.com/favicon.ico",
            "self_url": "https://example.com/feed/self",
            "site_name": "Example Site",
            "site_url": "https://example.com",
            "title": "Example Feed Title",
            "url": "https://example.com/feed"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: All fields should be populated correctly
        #expect(element.description == "A comprehensive RSS feed")
        #expect(element.favicon == "https://example.com/favicon.ico")
        #expect(element.selfURL == "https://example.com/feed/self")
        #expect(element.siteName == "Example Site")
        #expect(element.siteURL == "https://example.com")
        #expect(element.title == "Example Feed Title")
        #expect(element.url == "https://example.com/feed")
    }

    @Test("Decode FeedExploreElement with minimal fields")
    func testDecodeWithMinimalFields() async throws {
        // Given: JSON with only required structure (all fields are optional)
        let json = """
        {
            "title": "Minimal Feed"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Should succeed with only title populated
        #expect(element.title == "Minimal Feed")
        #expect(element.description == nil)
        #expect(element.favicon == nil)
        #expect(element.selfURL == nil)
        #expect(element.siteName == nil)
        #expect(element.siteURL == nil)
        #expect(element.url == nil)
    }

    @Test("Decode FeedExploreElement with all fields nil")
    func testDecodeWithAllFieldsNil() async throws {
        // Given: JSON with all fields explicitly set to null
        let json = """
        {
            "description": null,
            "favicon": null,
            "self_url": null,
            "site_name": null,
            "site_url": null,
            "title": null,
            "url": null
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: All fields should be nil
        #expect(element.description == nil)
        #expect(element.favicon == nil)
        #expect(element.selfURL == nil)
        #expect(element.siteName == nil)
        #expect(element.siteURL == nil)
        #expect(element.title == nil)
        #expect(element.url == nil)
    }

    @Test("Decode FeedExploreElement with empty object")
    func testDecodeEmptyObject() async throws {
        // Given: Empty JSON object
        let json = "{}"

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: All fields should be nil (all are optional)
        #expect(element.description == nil)
        #expect(element.favicon == nil)
        #expect(element.selfURL == nil)
        #expect(element.siteName == nil)
        #expect(element.siteURL == nil)
        #expect(element.title == nil)
        #expect(element.url == nil)
    }

    @Test("Decode FeedExploreElement with partial fields")
    func testDecodeWithPartialFields() async throws {
        // Given: JSON with subset of fields
        let json = """
        {
            "title": "Tech Blog",
            "url": "https://techblog.com/feed",
            "site_name": "Tech Blog"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Only specified fields should be populated
        #expect(element.title == "Tech Blog")
        #expect(element.url == "https://techblog.com/feed")
        #expect(element.siteName == "Tech Blog")
        #expect(element.description == nil)
        #expect(element.favicon == nil)
        #expect(element.selfURL == nil)
        #expect(element.siteURL == nil)
    }

    // MARK: - CodingKeys Tests

    @Test("CodingKeys map correctly from snake_case to camelCase")
    func testCodingKeysMapping() async throws {
        // Given: JSON with snake_case keys (API format)
        let json = """
        {
            "self_url": "https://example.com/self",
            "site_name": "Example",
            "site_url": "https://example.com"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Snake_case keys should map to camelCase properties
        #expect(element.selfURL == "https://example.com/self")
        #expect(element.siteName == "Example")
        #expect(element.siteURL == "https://example.com")
    }

    @Test("Verify all CodingKeys are defined correctly")
    func testAllCodingKeys() {
        // Given: FeedExploreElement.CodingKeys enum
        let codingKeys = FeedExploreElement.CodingKeys.self

        // Then: Verify all keys exist and have correct raw values
        #expect(codingKeys.description.rawValue == "description")
        #expect(codingKeys.favicon.rawValue == "favicon")
        #expect(codingKeys.selfURL.rawValue == "self_url")
        #expect(codingKeys.siteName.rawValue == "site_name")
        #expect(codingKeys.siteURL.rawValue == "site_url")
        #expect(codingKeys.title.rawValue == "title")
        #expect(codingKeys.url.rawValue == "url")
    }

    // MARK: - Decoding Array (FeedExploreDTO)

    @Test("Decode FeedExploreDTO with multiple elements")
    func testDecodeFeedExploreDTO() async throws {
        // Given: JSON array with multiple feed elements
        let json = """
        [
            {
                "title": "Feed 1",
                "url": "https://example1.com/feed",
                "site_name": "Site 1"
            },
            {
                "title": "Feed 2",
                "url": "https://example2.com/feed",
                "site_name": "Site 2"
            },
            {
                "title": "Feed 3",
                "url": "https://example3.com/feed"
            }
        ]
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON array as FeedExploreDTO
        let dto = try decoder.decode(FeedExploreDTO.self, from: jsonData)

        // Then: Should decode all elements correctly
        #expect(dto.count == 3)
        #expect(dto[0].title == "Feed 1")
        #expect(dto[0].url == "https://example1.com/feed")
        #expect(dto[0].siteName == "Site 1")
        #expect(dto[1].title == "Feed 2")
        #expect(dto[2].title == "Feed 3")
        #expect(dto[2].siteName == nil)
    }

    @Test("Decode empty FeedExploreDTO array")
    func testDecodeEmptyDTO() async throws {
        // Given: Empty JSON array
        let json = "[]"

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding empty array
        let dto = try decoder.decode(FeedExploreDTO.self, from: jsonData)

        // Then: Should succeed with empty array
        #expect(dto.isEmpty)
        #expect(dto.count == 0)
    }

    // MARK: - Encoding Tests

    @Test("Encode FeedExploreElement with all fields")
    func testEncodeWithAllFields() async throws {
        // Given: FeedExploreElement with all fields populated
        let element = FeedExploreElement(
            description: "Test description",
            favicon: "https://example.com/icon.png",
            selfURL: "https://example.com/self",
            siteName: "Test Site",
            siteURL: "https://example.com",
            title: "Test Title",
            url: "https://example.com/feed"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]

        // When: Encoding element
        let jsonData = try encoder.encode(element)
        let jsonString = String(decoding: jsonData, as: UTF8.self)

        // Then: Should encode with correct snake_case keys
        #expect(jsonString.contains("\"description\""))
        #expect(jsonString.contains("\"favicon\""))
        #expect(jsonString.contains("\"self_url\""))
        #expect(jsonString.contains("\"site_name\""))
        #expect(jsonString.contains("\"site_url\""))
        #expect(jsonString.contains("\"title\""))
        #expect(jsonString.contains("\"url\""))

        // Verify values
        #expect(jsonString.contains("Test description"))
        #expect(jsonString.contains("Test Site"))
        #expect(jsonString.contains("Test Title"))
    }

    @Test("Encode and decode round-trip preserves data")
    func testRoundTripEncoding() async throws {
        // Given: Original element
        let original = FeedExploreElement(
            description: "Round trip test",
            favicon: "https://example.com/favicon.ico",
            selfURL: "https://example.com/feed/self",
            siteName: "Round Trip Site",
            siteURL: "https://example.com",
            title: "Round Trip Title",
            url: "https://example.com/feed"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // When: Encoding then decoding
        let jsonData = try encoder.encode(original)
        let decoded = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Decoded should match original
        #expect(decoded.description == original.description)
        #expect(decoded.favicon == original.favicon)
        #expect(decoded.selfURL == original.selfURL)
        #expect(decoded.siteName == original.siteName)
        #expect(decoded.siteURL == original.siteURL)
        #expect(decoded.title == original.title)
        #expect(decoded.url == original.url)
    }

    @Test("Encode FeedExploreElement with nil values")
    func testEncodeWithNilValues() async throws {
        // Given: Element with all nil values
        let element = FeedExploreElement(
            description: nil,
            favicon: nil,
            selfURL: nil,
            siteName: nil,
            siteURL: nil,
            title: nil,
            url: nil
        )

        let encoder = JSONEncoder()

        // When: Encoding element
        let jsonData = try encoder.encode(element)

        // Then: Should encode as object with null values or omitted keys
        // (JSONEncoder typically includes null values by default)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FeedExploreElement.self, from: jsonData)

        #expect(decoded.description == nil)
        #expect(decoded.favicon == nil)
        #expect(decoded.selfURL == nil)
        #expect(decoded.siteName == nil)
        #expect(decoded.siteURL == nil)
        #expect(decoded.title == nil)
        #expect(decoded.url == nil)
    }

    // MARK: - Edge Cases

    @Test("Decode with extra unknown fields")
    func testDecodeWithExtraFields() async throws {
        // Given: JSON with extra fields not in the model
        let json = """
        {
            "title": "Test Feed",
            "url": "https://example.com/feed",
            "unknown_field": "should be ignored",
            "another_field": 12345
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Should successfully decode known fields, ignoring unknown ones
        #expect(element.title == "Test Feed")
        #expect(element.url == "https://example.com/feed")
    }

    @Test("Decode with empty strings")
    func testDecodeWithEmptyStrings() async throws {
        // Given: JSON with empty string values
        let json = """
        {
            "title": "",
            "url": "",
            "description": "",
            "site_name": ""
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Empty strings should be preserved (not converted to nil)
        #expect(element.title == "")
        #expect(element.url == "")
        #expect(element.description == "")
        #expect(element.siteName == "")
    }

    @Test("Decode with whitespace strings")
    func testDecodeWithWhitespaceStrings() async throws {
        // Given: JSON with whitespace-only values
        let json = """
        {
            "title": "   ",
            "description": "\\t\\n",
            "site_name": " "
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Whitespace should be preserved
        #expect(element.title == "   ")
        #expect(element.description == "\t\n")
        #expect(element.siteName == " ")
    }

    @Test("Decode with special characters and Unicode")
    func testDecodeWithSpecialCharacters() async throws {
        // Given: JSON with special characters and Unicode
        let json = """
        {
            "title": "Tech Blog 🚀",
            "description": "A blog about technology & innovation",
            "site_name": "Café • Blog",
            "url": "https://example.com/feed?category=tech&lang=en"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Special characters should be preserved
        #expect(element.title == "Tech Blog 🚀")
        #expect(element.description == "A blog about technology & innovation")
        #expect(element.siteName == "Café • Blog")
        #expect(element.url == "https://example.com/feed?category=tech&lang=en")
    }

    @Test("Decode with very long strings")
    func testDecodeWithLongStrings() async throws {
        // Given: JSON with very long string values
        let longDescription = String(repeating: "A", count: 10000)
        let json = """
        {
            "title": "Test",
            "description": "\(longDescription)"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding JSON
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Long strings should be handled correctly
        #expect(element.title == "Test")
        #expect(element.description?.count == 10000)
        #expect(element.description == longDescription)
    }

    // MARK: - Error Cases

    @Test("Decode fails with invalid JSON")
    func testDecodeInvalidJSON() async throws {
        // Given: Invalid JSON
        let invalidJSON = "{ this is not valid JSON }"

        let jsonData = try #require(invalidJSON.data(using: .utf8))
        let decoder = JSONDecoder()

        // When/Then: Should throw decoding error
        #expect(throws: (any Error).self) {
            try decoder.decode(FeedExploreElement.self, from: jsonData)
        }
    }

    @Test("Decode fails with wrong type")
    func testDecodeWrongType() async throws {
        // Given: JSON where field has wrong type
        let json = """
        {
            "title": 12345
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When/Then: Should throw decoding error (title should be String, not Int)
        #expect(throws: (any Error).self) {
            try decoder.decode(FeedExploreElement.self, from: jsonData)
        }
    }

    @Test("Decode fails with array instead of object")
    func testDecodeArrayInsteadOfObject() async throws {
        // Given: JSON array instead of object
        let json = """
        ["not", "an", "object"]
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When/Then: Should throw decoding error
        #expect(throws: (any Error).self) {
            try decoder.decode(FeedExploreElement.self, from: jsonData)
        }
    }

    // MARK: - Computed Property Tests (rssURL)

    @Test("rssURL returns selfURL when both selfURL and url are present")
    func testRSSURLPrioritizesSelfURL() {
        // Given: Element with both selfURL and url
        let element = FeedExploreElement(
            description: nil,
            favicon: nil,
            selfURL: "https://example.com/feed/self",
            siteName: nil,
            siteURL: nil,
            title: nil,
            url: "https://example.com/feed"
        )

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return selfURL (priority)
        #expect(rssURL == "https://example.com/feed/self")
    }

    @Test("rssURL returns url when selfURL is nil")
    func testRSSURLFallbacksToURL() {
        // Given: Element with only url (selfURL is nil)
        let element = FeedExploreElement(
            description: nil,
            favicon: nil,
            selfURL: nil,
            siteName: nil,
            siteURL: nil,
            title: nil,
            url: "https://example.com/feed.xml"
        )

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return url as fallback
        #expect(rssURL == "https://example.com/feed.xml")
    }

    @Test("rssURL returns nil when both selfURL and url are nil")
    func testRSSURLReturnsNilWhenBothNil() {
        // Given: Element with both selfURL and url as nil
        let element = FeedExploreElement(
            description: "Test",
            favicon: nil,
            selfURL: nil,
            siteName: "Test Site",
            siteURL: nil,
            title: "Test Title",
            url: nil
        )

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return nil
        #expect(rssURL == nil)
    }

    @Test("rssURL returns nil for empty element")
    func testRSSURLWithEmptyElement() {
        // Given: Element with all fields nil
        let element = FeedExploreElement(
            description: nil,
            favicon: nil,
            selfURL: nil,
            siteName: nil,
            siteURL: nil,
            title: nil,
            url: nil
        )

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return nil
        #expect(rssURL == nil)
    }

    @Test("rssURL handles empty string in selfURL")
    func testRSSURLWithEmptySelfURL() {
        // Given: Element with empty selfURL and valid url
        let element = FeedExploreElement(
            description: nil,
            favicon: nil,
            selfURL: "",
            siteName: nil,
            siteURL: nil,
            title: nil,
            url: "https://example.com/feed"
        )

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return empty selfURL (it's not nil, so it has priority)
        #expect(rssURL == "")
    }

    @Test("rssURL handles empty string in url when selfURL is nil")
    func testRSSURLWithEmptyURL() {
        // Given: Element with nil selfURL and empty url
        let element = FeedExploreElement(
            description: nil,
            favicon: nil,
            selfURL: nil,
            siteName: nil,
            siteURL: nil,
            title: nil,
            url: ""
        )

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return empty string from url
        #expect(rssURL == "")
    }

    @Test("rssURL preserves exact URL format from selfURL")
    func testRSSURLPreservesExactFormat() {
        // Given: Element with complex URLs
        let selfURLValue = "https://feeds.example.com/feed?format=rss&category=tech&lang=en#main"
        let element = FeedExploreElement(
            description: nil,
            favicon: nil,
            selfURL: selfURLValue,
            siteName: nil,
            siteURL: nil,
            title: nil,
            url: "https://example.com/simple-feed"
        )

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should preserve exact selfURL format
        #expect(rssURL == selfURLValue)
    }

    @Test("rssURL works with decoded JSON using selfURL")
    func testRSSURLFromDecodedJSONWithSelfURL() async throws {
        // Given: JSON with both self_url and url
        let json = """
        {
            "title": "Test Feed",
            "url": "https://example.com/feed",
            "self_url": "https://example.com/feed/canonical"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return self_url
        #expect(rssURL == "https://example.com/feed/canonical")
    }

    @Test("rssURL works with decoded JSON using url fallback")
    func testRSSURLFromDecodedJSONWithURLFallback() async throws {
        // Given: JSON with only url (no self_url)
        let json = """
        {
            "title": "Test Feed",
            "url": "https://example.com/rss.xml"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return url as fallback
        #expect(rssURL == "https://example.com/rss.xml")
    }

    @Test("rssURL returns nil for decoded JSON with neither field")
    func testRSSURLFromDecodedJSONWithNoURLs() async throws {
        // Given: JSON without url or self_url
        let json = """
        {
            "title": "Feed Without URL",
            "description": "This feed has no URL fields"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // When: Accessing rssURL
        let rssURL = element.rssURL

        // Then: Should return nil
        #expect(rssURL == nil)
    }

    // MARK: - Real-World API Response Tests

    @Test("Decode typical feedsearch.dev API response")
    func testDecodeRealWorldResponse() async throws {
        // Given: Realistic API response from feedsearch.dev
        let json = """
        {
            "url": "https://daringfireball.net/feeds/main",
            "title": "Daring Fireball",
            "description": "By John Gruber",
            "site_url": "https://daringfireball.net/",
            "site_name": "Daring Fireball",
            "favicon": "https://daringfireball.net/graphics/favicon.ico",
            "self_url": "https://daringfireball.net/feeds/main"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding response
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: All fields should be correctly decoded
        #expect(element.url == "https://daringfireball.net/feeds/main")
        #expect(element.title == "Daring Fireball")
        #expect(element.description == "By John Gruber")
        #expect(element.siteURL == "https://daringfireball.net/")
        #expect(element.siteName == "Daring Fireball")
        #expect(element.favicon == "https://daringfireball.net/graphics/favicon.ico")
        #expect(element.selfURL == "https://daringfireball.net/feeds/main")
    }

    @Test("Decode API response with missing optional fields")
    func testDecodeIncompleteAPIResponse() async throws {
        // Given: API response with some fields missing (common in real world)
        let json = """
        {
            "url": "https://example.com/feed.xml",
            "title": "Example Feed"
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()

        // When: Decoding response
        let element = try decoder.decode(FeedExploreElement.self, from: jsonData)

        // Then: Available fields should be decoded, others should be nil
        #expect(element.url == "https://example.com/feed.xml")
        #expect(element.title == "Example Feed")
        #expect(element.description == nil)
        #expect(element.siteURL == nil)
        #expect(element.siteName == nil)
        #expect(element.favicon == nil)
        #expect(element.selfURL == nil)
    }
}
