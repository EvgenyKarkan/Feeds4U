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
        let onSubmit: (String) -> Void

        static func feedEntry(prefillURL: String? = nil, onSubmit: @escaping (String) -> Void) -> URLInputAlertConfig {
            return URLInputAlertConfig(
                message: String.localized(key: LocalizableKeys.Feed.enterNew),
                actionTitle: String.localized(key: LocalizableKeys.add),
                placeholder: "https://www.example.com/rss",
                prefillURL: prefillURL,
                onSubmit: onSubmit
            )
        }

        static func feedSearch(onSubmit: @escaping (String) -> Void) -> URLInputAlertConfig {
            return URLInputAlertConfig(
                message: String.localized(key: LocalizableKeys.provideURL),
                actionTitle: String.localized(key: LocalizableKeys.Search.search),
                placeholder: "https://www.example.com",
                prefillURL: nil,
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
                submitAction: submitAction
            )
        }

        present(alertController, animated: true) { [weak alertController] in
            /// Pasteboard prefill is deferred until the alert is fully on screen.
            /// Reading `UIPasteboard.url` can suspend the call behind the system
            /// "Allow Paste" prompt — doing that inside the text-field
            /// configuration handler (mid-presentation) left the field empty
            /// even after the user tapped "Allow", because the alert finished
            /// configuring its fields while the prompt was still pending.
            guard (config.prefillURL ?? "").isEmpty,
                  let textField = alertController?.textFields?.first else {
                return
            }
            Self.prefillFromPasteboard(textField, submitAction: submitAction)
        }
    }

    /// Prefills the field with a URL from the pasteboard, if it holds one.
    ///
    /// Two clipboard shapes are supported:
    /// - a real URL object (`hasURLs` — e.g. copied from Safari's address bar);
    /// - a URL copied as plain text (e.g. from a messenger or a terminal),
    ///   detected via `detectedPatterns(for: [\.probableWebURL])`.
    ///
    /// Both `hasURLs`/`hasStrings` and pattern detection inspect the clipboard
    /// WITHOUT counting as access — the system "Allow Paste" prompt appears
    /// only at the final `.url`/`.string` read, and only when the clipboard
    /// actually contains something URL-shaped. The clipboard is never cleared:
    /// it belongs to the user, and wiping it here would silently destroy
    /// content copied for other purposes.
    static func prefillFromPasteboard(_ textField: UITextField, submitAction: UIAlertAction) {
        let pasteboard = UIPasteboard.general

        if pasteboard.hasURLs {
            applyPasteboardURL(pasteboard.url?.absoluteString, to: textField, submitAction: submitAction)
            return
        }

        guard pasteboard.hasStrings else {
            return
        }

        Task { @MainActor in
            /// Pattern detection is asynchronous and prompt-free; the paste
            /// prompt fires only on the `.string` read below, which happens
            /// only when a probable web URL was actually detected.
            let patterns = try? await pasteboard.detectedPatterns(for: [\.probableWebURL])
            guard patterns?.contains(\.probableWebURL) == true else {
                return
            }
            applyPasteboardURL(pasteboard.string, to: textField, submitAction: submitAction)
        }
    }

    /// Applies a pasteboard value to the field when it survives URL validation —
    /// garbage never gets prefilled, regardless of how it was typed in the clipboard.
    static func applyPasteboardURL(_ urlString: String?, to textField: UITextField, submitAction: UIAlertAction) {
        guard let urlString = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              urlString.isValidURL else {
            return
        }

        textField.text = urlString
        submitAction.isEnabled = true
    }

    /// Configures the URL text field with validation and autofill
    func configureURLTextField(
        _ textField: UITextField,
        placeholder: String,
        prefillURL: String?,
        submitAction: UIAlertAction
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

        /// Explicit prefill only (e.g. a deep-link URL). Pasteboard prefill is
        /// intentionally NOT done here — it happens after the alert finishes
        /// presenting, see `showURLInputAlert(config:)`.
        if let feedURL = prefillURL, !feedURL.isEmpty {
            textField.text = feedURL
            submitAction.isEnabled = feedURL.isValidURL
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
