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
    func showEnterFeedAlertView(_ feedURL: String) {
        let alertController = UIAlertController(title: nil, message: "Add feed", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)

        let nextAction = UIAlertAction(title: "Add", style: .default) { [self] _ in
            if let textField = alertController.textFields?.first {
                if !textField.text!.isEmpty {
                    addFeedPressed(textField.text!)
                }
                else {
                    showInvalidRSSAlert()
                }
            }
        }

        alertController.addAction(nextAction)
        alertController.addTextField { textField in
            textField.placeholder = "https://www.something.com/rss"

            if !feedURL.isEmpty {
                textField.text = feedURL
            }

            //textField.text = "http://rss.cnn.com/rss/cnn_topstories.rss"
            //textField.text = "https://justinpot.com/feed"
        }

        present(alertController, animated: true)
    }

    func showInvalidRSSAlert() {
        showAlertMessage("Feed can't be parsed")
    }

    func showDuplicateRSSAlert() {
        showAlertMessage("Feed already exists,\n try another one")
    }

    // MARK: - Common alert
    func showAlertMessage(_ message : String) {
        let alertController = UIAlertController(title: "Oops...", message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Ok", style: .default)
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }
}
