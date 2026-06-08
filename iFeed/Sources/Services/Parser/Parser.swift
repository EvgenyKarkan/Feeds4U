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
@MainActor
protocol ParserDelegateProtocol: AnyObject {
    /// Called synchronously before parsing begins.
    func didStartParsingFeed()
    /// Called on the main actor when the feed has been successfully parsed.
    func didEndParsingFeed(with data: ParsedFeedData)
    /// Called on the main actor when parsing fails.
    func didFailParsingFeed(with error: any Error)
    /// Called on the main actor when parsing is cancelled.
    func didCancelParsingFeed()
}

extension ParserDelegateProtocol {
    func didStartParsingFeed() {}
    func didCancelParsingFeed() {}
}

// MARK: - ParserProtocol
/// Public interface for triggering feed parsing and assigning a delegate.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ParserProtocol {
    /// Starts asynchronous parsing of the feed at the given URL.
    func beginParsingURL(_ url: URL)
    /// Assigns the delegate that receives parsing callbacks.
    func setDelegate(_ delegate: any ParserDelegateProtocol)
    /// Cancels any in-flight parsing operation.
    func cancelParsing()
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
/// RSS/Atom/JSON feed parser that wraps `FeedKit` and delivers results via ``ParserDelegateProtocol``.
///
/// Parsing runs on a dedicated serial queue (`com.iFeed.parser`) and results are dispatched back to the main actor.
/// This class is isolated to the `@MainActor` to ensure thread-safe delegate access and task management.
/// A ``FeedParserFactory`` closure (injectable for testing) creates the underlying ``FeedParsing`` instance per URL.
@MainActor
final class Parser {
    // MARK: - Properties
    /// Global concurrent queue for parsing.
    /// Allows multiple feeds to parse in parallel,
    /// leveraging modern multi-core performance while avoiding UI thread blocking.
    private static let parsingQueue = DispatchQueue.global(qos: .userInitiated)

    private let parserFactory: FeedParserFactory

    /// Versioning token for the active task.
    /// Prevents a race condition where a cancelled task could accidentally nil out
    /// a newly started task's reference, losing the ability to cancel the new one.
    private var taskVersion: Int = 0
    private var activeTask: Task<Void, Never>?

    /// Parser does not own its delegate — prevents retain cycles with the owning Interactor.
    private(set) weak var delegate: (any ParserDelegateProtocol)?

    // MARK: - Init
    /// `parserFactory` is a stored closure: (URL) -> FeedParsing.
    /// Each time `beginParsingURL(_:)` is called, this closure is invoked with the URL to produce a fresh parser.
    ///
    /// The `= { FeedParser(URL: $0) }` part is a default argument — if no closure is provided,
    /// Swift uses this one automatically. `$0` is shorthand for the closure's first parameter (the URL).
    /// So `Parser()` in production is equivalent to `Parser(parserFactory: { url in FeedParser(URL: url) })`.
    ///
    /// Tests pass their own closure — `Parser(parserFactory: { _ in mock })` — to return a mock instead.
    init(parserFactory: @escaping FeedParserFactory = { return FeedParser(URL: $0) }) {
        self.parserFactory = parserFactory
    }

    /// Automatic cleanup on deinit.
    /// Ensures that if the `Parser` (and its owning Interactor/Module) is dismissed,
    /// all background work and network requests are immediately stopped to save battery and CPU.
    deinit {
        activeTask?.cancel()
    }
}

// MARK: - Public API, ParserProtocol
extension Parser: ParserProtocol {

    func beginParsingURL(_ url: URL) {
        // 1. Cancel any previous request for this parser instance
        cancelParsing()

        // 2. Notify start on main actor
        delegate?.didStartParsingFeed()

        // 3. Increment version to uniquely identify this specific parse attempt
        taskVersion += 1
        let currentVersion = taskVersion
        let factory = parserFactory

        // 4. Create a new managed task
        activeTask = Task { [weak self] in
            // Bridge FeedKit's closure-based API to a Sendable result.
            // We run this bridge on the global concurrent queue.
            let result: Result<ParsedFeedData, any Error> = await withCheckedContinuation { continuation in
                let parser = factory(url)
                parser.parseAsync(queue: Self.parsingQueue) { parserResult in
                    switch parserResult {
                    case .success(let feed):
                        continuation.resume(returning: .success(ParsedFeedData(parsedFeed: feed)))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }
            }

            // 5. Check for cancellation before delivering results
            guard !Task.isCancelled else {
                self?.handleCompletion(version: currentVersion, wasCancelled: true)
                return
            }

            // 6. Deliver results on MainActor
            switch result {
            case .success(let data):
                self?.delegate?.didEndParsingFeed(with: data)
            case .failure(let error):
                self?.delegate?.didFailParsingFeed(with: error)
            }

            self?.handleCompletion(version: currentVersion, wasCancelled: false)
        }
    }

    func setDelegate(_ delegate: any ParserDelegateProtocol) {
        self.delegate = delegate
    }

    func cancelParsing() {
        activeTask?.cancel()
        activeTask = nil
    }
}

// MARK: - Private
private extension Parser {
    /// Atomic completion handler.
    /// Safely cleans up the `activeTask` reference only if it still belongs to this
    /// specific parse version, ensuring we don't nil out a newer Task started in the meantime.
    func handleCompletion(version: Int, wasCancelled: Bool) {
        if wasCancelled {
            delegate?.didCancelParsingFeed()
        }

        if taskVersion == version {
            activeTask = nil
        }
    }
}
