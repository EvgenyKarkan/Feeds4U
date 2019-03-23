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
        assert(!sender.isEqual(nil), "sender is nil")
        
        let waitingAnimation = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        view.addSubview(waitingAnimation)
        waitingAnimation.frame = CGRect(x: 120, y: 200, width: 37, height: 37)
        waitingAnimation.startAnimating()
        
        search.fillMatchingEngine {
            DispatchQueue.main.async {
                waitingAnimation.stopAnimating()
                waitingAnimation.removeFromSuperview()
                self.showEnterSearch()
            }
        }
    }
    
    func showEnterSearch() {
        let alertController = UIAlertController(title: "Search", message: "Search works best when you enter more than one word.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            self.view.endEditing(true)
        }
        alertController.addAction(cancelAction)
        
        let nextAction = UIAlertAction(title: "Search", style: .default) { action -> Void in
            if let query = alertController.textFields?.first?.text, !query.isEmpty {
                self.search.search(for: query, resultsFound: { [weak self] (results) in
                    DispatchQueue.main.async {
                        guard let results = results, !results.isEmpty else {
                            let noResultsFoundAlert = UIAlertController(title: "Search", message: "No results found", preferredStyle: .alert)
                            let noResultsCancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                            noResultsFoundAlert.addAction(noResultsCancelAction)
                            self?.present(noResultsFoundAlert, animated: true, completion: nil)
                            return
                        }
                        
                        self?.showSearchResults(results: results, for: query)
                    }
                })
            }
        }
        
        alertController.addAction(nextAction)
        alertController.addTextField { textField -> Void in
            textField.placeholder = "Cute kittens"
        }
        
        let rootVConWindow = EVKBrain.brain.presenter.window.rootViewController
        rootVConWindow!.present(alertController, animated: true, completion: nil)
    }
    
    private func showSearchResults(results: [FeedItem], for query: String) {
        let feedItemsViewController = EVKFeedItemsViewController()
        feedItemsViewController.feedItems = results
        feedItemsViewController.searchTitle = "Search: \(query)"
        navigationController?.pushViewController(feedItemsViewController, animated: true)
    }

}

