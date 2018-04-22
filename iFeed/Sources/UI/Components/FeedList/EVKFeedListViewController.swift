//
//  EVKFeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


class EVKFeedListViewController: EVKBaseViewController, EVKTableProviderProtocol {

    // MARK: - properties
    var feedListView: EVKFeedListView?
    var provider:     EVKFeedListTableProvider?
    let search:       Search = Search()
    
    // MARK: - Deinit
    deinit {
        provider?.delegate = nil
    }
    
    // MARK: - Life cycle
    override func loadView() {
        
        self.provider = EVKFeedListTableProvider(delegateObject: self)
        
        let aView = EVKFeedListView (frame: UIScreen.main.bounds)
        
        self.feedListView = aView
        self.view         = aView
        
        self.feedListView?.tableView.delegate   = self.provider!
        self.feedListView?.tableView.dataSource = self.provider!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.searchPressed(_:)))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addPressed(_:)))
        self.navigationItem.setRightBarButtonItems([searchButton, addButton], animated: true)
        
        if EVKBrain.brain.coreDater.allFeeds().count > 0 {
            self.addTrashButton(true)
        }
        else {
            self.feedListView?.tableView.alpha = 0.0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
        self.feedListView?.tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc func addPressed (_ sender: UIButton) {
        assert(!sender.isEqual(nil), "sender is nil")
        
        self.showEnterFeedAlertView("");
    }
    
    @objc func trashPressed (_ sender: UIButton) {
        let needsEdit: Bool = !self.feedListView!.tableView.isEditing
        
        self.feedListView?.tableView.setEditing(needsEdit, animated: true)
    }
    
    // MARK: - Inherited from base
    override func addFeedPressed (_ URL: String) {
        if EVKBrain.brain.isDuplicateURL(URL) {
            self.showDuplicateRSSAlert()
        }
        else {
            self.startParsingURL(URL)
        }
    }
    
    // MARK: - EVKXMLParserProtocol API
    override func didEndParsingFeed(_ feed: Feed) {
        if !feed.isEqual(nil) {
            self.provider?.dataSource.append(feed)
            EVKBrain.brain.coreDater.saveContext()
            
            self.feedListView?.tableView.reloadData()
            
            //add 'trash' only if there is no leftBarButtonItem
            if self.navigationItem.leftBarButtonItems == nil {
                self.addTrashButton(true)
                self.feedListView?.tableView.alpha = 1.0
            }
        }
    }
    
    // MARK: - EVKTableProviderProtocol
    func cellDidPress(atIndexPath: IndexPath) {
        if (atIndexPath as NSIndexPath).row < EVKBrain.brain.coreDater.allFeeds().count {
            let itemsVC: EVKFeedItemsViewController = EVKFeedItemsViewController()
            itemsVC.feed                            = EVKBrain.brain.feedForIndexPath(indexPath: atIndexPath)
            
            if (itemsVC.feed?.feedItems.count)! > 0 {
                self.navigationController?.pushViewController(itemsVC, animated: true)
            }
        }
    }
    
    func cellNeedsDelete(atIndexPath: IndexPath) {
        if (atIndexPath as NSIndexPath).row < EVKBrain.brain.coreDater.allFeeds().count {
            let feedToDelete: Feed = EVKBrain.brain.feedForIndexPath(indexPath: atIndexPath)
            
            EVKBrain.brain.coreDater.deleteObject(feedToDelete)
            EVKBrain.brain.coreDater.saveContext()
            
            self.provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
            self.feedListView?.tableView.beginUpdates()
            self.feedListView?.tableView.deleteRows(at: [atIndexPath], with: .automatic)
            self.feedListView?.tableView.endUpdates()
            
            //hide 'trash' for no data source
            if self.provider?.dataSource.count == 0 {
                self.addTrashButton(false)
                
                self.feedListView?.tableView.setEditing(false, animated: false)
                self.feedListView?.tableView.alpha = 0.0
            }
        }
    }
    
    // MARK: - Helpers
    func addTrashButton(_ add: Bool) {
        if add {
            let trashButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.trashPressed(_:)))
            self.navigationItem.setLeftBarButtonItems([trashButton], animated: true)
        }
        else {
            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
        }
    }
}
