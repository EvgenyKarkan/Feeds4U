//
//  FeedsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

/// Main screen of the app — displays the user's RSS feed subscriptions organized in sections.
/// Feeds can be ungrouped (top-level) or grouped into folders. Supports:
/// - Adding feeds by URL or exploring/searching for feeds
/// - Swipe-to-delete individual feeds
/// - Drag-and-drop to organize feeds into folders or ungroup them
/// - Collapsible folder sections via `FeedFolderHeaderView`
/// - Local search across all feed items
///
/// Follows VIPER: all user actions are forwarded to `presenter`, UI updates arrive
/// through `FeedsViewProtocol`, and table data is managed by `FeedsTableProvider`.
final class FeedsViewController: BaseListViewController {
    // MARK: - Properties
    var presenter: (any FeedsViewDelegate)?
    private var feedListView: FeedsView?
    private var tableViewProvider: FeedsTableProvider?

    private lazy var addButtonItem: UIBarButtonItem = {
        var addAction: UIAction {
            let action = UIAction(
                title: String.localized(key: LocalizableKeys.Feed.enterNew),
                image: UIImage(systemName: "plus.circle")
            ) { [weak self] _ in
                self?.showEnterFeedAlertView()
            }
            return action
        }

        var searchAction: UIAction {
            let action = UIAction(
                title: String.localized(key: LocalizableKeys.Feed.explore),
                image: UIImage(systemName: "globe")
            ) { [weak self] _ in
                self?.showSearchForFeedsAlertView()
            }
            return action
        }

        var contextMenu: UIMenu {
            return UIMenu(
                title: String.localized(key: LocalizableKeys.Feed.addNewLite),
                children: [addAction, searchAction]
            )
        }

        var button: UIButton {
            let image = UIImage(systemName: "plus")

            let button = UIButton(type: .system)
            button.setImage(image, for: .normal)
            button.menu = contextMenu
            button.showsMenuAsPrimaryAction = true
            button.accessibilityIdentifier = AccessibilityID.addFeedButton

            return button
        }

        return UIBarButtonItem(customView: button)
    }()

    private lazy var trashButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(trashButtonItemDidPress)
        )
        button.tintColor = .systemBlue
        button.accessibilityIdentifier = AccessibilityID.trashButton

        return button
    }()

    private var searchButton: UIButton?

    private lazy var searchButtonItem: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.addTarget(self, action: #selector(searchButtonItemDidPress), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityID.searchButton
        searchButton = button
        return UIBarButtonItem(customView: button)
    }()

    private lazy var fixedSpace: UIBarButtonItem = {
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 16
        return space
    }()

    // MARK: - Life cycle

    /// Sets up the table view with its data source, delegate, drag-and-drop support,
    /// and folder header registration. Uses `FeedsTableProvider` as an external
    /// delegate/dataSource to keep this VC focused on lifecycle and VIPER wiring.
    override func loadView() {
        tableViewProvider = FeedsTableProvider(delegate: self)
        tableViewProvider?.folderToggleHandler = { [weak self] folderId in
            self?.presenter?.onViewNeedsToToggleFolder(id: folderId)
        }

        /// `.zero` is intentional — once this view is assigned to the controller's
        /// `view`, the system resizes it to fill the window, so a real frame here
        /// would be overwritten anyway. Avoids the multi-scene-deprecated `UIScreen.main`.
        feedListView = FeedsView(frame: .zero)

        guard let tableView = feedListView?.tableView else {
            view = feedListView
            return
        }

        tableView.delegate = tableViewProvider
        tableView.dataSource = tableViewProvider

        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true

        tableView.register(
            FeedFolderHeaderView.self,
            forHeaderFooterViewReuseIdentifier: FeedFolderHeaderView.reuseId
        )

        view = feedListView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter?.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter?.onViewWillAppear()
    }

    // MARK: - Base override
    override func searchForFeedsPressed(with webPage: String) {
        presenter?.onViewNeedsToExploreFeeds(on: webPage)
    }

    override func addFeedPressed(_ URL: String) {
        presenter?.onViewNeedsToAddFeed(from: URL)
    }
}

// MARK: - FeedsViewProtocol
/// Presenter-driven UI updates. Each method receives a `FeedsViewState` snapshot
/// and applies it to the table provider, then refreshes the table view and navigation buttons.
extension FeedsViewController: @MainActor FeedsViewProtocol {

    func updateOnDidLoad(with viewState: FeedsViewState) {
        let allFeeds = viewState.allFeeds
        var rightItems: [UIBarButtonItem]

        if !allFeeds.isEmpty {
            addTrashButton(true)
            rightItems = [addButtonItem, fixedSpace, searchButtonItem]
        } else {
            feedListView?.tableView.alpha = .zero
            rightItems = [addButtonItem]
        }

        navigationItem.setRightBarButtonItems(rightItems, animated: true)
    }

    func updateOnWillAppear(with viewState: FeedsViewState) {
        applyViewState(viewState)
    }

    func showActivityIndicator() {
        showSpinner()
    }

    func hideActivityIndicator(_ completion: (() -> Void)?) {
        hideSpinner(completion)
    }

    func configureSearchButtonMenu(_ searches: [String]) {
        guard let button = searchButton else { return }

        if searches.isEmpty {
            button.menu = nil
            button.showsMenuAsPrimaryAction = false
            return
        }

        let recentActions = searches.map { query in
            UIAction(
                title: query,
                image: UIImage(systemName: "clock.arrow.circlepath")
            ) { [weak self] _ in
                self?.presenter?.onViewNeedsToSearchFeeds(by: query)
            }
        }

        let recentMenu = UIMenu(title: "", options: .displayInline, children: recentActions)

        let newSearchAction = UIAction(
            title: String.localized(key: LocalizableKeys.Search.newSearch),
            image: UIImage(systemName: "magnifyingglass")
        ) { [weak self] _ in
            self?.showEnterSearch()
        }

        let clearAction = UIAction(
            title: String.localized(key: LocalizableKeys.Search.clearRecent),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.presenter?.onViewNeedsToClearRecentSearches()
        }

        button.menu = UIMenu(
            title: String.localized(key: LocalizableKeys.Search.recentSearches),
            children: [recentMenu, newSearchAction, clearAction]
        )
        button.showsMenuAsPrimaryAction = true
    }

    func showEnterSearch() {
        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.Search.search),
            message: String.localized(key: LocalizableKeys.Search.description),
            preferredStyle: .alert
        )
        alertController.view.accessibilityIdentifier = AccessibilityID.searchInputAlert

        let cancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .cancel) { [weak self] _ in
            self?.nextAction = nil
        }
        alertController.addAction(cancelAction)

        nextAction = UIAlertAction(title: alertController.title, style: .default) { [weak self, weak alertController] _ in
            guard let query = alertController?.textFields?.first?.text,
                !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                self?.nextAction = nil
                return
            }
            self?.nextAction = nil
            self?.presenter?.onViewNeedsToSearchFeeds(by: query)
        }
        nextAction?.isEnabled = false

        guard let nextAction = nextAction else { return }

        alertController.addAction(nextAction)
        alertController.addTextField { [weak self] textField in
            textField.placeholder = String.localized(key: LocalizableKeys.Search.placeholder)
            textField.accessibilityIdentifier = AccessibilityID.alertTextField
            textField.addTarget(self,
                                action: #selector(self?.textFieldDidChangeForSearchInput(_:)),
                                for: .editingChanged)
        }

        presentGuarded(alertController)
    }

    func showNoSearchResultsAlert() {
        let noResultsAlert = UIAlertController(
            title: String.localized(key: LocalizableKeys.Search.search),
            message: String.localized(key: LocalizableKeys.Errors.noSearchResults),
            preferredStyle: .alert
        )
        noResultsAlert.view.accessibilityIdentifier = AccessibilityID.noSearchResultsAlert
        let noResultsCancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.confirmation),
                                                  style: .cancel)
        noResultsAlert.addAction(noResultsCancelAction)

        presentGuarded(noResultsAlert)
    }

    func showNoFeedsDiscoveredAlert() {
        let alert = UIAlertController(
            title: String.localized(key: LocalizableKeys.Feed.explore),
            message: String.localized(key: LocalizableKeys.Errors.noFeedsDiscovered),
            preferredStyle: .alert
        )
        alert.view.accessibilityIdentifier = AccessibilityID.noFeedsDiscoveredAlert
        let okAction = UIAlertAction(title: String.localized(key: LocalizableKeys.confirmation),
                                     style: .cancel)
        alert.addAction(okAction)

        presentGuarded(alert)
    }

    func disableTableViewEditingStateIfNeeded() {
        guard let tableView = feedListView?.tableView, tableView.isEditing else {
            return
        }
        tableView.setEditing(false, animated: true)
    }

    func showError(_ error: any Error) {
        showErrorAlertView(error: error)
    }

    func showFeedIsAlreadySavedError() {
        showAlreadySavedFeedAlert()
    }

    func showFeedParsingError(_ message: String) {
        showErrorAlert(message)
    }

    func updateOnDidEndParsingFeed(with viewState: FeedsViewState) {
        applyViewState(viewState)
    }

    /// Animates row/section removal. If the deleted feed was the last one in a folder,
    /// `sectionIndex` is non-nil and the entire folder section is removed.
    func animateFeedDeletion(at indexPath: IndexPath, removeSectionAt sectionIndex: Int?, with viewState: FeedsViewState) {
        guard let tableView = feedListView?.tableView else {
            applyViewState(viewState)
            return
        }

        tableView.performBatchUpdates {
            self.tableViewProvider?.sections = viewState.sections
            self.tableViewProvider?.unreadCounts = viewState.unreadCounts

            if let sectionIndex {
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }

        updateNavigationButtons(for: viewState)
    }

    func reloadFeedsList(with viewState: FeedsViewState) {
        applyViewState(viewState)
    }

    /// Animates expanding/collapsing a folder section by replacing the section's
    /// rows in a single `performBatchUpdates` — deleting the rows currently shown,
    /// then inserting the new set. Also refreshes the header's chevron state.
    ///
    /// The delete count is read straight from the table view, never from a
    /// caller-supplied snapshot, so it always equals what the table actually
    /// displays. Under rapid/chaotic toggling the presenter's snapshot can drift
    /// from the table, and a mismatched delete count is exactly what raises
    /// "invalid number of rows in section". Deleting all current rows and
    /// inserting all new rows is always count-consistent (old − old + new == new).
    func animateFolderToggle(at sectionIndex: Int, with viewState: FeedsViewState) {
        guard let tableView = feedListView?.tableView,
              sectionIndex < viewState.sections.count,
              sectionIndex < tableView.numberOfSections else {
            tableViewProvider?.sections = viewState.sections
            tableViewProvider?.unreadCounts = viewState.unreadCounts
            feedListView?.reloadTableView()
            return
        }

        let section = viewState.sections[sectionIndex]
        let isExpanded = section.folder?.isExpanded ?? true
        let newRowCount = isExpanded ? section.feeds.count : 0
        let currentRowCount = tableView.numberOfRows(inSection: sectionIndex)

        tableView.performBatchUpdates {
            self.tableViewProvider?.sections = viewState.sections
            self.tableViewProvider?.unreadCounts = viewState.unreadCounts

            if currentRowCount > 0 {
                let paths = (0..<currentRowCount).map { IndexPath(row: $0, section: sectionIndex) }
                tableView.deleteRows(at: paths, with: .fade)
            }
            if newRowCount > 0 {
                let paths = (0..<newRowCount).map { IndexPath(row: $0, section: sectionIndex) }
                tableView.insertRows(at: paths, with: .fade)
            }
        }

        if let header = tableView.headerView(forSection: sectionIndex) as? FeedFolderHeaderView {
            header.configure(
                name: section.folder?.name ?? "",
                feedCount: section.feeds.count,
                isExpanded: isExpanded
            )
        }
    }
}

// MARK: - TableProviderDelegate
extension FeedsViewController: @MainActor TableProviderDelegate {

    func tableProvider(_ provider: BaseTableProvider, didSelectRowAt indexPath: IndexPath) {
        presenter?.onViewDidSelectFeedAtIndexPath(indexPath)
    }

    func tableProvider(_ provider: BaseTableProvider, didDeleteRowAt indexPath: IndexPath) {
        presenter?.onViewNeedsToDeleteFeedAtIndexPath(indexPath)
    }
}

// MARK: - UITableViewDragDelegate
/// Enables dragging individual feed rows to reorganize them into folders.
/// Each dragged item carries the feed's `rssURL` as its identifier, stored both
/// in the `NSItemProvider` (for the system drag API) and in `localObject` (for
/// fast, type-safe access in the drop delegate without async loading).
extension FeedsViewController: UITableViewDragDelegate {

    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: any UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        guard let feed = tableViewProvider?.feed(at: indexPath) else {
            return []
        }

        let itemProvider = NSItemProvider(object: feed.rssURL as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = feed.rssURL

        return [dragItem]
    }
}

// MARK: - UITableViewDropDelegate
/// Handles three drop scenarios for feed organization:
///
/// 1. **Drop onto a folder section** → moves the feed into that folder.
///    If the feed is already in that folder, it is removed from the folder instead
///    (effectively "ungroups" it back to the top-level list).
///
/// 2. **Drop onto an ungrouped feed row** → prompts the user to create a new folder
///    containing both the dragged feed and the target feed.
///
/// 3. **Drop outside any valid section / onto empty space** → removes the feed from
///    its current folder (moves it back to top-level).
///
/// Only local drags are accepted (`canHandle` rejects external drops).
/// `dropSessionDidUpdate` provides visual feedback: `.insertIntoDestinationIndexPath`
/// when hovering over an ungrouped feed (folder creation), `.insertAtDestinationIndexPath`
/// otherwise (reorder / move into folder).
extension FeedsViewController: UITableViewDropDelegate {

    /// Rejects drops from other apps — only in-app feed reordering is supported.
    func tableView(_ tableView: UITableView,
                   canHandle session: any UIDropSession) -> Bool {
        return session.localDragSession != nil
    }

    /// Provides real-time visual drop feedback as the user drags over the table.
    /// - Hovering over an ungrouped feed row shows "insert into" highlight (merge into new folder).
    /// - Hovering over a folder section or empty area shows "insert at" indicator (move between rows).
    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: any UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard session.localDragSession != nil,
              let sections = tableViewProvider?.sections else {
            return UITableViewDropProposal(operation: .cancel)
        }

        guard let dest = destinationIndexPath, dest.section < sections.count else {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        let destSection = sections[dest.section]

        if destSection.folder == nil && dest.row < destSection.feeds.count {
            return UITableViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
        }

        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    /// Executes the drop by determining the relationship between source and destination:
    /// - Finds which folder (if any) the dragged feed currently belongs to.
    /// - Routes to one of three presenter actions: move to folder, remove from folder, or create new folder.
    func tableView(_ tableView: UITableView,
                   performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let dragItem = coordinator.items.first?.dragItem,
              let sourceURL = dragItem.localObject as? String,
              let sections = tableViewProvider?.sections else {
            return
        }

        let sourceFolder = sections.first { section in
            section.folder != nil && section.feeds.contains { $0.rssURL == sourceURL }
        }?.folder

        let dest = coordinator.destinationIndexPath

        /// No valid destination — remove from folder (move to top-level)
        guard let dest, dest.section < sections.count else {
            presenter?.onViewNeedsToRemoveFeedFromFolder(feedURL: sourceURL)
            return
        }

        let destSection = sections[dest.section]

        if let destFolder = destSection.folder {
            /// Dropped onto the same folder it's already in — treat as "ungroup"
            if destFolder.id == sourceFolder?.id {
                presenter?.onViewNeedsToRemoveFeedFromFolder(feedURL: sourceURL)
            } else {
                /// Dropped onto a different folder — move feed into it
                presenter?.onViewNeedsToMoveFeedToFolder(feedURL: sourceURL, folderId: destFolder.id)
            }
        } else if dest.row < destSection.feeds.count {
            /// Dropped onto an ungrouped feed — prompt to create a new folder with both feeds
            let targetFeed = destSection.feeds[dest.row]
            guard targetFeed.rssURL != sourceURL else {
                return
            }
            showCreateFolderAlert(feedURLs: [sourceURL, targetFeed.rssURL])
        } else {
            /// Dropped past the last row in an ungrouped section — remove from folder
            presenter?.onViewNeedsToRemoveFeedFromFolder(feedURL: sourceURL)
        }
    }
}

// MARK: - Private
private extension FeedsViewController {

    @objc func trashButtonItemDidPress() {
        guard let tableView = feedListView?.tableView else {
            return
        }
        tableView.setEditing(!tableView.isEditing, animated: true)
    }

    @objc func searchButtonItemDidPress() {
        presenter?.onViewNeedsToShowSearchInput()
    }

    func addTrashButton(_ add: Bool) {
        let items: [UIBarButtonItem]? = add ? [trashButtonItem] : nil
        navigationItem.setLeftBarButtonItems(items, animated: true)
    }

    /// Configures the navigation bar buttons and table view visibility based on the current feed count.
    func updateNavigationButtons(for viewState: FeedsViewState) {
        let allFeeds = viewState.allFeeds

        if allFeeds.isEmpty {
            // What: Reset UI for the empty state.
            // Why: Hides deletion and search controls when there is no content to act upon,
            // focusing the user's attention solely on the 'Add' action.
            // Applied synchronously — this method already runs on the main actor,
            // and deferring through a Task would postpone the update by a runloop
            // tick, briefly flashing the stale toolbar state.
            addTrashButton(false)
            feedListView?.tableView.setEditing(false, animated: false)
            feedListView?.tableView.alpha = .zero
            navigationItem.rightBarButtonItems = [addButtonItem]
        } else {
            // What: Restore UI for the populated state.
            // Why: Ensures search and deletion capabilities are available once feeds are present,
            // and reveals the table view if it was previously hidden.
            if navigationItem.leftBarButtonItems == nil {
                addTrashButton(true)
            }
            if feedListView?.tableView.alpha == .zero {
                feedListView?.tableView.alpha = 1
            }
            if navigationItem.rightBarButtonItems?.count == 1 {
                navigationItem.rightBarButtonItems?.append(contentsOf: [fixedSpace, searchButtonItem])
            }
        }
    }

    func showCreateFolderAlert(feedURLs: [String]) {
        let alert = UIAlertController(
            title: String.localized(key: LocalizableKeys.Folder.createTitle),
            message: String.localized(key: LocalizableKeys.Folder.createMessage),
            preferredStyle: .alert
        )
        alert.view.accessibilityIdentifier = AccessibilityID.createFolderAlert

        let cancelAction = UIAlertAction(
            title: String.localized(key: LocalizableKeys.cancel),
            style: .cancel
        ) { [weak self] _ in
            self?.nextAction = nil
        }
        alert.addAction(cancelAction)

        let createAction = UIAlertAction(
            title: String.localized(key: LocalizableKeys.Folder.create),
            style: .default
        ) { [weak self, weak alert] _ in
            self?.nextAction = nil
            guard let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else {
                return
            }
            self?.presenter?.onViewNeedsToCreateFolder(name: name, feedURLs: feedURLs)
        }
        createAction.isEnabled = false
        nextAction = createAction
        alert.addAction(createAction)

        alert.addTextField { [weak self] textField in
            textField.placeholder = String.localized(key: LocalizableKeys.Folder.namePlaceholder)
            textField.accessibilityIdentifier = AccessibilityID.alertTextField
            textField.autocapitalizationType = .words
            textField.addTarget(
                self,
                action: #selector(self?.textFieldDidChangeForSearchInput(_:)),
                for: .editingChanged
            )
        }

        presentGuarded(alert)
    }

    func applyViewState(_ viewState: FeedsViewState) {
        tableViewProvider?.sections = viewState.sections
        tableViewProvider?.unreadCounts = viewState.unreadCounts
        feedListView?.reloadTableView()

        updateNavigationButtons(for: viewState)
    }
}
