//
//  SummarizationError.swift
//  iFeed
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Failures that can occur while producing an ``ArticleSummary``.
enum SummarizationError: Error, Equatable {
    /// On-device summarization is not supported on this OS/hardware, or the
    /// system model is currently unavailable (e.g. Apple Intelligence is off).
    case unavailable
    /// The article carried no readable text to summarize.
    case emptyContent
    /// The model session failed (guardrails, context overflow, decoding, …).
    /// Carries the underlying error so the exact cause can be logged.
    case generationFailed(underlying: any Error)

    /// Compares cases only; the ``generationFailed`` payload is ignored because
    /// `any Error` is not itself `Equatable` and tests assert on the case.
    static func == (lhs: SummarizationError, rhs: SummarizationError) -> Bool {
        switch (lhs, rhs) {
        case (.unavailable, .unavailable),
             (.emptyContent, .emptyContent),
             (.generationFailed, .generationFailed):
            return true
        default:
            return false
        }
    }
}
