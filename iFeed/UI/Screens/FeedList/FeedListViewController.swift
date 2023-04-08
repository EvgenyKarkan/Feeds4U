//
//  FeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedListViewController: BaseViewController, TableProviderProtocol {

    // MARK: - Properties
    private var feedListView: FeedListView?
    private var provider: FeedListTableProvider?
    lazy var search: Search = Search()
    lazy var service: FeedSearchService = FeedSearchService()

    private lazy var addButton: UIBarButtonItem = {

        var addAction: UIAction {
            let title = "Enter a new feed"
            let image = UIImage(systemName: "plus.circle")
            let action = UIAction(title: title, image: image) { [weak self] _ in
                self?.showEnterFeedAlertView()
            }
            return action
        }

        var searchAction: UIAction {
            let title = "Search for feeds"
            let image = UIImage(systemName: "globe")
            let action = UIAction(title: title, image: image) { [weak self] _ in
                self?.showSearchForFeedsAlertView()
            }
            return action
        }

        var contextMenu: UIMenu {
            let menu = UIMenu(title: "Add a new feed",
                              children: [addAction, searchAction])
            return menu
        }

        var button: UIButton {
            let image = UIImage(systemName: "plus")

            let button = UIButton(type: .system)
            button.setImage(image, for: .normal)
            button.menu = contextMenu
            button.showsMenuAsPrimaryAction = true

            return button
        }

        return UIBarButtonItem(customView: button)
    }()

    private lazy var searchButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .search,
                               target: self,
                               action: #selector(searchPressed))
    }()

    private lazy var trashButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .trash,
                               target: self,
                               action: #selector(trashPressed))
    }()
    
    // MARK: - Deinit
    deinit {
        provider?.delegate = nil
    }
    
    // MARK: - Life cycle
    override func loadView() {
        provider = FeedListTableProvider(delegateObject: self)
        
        feedListView = FeedListView(frame: UIScreen.main.bounds)
        feedListView?.tableView.delegate = provider
        feedListView?.tableView.dataSource = provider

        view = feedListView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let allFeeds = Brain.brain.coreDater.allFeeds()
        var rightItems: [UIBarButtonItem]

        if !allFeeds.isEmpty {
            addTrashButton(true)
            rightItems = [addButton, searchButton]
        }
        else {
            feedListView?.tableView.alpha = .zero
            rightItems = [addButton]
        }

        navigationItem.setRightBarButtonItems(rightItems, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        provider?.dataSource = Brain.brain.coreDater.allFeeds()
        feedListView?.reloadTableView()
    }
    
    // MARK: - Actions
    @objc func addPressed (_ sender: UIButton) {        
        showEnterFeedAlertView()
    }
    
    @objc func trashPressed (_ sender: UIButton) {
        guard let tableView = feedListView?.tableView else {
            return
        }
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    // MARK: - Base override
    override func addFeedPressed(_ URL: String) {
        if Brain.brain.isDuplicateURL(URL) {
            showDuplicateFeedAlert()
        }
        else {
            showSpinner()
            startParsingURL(URL)
        }
    }

    override func searchForFeedsPressed(with webPage: String) {
        showSpinner()

        service.searchFeeds(on: webPage, completion: { [weak self] result in
            print("RESULT --- > \(result)")

            DispatchQueue.main.async {
                self?.hideSpinner()
            }
        })
    }
    
    // MARK: - ParserDelegate API
    override func didEndParsingFeed(_ feed: Feed) {
        super.didEndParsingFeed(feed)

        provider?.dataSource.append(feed)
        Brain.brain.coreDater.saveContext()

        feedListView?.reloadTableView()

        /// Add `trash` only if there is no `leftBarButtonItem`
        if navigationItem.leftBarButtonItems == nil {
            addTrashButton(true)
            feedListView?.tableView.alpha = 1
        }

        if navigationItem.rightBarButtonItems?.count == 1 {
            navigationItem.rightBarButtonItems?.append(searchButton)
        }
    }
    
    // MARK: - TableProviderProtocol
    func cellDidPress(at indexPath: IndexPath) {
        guard indexPath.row < Brain.brain.coreDater.allFeeds().count else {
            return
        }

        let feed = Brain.brain.feedForIndexPath(indexPath: indexPath)
        let feedItems = feed.sortedItems()

        guard !feedItems.isEmpty else {
            return
        }
        
        let itemsVC = FeedItemsViewController()
        itemsVC.feed = feed
        itemsVC.feedItems = feedItems
        
        navigationController?.pushViewController(itemsVC, animated: true)
    }
    
    func cellNeedsDelete(at indexPath: IndexPath) {
        guard indexPath.row < Brain.brain.coreDater.allFeeds().count else {
            return
        }
        
        let feedToDelete: Feed = Brain.brain.feedForIndexPath(indexPath: indexPath)
        
        Brain.brain.coreDater.deleteObject(feedToDelete)
        Brain.brain.coreDater.saveContext()
        
        provider?.dataSource = Brain.brain.coreDater.allFeeds()
    
        feedListView?.tableView.beginUpdates()
        feedListView?.tableView.deleteRows(at: [indexPath], with: .automatic)
        feedListView?.tableView.endUpdates()
        
        /// Hide `trash` & `search` for no data source
        if provider?.dataSource.isEmpty == true {
            addTrashButton(false)
            
            feedListView?.tableView.setEditing(false, animated: false)
            feedListView?.tableView.alpha = .zero

            navigationItem.rightBarButtonItems?.removeLast()
        }
    }
    
    // MARK: - Helpers
    private func addTrashButton(_ add: Bool) {
        if add {
            navigationItem.setLeftBarButtonItems([trashButton], animated: true)
        }
        else {
            navigationItem.setLeftBarButtonItems(nil, animated: true)
        }
    }
}
