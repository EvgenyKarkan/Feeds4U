//
//  FeedItemsProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import Foundation
#if DEBUG
import Mocking
#endif

/// Presenter ---> Wireframe
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol FeedItemsWireframeProtocol: AnyObject {
    func prewarmSafari(for feedItems: [FeedItem])
    func invalidateSafariPrewarm()
    func presentSafari(for url: URL, zoomingFrom cell: UITableViewCell)
    func pushArticleReader(title: String, htmlContent: String, articleURL: URL?)
}

/// Presenter ---> Interactor
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol FeedItemsInteractorProtocol: AnyObject {
    func getFeed() -> Feed?
    func getFeedItems() -> [FeedItem]?
    func getSearchTitle() -> String?
    func markItemAsReadIfNeeded(item: FeedItem)
    func markAllItemsAsRead()
    func hasUnreadItems() -> Bool
    func startParsingFeed(_ url: String, completion: @escaping (Result<Void, any Error>) -> Void)
}

/// Presenter ---> View
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol FeedItemsViewProtocol: AnyObject {
    func updateOnDidLoad(with viewState: FeedItemsViewState)
    func updateOnWillAppear()
    func updateOnDidEndParsingFeed(viewState: FeedItemsViewState)
    func updateOnDidFailParsingFeed(_ message: String)
}

/// View ---> Presenter
@MainActor
protocol FeedItemsViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewWillAppear()
    func onViewWillDisappear(isMovingFromParent: Bool, isBeingDismissed: Bool)
    func onViewDidSelectFeedItemAtIndexPath(_ indexPath: IndexPath, cell: UITableViewCell)
    func onViewDidPullToRefresh()
    func onMarkAllAsReadTapped()
}

/// Defines dependencies of current module
@MainActor
protocol FeedItemsDependencies: AnyObject {
    func parser() -> any ParserProtocol
    func storage() -> any StorageProtocol
}

/// Wireframe -> AppCoordinator
@MainActor
protocol FeedItemsCoordinatingDelegate: AnyObject {
    func onNeedToShowArticleReader(for title: String, htmlContent: String, articleURL: URL?)
}
