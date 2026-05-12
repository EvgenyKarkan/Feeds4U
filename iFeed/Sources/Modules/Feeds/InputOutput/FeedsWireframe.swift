//
//  FeedsWireframe.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

// TODO: - will hold a weak reference to coordinator and let it show the screens instead

final class FeedsWireframe {
    // MARK: - Properties
    weak var viewController: FeedsViewController?
}

// MARK: - FeedsWireframeProtocol
extension FeedsWireframe: FeedsWireframeProtocol {

    func navigateToFeedItems(for feed: Feed) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        let itemsVC = FeedItemsViewController()
        itemsVC.feed = feed
        itemsVC.feedItems = feed.sortedItems()

        navigationController.pushViewController(itemsVC, animated: true)
    }

    func navigateToSearchResults(with results: [FeedItem], matching query: String) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        let feedItemsViewController = FeedItemsViewController()
        feedItemsViewController.feedItems = results
        feedItemsViewController.searchTitle = "\(String.localized(key: LocalizableKeys.Search.search))\(":") \(query)"

        navigationController.pushViewController(feedItemsViewController, animated: true)
    }

    func presentDiscoveredFeeds(_ results: ExploreFeedsDTO,
                                for webPage: String,
                                onFeedSelected: @escaping ((String) -> Void)) {
        let resultsVC = ExploreFeedsResultsViewController.create(
            with: results,
            webPage: webPage,
            selectionCallback: onFeedSelected
        )

        viewController?.present(resultsVC, animated: true)
    }
}
