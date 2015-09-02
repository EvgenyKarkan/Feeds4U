//
//  EVKBaseTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/1/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKBaseTableProvider: NSObject, UITableViewDelegate, UITableViewDataSource {
   
    //MARK: - properties
    var dataSource: [AnyObject] = []
    
    var delegate: EVKTableProviderProtocol?
    
    
    //MARK: - Designated init
    init (delegateObject: EVKTableProviderProtocol) {
        
        self.delegate   = delegateObject
        
        println("Delegate obj is \(self.delegate)")
        
        //assert(!self.delegate.isEqual(nil), "Delegate can't be nil")
    }
    
    
    //MARK: - UITableViewDelegate & UITableViewDatasource API
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return 50.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        println(self.dataSource.count)
        
        return self.dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell()
        
        return cell
    }
}


protocol EVKTableProviderProtocol {
    
    
}
