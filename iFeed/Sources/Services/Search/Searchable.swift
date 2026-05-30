//
//  Searchable.swift
//  iFeed
//
//  Created by Assistant on 21.04.26.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Mocking

/// Protocol for search implementations that can index and search feed items
///
/// This protocol defines the contract for any search implementation in the app.
/// Conforming types can use different search backends (e.g., MatchingEngine, Core Spotlight)
/// while providing a consistent interface.
///
/// **Usage Pattern:**
/// 1. Call `fillMatchingEngine(completion:)` to index all feed items
/// 2. Call `search(for:resultsFound:)` to perform searches
///
/// **Example:**
/// ```swift
/// var search: Searchable = Search()
/// search.fillMatchingEngine {
///     search.search(for: "Swift") { results in
///         if let items = results {
///             print("Found \(items.count) items")
///         }
///     }
/// }
/// ```
@Mocked(compilationCondition: .debug)
protocol Searchable {

    /// Fills the search index with all available feed items
    ///
    /// This method prepares the search backend by indexing all feed items.
    /// The specific indexing mechanism depends on the conforming type.
    ///
    /// - Parameter completion: Called when indexing completes (on arbitrary queue)
    ///
    /// - Important: This method must complete successfully before calling `search(for:resultsFound:)`.
    mutating func fillMatchingEngine(completion: @escaping () -> Void)

    /// Searches for feed items matching the given search term
    ///
    /// Performs a search against the indexed feed items and returns matching results.
    /// The specific search algorithm depends on the conforming type.
    ///
    /// - Parameters:
    ///   - searchTerm: The text to search for in feed item titles
    ///   - resultsFound: Closure called with matching feed items, or nil if no matches
    ///
    /// - Important: `fillMatchingEngine(completion:)` must be called first.
    func search(for searchTerm: String, resultsFound: @escaping ([FeedItem]?) -> Void)
}
