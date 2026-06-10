//
//  FeedItemsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedItemsViewController: BaseListViewController {
    // MARK: - Properties
    var presenter: (any FeedItemsViewDelegate)?

    private var feedItemsView: FeedItemsView?
    private var provider: FeedItemsTableProvider?

    // MARK: - Life cycle
    override func loadView() {
        provider = FeedItemsTableProvider(delegate: self)

        feedItemsView = FeedItemsView(frame: UIScreen.main.bounds)
        feedItemsView?.tableView.delegate = provider
        feedItemsView?.tableView.dataSource = provider
        feedItemsView?.delegate = self

        view = feedItemsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter?.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter?.onViewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        /// Arguments indicate if view controller is about to be popped or dismissed
        presenter?.onViewWillDisappear(
            isMovingFromParent: isMovingFromParent,
            isBeingDismissed: isBeingDismissed
        )
    }
}

// MARK: - FeedItemsViewDelegate
extension FeedItemsViewController: @MainActor FeedItemsUIViewDelegate {

    func didPullToRefresh(_ sender: UIRefreshControl) {
        presenter?.onViewDidPullToRefresh()
    }
}

// MARK: - TableProviderDelegate
extension FeedItemsViewController: @MainActor TableProviderDelegate {

    func tableProvider(_ provider: BaseTableProvider, didSelectRowAt indexPath: IndexPath) {
        guard let cell = feedItemsView?.tableView.cellForRow(at: indexPath) else {
            return
        }
        presenter?.onViewDidSelectFeedItemAtIndexPath(indexPath, cell: cell)
    }
}

// MARK: - FeedItemsViewProtocol
extension FeedItemsViewController: @MainActor FeedItemsViewProtocol {

    func updateOnDidLoad(with viewState: FeedItemsViewState) {
        // is it possible to make this method more elegant?

        title = viewState.feed?.title

        if viewState.searchTitle != nil {
            title = viewState.searchTitle
            feedItemsView?.hideRefreshControl()
        }

        setupRightBarButtonItem(isVisible: viewState.isMarkAllAsReadVisible)

        guard let feedItems = viewState.feedItems, !feedItems.isEmpty else {
            return
        }

        provider?.dataSource = feedItems
    }

    func updateOnWillAppear() {
        /// Defers table reload until after any active transition completes.
        ///
        /// When `SFSafariViewController` is dismissed with a `.zoom` transition, this VC's
        /// `viewWillAppear` fires mid-animation. An immediate `reloadTableView()` at that
        /// point invalidates the cell the zoom is animating back to, causing the dismiss
        /// gesture to silently fail — the user has to tap "Done" a second time.
        /// Deferring the reload to the transition's completion callback keeps the cell
        /// alive for the full duration of the zoom-out animation.
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.feedItemsView?.reloadTableView()
            }
        } else {
            feedItemsView?.reloadTableView()
        }
    }

    func updateOnDidEndParsingFeed(viewState: FeedItemsViewState) {
        feedItemsView?.endRefreshing()

        setupRightBarButtonItem(isVisible: viewState.isMarkAllAsReadVisible)

        provider?.dataSource = viewState.feedItems ?? []
        feedItemsView?.reloadTableView()
    }

    func updateOnDidFailParsingFeed(_ message: String) {
        feedItemsView?.endRefreshing()
        feedItemsView?.scrollToTop()

        Task { @MainActor [weak self] in
            self?.showErrorAlert(message)
        }
    }
}

// MARK: - Private
private extension FeedItemsViewController {

    func setupRightBarButtonItem(isVisible: Bool) {
        guard isVisible else {
            navigationItem.setRightBarButton(nil, animated: true)
            return
        }

        let markAllAction = UIAction(
            title: String.localized(key: LocalizableKeys.markAllAsRead),
            image: UIImage(systemName: "checkmark.circle")
        ) { [weak self] _ in
            self?.presenter?.onMarkAllAsReadTapped()
        }

        let menu = UIMenu(title: "", children: [markAllAction])

        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.rectangle.stack"),
            menu: menu
        )
        barButtonItem.tintColor = .systemBlue

        navigationItem.setRightBarButton(barButtonItem, animated: true)
    }
}
