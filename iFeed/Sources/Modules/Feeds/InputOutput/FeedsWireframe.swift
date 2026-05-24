//
//  FeedsWireframe.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

@MainActor
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

    func presentFeedExplorer(for webPage: String,
                             onChallengePresented: @escaping () -> Void,
                             onResult: @escaping (Result<ExploreFeedsDTO, any Error>) -> Void) {
        delegate?.onNeedToStartFeedExploration(
            for: webPage,
            onChallengePresented: onChallengePresented,
            onResult: onResult
        )
    }

    func presentDiscoveredFeeds(_ results: ExploreFeedsDTO,
                                for webPage: String,
                                onFeedSelected: @escaping ((String) -> Void)) {
        delegate?.onNeedToShowExploreFeeds(with: results, webPage: webPage)
    }
}
