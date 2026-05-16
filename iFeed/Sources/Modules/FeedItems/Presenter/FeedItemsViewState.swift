//
//  FeedItemsViewState.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

struct FeedItemsViewState {
    // MARK: - Properties
    let feed: Feed?

    // in case of search - items may belong to different feeds
    let feedItems: [FeedItem]?

    let searhTitle: String?

    // MARK: - Init
    init(feed: Feed? = nil, feedItems: [FeedItem]? = nil, searhTitle: String? = nil) {
        self.feed = feed
        self.feedItems = feedItems
        self.searhTitle = searhTitle
    }
}
