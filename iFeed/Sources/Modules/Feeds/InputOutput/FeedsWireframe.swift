//
//  FeedsWireframe.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedsWireframe {
    // MARK: - Properties
    weak var viewController: FeedsViewController?
    weak var delegate: (any FeedsCoordinatingDelegate)?
}

// MARK: - FeedsWireframeProtocol
extension FeedsWireframe: FeedsWireframeProtocol {

    func navigateToFeedItems(for feed: Feed) {
        delegate?.onNeedToShowFeedDetails(for: feed)
    }

    func navigateToSearchResults(with results: [FeedItem], matching query: String) {
        delegate?.onNeedToShowSearchResults(with: results, matching: query)
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
