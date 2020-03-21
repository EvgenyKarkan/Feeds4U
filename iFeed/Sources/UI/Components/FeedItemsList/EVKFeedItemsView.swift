//
//  EVKFeedItemsView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/15/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedItemsView: EVKBaseView {

    // MARK: - Property
    weak var feedListDelegate: EVKFeedItemsViewProtocol?
    var refreshControl = UIRefreshControl()
    
    // MARK: - Init
    override func initialViewSetup() {
        super.initialViewSetup()
        
        refreshControl.tintColor = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    // MARK: - Action
    @objc fileprivate func refresh(_ sender: UIRefreshControl) {
        feedListDelegate?.didPullToRefresh(sender)
    }
}

// MARK: - EVKXMLParserProtocol
protocol EVKFeedItemsViewProtocol: class {
    func didPullToRefresh(_ sender: UIRefreshControl)
}
