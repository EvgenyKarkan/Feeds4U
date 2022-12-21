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
    init(delegateObject: EVKTableProviderProtocol) {
        delegate = delegateObject
    }
    
    // MARK: - UITableViewDelegate & UITableViewDatasource API    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return .zero
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.cellDidPress(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        delegate?.cellNeedsDelete?(at: indexPath)
    }
}

// MARK: - EVKTableProviderProtocol
@objc protocol EVKTableProviderProtocol: AnyObject {
    func cellDidPress(at indexPath: IndexPath)
    @objc optional func cellNeedsDelete(at indexPath: IndexPath)
}