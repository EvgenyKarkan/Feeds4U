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
protocol FeedItemsViewDelegate: AnyObject {
    func didPullToRefresh(_ sender: UIRefreshControl)
}

final class FeedItemsView: BaseListView {

    // MARK: - Property
    weak var delegate: (any FeedItemsViewDelegate)?
    private lazy var refreshControl = UIRefreshControl()

    // MARK: - Base override
    override func initialViewSetup() {
        super.initialViewSetup()

        refreshControl.tintColor = UIColor(resource: .tangerine)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        refreshControl.layer.zPosition = -CGFloat(Float.greatestFiniteMagnitude)
        tableView.refreshControl = refreshControl // iOS 10+ recommended
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
        DispatchQueue.main.async {
            self.endRefreshing()
            self.tableView.setContentOffset(.zero, animated: true)
        }
    }
}
