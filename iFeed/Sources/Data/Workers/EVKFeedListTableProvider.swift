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
        
        return EVKBrain.brain.coreDater.allFeeds().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(kFeedCell) as? UITableViewCell
        
        if cell == nil {
            cell                             = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kFeedCell)
            cell?.accessoryType              = UITableViewCellAccessoryType.DisclosureIndicator
            cell?.backgroundColor            = UIColor.lightGrayColor()
            //            cell?.textLabel?.textColor       = UIColor.whiteColor()
            //            cell?.detailTextLabel?.textColor = UIColor.whiteColor()
        }
        
        var feed: Feed?
        feed = EVKBrain.brain.feedForIndexPath(indexPath: indexPath)

        if feed != nil {
            cell!.textLabel?.text       = feed?.title
            cell!.detailTextLabel?.text = feed?.rssURL
        }
        
        return cell!
    }
}
