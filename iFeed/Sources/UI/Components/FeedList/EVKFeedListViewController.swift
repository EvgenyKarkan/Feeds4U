//
//  EVKFeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedListViewController: EVKBaseViewController, EVKTableProviderProtocol {

    // MARK: - properties
    var feedListView: EVKFeedListView?
    var provider: EVKFeedListTableProvider?
    var search: Search = Search()
    
    // MARK: - Deinit
    deinit {
        provider?.delegate = nil
    }
    
    // MARK: - Life cycle
    override func loadView() {
        
        provider = EVKFeedListTableProvider(delegateObject: self)
        
        let aView = EVKFeedListView(frame: UIScreen.main.bounds)
        
        feedListView = aView
        view = aView
        
        feedListView?.tableView.delegate   = provider!
        feedListView?.tableView.dataSource = provider!
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
        
        if EVKBrain.brain.coreDater.allFeeds().count > 0 {
            addTrashButton(true)
        }
        else {
            feedListView?.tableView.alpha = 0.0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
        feedListView?.tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc func addPressed (_ sender: UIButton) {
        assert(!sender.isEqual(nil), "sender is nil")
        
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
    
    // MARK: - EVKXMLParserProtocol API
    override func didEndParsingFeed(_ feed: Feed) {
        if !feed.isEqual(nil) {
            provider?.dataSource.append(feed)
            EVKBrain.brain.coreDater.saveContext()
            
            feedListView?.tableView.reloadData()
            
            //add 'trash' only if there is no leftBarButtonItem
            if navigationItem.leftBarButtonItems == nil {
                addTrashButton(true)
                feedListView?.tableView.alpha = 1.0
            }
        }
    }
    
    // MARK: - EVKTableProviderProtocol
    func cellDidPress(atIndexPath: IndexPath) {
        if (atIndexPath as NSIndexPath).row < EVKBrain.brain.coreDater.allFeeds().count {
            let itemsVC: EVKFeedItemsViewController = EVKFeedItemsViewController()
            itemsVC.feed = EVKBrain.brain.feedForIndexPath(indexPath: atIndexPath)
            itemsVC.feedItems = itemsVC.feed?.sortedItems()
            
            if (itemsVC.feed?.feedItems.count)! > 0 {
                navigationController?.pushViewController(itemsVC, animated: true)
            }
        }
    }
    
    func cellNeedsDelete(atIndexPath: IndexPath) {
        if (atIndexPath as NSIndexPath).row < EVKBrain.brain.coreDater.allFeeds().count {
            let feedToDelete: Feed = EVKBrain.brain.feedForIndexPath(indexPath: atIndexPath)
            
            EVKBrain.brain.coreDater.deleteObject(feedToDelete)
            EVKBrain.brain.coreDater.saveContext()
            
            provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
            feedListView?.tableView.beginUpdates()
            feedListView?.tableView.deleteRows(at: [atIndexPath], with: .automatic)
            feedListView?.tableView.endUpdates()
            
            //hide 'trash' for no data source
            if provider?.dataSource.count == 0 {
                addTrashButton(false)
                
                feedListView?.tableView.setEditing(false, animated: false)
                feedListView?.tableView.alpha = 0.0
            }
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
