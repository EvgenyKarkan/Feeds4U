//
//  UITestScenario.swift
//  iFeed
//
//  Created by Evgeny Karkan on 13.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Named, self-contained data fixtures shared between the app's UI-test launch
/// hook (`UITestSupport` / `Seeder`) and the UI-test target. Selected at launch
/// via the `-uiScenario <rawValue>` argument.
///
/// Compiled into both the app and the UI-test target so the two sides agree on
/// the scenario names without string drift.
enum UITestScenario: String {
    /// No feeds — the empty state.
    case empty
    /// A handful of ungrouped feeds with unread items.
    case populated
    /// Exactly one feed (used to verify delete-to-empty).
    case singleFeed
    /// Ungrouped feeds plus one folder grouping two of them.
    case folders
    /// Feeds with searchable item titles plus seeded recent searches.
    case search
}
