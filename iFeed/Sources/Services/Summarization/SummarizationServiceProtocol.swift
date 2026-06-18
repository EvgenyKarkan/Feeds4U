//
//  SummarizationServiceProtocol.swift
//  iFeed
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
#if DEBUG
import Mocking
#endif

/// On-device article summarization, abstracted so callers never touch
/// `FoundationModels` directly and can be unit-tested with a mock.
///
/// All availability gating lives behind ``isAvailable`` and the concrete
/// implementation; consumers treat summarization as an ordinary async operation
/// that may throw ``SummarizationError``.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol SummarizationServiceProtocol: AnyObject {
    /// `true` when on-device summarization can run right now (supported OS and
    /// hardware, and the system model is ready). Drives whether the UI offers
    /// the feature at all.
    var isAvailable: Bool { get }

    /// Asks the system to load the model resources ahead of time so the first
    /// real request skips the cold-start cost. Safe to call when unavailable
    /// (no-op) and safe to call more than once.
    func prewarm()

    /// Streams progressively larger snapshots of the article digest as the model
    /// generates it, so the UI can show text the moment the first tokens arrive
    /// instead of waiting for the whole response.
    /// - Parameters:
    ///   - title: The article title, used to steer the model.
    ///   - htmlContent: The raw article HTML; stripped to plain text internally.
    /// - Returns: A stream of growing ``ArticleSummary`` snapshots; the final
    ///   element is the complete summary. The stream finishes with a
    ///   ``SummarizationError`` when unavailable, empty, or generation fails.
    func summarize(title: String, htmlContent: String) -> AsyncThrowingStream<ArticleSummary, any Error>
}
