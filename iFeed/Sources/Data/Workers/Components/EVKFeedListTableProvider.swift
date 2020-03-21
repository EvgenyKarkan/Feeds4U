//
//  EVKFeedListTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedListTableProvider: EVKBaseTableProvider {
 
    private let kFeedCell: String = "FeedCell"
    
    // MARK: - Overriden base API
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: kFeedCell) as? EVKFeedCell
        
        if cell == nil {
            cell = EVKFeedCell(style: .subtitle, reuseIdentifier: kFeedCell)
            cell?.accessoryType = .disclosureIndicator
        }
        
        var feed: Feed?
        feed = dataSource[(indexPath as NSIndexPath).row] as? Feed

        if feed != nil {
            cell!.titleText = feed?.title
            cell!.subTitleText = feed?.summary
            cell!.itemsCountText = (feed?.unreadItems().count)?.description
        }
        
        return cell!
    }
}
