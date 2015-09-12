//
//  EVKFeedItemsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedItemsViewController: EVKBaseViewController, EVKTableProviderProtocol, EVKFeedItemsViewProtocol {

    // MARK: - property
    var feedItemsView: EVKFeedItemsView
    var provider:      EVKFeedItemsTableProvider?
    var feed:          Feed?
    
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
        self.feedItemsView.feedListDelegate     = self
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
        
        var item      = self.feed?.sortedItems()[atIndexPath.row]
        item?.wasRead = true
        
        EVKBrain.brain.coreDater.saveContext()
        
        var webVC: EVKBrowserViewController = EVKBrowserViewController(configuration: nil)
        webVC.loadURLString(item?.link)
        
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    // MARK: - EVKFeedListViewProtocol API
    func didPullToRefresh(sender: UIRefreshControl) {
        
        assert(!sender.isEqual(nil), "Sender is nil")

        let URL: String = self.feed!.rssURL
                
        self.startParsingURL(URL)
    }
    
    // MARK: - EVKXMLParserProtocol API
    override func didEndParsingFeed(feed: Feed) {
        
        if !feed.isEqual(nil) && self.feed != nil {
            
            // self feed
            var existFeedItems: [FeedItem] = self.feed!.feedItems.allObjects as! [FeedItem]
            
            //array from of all feed items 'publish dates'
            var refreshDatesArr: [NSTimeInterval] = existFeedItems.map {
                return $0.publishDate.timeIntervalSince1970
            }
            
            //incoming feed
            var incomingFeed:  Feed       = feed
            var incomingItems: [FeedItem] = (incomingFeed.feedItems.allObjects as? [FeedItem])!
            
            //iterate over each incoming feed item to find new item to add - which 'publish date' is not exists yet
            for item: FeedItem in incomingItems {
                if !contains(refreshDatesArr, item.publishDate.timeIntervalSince1970) {
                    //create relationship
                    item.feed = self.feed!
                    
                    println("Added item \(item.title)")
                }
            }

            self.feedItemsView.refreshControl.endRefreshing()
        }
        
        //delete temporary incoming 'feed'
        EVKBrain.brain.coreDater.deleteObject(feed)
        EVKBrain.brain.coreDater.saveContext()
        
        self.provider?.dataSource = self.feed!.sortedItems()
        self.feedItemsView.tableView.reloadData()
    }
}
