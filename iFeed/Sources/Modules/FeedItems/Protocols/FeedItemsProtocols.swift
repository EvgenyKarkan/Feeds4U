//
//  FeedItemsProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import Foundation

/// Presenter ---> Wireframe
protocol FeedItemsWireframeProtocol: AnyObject {
    func prewarmSafari(for feedItems: [FeedItem])
    func invalidateSafariPrewarm()
    func presentSafari(for url: URL, zoomingFrom cell: UITableViewCell)
}

/// Presenter ---> Interactor
protocol FeedItemsInteractorProtocol: AnyObject {
    func getFeed() -> Feed?
    func getFeedItems() -> [FeedItem]?
    func getSearchTitle() -> String?
    func markItemAsReadIfNeeded(item: FeedItem)
    func startParsingFeed(_ url: String, completion: @escaping (Result<Void, any Error>) -> Void)
}

/// Presenter ---> View
protocol FeedItemsViewProtocol: AnyObject {
    func updateOnDidLoad(with viewState: FeedItemsViewState)
    func updateOnWillAppear()
    func updateOnDidEndParsingFeed(viewState: FeedItemsViewState)
    func updateOnDidFailParsingFeed()
}

/// View ---> Presenter
protocol FeedItemsViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewWillAppear()
    func onViewWillDisappear(isMovingFromParent: Bool, isBeingDismissed: Bool)
    func onViewDidSelectFeedItemAtIndexPath(_ indexPath: IndexPath, cell: UITableViewCell)
    func onViewDidPullToRefresh()
}

/// Defines dependencies of current module
protocol FeedItemsDependencies: AnyObject {
    func parser() -> any ParserProtocol
    func storage() -> any StorageProtocol
}
