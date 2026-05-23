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
    var presenter: (any ExploreFeedsViewDelegate)?

    private var results: [ExploreFeedsResult] = []
    private var webPageTitle: String = String()
    private let reuseId = ExploreFeedsResultCell.reuseId

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter?.onViewDidLoad()
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
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? ExploreFeedsResultCell,
            !results.isEmpty, indexPath.row < results.count else {
            return UITableViewCell()
        }

        let result = results[indexPath.row]
        cell.updateWithResult(result)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < results.count else {
            return
        }

        let result = results[indexPath.row]

        guard let url: String = result.data.rssURL, !url.isEmpty else {
            return
        }
        presenter?.onViewNeedsToAddFeed(from: url)
    }
}

// MARK: - ExploreFeedsViewProtocol
extension ExploreFeedsResultsViewController: ExploreFeedsViewProtocol {

    func updateOnDidLoad(with viewState: ExploreFeedsViewState) {
        navigationItem.title = viewState.webPageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissScreen)
        )

        let nibName = String(describing: ExploreFeedsResultCell.self)
        tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: reuseId)
        tableView.estimatedRowHeight = UITableView.automaticDimension

        update(with: viewState)
    }

    func update(with viewState: ExploreFeedsViewState) {
        results = viewState.exploreResults
        tableView.reloadData()
    }

    func showFeedIsAlreadySavedError() {
        showAlreadySavedFeedAlert()
    }

    func showFeedParsingError() {
        showInvalidFeedAlert()
    }

    func showActivityIndicator() {
        showSpinner()
    }

    func hideActivityIndicator() {
        hideSpinner(nil)
    }
}
