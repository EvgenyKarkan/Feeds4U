//
//  FeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class FeedListViewController: UIViewController {

    //MARK: - property    
    var feedView: FeedListView
    
    
    //MARK: - Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        feedView = FeedListView()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Life cycle
    override func loadView() {
        
        var aView = FeedListView (frame: UIScreen.mainScreen().bounds)
        
        feedView = aView
        self.view = aView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
