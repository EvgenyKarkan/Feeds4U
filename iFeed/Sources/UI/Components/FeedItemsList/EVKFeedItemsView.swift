//
//  EVKFeedItemsView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/15/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

// MARK: - EVKParserDelegate
protocol EVKFeedItemsViewDelegate: AnyObject {
    func didPullToRefresh(_ sender: UIRefreshControl)
}

class EVKFeedItemsView: EVKBaseView {

    // MARK: - Property
    weak var delegate: EVKFeedItemsViewDelegate?
    let refreshControl = UIRefreshControl()
    
    // MARK: - Init
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
}
