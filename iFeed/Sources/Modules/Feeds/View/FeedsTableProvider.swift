//
//  FeedsTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import CoreData

final class FeedsTableProvider: BaseTableProvider {

    // MARK: - Properties
    var unreadCounts: [NSManagedObjectID: Int] = [:]

    // MARK: - Overriden base API
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseId) as? FeedCell,
              !dataSource.isEmpty, indexPath.row < dataSource.count,
              let feed: Feed = dataSource[indexPath.row] as? Feed else {
            return UITableViewCell()
        }

        let count = unreadCounts[feed.objectID] ?? .zero

        cell.titleText = feed.title
        cell.subTitleText = feed.summary
        cell.itemsCountText = count.description

        return cell
    }
}
