//
//  UITestParser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 14.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

#if DEBUG
import Foundation

/// Deterministic, offline `ParserProtocol` used under UI testing.
///
/// The seeded feeds carry fake URLs, so a real pull-to-refresh would hit the
/// network and leave the refresh control spinning indefinitely — which stops
/// XCUI from ever seeing the app as idle (the same class of hang the stress
/// suite exposed). This stub resolves every parse immediately with an empty
/// success: the refresh ends right away and the seeded item list is unchanged,
/// so refresh can be exercised under stress without flakiness or data loss.
@MainActor
final class UITestParser: ParserProtocol {

    private weak var delegate: (any ParserDelegateProtocol)?

    func setDelegate(_ delegate: any ParserDelegateProtocol) {
        self.delegate = delegate
    }

    func beginParsingURL(_ url: URL) {
        delegate?.didStartParsingFeed()
        delegate?.didEndParsingFeed(with: ParsedFeedData(title: nil, summary: nil, items: []))
    }

    func cancelParsing() {
        delegate?.didCancelParsingFeed()
    }

    /// Resolves immediately with an empty success so a refresh-all fan-out under
    /// UI testing ends right away (the seeded URLs are fake) and the seeded item
    /// list is left unchanged.
    func parse(_ url: URL) async -> Result<ParsedFeedData, any Error> {
        return .success(ParsedFeedData(title: nil, summary: nil, items: []))
    }
}
#endif
