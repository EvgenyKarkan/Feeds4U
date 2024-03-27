//
//  BaseViewController+Alert.swift
//  iFeed
//
//  Created by Evgeny Karkan on 22.12.2022.
//  Copyright © 2022 Evgeny Karkan. All rights reserved.
//

import UIKit

extension BaseViewController {

    // MARK: - Enter Feed Alert
    func showEnterFeedAlertView(_ feedURL: String? = nil) {
        let alertController = UIAlertController(
            title: nil,
            message: String.localized(key: LocalizableKeys.enterNewFeed),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .cancel)
        alertController.addAction(cancelAction)

        let nextAction = UIAlertAction(title: String.localized(key: LocalizableKeys.add),
                                       style: .default) { [weak self] _ in
            guard let text = alertController.textFields?.first?.text else {
                self?.showInvalidFeedAlert()
                return
            }
            self?.addFeedPressed(text)
        }

        alertController.addAction(nextAction)
        alertController.addTextField { textField in
            textField.placeholder = "https://www.something.com/rss"

            /// Try to handle redirect link from `application(_ application: UIApplication, open url: URL, ...)`
            if let feedString = feedURL, !feedString.isEmpty {
                textField.text = feedString
            /// Try to handle copied to pasteboard link
            } else if let copiedText = UIPasteboard.general.url {
                textField.text = copiedText.absoluteString
            }

            // textField.text = "http://rss.cnn.com/rss/cnn_topstories.rss"
        }

        present(alertController, animated: true)
    }

    // MARK: - Explore Feeds Alert
    func showSearchForFeedsAlertView() {
        let alertController = UIAlertController(
            title: nil,
            message: String.localized(key: LocalizableKeys.provideURL),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .cancel)
        alertController.addAction(cancelAction)

        let nextAction = UIAlertAction(title: String.localized(key: LocalizableKeys.search), style: .default) { [weak self] _ in
            guard let text = alertController.textFields?.first?.text else {
                self?.showInvalidFeedAlert()
                return
            }
            self?.searchForFeedsPressed(with: text)
        }

        alertController.addAction(nextAction)
        alertController.addTextField { textField in
            textField.placeholder = "https://www.something.com"

            /// Try to handle copied to pasteboard link
            if let copiedText = UIPasteboard.general.url {
                textField.text = copiedText.absoluteString
            }
        }
        present(alertController, animated: true)
    }

    func showErrorAlertView(error: Error) {
        let action = UIAlertAction(
            title: String.localized(key: LocalizableKeys.confirmation),
            style: .default,
            handler: nil
        )

        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.Errors.error),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alertController.addAction(action)

        present(alertController, animated: true)
    }
}
