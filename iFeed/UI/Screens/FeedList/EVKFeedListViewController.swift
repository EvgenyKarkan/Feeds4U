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
        
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search,
                                           target: self,
                                           action: #selector(searchPressed(_:)))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add,
                                        target: self,
                                        action: #selector(addPressed(_:)))
        navigationItem.setRightBarButtonItems([searchButton, addButton], animated: true)
        
        if !EVKBrain.brain.coreDater.allFeeds().isEmpty {
            addTrashButton(true)
        }
        else {
            feedListView?.tableView.alpha = .zero
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
        feedListView?.tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc func addPressed (_ sender: UIButton) {        
        showEnterFeedAlertView("");
    }
    
    @objc func trashPressed (_ sender: UIButton) {
        let needsEdit: Bool = !feedListView!.tableView.isEditing
        
        feedListView?.tableView.setEditing(needsEdit, animated: true)
    }
    
    // MARK: - Inherited from base
    override func addFeedPressed (_ URL: String) {
        if EVKBrain.brain.isDuplicateURL(URL) {
            showDuplicateRSSAlert()
        }
        else {
            startParsingURL(URL)
        }
    }
    
    // MARK: - EVKParserDelegate API
    override func didEndParsingFeed(_ feed: Feed) {
        provider?.dataSource.append(feed)
        EVKBrain.brain.coreDater.saveContext()

        feedListView?.tableView.reloadData()

        /// Add `trash` only if there is no `leftBarButtonItem`
        if navigationItem.leftBarButtonItems == nil {
            addTrashButton(true)
            feedListView?.tableView.alpha = 1.0
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
        
        /// Hide `trash` for no data source
        if provider?.dataSource.isEmpty == true {
            addTrashButton(false)
            
            feedListView?.tableView.setEditing(false, animated: false)
            feedListView?.tableView.alpha = .zero
        }
    }
    
    // MARK: - Helpers
    private func addTrashButton(_ add: Bool) {
        if add {
            let trashButton = UIBarButtonItem(barButtonSystemItem: .trash,
                                              target: self,
                                              action: #selector(trashPressed(_:)))
            navigationItem.setLeftBarButtonItems([trashButton], animated: true)
        }
        else {
            navigationItem.setLeftBarButtonItems(nil, animated: true)
        }
    }
}
