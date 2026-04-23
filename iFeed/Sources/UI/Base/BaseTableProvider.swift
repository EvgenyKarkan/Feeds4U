//
//  BaseTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/1/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

// MARK: - TableProviderDelegate
@objc protocol TableProviderDelegate: AnyObject {
    func tableProvider(_ provider: BaseTableProvider, didSelectRowAt indexPath: IndexPath)
    @objc optional func tableProvider(_ provider: BaseTableProvider, didDeleteRowAt indexPath: IndexPath)
}

class BaseTableProvider: NSObject, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    var dataSource: [AnyObject] = []
    weak var delegate: (any TableProviderDelegate)?

    // MARK: - Designated init
    required init(delegateObject: any TableProviderDelegate) {
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
        fatalError("Subclasses must override cellForRowAt")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.tableProvider(self, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        delegate?.tableProvider?(self, didDeleteRowAt: indexPath)
    }
}
