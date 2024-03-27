//
//  FeedsViewController+Search.swift
//  iFeed
//
//  Created by Julius Bahr on 20.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import UIKit

extension FeedsViewController {

    @objc func searchPressed(_ sender: UIButton) {
        showSpinner()

        search.fillMatchingEngine {
            DispatchQueue.main.async { [self] in
                hideSpinner()
                showEnterSearch()
            }
        }
    }

    func showEnterSearch() {
        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.search),
            message: String.localized(key: LocalizableKeys.searchDescription),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .cancel)
        alertController.addAction(cancelAction)

        let nextAction = UIAlertAction(title: alertController.title, style: .default) { [weak self] _ in
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

        alertController.addAction(nextAction)
        alertController.addTextField { textField in
            textField.placeholder = String.localized(key: LocalizableKeys.searchPlaceholder)
        }

        present(alertController, animated: true)
    }

    private func showSearchResults(results: [FeedItem], for query: String) {
        let feedItemsViewController = FeedItemsViewController()
        feedItemsViewController.feedItems = results
        feedItemsViewController.searchTitle = "\(String.localized(key: LocalizableKeys.search))\(":") \(query)"

        navigationController?.pushViewController(feedItemsViewController, animated: true)
    }
}
