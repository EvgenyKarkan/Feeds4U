//
//  EVKFeedListViewController+Search.swift
//  iFeed
//
//  Created by Julius Bahr on 20.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import UIKit

extension EVKFeedListViewController {
    
    @objc func searchPressed (_ sender: UIButton) {
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
            title: "Search",
            message: "Search works best when you enter more than one word.",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
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
                            message: "No results found",
                            preferredStyle: .alert
                        )
                        let noResultsCancelAction = UIAlertAction(title: "OK", style: .cancel)
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
            textField.placeholder = "Cute kittens"
        }

        present(alertController, animated: true)
    }
    
    private func showSearchResults(results: [FeedItem], for query: String) {
        let feedItemsViewController = EVKFeedItemsViewController()
        feedItemsViewController.feedItems = results
        feedItemsViewController.searchTitle = "Search: \(query)"
        navigationController?.pushViewController(feedItemsViewController, animated: true)
    }
}
