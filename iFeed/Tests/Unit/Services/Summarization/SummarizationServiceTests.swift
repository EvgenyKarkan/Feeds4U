//
//  SummarizationServiceTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Foundation
@testable import iFeed

@Suite
@MainActor
struct SummarizationServiceTests {

    // MARK: - ArticleSummary

    @Test func articleSummary_equatesByContent() {
        // Given
        let first = ArticleSummary(summary: "A", keyPoints: ["x", "y"])
        let second = ArticleSummary(summary: "A", keyPoints: ["x", "y"])
        let different = ArticleSummary(summary: "B", keyPoints: ["x", "y"])

        // When / Then
        #expect(first == second)
        #expect(first != different)
    }

    // MARK: - SummarizationError

    @Test func summarizationError_equatesByCase() {
        // Given
        enum Dummy: Error { case aCase, bCase }

        // When / Then — `generationFailed` matches by case, ignoring its payload.
        #expect(SummarizationError.unavailable == SummarizationError.unavailable)
        #expect(SummarizationError.emptyContent == SummarizationError.emptyContent)
        #expect(SummarizationError.generationFailed(underlying: Dummy.aCase)
            == SummarizationError.generationFailed(underlying: Dummy.bCase))
        #expect(SummarizationError.unavailable != SummarizationError.emptyContent)
    }

    // MARK: - Availability

    @Test func summarize_whenUnavailable_throwsUnavailable() async {
        // Given — on the iOS-18 simulator the system model is not present, so the
        // service must surface `.unavailable` rather than crash.
        let sut = SummarizationService()

        // When / Then
        if !sut.isAvailable {
            await #expect(throws: SummarizationError.unavailable) {
                for try await _ in sut.summarize(title: "T", htmlContent: "<p>Body</p>") {}
            }
        }
    }
}
