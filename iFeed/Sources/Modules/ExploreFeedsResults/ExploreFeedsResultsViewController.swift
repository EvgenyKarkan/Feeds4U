//
//  ExploreFeedsResultsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit

final class ExploreFeedsResultsViewController: UITableViewController {

    // MARK: - Properties
    private lazy var searchResults: ExploreFeedsDTO = []
    private lazy var webPageTitle: String = String()
    private var selectionCallback: ((String) -> Void)?
    private var savedURLs: Set<String> = []

    private let reuseId = ExploreFeedsResultCell.reuseId

    // MARK: - Constructor
    /// Returns `UINavigationController` with `Self` embedded into as `rootViewController`
    static func create(with data: ExploreFeedsDTO,
                       webPage: String,
                       selectionCallback: @escaping ((String) -> Void)) -> UINavigationController {
        let resultsController = ExploreFeedsResultsViewController.instanceFromNib()
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

        let nibName = String(describing: ExploreFeedsResultCell.self)
        tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: reuseId)
        tableView.estimatedRowHeight = UITableView.automaticDimension

        savedURLs = NewCoreDataManager.shared.savedFeedURLs()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? ExploreFeedsResultCell,
            !searchResults.isEmpty, indexPath.row < searchResults.count else {
            return UITableViewCell()
        }

        let element: ExploreFeedsElement = searchResults[indexPath.row]
        let isAlreadyStored = element.rssURL.flatMap { URL(string: $0)?.absoluteString }.map { savedURLs.contains($0) } ?? false

        let state: AddState = isAlreadyStored ? .added : .notAdded
        let model: ExploreFeedsResult = ExploreFeedsResult(data: element, state: state)

        cell.updateWithResults(model)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < searchResults.count else {
            return
        }

        let model: ExploreFeedsElement = searchResults[indexPath.row]

        guard let urlString = model.rssURL, !urlString.isEmpty else {
            return
        }

        selectionCallback?(urlString)
        savedURLs = NewCoreDataManager.shared.savedFeedURLs()


        // TODO: - handle successfull selection on UI - check mark shoudl turn orange

        // tableView.reloadRows(at: [indexPath], with: .automatic) ?
    }
}
