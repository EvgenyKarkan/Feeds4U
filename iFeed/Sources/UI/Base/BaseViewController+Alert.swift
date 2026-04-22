//
//  BaseViewController+Alert.swift
//  iFeed
//
//  Created by Evgeny Karkan on 22.12.2022.
//  Copyright © 2022 Evgeny Karkan. All rights reserved.
//

import UIKit

extension BaseViewController {

    // MARK: - Enter Feed Alert, enter a direct feed URL
    func showEnterFeedAlertView(_ feedURL: String? = nil) {
        let alertController = UIAlertController(
            title: nil,
            message: String.localized(key: LocalizableKeys.Feed.enterNew),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .cancel)
        alertController.addAction(cancelAction)

        nextAction = UIAlertAction(title: String.localized(key: LocalizableKeys.add),
                                   style: .default) { [weak self] _ in
            guard let text = alertController.textFields?.first?.text else {
                self?.showInvalidFeedAlert()
                return
            }
            self?.addFeedPressed(text)
        }
        nextAction?.isEnabled = false

        guard let nextAction = nextAction else { return }

        alertController.addAction(nextAction)
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "https://www.something.com/rss"
            textField.addTarget(self,
                                action: #selector(self?.textFieldDidChangeForURLInput(_:)),
                                for: .editingChanged)

            /// Try to handle redirect link from `application(_ application: UIApplication, open url: URL, ...)`
            if let feedString = feedURL, !feedString.isEmpty {
                textField.text = feedString
                nextAction.isEnabled = true
            /// Try to handle copied to pasteboard link
            } else if let copiedText = UIPasteboard.general.url {
                textField.text = copiedText.absoluteString
                nextAction.isEnabled = true

                /// Clear data once it is set
                UIPasteboard.general.url = nil
                UIPasteboard.general.string = nil
            }

            // textField.text = "http://rss.cnn.com/rss/cnn_topstories.rss"
        }

        present(alertController, animated: true)
    }

    // MARK: - Explore Feeds Alert, enter a web URL to search for its feeds
    func showSearchForFeedsAlertView() {
        let alertController = UIAlertController(
            title: nil,
            message: String.localized(key: LocalizableKeys.provideURL),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .cancel)
        alertController.addAction(cancelAction)

        nextAction = UIAlertAction(title: String.localized(key: LocalizableKeys.Search.search),
                                       style: .default) { [weak self] _ in
            guard let text = alertController.textFields?.first?.text else {
                self?.showInvalidFeedAlert()
                return
            }
            self?.searchForFeedsPressed(with: text)
        }
        nextAction?.isEnabled = false

        guard let nextAction = nextAction else { return }

        alertController.addAction(nextAction)
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "https://www.something.com"
            textField.addTarget(self,
                                action: #selector(self?.textFieldDidChangeForURLInput(_:)),
                                for: .editingChanged)

            /// Try to handle copied to pasteboard link
            if let copiedText = UIPasteboard.general.url {
                textField.text = copiedText.absoluteString
                nextAction.isEnabled = true

                /// Clear data once it is set
                UIPasteboard.general.url = nil
                UIPasteboard.general.string = nil
            }
        }
        present(alertController, animated: true)
    }

    func showErrorAlertView(error: any Error) {
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

// MARK: - Private
extension BaseViewController {

    @objc func textFieldDidChangeForURLInput(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            nextAction?.isEnabled = false
            return
        }

        nextAction?.isEnabled = text.isValidURL
    }

    @objc func textFieldDidChangeForSearchInput(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            nextAction?.isEnabled = false
            return
        }

        nextAction?.isEnabled = true
    }
}
