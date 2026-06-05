//
//  ParserTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 06.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

@preconcurrency import FeedKit
import Foundation
import Mocking
import Testing
@testable import iFeed

@Suite("Parser Tests")
struct ParserTests {

    // MARK: - Properties

    private let sut: Parser
    private let mockFeedParser: FeedParsingMock
    private let delegate: ParserDelegateProtocolMock
    private let testURL: URL

    // MARK: - Init

    init() throws {
        testURL = try #require(URL(string: "https://example.com/feed"))

        let mock = FeedParsingMock()
        mockFeedParser = mock
        nonisolated(unsafe) let unsafeMock = mock

        sut = Parser(parserFactory: { _ in unsafeMock })

        delegate = ParserDelegateProtocolMock()
        sut.setDelegate(delegate)
    }

    // MARK: - setDelegate

    @Test func setDelegate_setsDelegate() {
        // Given
        let parser = Parser()
        let newDelegate = ParserDelegateProtocolMock()

        // When
        parser.setDelegate(newDelegate)

        // Then
        #expect(parser.delegate === newDelegate)
    }

    // MARK: - beginParsingURL — success

    @Test func beginParsingURL_onSuccess_callsDidEndParsingFeedWithParsedData() async throws {
        // Given
        let feedData = Data(Self.rssFeedXML.utf8)
        let feedParser = FeedParser(data: feedData)
        let parsedFeed = try feedParser.parse().get()

        mockFeedParser._parseAsync.implementation = .invokes { queue, completion in
            queue.async {
                completion(.success(parsedFeed))
            }
        }

        // When
        sut.beginParsingURL(testURL)

        // Then
        await fulfillment { delegate._didEndParsingFeed.callCount > 0 }
        #expect(delegate._didStartParsingFeed.callCount == 1)
        let feedDataResult = delegate._didEndParsingFeed.lastInvocation
        #expect(feedDataResult?.title == "Test Feed")
        #expect(feedDataResult?.items.count == 1)
        #expect(feedDataResult?.items.first?.link == "https://example.com/one")
        #expect(delegate._didFailParsingFeed.callCount == 0)
    }

    // MARK: - beginParsingURL — failure

    @Test func beginParsingURL_onFailure_callsDidFailParsingFeedWithError() async {
        // Given
        mockFeedParser._parseAsync.implementation = .invokes { queue, completion in
            queue.async {
                completion(.failure(.feedNotFound))
            }
        }

        // When
        sut.beginParsingURL(testURL)

        // Then
        await fulfillment { delegate._didFailParsingFeed.callCount > 0 }
        #expect(delegate._didStartParsingFeed.callCount == 1)
        #expect(delegate._didEndParsingFeed.callCount == 0)
        #expect(delegate._didFailParsingFeed.lastInvocation is ParserError)
    }

    // MARK: - beginParsingURL — uses factory with correct URL

    @Test func beginParsingURL_passesURLToFactory() throws {
        // Given
        let box = URLBox()
        let parser = Parser(parserFactory: { url in
            box.url = url
            return FeedParsingMock()
        })
        parser.setDelegate(delegate)
        let expectedURL = try #require(URL(string: "https://example.com/specific-feed"))

        // When
        parser.beginParsingURL(expectedURL)

        // Then
        #expect(box.url == expectedURL)
    }

    // MARK: - beginParsingURL — calls didStartParsingFeed

    @Test func beginParsingURL_callsDidStartParsingFeed() {
        // Given
        #expect(delegate._didStartParsingFeed.callCount == 0)

        // When
        sut.beginParsingURL(testURL)

        // Then
        #expect(delegate._didStartParsingFeed.callCount == 1)
    }

    // MARK: - beginParsingURL — nil delegate does not crash

    @Test func beginParsingURL_withNilDelegate_doesNotCrash() {
        // Given
        let parser = Parser(parserFactory: { _ in FeedParsingMock() })

        // When / Then — no crash
        parser.beginParsingURL(testURL)
    }
}

// MARK: - Helpers

private extension ParserTests {

    func fulfillment(timeout: TimeInterval = 2, condition: @escaping @Sendable () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    static let rssFeedXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
        <channel>
            <title>Test Feed</title>
            <description>Test Description</description>
            <item>
                <title>Item One</title>
                <link>https://example.com/one</link>
                <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
            </item>
        </channel>
    </rss>
    """
}

// MARK: - URLBox

private final class URLBox: @unchecked Sendable {
    var url: URL?
}
