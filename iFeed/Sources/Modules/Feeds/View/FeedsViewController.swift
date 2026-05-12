//
//  FeedsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

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

            return button
        }

        return UIBarButtonItem(customView: button)
    }()

    private lazy var trashButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(trashButtonItemDidPress)
        )
    }()

    private lazy var searchButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(searchButtonItemDidPress)
        )
    }()

    // MARK: - Life cycle
    override func loadView() {
        tableViewProvider = FeedsTableProvider(delegate: self)

        feedListView = FeedsView(frame: UIScreen.main.bounds)
        feedListView?.tableView.delegate = tableViewProvider
        feedListView?.tableView.dataSource = tableViewProvider

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
extension FeedsViewController: FeedsViewProtocol {

    func updateOnDidLoad(with viewState: FeedsViewState) {
        let allFeeds = viewState.feeds
        var rightItems: [UIBarButtonItem]

        if !allFeeds.isEmpty {
            addTrashButton(true)
            rightItems = [addButtonItem, searchButtonItem]
        } else {
            feedListView?.tableView.alpha = .zero
            rightItems = [addButtonItem]
        }

        navigationItem.setRightBarButtonItems(rightItems, animated: true)
    }

    func updateOnWillAppear(with viewState: FeedsViewState) {
        tableViewProvider?.dataSource = viewState.feeds
        tableViewProvider?.unreadCounts = viewState.unreadCounts
        feedListView?.reloadTableView()
    }

    func showActivityIndicator() {
        showSpinner()
    }

    func hideActivityIndicator(_ completion: (() -> Void)?) {
        hideSpinner(completion)
    }

    func showEnterSearch() {
        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.Search.search),
            message: String.localized(key: LocalizableKeys.Search.description),
            preferredStyle: .alert
        )

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
            textField.addTarget(self,
                                action: #selector(self?.textFieldDidChangeForSearchInput(_:)),
                                for: .editingChanged)
        }

        present(alertController, animated: true)
    }

    func showNoSearchResultsAlert() {
        let noResultsAlert = UIAlertController(
            title: String.localized(key: LocalizableKeys.Search.search),
            message: String.localized(key: LocalizableKeys.Errors.noSearchResults),
            preferredStyle: .alert
        )
        let noResultsCancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.confirmation),
                                                  style: .cancel)
        noResultsAlert.addAction(noResultsCancelAction)

        if presentedViewController == nil {
            present(noResultsAlert, animated: true)
        }
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

    func showFeedParsingError() {
        showInvalidFeedAlert()
    }

    func appendParsedFeed(_ feed: Feed) {
        tableViewProvider?.dataSource.append(feed)
    }

    func updateOnDidEndParsingFeed() {
        feedListView?.reloadTableView()

        /// Add `trash` only if there is no `leftBarButtonItem`
        if navigationItem.leftBarButtonItems == nil {
            addTrashButton(true)
            feedListView?.tableView.alpha = 1
        }

        if navigationItem.rightBarButtonItems?.count == 1 {
            navigationItem.rightBarButtonItems?.append(searchButtonItem)
        }
    }

    func updateViewAfterFeedDeletionAtIndexPath(_ indexPath: IndexPath, feeds: [Feed]) {
        tableViewProvider?.dataSource = feeds

        feedListView?.tableView.beginUpdates()
        feedListView?.tableView.deleteRows(at: [indexPath], with: .fade)
        feedListView?.tableView.endUpdates()

        /// Hide `trash` & `search` if no data source
        if tableViewProvider?.dataSource.isEmpty == true {
            DispatchQueue.main.async(execute: { [weak self] in
                self?.addTrashButton(false)

                self?.feedListView?.tableView.setEditing(false, animated: false)
                self?.feedListView?.tableView.alpha = .zero

                self?.navigationItem.rightBarButtonItems?.removeLast()
            })
        }
    }
}

// MARK: - TableProviderDelegate
extension FeedsViewController: TableProviderDelegate {

    func tableProvider(_ provider: BaseTableProvider, didSelectRowAt indexPath: IndexPath) {
        presenter?.onViewDidSelectFeedAtIndexPath(indexPath)
    }

    func tableProvider(_ provider: BaseTableProvider, didDeleteRowAt indexPath: IndexPath) {
        presenter?.onViewNeedsToDeleteFeedAtIndexPath(indexPath)
    }

    private var allFeeds: [Feed] {
        return presenter?.getAllFeeds() ?? []
    }

    private func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        return presenter?.feedForIndexPath(indexPath)
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
        presenter?.onViewDidPressSearch()
    }

    func addTrashButton(_ add: Bool) {
        let items: [UIBarButtonItem]? = add ? [trashButtonItem] : nil
        navigationItem.setLeftBarButtonItems(items, animated: true)
    }
}
