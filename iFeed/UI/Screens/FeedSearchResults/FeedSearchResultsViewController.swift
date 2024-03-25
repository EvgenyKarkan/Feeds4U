//
//  FeedSearchResultsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedSearchResultsViewController: UITableViewController {

    // MARK: - Properties
    private var searchResults: FeedSearchDTO = []
    private var webPageTitle: String = String()
    private var feedParseCallback: ((Feed) -> Void)?

    private var reuseId = FeedSearchResultsCell.reuseId
    private lazy var parser = Parser()

    // MARK: - Constructor
    /// Returns `UINavigationController` with `Self` embedded into as `rootViewController`
    static func create(with data: FeedSearchDTO,
                       webPage: String,
                       parsingCallback: ((Feed) -> Void)?) -> UINavigationController {
        let vcr = FeedSearchResultsViewController.instanceFromNib()
        vcr.searchResults = data
        vcr.webPageTitle = webPage
        vcr.feedParseCallback = parsingCallback

        let navigationVC = UINavigationController(rootViewController: vcr)
        navigationVC.modalPresentationStyle = .fullScreen

        return navigationVC
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        parser.delegate = self

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

        if let urlString = element.selfURL,
            let url = URL(string: urlString), Brain.brain.isAlreadySavedURL(url.absoluteString) {
            isAlreadyStored = true
        }

        let state: AddedState = isAlreadyStored ? .added : .notAdded
        let model: FeedSearchResults = FeedSearchResults(data: element, state: state)

        cell.updateWithResults(model)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < searchResults.count else {
            return
        }

        let model: FeedSearchElement = searchResults[indexPath.row]

        guard let urlString = model.selfURL,
            let url = URL(string: urlString) else {
            return
        }

        /// Consider to move it to parser and return some method from protocol
        if Brain.brain.isAlreadySavedURL(url.absoluteString) {
            showAlreadySavedFeedAlert()
        } else {
            showSpinner()
            parser.beginParsingURL(url)
        }
    }
}

// MARK: - ParserDelegateProtocol
extension FeedSearchResultsViewController: ParserDelegateProtocol {

    func didEndParsingFeed(_ feed: Feed) {
        hideSpinner()

        dump(feed)

        feedParseCallback?(feed)
        tableView.reloadData()
    }

    func didFailParsingFeed() {
        hideSpinner()
        tableView.reloadData()
    }
}
