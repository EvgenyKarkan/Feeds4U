//
//  EVKBaseTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/1/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.cellDidPress(atIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        self.delegate?.cellNeedsDelete!(atIndexPath: indexPath)
    }
}

// MARK: - EVKTableProviderProtocol
@objc protocol EVKTableProviderProtocol : class {
    func cellDidPress(atIndexPath: IndexPath)
    @objc optional func cellNeedsDelete(atIndexPath: IndexPath)
}
