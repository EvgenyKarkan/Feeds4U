//
//  FeedsTableProvider.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import CoreData

/// Serves as the `UITableViewDataSource` and `UITableViewDelegate` for the feeds list.
/// Decouples table view logic from `FeedsViewController`, keeping the VC focused on
/// lifecycle and VIPER wiring.
///
/// The table is organized into `FeedsSection`s — each section is either a named folder
/// (with a collapsible `FeedFolderHeaderView`) or an ungrouped top-level section
/// (no header, `folder == nil`). Collapsed folders return zero rows.
///
/// Data flow: the presenter builds a `FeedsViewState` containing `sections` and
/// `unreadCounts`, which the VC assigns here before calling `reloadTableView()`.
final class FeedsTableProvider: BaseTableProvider {

    // MARK: - Properties
    /// Current table sections — set by the VC each time the presenter provides a new view state.
    var sections: [FeedsSection] = []
    /// Maps each Feed's Core Data `objectID` to its unread item count, used for badge display in cells.
    var unreadCounts: [NSManagedObjectID: Int] = [:]
    /// Called when the user taps a folder header's expand/collapse chevron. Passes the folder's UUID.
    var folderToggleHandler: ((UUID) -> Void)?

    // MARK: - Helpers
    /// Safe lookup used to retrieve the feed model for a given row.
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

    /// One table section per `FeedsSection` — either a folder group or ungrouped feeds.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    /// Returns zero rows for collapsed folders, hiding their feeds without removing the section header.
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

    /// Configures a `FeedCell` with the feed's title, summary, and unread count.
    /// `isNested` indents feeds that belong to a folder for visual hierarchy.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedCell.reuseId) as? FeedCell,
              indexPath.section < sections.count else {
            return UITableViewCell()
        }

        let section = sections[indexPath.section]

        guard indexPath.row < section.feeds.count else {
            return UITableViewCell()
        }

        let feed = section.feeds[indexPath.row]
        let count = unreadCounts[feed.objectID] ?? .zero

        cell.titleText = feed.title
        cell.subTitleText = feed.summary
        cell.itemsCountText = count.description
        cell.isNested = section.folder != nil

        return cell
    }

    // MARK: - UITableViewDelegate (headers)

    /// Returns a `FeedFolderHeaderView` for folder sections only. Ungrouped sections
    /// return `nil` (no header). The header shows the folder name, feed count, and
    /// a chevron whose tap triggers `folderToggleHandler` to expand/collapse the section.
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

    /// Zero height for ungrouped sections (no visible header), automatic sizing for folders.
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < sections.count, sections[section].folder != nil else {
            return .zero
        }
        return UITableView.automaticDimension
    }

    /// Estimated height for folder headers. Returning zero for ungrouped sections
    /// prevents UIKit from reserving any header space.
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard section < sections.count, sections[section].folder != nil else {
            return .zero
        }
        return 36
    }
}
