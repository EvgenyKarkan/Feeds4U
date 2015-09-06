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
    
    let kItemsCell = "ItemsCell"
    
    
    // MARK: - Overriden base API
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.dataSource.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(kItemsCell) as? UITableViewCell
        
        if cell == nil {
            cell                             = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kItemsCell)
            cell?.accessoryType              = UITableViewCellAccessoryType.DisclosureIndicator
            cell?.backgroundColor            = UIColor.lightGrayColor()
            //            cell?.textLabel?.textColor       = UIColor.whiteColor()
            //            cell?.detailTextLabel?.textColor = UIColor.whiteColor()
        }
        
        var item: FeedItem?
        
        if self.dataSource.count > 0 && indexPath.row < self.dataSource.count {
            item = self.dataSource[indexPath.row] as? FeedItem
        }

        if item != nil {

            //println("Summary ==== \(item)")
            
            var dateFormatter        = NSDateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy hh:mm"
            
            var dateString = dateFormatter.stringFromDate(item!.publishDate)
            
            cell!.textLabel?.text       = item?.title
            cell!.detailTextLabel?.text = dateString
        }
        
        return cell!
    }
}
