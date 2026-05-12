//
//  BaseViewController+Alert.swift
//  iFeed
//
//  Created by Evgeny Karkan on 22.12.2022.
//  Copyright © 2022 Evgeny Karkan. All rights reserved.
//

import UIKit

// MARK: - Alert Configuration
extension BaseListViewController {

    /// Configuration for URL input alerts
    struct URLInputAlertConfig {
        let message: String
        let actionTitle: String
        let placeholder: String
        let prefillURL: String?
        let shouldClearPasteboard: Bool
        let onSubmit: (String) -> Void

        static func feedEntry(prefillURL: String? = nil, onSubmit: @escaping (String) -> Void) -> URLInputAlertConfig {
            return URLInputAlertConfig(
                message: String.localized(key: LocalizableKeys.Feed.enterNew),
                actionTitle: String.localized(key: LocalizableKeys.add),
                placeholder: "https://www.example.com/rss",
                prefillURL: prefillURL,
                shouldClearPasteboard: true,
                onSubmit: onSubmit
            )
        }

        static func feedSearch(onSubmit: @escaping (String) -> Void) -> URLInputAlertConfig {
            return URLInputAlertConfig(
                message: String.localized(key: LocalizableKeys.provideURL),
                actionTitle: String.localized(key: LocalizableKeys.Search.search),
                placeholder: "https://www.example.com",
                prefillURL: nil,
                shouldClearPasteboard: true,
                onSubmit: onSubmit
            )
        }
    }
}

// MARK: - Public Alert Methods
extension BaseListViewController {

    /// Shows an alert to enter a direct feed URL
    /// - Parameter feedURL: Optional URL to prefill (e.g., from deep link)
    func showEnterFeedAlertView(_ feedURL: String? = nil) {
        let config = URLInputAlertConfig.feedEntry(prefillURL: feedURL) { [weak self] urlString in
            self?.addFeedPressed(urlString)
        }
        showURLInputAlert(config: config)
    }

    /// Shows an alert to enter a website URL to search for feeds
    func showSearchForFeedsAlertView() {
        let config = URLInputAlertConfig.feedSearch { [weak self] urlString in
            self?.searchForFeedsPressed(with: urlString)
        }
        showURLInputAlert(config: config)
    }

    /// Shows a generic error alert
    /// - Parameter error: The error to display
    func showErrorAlertView(error: any Error) {
        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.Errors.error),
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(
            title: String.localized(key: LocalizableKeys.confirmation),
            style: .default
        ))

        present(alertController, animated: true)
    }
}

// MARK: - Private Implementation
private extension BaseListViewController {

    /// Generic method to show URL input alerts
    /// - Parameter config: Configuration for the alert
    func showURLInputAlert(config: URLInputAlertConfig) {
        let alertController = UIAlertController(
            title: nil,
            message: config.message,
            preferredStyle: .alert
        )

        // Cancel action
        alertController.addAction(UIAlertAction(
            title: String.localized(key: LocalizableKeys.cancel),
            style: .cancel
        ) { [weak self] _ in
            self?.nextAction = nil
        })

        // Submit action (initially disabled)
        let submitAction = UIAlertAction(
            title: config.actionTitle,
            style: .default
        ) { [weak self, weak alertController] _ in
            guard let urlString = alertController?.textFields?.first?.text else {
                self?.nextAction = nil
                self?.showInvalidFeedAlert()
                return
            }
            self?.nextAction = nil
            config.onSubmit(urlString)
        }
        submitAction.isEnabled = false

        // Store reference for text field validation
        nextAction = submitAction
        alertController.addAction(submitAction)

        // Configure text field
        alertController.addTextField { [weak self] textField in
            self?.configureURLTextField(
                textField,
                placeholder: config.placeholder,
                prefillURL: config.prefillURL,
                submitAction: submitAction,
                shouldClearPasteboard: config.shouldClearPasteboard
            )
        }

        present(alertController, animated: true)
    }

    /// Configures the URL text field with validation and autofill
    func configureURLTextField(
        _ textField: UITextField,
        placeholder: String,
        prefillURL: String?,
        submitAction: UIAlertAction,
        shouldClearPasteboard: Bool
    ) {
        textField.placeholder = placeholder
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.addTarget(
            self,
            action: #selector(textFieldDidChangeForURLInput(_:)),
            for: .editingChanged
        )

        /// Prefill logic with priority: explicit URL > pasteboard
        if let feedURL = prefillURL, !feedURL.isEmpty {
            textField.text = feedURL
            submitAction.isEnabled = feedURL.isValidURL
        } else if let pasteboardURL = UIPasteboard.general.url?.absoluteString {
            textField.text = pasteboardURL
            submitAction.isEnabled = pasteboardURL.isValidURL

            if shouldClearPasteboard {
                UIPasteboard.general.url = nil
                UIPasteboard.general.string = nil
            }
        }
    }
}

// MARK: - Text Field Validation
extension BaseListViewController {

    @objc func textFieldDidChangeForURLInput(_ textField: UITextField) {
        let text = textField.text ?? ""
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Enable submit button only if URL is valid
        nextAction?.isEnabled = !trimmedText.isEmpty && trimmedText.isValidURL
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
