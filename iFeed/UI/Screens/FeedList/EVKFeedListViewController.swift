//
//  EVKFeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

final class EVKFeedListViewController: EVKBaseViewController, EVKTableProviderProtocol {

    // MARK: - Properties
    private var feedListView: EVKFeedListView?
    private var provider: EVKFeedListTableProvider?
    lazy var search: Search = Search()

    private lazy var addButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .add,
                               target: self,
                               action: #selector(addPressed))
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
        provider = EVKFeedListTableProvider(delegateObject: self)
        
        feedListView = EVKFeedListView(frame: UIScreen.main.bounds)
        feedListView?.tableView.delegate = provider
        feedListView?.tableView.dataSource = provider

        view = feedListView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let allFeeds = EVKBrain.brain.coreDater.allFeeds()
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
        
        provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        feedListView?.reloadTableView()
    }
    
    // MARK: - Actions
    @objc func addPressed (_ sender: UIButton) {        
        showEnterFeedAlertView(String())
    }
    
    @objc func trashPressed (_ sender: UIButton) {
        guard let tableView = feedListView?.tableView else {
            return
        }
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    // MARK: - Base override
    override func addFeedPressed (_ URL: String) {
        if EVKBrain.brain.isDuplicateURL(URL) {
            showDuplicateRSSAlert()
        }
        else {
            showSpinner()
            startParsingURL(URL)
        }
    }
    
    // MARK: - EVKParserDelegate API
    override func didEndParsingFeed(_ feed: Feed) {
        super.didEndParsingFeed(feed)

        provider?.dataSource.append(feed)
        EVKBrain.brain.coreDater.saveContext()

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
    
    // MARK: - EVKTableProviderProtocol
    func cellDidPress(at indexPath: IndexPath) {
        guard indexPath.row < EVKBrain.brain.coreDater.allFeeds().count else {
            return
        }

        let feed = EVKBrain.brain.feedForIndexPath(indexPath: indexPath)
        let feedItems = feed.sortedItems()

        guard !feedItems.isEmpty else {
            return
        }
        
        let itemsVC = EVKFeedItemsViewController()
        itemsVC.feed = feed
        itemsVC.feedItems = feedItems
        
        navigationController?.pushViewController(itemsVC, animated: true)
    }
    
    func cellNeedsDelete(at indexPath: IndexPath) {
        guard indexPath.row < EVKBrain.brain.coreDater.allFeeds().count else {
            return
        }
        
        let feedToDelete: Feed = EVKBrain.brain.feedForIndexPath(indexPath: indexPath)
        
        EVKBrain.brain.coreDater.deleteObject(feedToDelete)
        EVKBrain.brain.coreDater.saveContext()
        
        provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
    
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
