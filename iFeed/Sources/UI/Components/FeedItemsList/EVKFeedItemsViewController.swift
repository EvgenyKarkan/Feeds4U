//
//  EVKFeedItemsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


class EVKFeedItemsViewController: EVKBaseViewController, EVKTableProviderProtocol, EVKFeedItemsViewProtocol {

    // MARK: - property
    var feedItemsView: EVKFeedItemsView?
    var provider:      EVKFeedItemsTableProvider?
    var feed:          Feed?
    var feedItems:     [FeedItem]?
    
    // MARK: - Deinit
    deinit {
        provider?.delegate              = nil
        feedItemsView?.feedListDelegate = nil
    }

    // MARK: - Life cycle
    override func loadView() {
        self.provider = EVKFeedItemsTableProvider(delegateObject: self)
        
        let aView = EVKFeedItemsView (frame: UIScreen.main.bounds)
        
        self.feedItemsView = aView
        self.view = aView
        
        self.feedItemsView?.tableView.delegate   = self.provider!
        self.feedItemsView?.tableView.dataSource = self.provider!
        self.feedItemsView?.feedListDelegate     = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let feedItems = feedItems, !feedItems.isEmpty else {
            return
        }
        
        // populate table view
        self.provider?.dataSource = feedItems
            
        self.feedItemsView?.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.feedItemsView?.tableView.reloadData()
        
        self.title = self.feed?.title
    }
    
    // MARK: - EVKTableProviderProtocol API
    func cellDidPress(atIndexPath: IndexPath) {
        let item = self.feed?.sortedItems()[(atIndexPath as NSIndexPath).row]
        
        if item?.link != nil {
            item?.wasRead = true
            
            EVKBrain.brain.coreDater.saveContext()
            
            let webVC: EVKBrowserViewController = EVKBrowserViewController(configuration: nil)
            webVC.loadURLString(item?.link)
            
            self.navigationController?.pushViewController(webVC, animated: true)
        }
        else {
            self.showAlertMessage("Web link is missing")
        }
    }
    
    // MARK: - EVKFeedListViewProtocol API
    func didPullToRefresh(_ sender: UIRefreshControl) {
        assert(!sender.isEqual(nil), "Sender is nil")

        let URL: String = self.feed!.rssURL
        self.startParsingURL(URL)
    }
    
    // MARK: - EVKXMLParserProtocol API
    override func didEndParsingFeed(_ feed: Feed) {
        if !feed.isEqual(nil) && self.feed != nil {
            //self feed
            let existFeedItems: [FeedItem] = self.feed!.feedItems.allObjects as! [FeedItem]
            
            //array from of all feed items 'publish dates'
            let refreshDatesArr: [TimeInterval] = existFeedItems.map {
                return $0.publishDate.timeIntervalSince1970
            }
            
            //incoming feed
            let incomingFeed:  Feed       = feed
            var incomingItems: [FeedItem] = (incomingFeed.feedItems.allObjects as? [FeedItem])!
            
            //delete temporary incoming 'feed'
            EVKBrain.brain.coreDater.deleteObject(feed)
            
            //iterate over each incoming feed item to find new item to add - which 'publish date' is not exists yet
            for item: FeedItem in incomingItems {
                if !refreshDatesArr.contains(item.publishDate.timeIntervalSince1970) {
                    //create relationship
                    item.feed = self.feed!
                }
                else {
                    EVKBrain.brain.coreDater.deleteObject(item)
                }
            }
            
            EVKBrain.brain.coreDater.saveContext()
            
            incomingItems.removeAll()
            
            self.feedItemsView?.refreshControl.endRefreshing()
        }
        
        self.provider?.dataSource = self.feed!.sortedItems()
        self.feedItemsView?.tableView.reloadData()
    }
}
