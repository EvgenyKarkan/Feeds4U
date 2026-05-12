//
//  ParsedFeedItemData.swift
//  iFeed
//
//  Created by Evgeny Karkan on 12.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation

/// A normalized, sendable representation of a parsed feed item.
///
/// `ParsedFeedItemData` keeps only the fields required to create the app's
/// `FeedItem` entity. It is built on the background parsing queue from
/// FeedKit-specific RSS, Atom, or JSON item models and can then be safely passed
/// across queue boundaries.
struct ParsedFeedItemData: Sendable {
    /// The item title, or a fallback value when the source omits one.
    let title: String

    /// The canonical URL string for the item.
    let link: String

    /// The item's publication date, or the creation date when the source omits one.
    let publishDate: Date
}

// MARK: - Inits
extension ParsedFeedItemData {

    /// Creates normalized item data from an RSS feed item.
    ///
    /// Returns `nil` when the RSS item does not provide a link, because the app
    /// requires a URL to create a usable feed item.
    ///
    /// - Parameter rssFeedItem: The RSS item returned by FeedKit.
    init?(rssFeedItem: RSSFeedItem) {
        guard let link = rssFeedItem.link else {
            return nil
        }

        self.init(
            title: rssFeedItem.title ?? "N/A",
            link: link,
            publishDate: rssFeedItem.pubDate ?? Date()
        )
    }

    /// Creates normalized item data from an Atom feed entry.
    ///
    /// Returns `nil` when the Atom entry does not provide a link, because the app
    /// requires a URL to create a usable feed item.
    ///
    /// - Parameter atomFeedItem: The Atom entry returned by FeedKit.
    init?(atomFeedItem: AtomFeedEntry) {
        guard let link = atomFeedItem.links?.first?.attributes?.href else {
            return nil
        }

        self.init(
            title: atomFeedItem.title ?? "N/A",
            link: link,
            publishDate: atomFeedItem.published ?? Date()
        )
    }

    /// Creates normalized item data from a JSON Feed item.
    ///
    /// Returns `nil` when the JSON Feed item does not provide a URL, because the
    /// app requires one to create a usable feed item.
    ///
    /// - Parameter jsonFeedItem: The JSON Feed item returned by FeedKit.
    init?(jsonFeedItem: JSONFeedItem) {
        guard let link = jsonFeedItem.url else {
            return nil
        }

        self.init(
            title: jsonFeedItem.title ?? "N/A",
            link: link,
            publishDate: jsonFeedItem.datePublished ?? Date()
        )
    }
}
