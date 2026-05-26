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
    var sections: [FeedsSection] = []
    var unreadCounts: [NSManagedObjectID: Int] = [:]
    var folderToggleHandler: ((UUID) -> Void)?

    // MARK: - Helpers
    func feed(at indexPath: IndexPath) -> Feed? {
        guard indexPath.section < sections.count else {
            return nil
        }
        let section = sections[indexPath.section]

        guard indexPath.row < section.feeds.count else {
            return nil
        }

        return section.feeds[indexPath.row]
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else {
            return .zero
        }
        let feedsSection = sections[section]

        if let folder = feedsSection.folder, !folder.isExpanded {
            return .zero
        }

        return feedsSection.feeds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseId) as? FeedCell,
              let feed = feed(at: indexPath) else {
            return UITableViewCell()
        }

        let count = unreadCounts[feed.objectID] ?? .zero

        cell.titleText = feed.title
        cell.subTitleText = feed.summary
        cell.itemsCountText = count.description
        cell.isNested = sections[indexPath.section].folder != nil

        return cell
    }

    // MARK: - UITableViewDelegate (headers)
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < sections.count,
              let folder = sections[section].folder else {
            return nil
        }

        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: FeedFolderHeaderView.reuseId
        ) as? FeedFolderHeaderView else {
            return nil
        }

        header.configure(
            name: folder.name,
            feedCount: sections[section].feeds.count,
            isExpanded: folder.isExpanded
        )

        header.onToggle = { [weak self] in
            self?.folderToggleHandler?(folder.id)
        }

        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < sections.count, sections[section].folder != nil else {
            return .zero
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard section < sections.count, sections[section].folder != nil else {
            return .zero
        }
        return 36
    }
}
