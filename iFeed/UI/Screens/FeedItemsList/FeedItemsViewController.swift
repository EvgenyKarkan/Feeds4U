//
//  FeedItemsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import Foundation

final class FeedItemsViewController: BaseViewController, TableProviderProtocol, FeedItemsViewDelegate {

    // MARK: - Properties
    private var feedItemsView: FeedItemsView?
    private var provider: FeedItemsTableProvider?

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
        provider = FeedItemsTableProvider(delegateObject: self)
        
        feedItemsView = FeedItemsView(frame: UIScreen.main.bounds)
        feedItemsView?.tableView.delegate = provider
        feedItemsView?.tableView.dataSource = provider
        feedItemsView?.delegate = self

        view = feedItemsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = searchTitle ?? feed?.title

        if searchTitle != nil {
            feedItemsView?.hideRefreshControl()
        }
        
        guard let feedItems = feedItems, !feedItems.isEmpty else {
            return
        }

        provider?.dataSource = feedItems
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        feedItemsView?.reloadTableView()
    }
    
    // MARK: - TableProviderProtocol
    func cellDidPress(at indexPath: IndexPath) {
        guard let items = feedItems, !items.isEmpty, indexPath.row < items.count else {
            return
        }

        let item = items[indexPath.row]
    
        guard let url = URL(string: item.link) else {
            return
        }

        if !item.wasRead.boolValue {
            item.wasRead = true
            Brain.brain.coreDater.saveContext()
        }
        
        let safariVC = SafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    // MARK: - FeedListViewProtocol
    func didPullToRefresh(_ sender: UIRefreshControl) {
        guard let url = feed?.rssURL, !url.isEmpty else {
            return
        }
        
        startParsingURL(url)
    }
    
    // MARK: - ParserDelegateProtocol
    override func didEndParsingFeed(_ feed: Feed) {
        super.didEndParsingFeed(feed)

        guard let selfFeed = self.feed else {
            return
        }

        /// Existed feed items
        let existFeedItems: [FeedItem] = (selfFeed.feedItems.allObjects as? [FeedItem]) ?? []
        let existedTitles: [String] = existFeedItems.map(\.title)
        let existedLinks: [String] = existFeedItems.map(\.link)
        let existedDates: [TimeInterval] = existFeedItems.map(\.publishDate.timeIntervalSince1970)

        print("existFeedItems ---- \(existFeedItems.count)")

        /// Incoming feed items
        let incomingItems: [FeedItem] = (feed.feedItems.allObjects as? [FeedItem]) ?? []

        print("incomingItems ---- \(incomingItems.count)")

        /// Delete temporary incoming `feed`
        Brain.brain.coreDater.deleteObject(feed)

        /// Iterate over incoming feed items to find a new item to add to existing feed object
        for item: FeedItem in incomingItems {
            let isUniqueTitle = !existedTitles.contains(item.title)
            let isUniqueLink = !existedLinks.contains(item.link)
            let isUniqueDate = !existedDates.contains(item.publishDate.timeIntervalSince1970)

            let isUniqueItem = isUniqueTitle && isUniqueLink && isUniqueDate

            if isUniqueItem {
                /// Create a relationship
                item.feed = selfFeed
            }
            else {
                Brain.brain.coreDater.deleteObject(item)
            }
        }

        Brain.brain.coreDater.saveContext()

        provider?.dataSource = selfFeed.sortedItems()

        feedItemsView?.reloadTableView()
        feedItemsView?.endRefreshing()
    }
}
