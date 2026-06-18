//
//  ArticleSummary.swift
//  iFeed
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// A plain, transport-only digest of an article produced by on-device
/// summarization.
///
/// Deliberately free of any `FoundationModels` types or availability gating so
/// it can cross VIPER layers (Service → Interactor → Presenter → View) on any
/// supported OS. The concrete service maps the model's guided output into this
/// value type before handing it back.
struct ArticleSummary: Sendable, Equatable {
    /// A short, neutral overview of the article (2–3 sentences).
    let summary: String
    /// The most important takeaways, at most three short bullet points.
    let keyPoints: [String]
}
