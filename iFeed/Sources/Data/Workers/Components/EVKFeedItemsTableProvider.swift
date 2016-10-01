//
//  EVKFeedItemsTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


class EVKFeedItemsTableProvider: EVKBaseTableProvider {
   
    // MARK: - Constant
    fileprivate let kItemsCell = "ItemsCell"
    
    // MARK: - Overriden base API
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: kItemsCell) as? EVKFeedCell
        
        if cell == nil {
            cell                = EVKFeedCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: kItemsCell)
            cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        }
        
        var item: FeedItem?
        
        if self.dataSource.count > 0 && (indexPath as NSIndexPath).row < self.dataSource.count {
            item = self.dataSource[(indexPath as NSIndexPath).row] as? FeedItem
        }

        if item != nil {
            let dateFormatter        = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy hh:mm"
            
            let dateString = dateFormatter.string(from: item!.publishDate as Date)

            cell!.wasReadCell  = item!.wasRead.boolValue
            cell!.titleText    = item!.title
            cell!.subTitleText = dateString
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
}
