//
//  ParseContinuationBox.swift
//  iFeed
//
//  Created by Evgeny Karkan on 11.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Synchronization
#if DEBUG
import Mocking
#endif

/// Continuation used by ``Parser`` to bridge FeedKit's callback API into async/await.
///
/// A `nil` result means "cancelled before the parser produced anything".
typealias ParseContinuation = CheckedContinuation<Result<ParsedFeedData, any Error>?, Never>

// MARK: - ParseContinuationBoxing

/// Owns a parse-bridging continuation and guarantees it is resumed exactly once.
///
/// Abstracted behind a protocol so ``Parser`` receives it as an injected
/// dependency (via ``ParseContinuationBoxFactory``) and tests can mock it.
/// `Sendable` because the box is shared between the continuation body and the
/// task-cancellation handler, which may fire on another thread.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol ParseContinuationBoxing: Sendable {
    /// Stores the continuation; implementations must resume it immediately
    /// when cancellation already won the race.
    func store(_ continuation: ParseContinuation)

    /// Resumes the stored continuation once; subsequent calls must be no-ops.
    func resume(returning result: Result<ParsedFeedData, any Error>?)
}

/// A closure that creates a fresh ``ParseContinuationBoxing`` for one parse attempt.
///
/// A box is single-use by design (resume-once), so ``Parser`` needs a new
/// instance per `beginParsingURL(_:)` call. Tests inject a closure returning a mock.
typealias ParseContinuationBoxFactory = @Sendable () -> any ParseContinuationBoxing

// MARK: - ParseContinuationBox

/// Production ``ParseContinuationBoxing`` implementation.
///
/// The continuation is held here — not only inside FeedKit's result callback —
/// so that cancelling the task can resume (and thereby free) it even when the
/// underlying parser never invokes its callback (hung request, inert parser).
/// Without this, `cancelParsing()`/`deinit` would leave the task suspended
/// forever and the runtime would report
/// "SWIFT TASK CONTINUATION MISUSE: leaked its continuation".
final class ParseContinuationBox: ParseContinuationBoxing {

    private struct State {
        var continuation: ParseContinuation?
        /// Set when the cancellation handler fired before ``store(_:)`` ran.
        var wasCancelledBeforeStore = false
        /// Set once the continuation has been resumed — later resumes are ignored.
        var isDone = false
    }

    private let state = Mutex(State())

    /// Stores the continuation; resumes it immediately when cancellation won the race.
    func store(_ continuation: ParseContinuation) {
        let resumeNow = state.withLock { state -> Bool in
            if state.wasCancelledBeforeStore && !state.isDone {
                state.isDone = true
                return true
            }
            state.continuation = continuation
            return false
        }

        if resumeNow {
            continuation.resume(returning: nil)
        }
    }

    /// Resumes the stored continuation once; subsequent calls are no-ops
    /// (e.g. a late FeedKit callback after the parse was already cancelled).
    func resume(returning result: Result<ParsedFeedData, any Error>?) {
        let continuation = state.withLock { state -> ParseContinuation? in
            guard !state.isDone else {
                return nil
            }
            guard let stored = state.continuation else {
                /// Cancellation fired before the continuation was stored —
                /// remember it so ``store(_:)`` resumes immediately.
                state.wasCancelledBeforeStore = true
                return nil
            }
            state.isDone = true
            state.continuation = nil
            return stored
        }

        continuation?.resume(returning: result)
    }
}
