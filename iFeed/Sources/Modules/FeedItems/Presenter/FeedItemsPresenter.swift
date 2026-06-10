//
//  FeedItemsPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

@MainActor
final class FeedItemsPresenter {
    // MARK: - Properties
    private let wireframe: any FeedItemsWireframeProtocol
    private let interactor: any FeedItemsInteractorProtocol
    private weak var view: (any FeedItemsViewProtocol)?

    /// Snapshot of the items most recently handed to the view.
    /// Row selection resolves against this snapshot so a tap always maps to the
    /// row the table is displaying — re-fetching via `getFeedItems()` is not
    /// guaranteed to return the same order for items with equal publish dates.
    private var displayedItems: [FeedItem] = []

    // MARK: - Init
    init(interactor: any FeedItemsInteractorProtocol,
         wireframe: any FeedItemsWireframeProtocol,
         view: any FeedItemsViewProtocol) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.view = view
    }
}

// MARK: - FeedItemsViewDelegate
extension FeedItemsPresenter: FeedItemsViewDelegate {

    func onViewDidLoad() {
        let feedItems = interactor.getFeedItems()
        displayedItems = feedItems ?? []

        let viewState = FeedItemsViewState(
            feed: interactor.getFeed(),
            feedItems: feedItems,
            searchTitle: interactor.getSearchTitle(),
            isMarkAllAsReadVisible: interactor.hasUnreadItems()
        )

        view?.updateOnDidLoad(with: viewState)

        guard let items = feedItems else {
            return
        }

        wireframe.prewarmSafari(for: items)
    }

    func onViewWillAppear() {
        view?.updateOnWillAppear()
    }

    func onViewWillDisappear(isMovingFromParent: Bool,
                             isBeingDismissed: Bool) {
        if isMovingFromParent || isBeingDismissed {
            wireframe.invalidateSafariPrewarm()
        }
    }

    func onViewDidSelectFeedItemAtIndexPath(_ indexPath: IndexPath, cell: UITableViewCell) {
        guard !displayedItems.isEmpty, indexPath.row < displayedItems.count else {
            return
        }

        let item = displayedItems[indexPath.row]
        let url = URL(string: item.link)

        interactor.markItemAsReadIfNeeded(item: item)

        if let htmlContent = item.htmlContent, htmlContent.count >= 300 {
            wireframe.pushArticleReader(title: item.title, htmlContent: htmlContent, articleURL: url)
        } else if let url {
            wireframe.presentSafari(for: url, zoomingFrom: cell)
        }
    }

    func onViewDidPullToRefresh() {
        guard let url = interactor.getFeed()?.rssURL, !url.isEmpty else {
            return
        }

        interactor.startParsingFeed(url) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success:
                let feedItems = self.interactor.getFeedItems()
                self.displayedItems = feedItems ?? []

                let viewState = FeedItemsViewState(
                    feedItems: feedItems,
                    isMarkAllAsReadVisible: self.interactor.hasUnreadItems()
                )
                self.view?.updateOnDidEndParsingFeed(viewState: viewState)

                guard let items = feedItems else {
                    return
                }
                wireframe.prewarmSafari(for: items)

            case .failure(let error):
                self.view?.updateOnDidFailParsingFeed(error.localizedDescription)
            }
        }
    }

    func onMarkAllAsReadTapped() {
        interactor.markAllItemsAsRead()

        let feedItems = interactor.getFeedItems()
        displayedItems = feedItems ?? []

        let viewState = FeedItemsViewState(
            feed: interactor.getFeed(),
            feedItems: feedItems,
            searchTitle: interactor.getSearchTitle(),
            isMarkAllAsReadVisible: false
        )
        view?.updateOnDidEndParsingFeed(viewState: viewState)
    }
}
