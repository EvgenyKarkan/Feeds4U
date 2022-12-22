//
//  EVKFeedListTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKFeedListTableProvider: EVKBaseTableProvider {
    
    // MARK: - Overriden base API
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseId) as? FeedCell else {
            return UITableViewCell()
        }
        guard !dataSource.isEmpty, indexPath.row < dataSource.count,
            let feed: Feed = dataSource[indexPath.row] as? Feed else {
            return UITableViewCell()
        }

        cell.titleText = feed.title
        cell.subTitleText = feed.summary
        cell.itemsCountText = feed.unreadItems().count.description
        
        return cell
    }
}
