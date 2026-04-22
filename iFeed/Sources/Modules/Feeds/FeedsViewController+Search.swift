//
//  FeedsViewController+Search.swift
//  iFeed
//
//  Created by Julius Bahr on 20.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import UIKit
import Dispatch

extension FeedsViewController {

    @objc func searchPressed(_ sender: UIButton) {
        showSpinner()

        search.fillMatchingEngine {
            DispatchQueue.main.async { [weak self] in
                self?.hideSpinner({
                    self?.showEnterSearch()
                })
            }
        }
    }

    func showEnterSearch() {
        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.Search.search),
            message: String.localized(key: LocalizableKeys.Search.description),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .cancel)
        alertController.addAction(cancelAction)

        nextAction = UIAlertAction(title: alertController.title, style: .default) { [weak self] _ in
            guard let query = alertController.textFields?.first?.text,
                !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }

            self?.search.search(for: query, resultsFound: { [weak self] (results) in
                DispatchQueue.main.async {
                    guard let results = results, !results.isEmpty else {
                        let noResultsAlert = UIAlertController(
                            title: alertController.title,
                            message: String.localized(key: LocalizableKeys.Errors.noSearchResults),
                            preferredStyle: .alert
                        )
                        let noResultsCancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.confirmation),
                                                                  style: .cancel)
                        noResultsAlert.addAction(noResultsCancelAction)

                        if self?.presentedViewController == nil {
                            self?.present(noResultsAlert, animated: true)
                        }
                        return
                    }

                    self?.showSearchResults(results: results, for: query)
                }
            })
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

    private func showSearchResults(results: [FeedItem], for query: String) {
        let feedItemsViewController = FeedItemsViewController()
        feedItemsViewController.feedItems = results
        feedItemsViewController.searchTitle = "\(String.localized(key: LocalizableKeys.Search.search))\(":") \(query)"

        navigationController?.pushViewController(feedItemsViewController, animated: true)
    }
}
