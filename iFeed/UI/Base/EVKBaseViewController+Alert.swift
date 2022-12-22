//
//  EVKBaseViewController+Alert.swift
//  iFeed
//
//  Created by Evgeny Karkan on 22.12.2022.
//  Copyright © 2022 Evgeny Karkan. All rights reserved.
//

import UIKit

extension EVKBaseViewController {

    // MARK: - Alerts
    func showEnterFeedAlertView(_ feedURL: String) {
        let alertController = UIAlertController(title: nil, message: "Add feed", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            self.view.endEditing(true)
        }
        alertController.addAction(cancelAction)

        let nextAction = UIAlertAction(title: "Add", style: .default) { action -> Void in
            if let textField = alertController.textFields?.first {
                if !textField.text!.isEmpty {
                    self.addFeedPressed(textField.text!)
                }
                else {
                    self.showInvalidRSSAlert()
                }
            }
        }

        alertController.addAction(nextAction)
        alertController.addTextField { textField -> Void in
            textField.placeholder = "https://www.something.com/rss"

            textField.text = "https://justinpot.com/feed"

            if !feedURL.isEmpty {
                textField.text = feedURL
            }
        }

        let rootVConWindow = EVKBrain.brain.presenter.window.rootViewController
        rootVConWindow!.present(alertController, animated: true)
    }

    func showInvalidRSSAlert() {
        showAlertMessage("RSS feed can't be parsed")
    }

    func showDuplicateRSSAlert() {
        showAlertMessage("RSS feed already exists,\n try another one")
    }

    // MARK: - Common alert
    func showAlertMessage(_ message : String) {
        let alertController = UIAlertController(title: "Oops...", message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "Ok", style: .default) { action -> Void in
            self.view.endEditing(true)
        }
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }
}
