//
//  EVKFeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKFeedListViewController: EVKBaseViewController, EVKXMLParserProtocol, EVKTableProviderProtocol, EVKFeedListViewProtocol {

    // MARK: - properties
    var feedListView:   EVKFeedListView
    var provider:       EVKFeedListTableProvider?
    
    private var refreshedFeed:  Feed?
    private var refreshCounter: Int!
    
    private var proxyFeeds: [Feed]
    
    
    // MARK: - Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        self.feedListView = EVKFeedListView()
        
        self.refreshCounter = EVKBrain.brain.coreDater.allFeeds().count
        
        self.proxyFeeds = []
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.provider = EVKFeedListTableProvider(delegateObject: self);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Life cycle
    override func loadView() {
        
        var aView = EVKFeedListView (frame: UIScreen.mainScreen().bounds)
        
        self.feedListView = aView
        self.view = aView
        
        self.feedListView.tableView.delegate   = self.provider!
        self.feedListView.tableView.dataSource = self.provider!
        self.feedListView.feedListDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var addButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add,
                                                                     target: self,
                                                                     action: "addPressed:")
        self.navigationItem.setRightBarButtonItems([addButton], animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
        self.feedListView.tableView.reloadData()
    }
    
    
    // MARK: - Private
    private func startParsingURL(URL: String) {
        
        let parser            = EVKBrain.brain.parser
        parser.parserDelegate = self
        parser.beginParseURL(NSURL(string: URL)!)
    }
    
    private func parseRefreshedData(feeds: [Feed]) {
        //delete incoming 'feed' objects from CD context
        for feed: Feed in self.proxyFeeds {
            EVKBrain.brain.coreDater.deleteObject(feed)
        }
        
        self.proxyFeeds.removeAll(keepCapacity: false)
        
        assert(feeds.count == self.provider?.dataSource.count, "Counts not equal")
        
        if feeds.count == self.provider?.dataSource.count {
            
            var loopCounter = feeds.count
            
            //incoming array
            for feed1: Feed in feeds {  //println("Feed 1 title \(feed1.title)")
                //existed array
                var existArray = self.provider?.dataSource as! [Feed]
                
                for feed2: Feed in existArray {   //println("Feed 2 title \(feed2.title)")
                    //found matching of 2 feeds
                    if feed1.rssURL == feed2.rssURL {
                        println(feed1.title)
                        
                        //feed items from matched feed
                        var existFeedItems: [FeedItem] = feed2.feedItems.allObjects as! [FeedItem]
                        
                        //'publish date' array of all feed items
                        var refreshDatesArr: [NSTimeInterval] = existFeedItems.map {
                            return $0.publishDate.timeIntervalSince1970
                        }
                        
                        //incoming feed to compare it items with existed feed
                        var incomingFeedItems: [FeedItem] = feed1.feedItems.allObjects as! [FeedItem]
                        
                        //iterate over each incoming feed item to find new item - which 'publish date' is not exists yet
                        for item: FeedItem in incomingFeedItems {
                            if !contains(refreshDatesArr, item.publishDate.timeIntervalSince1970) {
                                //relationship
                                item.feed = self.refreshedFeed!
                                EVKBrain.brain.coreDater.saveContext()
                            }
                        }
                        
                        loopCounter--
                        
                        if loopCounter == 0 {
                            self.feedListView.tableView.reloadData()
                            self.feedListView.refreshControl.endRefreshing()
                        }
                        
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    func addPressed (sender: UIButton) {
        
        assert(!sender.isEqual(nil), "sender is nil")
        
        showAlertView(sender);
    }
    
    // MARK: - Inherited from base
    override func addFeedPressed (URL: String) {
        
        startParsingURL(URL)
    }
    
    // MARK: - EVKXMLParserProtocol API
    func didEndParsingFeed(feed: Feed) {
        //println("CALLED END")
        
        if self.feedListView.refreshControl.refreshing {
            
            self.proxyFeeds.append(feed)
            
            self.refreshCounter!--
            
            if self.refreshCounter == 0 {
                self.refreshCounter = EVKBrain.brain.coreDater.allFeeds().count
                
                parseRefreshedData(self.proxyFeeds)
            }
        }
        else {
            self.provider?.dataSource.append(feed)
            EVKBrain.brain.coreDater.saveContext()
            self.feedListView.tableView.reloadData()
        }
    }
    
    
    // MARK: - EVKTableProviderProtocol
    func cellDidPress(#atIndexPath: NSIndexPath) {

        var itemsVC: EVKFeedItemsViewController = EVKFeedItemsViewController()
        itemsVC.feed                            = EVKBrain.brain.feedForIndexPath(indexPath: atIndexPath)
        
        self.navigationController?.pushViewController(itemsVC, animated: true)
    }
    
    // MARK: - EVKFeedListViewProtocol API
    func didPullToRefresh(sender: UIRefreshControl) {
        
        assert(!sender.isEqual(nil), "Sender is nil")
        
        var allFeeds: [Feed] = EVKBrain.brain.coreDater.allFeeds()
        var counter: Int     = allFeeds.count
        self.refreshCounter  = counter
        
        if counter > 0 {
            for (index: Int, feed: Feed) in enumerate(allFeeds) {
                
                self.refreshedFeed = feed
                
                println("TITLE IN LOOP \(self.refreshedFeed!.title)")
                
                let URL: String = self.refreshedFeed!.rssURL

                self.startParsingURL(URL)
            }
        }
    }
}
