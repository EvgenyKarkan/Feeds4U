//
//  FeedItemsView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/15/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import Dispatch

// MARK: - FeedItemsViewDelegate
protocol FeedItemsUIViewDelegate: AnyObject {
    func didPullToRefresh(_ sender: UIRefreshControl)
}

final class FeedItemsView: BaseListView {

    // MARK: - Property
    weak var delegate: (any FeedItemsUIViewDelegate)?
    private lazy var refreshControl = UIRefreshControl()

    // MARK: - Base override
    override func initialViewSetup() {
        super.initialViewSetup()

        refreshControl.tintColor = .systemGray
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        tableView.refreshControl = refreshControl
        refreshControl.layer.zPosition = tableView.layer.zPosition - 1
    }

    // MARK: - Action
    @objc private func refresh(_ sender: UIRefreshControl) {
        delegate?.didPullToRefresh(sender)
    }

    // MARK: - Public
    func endRefreshing() {
        guard refreshControl.isRefreshing else {
            return
        }
        refreshControl.endRefreshing()
    }

    func hideRefreshControl() {
        refreshControl.removeFromSuperview()
    }

    func scrollToTop() {
        Task { @MainActor [weak self] in
            self?.endRefreshing()
            self?.tableView.setContentOffset(.zero, animated: true)
        }
    }
}
