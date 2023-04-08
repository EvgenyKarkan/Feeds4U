//
//  BaseViewController+Alert.swift
//  iFeed
//
//  Created by Evgeny Karkan on 22.12.2022.
//  Copyright © 2022 Evgeny Karkan. All rights reserved.
//

import UIKit

extension BaseViewController {

    // MARK: - Alerts
    func showEnterFeedAlertView(_ feedURL: String = String()) {
        let alertController = UIAlertController(title: nil,
                                                message: "Enter a new feed",
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let nextAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let text = alertController.textFields?.first?.text else {
                self?.showInvalidFeedAlert()
                return
            }
            self?.addFeedPressed(text)
        }

        alertController.addAction(nextAction)
        alertController.addTextField { textField in
            textField.placeholder = "https://www.something.com/rss"

            if !feedURL.isEmpty {
                textField.text = feedURL
            }

            ///textField.text = "http://rss.cnn.com/rss/cnn_topstories.rss"
        }

        present(alertController, animated: true)
    }

    func showSearchForFeedsAlertView() {
        let alertController = UIAlertController(title: nil,
                                                message: "Please provide a webpage URL to search for its feeds",
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let nextAction = UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            guard let text = alertController.textFields?.first?.text else {
                self?.showInvalidFeedAlert()
                return
            }
            self?.searchForFeedsPressed(with: text)
        }

        alertController.addAction(nextAction)
        alertController.addTextField { textField in
            textField.placeholder = "https://www.something.com"

            textField.text = "https://stackoverflow.com"
        }

        present(alertController, animated: true)
    }

    func showInvalidFeedAlert() {
        showAlert("Sorry, we couldn't read this feed. Please try again later or check the URL to make sure it's valid.")
    }

    func showDuplicateFeedAlert() {
        showAlert("It looks like this feed already exists.\n Please enter a different one to continue.")
    }

    // MARK: - Common alert
    func showAlert(_ message: String) {
        let alertController = UIAlertController(title: "Oops...",
                                                message: message,
                                                preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }
}
