//
//  FeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class FeedListViewController: UIViewController {

    var feedView: FeedListView! {
        return self.view as! FeedListView
    }
    
    override func loadView() {
        self.view = FeedListView(frame: UIScreen.mainScreen().bounds)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
