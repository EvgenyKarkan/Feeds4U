//
//  FeedItemsTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedItemsTableProvider: BaseTableProvider {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy hh:mm"
        formatter.timeZone = .current
        return formatter
    }()

    // MARK: - Overriden base
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseId) as? FeedCell else {
            return UITableViewCell()
        }
        guard !dataSource.isEmpty, indexPath.row < dataSource.count,
            let item: FeedItem = dataSource[indexPath.row] as? FeedItem else {
            return UITableViewCell()
        }

        cell.wasReadCell = item.wasRead.boolValue
        cell.titleText = item.title
        cell.subTitleText = Self.dateFormatter.string(from: item.publishDate)

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
