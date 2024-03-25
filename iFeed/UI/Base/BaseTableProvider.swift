//
//  BaseTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/1/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

// MARK: - TableProviderProtocol
@objc protocol TableProviderProtocol: AnyObject {
    func cellDidPress(at indexPath: IndexPath)
    @objc optional func cellNeedsDelete(at indexPath: IndexPath)
}

class BaseTableProvider: NSObject, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    var dataSource: [AnyObject] = []
    weak var delegate: TableProviderProtocol?

    // MARK: - Designated init
    required init(delegateObject: TableProviderProtocol) {
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
