//
//  FeedsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import Dispatch

final class FeedsViewController: BaseViewController {

    // MARK: - Properties
    private var feedListView: FeedsView?
    private var provider: FeedsTableProvider?
    lazy var search: Search = Search()
    private lazy var service: FeedSearchService = FeedSearchService()

    // MARK: - Private Properties
    private lazy var addButton: UIBarButtonItem = {
        var addAction: UIAction {
            let title = String.localized(key: LocalizableKeys.Feed.enterNew)
            let image = UIImage(systemName: "plus.circle")
            let action = UIAction(title: title, image: image) { [weak self] _ in
                self?.showEnterFeedAlertView()
            }
            return action
        }

        var searchAction: UIAction {
            let title = String.localized(key: LocalizableKeys.Feed.explore)
            let image = UIImage(systemName: "globe")
            let action = UIAction(title: title, image: image) { [weak self] _ in
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

    private lazy var searchButton: UIBarButtonItem = {
        return UIBarButtonItem(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(searchPressed)
        )
    }()

    private lazy var trashButton: UIBarButtonItem = {
        return UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(trashPressed)
        )
    }()

    // MARK: - Deinit
    deinit {
        provider?.delegate = nil
    }

    // MARK: - Life cycle
    override func loadView() {
        provider = FeedsTableProvider(delegateObject: self)

        feedListView = FeedsView(frame: UIScreen.main.bounds)
        feedListView?.tableView.delegate = provider
        feedListView?.tableView.dataSource = provider

        view = feedListView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let allFeeds = Brain.brain.coreDater.allFeeds()
        var rightItems: [UIBarButtonItem]

        if !allFeeds.isEmpty {
            addTrashButton(true)
            rightItems = [addButton, searchButton]
        } else {
            feedListView?.tableView.alpha = .zero
            rightItems = [addButton]
        }

        navigationItem.setRightBarButtonItems(rightItems, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        provider?.dataSource = Brain.brain.coreDater.allFeeds()
        feedListView?.reloadTableView()
    }

    // MARK: - Base override
    override func addFeedPressed(_ URL: String) {
        if Brain.brain.isAlreadySavedURL(URL) {
            showAlreadySavedFeedAlert()
        } else {
            showSpinner()
            startParsingURL(URL)
        }
    }

    override func searchForFeedsPressed(with webPage: String) {
        showSpinner()

        service.searchFeeds(on: webPage, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.hideSpinner()

                switch result {
                case .success(let data):
                    /// Filter data from items with invalid URL
                    let filteredData: FeedSearchDTO = data.compactMap { element -> FeedSearchElement? in
                        if let urlString = element.rssURL, URL(string: urlString) != nil {
                            return element
                        }
                        return nil
                    }
                    guard !filteredData.isEmpty else {
                        // TODO: - Handle this case on UI
                        self?.showErrorAlertView(error: NSError(domain: #function, code: #line))
                        return
                    }

                    let callback: ((Feed) -> Void)? = { feed in
                        self?.didEndParsingFeed(feed)
                    }
                    let resultsVC = FeedSearchResultsViewController.create(
                        with: filteredData,
                        webPage: webPage,
                        parsingCallback: callback
                    )
                    self?.present(resultsVC, animated: true)
                case .failure(let error):
                    self?.showErrorAlertView(error: error)
                }
            }
        })
    }

    // MARK: - ParserDelegateProtocol base override
    override func didEndParsingFeed(_ feed: Feed) {
        super.didEndParsingFeed(feed)

        provider?.dataSource.append(feed)
        Brain.brain.coreDater.saveContext()

        feedListView?.reloadTableView()

        /// Add `trash` only if there is no `leftBarButtonItem`
        if navigationItem.leftBarButtonItems == nil {
            addTrashButton(true)
            feedListView?.tableView.alpha = 1
        }

        if navigationItem.rightBarButtonItems?.count == 1 {
            navigationItem.rightBarButtonItems?.append(searchButton)
        }
    }
}

// MARK: - TableProviderDelegate
extension FeedsViewController: TableProviderDelegate {

    func tableProvider(_ provider: BaseTableProvider, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < Brain.brain.coreDater.allFeeds().count else {
            return
        }

        let feed = Brain.brain.feedForIndexPath(indexPath)

        guard let feedItems = feed?.sortedItems(), !feedItems.isEmpty else {
            return
        }

        let itemsVC = FeedItemsViewController()
        itemsVC.feed = feed
        itemsVC.feedItems = feedItems

        navigationController?.pushViewController(itemsVC, animated: true)
    }

    func tableProvider(_ provider: BaseTableProvider, didDeleteRowAt indexPath: IndexPath) {
        guard indexPath.row < Brain.brain.coreDater.allFeeds().count,
            let feedToDelete: Feed = Brain.brain.feedForIndexPath(indexPath) else {
            return
        }

        Brain.brain.coreDater.deleteObject(feedToDelete)
        Brain.brain.coreDater.saveContext()

        self.provider?.dataSource = Brain.brain.coreDater.allFeeds()

        feedListView?.tableView.beginUpdates()
        feedListView?.tableView.deleteRows(at: [indexPath], with: .fade)
        feedListView?.tableView.endUpdates()

        /// Hide `trash` & `search` if no data source
        if self.provider?.dataSource.isEmpty == true {
            DispatchQueue.main.async(execute: { [weak self] in
                self?.addTrashButton(false)

                self?.feedListView?.tableView.setEditing(false, animated: false)
                self?.feedListView?.tableView.alpha = .zero

                self?.navigationItem.rightBarButtonItems?.removeLast()
            })
        }
    }
}

// MARK: - Actions + Helpers
private extension FeedsViewController {

    @objc func addPressed() {
        showEnterFeedAlertView()
    }

    @objc func trashPressed() {
        guard let tableView = feedListView?.tableView else {
            return
        }
        tableView.setEditing(!tableView.isEditing, animated: true)
    }

    func addTrashButton(_ add: Bool) {
        let items: [UIBarButtonItem]? = add ? [trashButton] : nil
        navigationItem.setLeftBarButtonItems(items, animated: true)
    }
}
