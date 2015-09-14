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
    var feedListView: EVKFeedListView
    var provider:     EVKFeedListTableProvider?
    
    // MARK: - Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        self.feedListView = EVKFeedListView()
        
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
        self.view         = aView
        
        self.feedListView.tableView.delegate   = self.provider!
        self.feedListView.tableView.dataSource = self.provider!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var addButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add,
                                                                      target: self,
                                                                      action: "addPressed:")
        self.navigationItem.setRightBarButtonItems([addButton], animated: true)
        
        if EVKBrain.brain.coreDater.allFeeds().count > 0 {
            addTrashButton(true)
        }
        else {
            self.feedListView.tableView.alpha = 0.0
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
        self.feedListView.tableView.reloadData()
    }
    
    // MARK: - Actions
    func addPressed (sender: UIButton) {
        
        assert(!sender.isEqual(nil), "sender is nil")
        
        showEnterFeedAlertView(sender);
    }
    
    func trashPressed (sender: UIButton) {

        var needsEdit: Bool = !self.feedListView.tableView.editing
        
        self.feedListView.tableView.setEditing(needsEdit, animated: true)
    }
    
    // MARK: - Inherited from base
    override func addFeedPressed (URL: String) {
        
        if EVKBrain.brain.isDuplicateURL(URL) {
            showDuplicateRSSAlert()
        }
        else {
            startParsingURL(URL)
        }
    }
    
    // MARK: - EVKXMLParserProtocol API
    override func didEndParsingFeed(feed: Feed) {

        if !feed.isEqual(nil) {
            self.provider?.dataSource.append(feed)
            EVKBrain.brain.coreDater.saveContext()
            
            self.feedListView.tableView.reloadData()
            
            //add 'trash' only if there is no leftBarButtonItem
            if self.navigationItem.leftBarButtonItems == nil {
                addTrashButton(true)
                self.feedListView.tableView.alpha = 1.0
            }
        }
    }
    
    // MARK: - EVKTableProviderProtocol
    func cellDidPress(#atIndexPath: NSIndexPath) {

        if atIndexPath.row < EVKBrain.brain.coreDater.allFeeds().count {
            var itemsVC: EVKFeedItemsViewController = EVKFeedItemsViewController()
            itemsVC.feed                            = EVKBrain.brain.feedForIndexPath(indexPath: atIndexPath)
            
            if itemsVC.feed?.feedItems.count > 0 {
                self.navigationController?.pushViewController(itemsVC, animated: true)
            }
        }
    }
    
    func cellNeedsDelete(#atIndexPath: NSIndexPath) {
        
        if atIndexPath.row < EVKBrain.brain.coreDater.allFeeds().count {
            var feedToDelete: Feed = EVKBrain.brain.feedForIndexPath(indexPath: atIndexPath)
            
            EVKBrain.brain.coreDater.deleteObject(feedToDelete)
            EVKBrain.brain.coreDater.saveContext()
            
            self.provider?.dataSource = EVKBrain.brain.coreDater.allFeeds()
        
            self.feedListView.tableView.beginUpdates()
            self.feedListView.tableView.deleteRowsAtIndexPaths([atIndexPath], withRowAnimation: .Automatic)
            self.feedListView.tableView.endUpdates()
            
            //hide 'trash' for no data source
            if self.provider?.dataSource.count == 0 {
                addTrashButton(false)
                
                self.feedListView.tableView.setEditing(false, animated: false)
                self.feedListView.tableView.alpha = 0.0
            }
        }
    }
    
    // MARK: - Helpers
    func addTrashButton(add: Bool) {
        
        if add {
            var trashButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash,
                                                                            target: self,
                                                                            action: "trashPressed:")
            
            self.navigationItem.setLeftBarButtonItems([trashButton], animated: true)
        }
        else {
            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
        }
    }
}
