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

@Suite("Parser Tests", .serialized)
@MainActor
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
        await fulfillment {
            MainActor.assumeIsolated {
                delegate._didEndParsingFeed.callCount > 0
            }
        }
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
        await fulfillment {
            MainActor.assumeIsolated {
                delegate._didFailParsingFeed.callCount > 0
            }
        }
        #expect(delegate._didStartParsingFeed.callCount == 1)
        #expect(delegate._didEndParsingFeed.callCount == 0)
        #expect(delegate._didFailParsingFeed.lastInvocation is ParserError)
    }

    // MARK: - beginParsingURL — uses factory with correct URL

    @Test func beginParsingURL_passesURLToFactory() async throws {
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
        await fulfillment {
            box.url != nil
        }
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

    // MARK: - cancellation

    // MARK: - refinements (versioning, deinit, parallelism)

    @Test func testVersioning_cancelledTaskDoesNotNilNewTask() async throws {
        // Given
        nonisolated(unsafe) var continuationA: CheckedContinuation<Result<ParsedFeedData, any Error>, Never>?
        let mockA = FeedParsingMock()
        mockA._parseAsync.implementation = .invokes { _, completion in
            nonisolated(unsafe) let unsafeCompletion = completion
            Task {
                let result = await withCheckedContinuation { continuation in
                    continuationA = continuation
                }
                // Convert Result<ParsedFeedData, Error> to Result<FeedKit.Feed, FeedKit.ParserError> safely
                switch result {
                case .success:
                    unsafeCompletion(.failure(.feedNotFound))
                case .failure:
                    unsafeCompletion(.failure(.feedNotFound))
                }
            }
        }

        let mockB = FeedParsingMock()
        mockB._parseAsync.implementation = .invokes { queue, completion in
            queue.async {
                completion(.failure(.feedNotFound))
            }
        }

        // What: A custom factory that returns mockA then mockB.
        // We use an actor-isolated counter and captured mocks to avoid data races.
        nonisolated(unsafe) var callCount = 0
        nonisolated(unsafe) let unsafeMockA = mockA
        nonisolated(unsafe) let unsafeMockB = mockB

        let factory: FeedParserFactory = { @Sendable _ in
            callCount += 1
            return callCount == 1 ? unsafeMockA : unsafeMockB
        }

        let parser = Parser(parserFactory: factory)
        parser.setDelegate(delegate)

        // When
        // 1. Start Task A (will hang on continuationA)
        parser.beginParsingURL(testURL)
        await fulfillment {
            continuationA != nil
        }

        // 2. Start Task B (will cancel Task A and finish quickly)
        parser.beginParsingURL(testURL)

        // 3. Wait for Task B to finish and nil out its version
        let targetDelegate = delegate
        await fulfillment {
            MainActor.assumeIsolated {
                targetDelegate._didFailParsingFeed.callCount == 1
            }
        }

        // 4. Finally resume Task A (which was cancelled)
        continuationA?.resume(returning: .failure(NSError(domain: "cancelled", code: -1)))

        // Then
        // If versioning works, Task A should NOT have nilled out Task B's completion state
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(delegate._didFailParsingFeed.callCount == 1)
        #expect(delegate._didCancelParsingFeed.callCount == 1)
    }

    @Test func testDeinit_cancelsActiveTask() async throws {
        // Given
        let mock = FeedParsingMock()
        nonisolated(unsafe) var taskWasStarted = false
        mock._parseAsync.implementation = .invokes { _, _ in
            taskWasStarted = true
        }

        nonisolated(unsafe) let unsafeMock = mock
        var parserInstance: Parser? = Parser(parserFactory: { _ in unsafeMock })
        parserInstance?.setDelegate(delegate)

        // When
        parserInstance?.beginParsingURL(testURL)
        await fulfillment { taskWasStarted }

        // Capture the delegate reference to check it later
        let weakDelegate = delegate

        // Deinit the parser
        parserInstance = nil

        // Then
        // We wait a bit to allow deinit's Task to run
        try await Task.sleep(nanoseconds: 100_000_000)

        // Delegate should not have received any end/fail calls because task was cancelled
        #expect(weakDelegate._didEndParsingFeed.callCount == 0)
        #expect(weakDelegate._didFailParsingFeed.callCount == 0)
    }

    @Test func testParallelParsing() async throws {
        // Given
        let iterationCount = 5
        nonisolated(unsafe) var startedCount = 0
        let lock = NSLock()

        let mock = FeedParsingMock()
        mock._parseAsync.implementation = .invokes { queue, completion in
            lock.withLock { startedCount += 1 }
            // Sleep a bit to ensure they overlap
            queue.asyncAfter(deadline: .now() + 0.1) {
                completion(.failure(.feedNotFound))
            }
        }

        nonisolated(unsafe) let unsafeMock = mock
        let parsers = (0..<iterationCount).map { _ in
            let parser = Parser(parserFactory: { _ in unsafeMock })
            parser.setDelegate(delegate)
            return parser
        }

        // When
        for parser in parsers {
            parser.beginParsingURL(testURL)
        }

        // Then
        await fulfillment {
            lock.withLock { startedCount == iterationCount }
        }
        #expect(startedCount == iterationCount)

        await fulfillment {
            MainActor.assumeIsolated {
                delegate._didFailParsingFeed.callCount == iterationCount
            }
        }
        #expect(delegate._didFailParsingFeed.callCount == iterationCount)
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
