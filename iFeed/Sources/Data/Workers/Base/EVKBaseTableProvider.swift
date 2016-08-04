//
//  EVKBaseTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/1/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


class EVKBaseTableProvider: NSObject, UITableViewDelegate, UITableViewDataSource {
   
    // MARK: - properties
    var dataSource: [AnyObject] = []
    weak var delegate: EVKTableProviderProtocol?
    
    // MARK: - Designated init
    init (delegateObject: EVKTableProviderProtocol) {
        self.delegate = delegateObject

        super.init()
        
        assert(self.delegate != nil, "Delegate can't be nil")
    }
    
    // MARK: - UITableViewDelegate & UITableViewDatasource API
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.cellDidPress(atIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.cellNeedsDelete!(atIndexPath: indexPath)
    }
}

// MARK: - EVKTableProviderProtocol
@objc protocol EVKTableProviderProtocol : class {
    func cellDidPress(atIndexPath atIndexPath: NSIndexPath)
    optional func cellNeedsDelete(atIndexPath atIndexPath: NSIndexPath)
}
