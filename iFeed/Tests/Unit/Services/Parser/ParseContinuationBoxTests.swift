//
//  ParseContinuationBoxTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 11.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

@Suite("ParseContinuationBox Tests")
struct ParseContinuationBoxTests {

    @Test func storeThenResume_deliversResultExactlyOnce() async throws {
        // Given
        let box = ParseContinuationBox()

        // When
        let result: Result<ParsedFeedData, any Error>? = await withCheckedContinuation { continuation in
            box.store(continuation)
            box.resume(returning: .success(ParsedFeedData(title: "T", summary: nil, items: [])))
            // A second resume must be silently ignored — resuming a checked
            // continuation twice would crash the process.
            box.resume(returning: nil)
        }

        // Then
        let parsed = try #require(try result?.get())
        #expect(parsed.title == "T")
    }

    @Test func resumeWithFailure_deliversError() async {
        // Given
        let box = ParseContinuationBox()

        // When
        let result: Result<ParsedFeedData, any Error>? = await withCheckedContinuation { continuation in
            box.store(continuation)
            box.resume(returning: .failure(URLError(.timedOut)))
        }

        // Then
        guard case .failure(let error)? = result else {
            Issue.record("Expected failure result")
            return
        }
        #expect((error as? URLError)?.code == .timedOut)
    }

    @Test func resumeBeforeStore_resumesImmediatelyWithNil() async {
        // Given — the cancellation handler wins the race against store(_:).
        let box = ParseContinuationBox()
        box.resume(returning: nil)

        // When
        let result: Result<ParsedFeedData, any Error>? = await withCheckedContinuation { continuation in
            box.store(continuation)
        }

        // Then — the stored continuation is resumed at once with the cancellation marker.
        #expect(result == nil)
    }

    @Test func lateResumeAfterCancellation_isIgnored() async {
        // Given — a parse cancelled through the box.
        let box = ParseContinuationBox()
        let result: Result<ParsedFeedData, any Error>? = await withCheckedContinuation { continuation in
            box.store(continuation)
            box.resume(returning: nil)
        }
        #expect(result == nil)

        // When / Then — a FeedKit callback arriving after cancellation must be
        // a no-op rather than a second (crashing) resume.
        box.resume(returning: .success(ParsedFeedData(title: "Late", summary: nil, items: [])))
    }
}
