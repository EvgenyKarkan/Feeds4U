//
//  EVKFeedItemsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedItemsViewController: EVKBaseViewController, EVKTableProviderProtocol {

    // MARK: - property
    var feedItemsView: EVKFeedItemsView
    var provider: EVKFeedItemsTableProvider?
    
    // MARK: - Property setter, getter
    var feed: Feed?
    
    // MARK: - Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        self.feedItemsView = EVKFeedItemsView()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.provider = EVKFeedItemsTableProvider(delegateObject: self);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle
    override func loadView() {
        
        var aView = EVKFeedItemsView (frame: UIScreen.mainScreen().bounds)
        
        self.feedItemsView = aView
        self.view = aView
        
        self.feedItemsView.tableView.delegate   = self.provider!
        self.feedItemsView.tableView.dataSource = self.provider!
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // populate table view
        if self.feed != nil && self.feed?.feedItems.allObjects.count > 0 {
            
            var items = self.feed?.sortedItems()
            
            self.provider?.dataSource = items!
            
            self.feedItemsView.tableView.reloadData()
        }
    }
    
    // MARK: - EVKTableProviderProtocol API
    func cellDidPress(#atIndexPath: NSIndexPath) {
        
        var item = self.feed?.sortedItems()[atIndexPath.row]
        
        var webVC: KINWebBrowserViewController = KINWebBrowserViewController()
        
        webVC.loadURLString(item?.link)
        
        self.navigationController?.pushViewController(webVC, animated: true)
    }
}
