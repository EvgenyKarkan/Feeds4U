//
//  ParsedFeedData.swift
//  iFeed
//
//  Created by Evgeny Karkan on 12.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation

/// A normalized, sendable representation of a parsed feed.
///
/// `ParsedFeedData` removes the parser's main-thread Core Data workflow from
/// FeedKit's concrete RSS, Atom, and JSON feed model types. The parser creates
/// this value on the background parsing queue, then safely passes it to the main
/// queue to create app-specific `Feed` and `FeedItem` entities.
struct ParsedFeedData: Sendable {
    /// The feed title provided by the source document, when available.
    let title: String?

    /// A short feed description or subtitle, normalized from the source format.
    let summary: String?

    /// Feed entries that contain enough data to create app feed item entities.
    let items: [ParsedFeedItemData]
}

// MARK: - Inits
extension ParsedFeedData {

    /// Creates normalized feed data from any FeedKit-supported feed format.
    ///
    /// - Parameter parsedFeed: The RSS, Atom, or JSON feed returned by FeedKit.
    init(parsedFeed: FeedKit.Feed) {
        switch parsedFeed {
        case .rss(let rssFeed):
            self.init(
                title: rssFeed.title,
                summary: rssFeed.description,
                items: rssFeed.items?.compactMap(ParsedFeedItemData.init(rssFeedItem:)) ?? []
            )
        case .atom(let atomFeed):
            self.init(
                title: atomFeed.title,
                summary: (atomFeed.subtitle?.value ?? atomFeed.rights) ?? String(),
                items: atomFeed.entries?.compactMap(ParsedFeedItemData.init(atomFeedItem:)) ?? []
            )
        case .json(let jsonFeed):
            self.init(
                title: jsonFeed.title,
                summary: jsonFeed.description,
                items: jsonFeed.items?.compactMap(ParsedFeedItemData.init(jsonFeedItem:)) ?? []
            )
        }
    }
}
