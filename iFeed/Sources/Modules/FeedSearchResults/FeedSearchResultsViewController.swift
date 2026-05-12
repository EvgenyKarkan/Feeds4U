//
//  FeedSearchResultsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit

// TODO: - consider renaming this UX, `search` may be confusing
// Maybe ExploreRSSResultsViewController

final class FeedSearchResultsViewController: UITableViewController {

    // MARK: - Properties
    private lazy var searchResults: FeedSearchDTO = []
    private lazy var webPageTitle: String = String()
    private var selectionCallback: ((String) -> Void)?

    private let reuseId = FeedSearchResultsCell.reuseId

    // MARK: - Constructor
    /// Returns `UINavigationController` with `Self` embedded into as `rootViewController`
    static func create(with data: FeedSearchDTO,
                       webPage: String,
                       selectionCallback: @escaping ((String) -> Void)) -> UINavigationController {
        let resultsController = FeedSearchResultsViewController.instanceFromNib()
        resultsController.searchResults = data
        resultsController.webPageTitle = webPage
        resultsController.selectionCallback = selectionCallback

        let navigationVC = UINavigationController(rootViewController: resultsController)
        navigationVC.modalPresentationStyle = .fullScreen

        return navigationVC
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = webPageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissScreen)
        )

        let nibName = String(describing: FeedSearchResultsCell.self)
        tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: reuseId)
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }

    // MARK: - Action
    @objc private func dismissScreen() {
        dismiss(animated: true)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? FeedSearchResultsCell,
            !searchResults.isEmpty, indexPath.row < searchResults.count else {
            return UITableViewCell()
        }

        let element: FeedSearchElement = searchResults[indexPath.row]
        var isAlreadyStored = false

        if let urlString = element.rssURL,
           let url = URL(string: urlString), DIContainer().storage().isAlreadySavedURL(url.absoluteString) {
            isAlreadyStored = true
        }

        let state: AddState = isAlreadyStored ? .added : .notAdded
        let model: FeedSearchResults = FeedSearchResults(data: element, state: state)

        cell.updateWithResults(model)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < searchResults.count else {
            return
        }

        let model: FeedSearchElement = searchResults[indexPath.row]

        guard let urlString = model.rssURL, !urlString.isEmpty else {
            return
        }

        selectionCallback?(urlString)

        // TODO: - handle successfull selection on UI - check mark shoudl turn orange
    }
}
