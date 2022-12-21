//
//  EVKFeedItemsTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedItemsTableProvider: EVKBaseTableProvider {
   
    // MARK: - Constant
    private let kItemsCell = "ItemsCell"
    
    // MARK: - Overriden base API
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: kItemsCell) as? EVKFeedCell
        
        if cell == nil {
            cell = EVKFeedCell(style: .subtitle, reuseIdentifier: kItemsCell)
            cell?.accessoryType = .disclosureIndicator
        }
        
        var item: FeedItem?
        
        if !dataSource.isEmpty && indexPath.row < dataSource.count {
            item = dataSource[indexPath.row] as? FeedItem
        }

        if item != nil {
            //TODO:- Cache date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy hh:mm"
            
            let dateString = dateFormatter.string(from: item!.publishDate as Date)

            cell!.wasReadCell = item!.wasRead.boolValue
            cell!.titleText = item!.title
            cell!.subTitleText = dateString
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
