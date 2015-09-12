//
//  EVKFeedListTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKFeedListTableProvider: EVKBaseTableProvider {
 
    let kFeedCell: String = "FeedCell"
    
    // MARK: - Overriden base API
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.dataSource.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(kFeedCell) as? EVKFeedCell
        
        if cell == nil {
            cell                = EVKFeedCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kFeedCell)
            cell?.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        
        var feed: Feed?        
        feed = self.dataSource[indexPath.row] as? Feed

        if feed != nil {
            cell!.titleText      = feed?.title
            cell!.subTitleText   = feed?.summary
            cell!.itemsCountText = (feed?.unreadItems().count)?.description
        }
        
        return cell!
    }
}
