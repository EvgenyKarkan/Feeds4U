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
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(kItemsCell) as? EVKFeedCell
        
        if cell == nil {
            cell                = EVKFeedCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kItemsCell)
            cell?.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        
        var item: FeedItem?
        
        if self.dataSource.count > 0 && indexPath.row < self.dataSource.count {
            item = self.dataSource[indexPath.row] as? FeedItem
        }

        if item != nil {
            let dateFormatter        = NSDateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy hh:mm"
            
            let dateString = dateFormatter.stringFromDate(item!.publishDate)

            cell!.wasReadCell  = item!.wasRead.boolValue
            cell!.titleText    = item!.title
            cell!.subTitleText = dateString
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}
