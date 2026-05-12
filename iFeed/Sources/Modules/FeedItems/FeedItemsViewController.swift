//
//  FeedItemsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import Foundation
import SafariServices

final class FeedItemsViewController: BaseListViewController, TableProviderDelegate, FeedItemsViewDelegate {

    // MARK: - Properties
    private var feedItemsView: FeedItemsView?
    private var provider: FeedItemsTableProvider?
    private var prewarmingToken: SFSafariViewController.PrewarmingToken?

    var feed: Feed?
    var feedItems: [FeedItem]?
    var searchTitle: String?

    let storage = DIContainer().storage()

    // MARK: - Deinit
    deinit {
        provider?.delegate = nil
        feedItemsView?.delegate = nil
    }

    // MARK: - Life cycle
    override func loadView() {
        provider = FeedItemsTableProvider(delegate: self)

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

        /// Pre-warming Safari connections
        prewarmConnections(to: feedItems)
    }

    /// Defers table reload until after any active transition completes.
    ///
    /// When `SFSafariViewController` is dismissed with a `.zoom` transition, this VC's
    /// `viewWillAppear` fires mid-animation. An immediate `reloadTableView()` at that
    /// point invalidates the cell the zoom is animating back to, causing the dismiss
    /// gesture to silently fail — the user has to tap "Done" a second time.
    /// Deferring the reload to the transition's completion callback keeps the cell
    /// alive for the full duration of the zoom-out animation.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.feedItemsView?.reloadTableView()
            }
        } else {
            feedItemsView?.reloadTableView()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        /// View controller is about to be popped or dismissed
        if isMovingFromParent || isBeingDismissed {
            prewarmingToken?.invalidate()
            prewarmingToken = nil
        }
    }

    // MARK: - TableProviderDelegate
    func tableProvider(_ provider: BaseTableProvider, didSelectRowAt indexPath: IndexPath) {
        guard let items = feedItems, !items.isEmpty, indexPath.row < items.count else {
            return
        }

        let item = items[indexPath.row]

        guard let url = URL(string: item.link) else {
            return
        }

        if !item.wasRead.boolValue {
            item.wasRead = NSNumber.init(value: true)

            storage.saveChanges()

            self.provider?.dataSource = items
        }

        presentSafari(for: url, zoomingFrom: indexPath)
    }

    // MARK: - FeedItemsViewDelegate
    func didPullToRefresh(_ sender: UIRefreshControl) {
        guard let url = feed?.rssURL, !url.isEmpty else {
            return
        }

        startParsingURL(url)
    }

    // MARK: - ParserDelegateProtocol
    override func didEndParsingFeed(_ feed: Feed) {
        super.didEndParsingFeed(feed)

        guard let currentFeed = self.feed else {
            return
        }

        /// Existed feed items
        let existFeedItems: [FeedItem] = (currentFeed.feedItems.allObjects as? [FeedItem]) ?? []
        let existedTitles: Set<String> = Set(existFeedItems.map(\.title))
        let existedLinks: Set<String> = Set(existFeedItems.map(\.link))
        let existedDates: Set<TimeInterval> = Set(existFeedItems.map(\.publishDate.timeIntervalSince1970))

        print("existFeedItems ---- \(existFeedItems.count)")

        /// Incoming feed items
        let incomingItems: [FeedItem] = (feed.feedItems.allObjects as? [FeedItem]) ?? []

        print("incomingItems ---- \(incomingItems.count)")

        /// Delete temporary incoming `feed`
        storage.delete(feed)

        /// Pre-warming Safari support
        var uniqueIncomingItems: [FeedItem] = []

        /// Iterate over incoming feed items to find a new item to add to existing feed object
        for item: FeedItem in incomingItems {
            let isUniqueTitle = !existedTitles.contains(item.title)
            let isUniqueLink = !existedLinks.contains(item.link)
            let isUniqueDate = !existedDates.contains(item.publishDate.timeIntervalSince1970)

            let isUniqueItem = isUniqueTitle && isUniqueLink && isUniqueDate

            if isUniqueItem {
                /// Create a relationship
                item.feed = currentFeed
                uniqueIncomingItems.append(item)
            } else {
                storage.delete(item)
            }
        }

        storage.saveChanges()

        let sortedItems = currentFeed.sortedItems()
        provider?.dataSource = sortedItems
        feedItems = sortedItems

        feedItemsView?.reloadTableView()
        feedItemsView?.endRefreshing()

        /// Pre-warming Safari connections
        prewarmConnections(to: uniqueIncomingItems)
    }

    override func didFailParsingFeed() {
        super.didFailParsingFeed()

        feedItemsView?.scrollToTop()
    }
}

// MARK: - Private
private extension FeedItemsViewController {

    func presentSafari(for url: URL, zoomingFrom indexPath: IndexPath) {
        let configuration = SFSafariViewController.Configuration()

        let safariVC = SFSafariViewController(url: url, configuration: configuration)

        let zoomOptions = UIViewController.Transition.ZoomOptions()
        zoomOptions.dimmingColor = .tangerine

        safariVC.preferredTransition = .zoom(options: zoomOptions) { [weak self] _ in
            guard let self,
                  let tableView = self.feedItemsView?.tableView,
                  let cell = tableView.cellForRow(at: indexPath) else {
                return nil
            }
            return cell
        }
        present(safariVC, animated: true)
    }

    /// Pre-warms Safari connections for feed item URLs to improve loading performance
    ///
    /// Safari's connection prewarming establishes network connections in advance, allowing web pages
    /// to load faster when the user actually taps on a feed item. This method processes feed items,
    /// validates their URLs, and requests Safari to prewarm connections to unique URLs.
    ///
    /// - Parameter items: Array of feed items whose URLs should be prewarmed
    ///
    /// - Note: This method is called in two scenarios:
    ///   1. When initially loading a feed (`viewDidLoad`) - prewarms all feed items
    ///   2. After refreshing a feed (`didEndParsingFeed`) - prewarms only new unique items
    func prewarmConnections(to items: [FeedItem]) {
        // Step 1: Clean up any existing prewarming token
        // -----------------------------------------------
        // If we previously prewarmed connections, invalidate that token to free up system resources.
        // This prevents resource leaks when the method is called multiple times (e.g., during refresh).
        prewarmingToken?.invalidate()

        // Step 2: Extract and deduplicate valid URLs from feed items
        // -----------------------------------------------------------
        // - Filter out items with empty link strings (prevents URL creation failures)
        // - Convert link strings to URL objects (compactMap removes nil values from invalid URLs)
        // - Use Set to automatically eliminate duplicate URLs, improving both:
        //   * Performance: O(n) deduplication
        //   * Resource efficiency: Don't prewarm the same URL multiple times
        let uniqueURLs = Set(items.compactMap { item -> URL? in
            guard !item.link.isEmpty else { return nil }
            return URL(string: item.link)
        })

        // Step 3: Validate we have URLs to prewarm
        // -----------------------------------------
        // If no valid URLs were found, clear the token and exit early
        guard !uniqueURLs.isEmpty else {
            prewarmingToken = nil
            return
        }

        // Step 4: Limit the number of connections to prewarm
        // ---------------------------------------------------
        // Safari's connection prewarming has practical system limits. Prewarming too many connections
        // can be wasteful and may not provide benefits beyond the first few items the user is likely
        // to tap. Limiting to 10 URLs balances performance with resource usage.
        // Note: Set is unordered, so prefix() gives arbitrary 10 items, not necessarily the "first" ones
        let urlsToPrewarm = Array(uniqueURLs.prefix(10))

        // Step 5: Request Safari to prewarm connections
        // ----------------------------------------------
        // Store the token so we can invalidate it later when:
        // - The view controller is dismissed/popped (in viewWillDisappear)
        // - New items are being prewarmed (Step 1 of this method)
        prewarmingToken = SFSafariViewController.prewarmConnections(to: urlsToPrewarm)
    }
}
