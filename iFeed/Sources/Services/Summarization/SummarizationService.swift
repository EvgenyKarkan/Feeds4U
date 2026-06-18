//
//  SummarizationService.swift
//  iFeed
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Default ``SummarizationServiceProtocol`` backed by Apple's on-device
/// Foundation Models (iOS 26+).
///
/// Everything model-specific is gated behind `#if canImport(FoundationModels)`
/// and `@available(iOS 26.0, *)`. On older systems — or when Apple Intelligence
/// is unavailable — ``isAvailable`` is `false`, ``prewarm()`` is a no-op, and the
/// summary stream finishes with ``SummarizationError/unavailable``, so the UI
/// simply never offers the feature.
@MainActor
final class SummarizationService: SummarizationServiceProtocol {

    /// Cap on the plain-text characters sent to the model. The model must read
    /// the whole prompt before emitting a token (prefill), so a tighter cap
    /// directly shortens time-to-first-token.
    private let maxInputCharacters = 6000

    /// Holds the prewarmed session alive so its loaded resources are not released
    /// before the first real request. Typed `Any?` because `LanguageModelSession`
    /// is only available on iOS 26.
    private var prewarmedSession: Any?

    /// Steers the model. Shared by prewarming and generation so the prewarmed
    /// session matches the one used for the real request.
    fileprivate static let instructionsText = """
    You summarize news and blog articles for a reader app. Be neutral, factual and concise. \
    Never invent facts that are not present in the supplied text.
    """

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    func prewarm() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else {
                return
            }
            let session = LanguageModelSession { Self.instructionsText }
            session.prewarm()
            prewarmedSession = session
        }
        #endif
    }

    func summarize(title: String, htmlContent: String) -> AsyncThrowingStream<ArticleSummary, any Error> {
        AsyncThrowingStream<ArticleSummary, any Error> { continuation in
            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }
                do {
                    #if canImport(FoundationModels)
                    if #available(iOS 26.0, *) {
                        try await self.streamSummary(title: title, htmlContent: htmlContent, into: continuation)
                        continuation.finish()
                        return
                    }
                    #endif
                    continuation.finish(throwing: SummarizationError.unavailable)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

#if canImport(FoundationModels)

/// The model's guided-generation schema. Kept at file scope (rather than nested)
/// so the `@Generable` macro expands cleanly under the availability gate.
@available(iOS 26.0, *)
@Generable
private struct GeneratedDigest {
    @Guide(description: "A concise 2 to 3 sentence overview of the article, in the same language as the article")
    var summary: String

    @Guide(description: "The most important takeaways from the article, at most three short bullet points")
    var keyPoints: [String]
}

@available(iOS 26.0, *)
private extension SummarizationService {

    func streamSummary(title: String,
                       htmlContent: String,
                       into continuation: AsyncThrowingStream<ArticleSummary, any Error>.Continuation) async throws {
        guard SystemLanguageModel.default.availability == .available else {
            throw SummarizationError.unavailable
        }

        // The prewarmed session has served its purpose (model resources are now
        // loaded); drop it so it isn't held for the app's lifetime.
        prewarmedSession = nil

        // Strip the HTML off the main actor — the regex passes can be heavy on a
        // large article and would otherwise hitch the UI right at tap time.
        let cap = maxInputCharacters
        let plainText = await Task.detached(priority: .userInitiated) {
            HTMLPlainText.extract(from: htmlContent, maxLength: cap)
        }.value
        guard !plainText.isEmpty else {
            throw SummarizationError.emptyContent
        }

        let session = LanguageModelSession { Self.instructionsText }
        let prompt = """
        Summarize the following article titled "\(title)":

        \(plainText)
        """

        do {
            let responseStream = session.streamResponse(to: prompt, generating: GeneratedDigest.self)

            for try await snapshot in responseStream {
                // Skip empty leading snapshots so the card never flashes blank;
                // emit growing snapshots as soon as there is text to show.
                let partial = snapshot.content
                guard let text = partial.summary, !text.isEmpty else {
                    continue
                }
                continuation.yield(ArticleSummary(summary: text,
                                                  keyPoints: Array((partial.keyPoints ?? []).prefix(3))))
            }
        } catch {
            throw SummarizationError.generationFailed(underlying: error)
        }
    }
}
#endif
