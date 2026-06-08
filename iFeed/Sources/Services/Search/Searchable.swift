//
//  Searchable.swift
//  iFeed
//
//  Created by Assistant on 21.04.26.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
#if DEBUG
import Mocking
#endif

/// Protocol for search implementations that can index and search feed items
///
/// This protocol defines the contract for any search implementation in the app.
/// Conforming types can use different search backends (e.g., MatchingEngine, Core Spotlight)
/// while providing a consistent interface.
///
/// **Usage Pattern:**
/// 1. Call `fillMatchingEngine()` to index all feed items
/// 2. Call `search(for:)` to perform searches
///
/// **Example:**
/// ```swift
/// var search: Searchable = Search(storage: storage)
/// await search.fillMatchingEngine()
/// let results = await search.search(for: "Swift")
/// ```
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol Searchable {
    /// Fills the search index with all available feed items.
    ///
    /// Suspends until indexing completes. Call this before `search(for:)`.
    @MainActor mutating func fillMatchingEngine() async

    /// Searches for feed items matching the given search term.
    ///
    /// Returns matched items sorted newest-first, or `nil` when nothing matches or the
    /// engine has not been filled yet.
    @MainActor func search(for searchTerm: String) async -> [FeedItem]?
}
