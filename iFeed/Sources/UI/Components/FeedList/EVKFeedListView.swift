//
//  EVKFeedListView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/15/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKFeedListView: EVKBaseView {

    // MARK: - Property
    var refreshControl: UIRefreshControl!
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.refreshControl                 = UIRefreshControl()
        self.refreshControl.tintColor       = UIColor(red:0.98, green:0.64, blue:0.15, alpha:1)
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Action
    @objc private func refresh(sender: AnyObject) {
        // Code to refresh table view
    }
}

