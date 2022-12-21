//
//  EVKFeedItemsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedItemsViewController: EVKBaseViewController, EVKTableProviderProtocol, EVKFeedItemsViewDelegate {

    // MARK: - property
    var feedItemsView: EVKFeedItemsView?
    var provider: EVKFeedItemsTableProvider?
    var feed: Feed?
    var feedItems: [FeedItem]?
    var searchTitle: String?
    
    // MARK: - Deinit
    deinit {
        provider?.delegate = nil
        feedItemsView?.delegate = nil
    }

    // MARK: - Life cycle
    override func loadView() {
        provider = EVKFeedItemsTableProvider(delegateObject: self)
        
        let aView = EVKFeedItemsView(frame: UIScreen.main.bounds)
        
        feedItemsView = aView
        view = aView
        
        feedItemsView?.tableView.delegate = provider!
        feedItemsView?.tableView.dataSource = provider!
        feedItemsView?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let feedItems = feedItems, !feedItems.isEmpty else {
            return
        }
        
        // populate table view
        provider?.dataSource = feedItems
            
        feedItemsView?.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        feedItemsView?.tableView.reloadData()
        
        if let searchTitle = searchTitle {
            title = searchTitle
        } else {
            title = self.feed?.title
        }
    }
    
    // MARK: - EVKTableProviderProtocol API
    func cellDidPress(at indexPath: IndexPath) {
        guard let items = feedItems, !items.isEmpty else {
            return
        }
        
        let item = items[indexPath.row]
        
        item.wasRead = true
        
        EVKBrain.brain.coreDater.saveContext()
    
        guard let url = URL(string: item.link) else {
            return
        }
        
        let safariVC = EVKSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    // MARK: - EVKFeedListViewProtocol API
    func didPullToRefresh(_ sender: UIRefreshControl) {
        guard let url = feed?.rssURL else {
            return
        }
        
        startParsingURL(url)
    }
    
    // MARK: - EVKParserDelegate API
    override func didEndParsingFeed(_ feed: Feed) {
        if !feed.isEqual(nil) && self.feed != nil {
            //self feed
            let existFeedItems: [FeedItem] = self.feed!.feedItems.allObjects as! [FeedItem]
            
            //array from of all feed items 'publish dates'
            let refreshDatesArr: [TimeInterval] = existFeedItems.map {
                return $0.publishDate.timeIntervalSince1970
            }
            
            //incoming feed
            let incomingFeed: Feed = feed
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
            
            feedItemsView?.refreshControl.endRefreshing()
        }
        
        provider?.dataSource = self.feed!.sortedItems()
        feedItemsView?.tableView.reloadData()
    }
}
