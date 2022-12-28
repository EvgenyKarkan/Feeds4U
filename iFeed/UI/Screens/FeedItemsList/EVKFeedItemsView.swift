//
//  EVKFeedItemsView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/15/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

// MARK: - EVKFeedItemsViewDelegate
protocol EVKFeedItemsViewDelegate: AnyObject {
    func didPullToRefresh(_ sender: UIRefreshControl)
}

final class EVKFeedItemsView: EVKBaseView {

    // MARK: - Property
    weak var delegate: EVKFeedItemsViewDelegate?
    private lazy var refreshControl = UIRefreshControl()
    
    // MARK: - Base override
    override func initialViewSetup() {
        super.initialViewSetup()
        
        refreshControl.tintColor = UIColor(named: "Tangerine")
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
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
}
