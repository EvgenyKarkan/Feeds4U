//
//  Parser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation
import Dispatch
#if DEBUG
import Mocking
#endif

// MARK: - ParserDelegateProtocol

/// Delegate notified of feed parsing lifecycle events on the main actor.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol ParserDelegateProtocol: AnyObject {
    /// Called synchronously before parsing begins.
    func didStartParsingFeed()
    /// Called on the main actor when the feed has been successfully parsed.
    func didEndParsingFeed(with data: ParsedFeedData)
    /// Called on the main actor when parsing fails.
    func didFailParsingFeed(with error: any Error)
}

extension ParserDelegateProtocol {
    func didStartParsingFeed() {}
}

// MARK: - ParserProtocol

/// Public interface for triggering feed parsing and assigning a delegate.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol ParserProtocol {
    /// Starts asynchronous parsing of the feed at the given URL.
    func beginParsingURL(_ url: URL)
    /// Assigns the delegate that receives parsing callbacks.
    func setDelegate(_ delegate: any ParserDelegateProtocol)
}

// MARK: - FeedParsing

/// Abstraction over `FeedKit.FeedParser` to enable dependency injection and testing.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol FeedParsing {
    /// Parses the feed asynchronously on the given queue and delivers the result via closure.
    func parseAsync(queue: DispatchQueue, result: @escaping (Result<FeedKit.Feed, FeedKit.ParserError>) -> Void)
}

extension FeedParser: FeedParsing {}

/// Factory closure that creates a ``FeedParsing`` instance for a given feed URL.
typealias FeedParserFactory = @Sendable (URL) -> any FeedParsing

// MARK: - Parser class

/// Thread-safe RSS/Atom/JSON feed parser that wraps `FeedKit` and delivers results via ``ParserDelegateProtocol``.
///
/// Parsing runs on a dedicated serial queue (`com.iFeed.parser`) and results are dispatched back to the main actor.
/// A ``FeedParserFactory`` closure (injectable for testing) creates the underlying ``FeedParsing`` instance per URL.
final class Parser: @unchecked Sendable {
    // MARK: - Properties
    private static let parsingQueue = DispatchQueue(label: "com.iFeed.parser", qos: .userInitiated)
    private let parserFactory: FeedParserFactory
    // weak: Parser does not own its delegate — prevents retain cycles with the owning Interactor.
    weak var delegate: (any ParserDelegateProtocol)?

    // MARK: - Init

    // `parserFactory` is a stored closure: (URL) -> FeedParsing.
    // Each time `beginParsingURL(_:)` is called, this closure is invoked with the URL to produce a fresh parser.
    //
    // The `= { FeedParser(URL: $0) }` part is a default argument — if no closure is provided,
    // Swift uses this one automatically. `$0` is shorthand for the closure's first parameter (the URL).
    // So `Parser()` in production is equivalent to `Parser(parserFactory: { url in FeedParser(URL: url) })`.
    //
    // Tests pass their own closure — `Parser(parserFactory: { _ in mock })` — to return a mock instead.
    init(parserFactory: @escaping FeedParserFactory = { FeedParser(URL: $0) }) {
        self.parserFactory = parserFactory
    }
}

// MARK: - ParserProtocol, Public API
extension Parser: ParserProtocol {

    /// Internal result type that bridges the non-`Sendable` `FeedKit.Feed` across isolation boundaries.
    enum ParsedFeedResult: Sendable {
        case success(ParsedFeedData)
        case failure(any Error & Sendable)
    }

    func beginParsingURL(_ url: URL) {
        delegate?.didStartParsingFeed()

        let parser = parserFactory(url)

        // `parser` is intentionally captured strongly — it must stay alive until parseAsync completes.
        // No retain cycle: the closure is one-shot and released by FeedKit after firing.
        parser.parseAsync(queue: Self.parsingQueue) { result in
            let parsedResult: ParsedFeedResult

            switch result {
            case .success(let parsedFeed):
                parsedResult = .success(ParsedFeedData(parsedFeed: parsedFeed))
            case .failure(let error):
                parsedResult = .failure(error)
            }

            // [weak self]: avoids retaining Parser beyond its natural lifetime while the Task awaits dispatch.
            Task { @MainActor [weak self] in
                switch parsedResult {
                case .success(let feedData):
                    self?.delegate?.didEndParsingFeed(with: feedData)
                case .failure(let error):
                    self?.delegate?.didFailParsingFeed(with: error)
                }
            }
        }
    }

    func setDelegate(_ delegate: any ParserDelegateProtocol) {
        self.delegate = delegate
    }
}
