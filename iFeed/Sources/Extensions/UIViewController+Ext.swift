//
//  UIViewController+Ext.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit
import KRProgressHUD

extension UIViewController {

    // MARK: - Instance From Nib

    /// Creates a view controller instance from a nib file named after the view controller type.
    ///
    /// Use this helper for view controllers whose nib filename matches the class name.
    /// For example, `FeedSearchResultsViewController.instanceFromNib()` loads a nib named
    /// `FeedSearchResultsViewController.xib`.
    ///
    /// - Returns: A new instance of the receiving `UIViewController` subclass configured with
    ///   its matching nib name and the main bundle.
    static func instanceFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>(_ viewType: T.Type) -> T {
            return T.init(nibName: String(describing: T.self), bundle: nil)
        }
        return instantiateFromNib(self)
    }

    // MARK: - Common error alert

    /// Presents a localized generic error alert with the provided message.
    ///
    /// The alert uses the app's generic error title and confirmation button text from
    /// `LocalizableKeys`, then presents it modally over the current view controller.
    ///
    /// - Parameter message: The localized or user-facing message to display in the alert body.
    func showErrorAlert(_ message: String) {
        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.Errors.generic),
            message: message,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: String.localized(key: LocalizableKeys.confirmation), style: .default)
        alertController.addAction(okAction)

        /// If view controller is covered by a modal vc - the modal vc must present alert on top of it
        if presentedViewController != nil {
            presentedViewController?.present(alertController, animated: true)
        } else {
            present(alertController, animated: true)
        }
    }

    // MARK: - Specific alerts

    /// Presents an error alert that tells the user the selected feed cannot be read.
    func showInvalidFeedAlert() {
        showErrorAlert(String.localized(key: LocalizableKeys.Errors.unreadableFeed))
    }

    /// Presents an error alert that tells the user the selected feed is already saved.
    func showAlreadySavedFeedAlert() {
        showErrorAlert(String.localized(key: LocalizableKeys.Errors.preExistedFeed))
    }
}

// MARK: - Spinner helper
extension UIViewController {

    /// Shows the app-wide loading spinner using the app's branded progress HUD styling.
    ///
    /// The spinner is displayed through `KRProgressHUD` with a tangerine background and white
    /// activity indicator colors.
    func showSpinner() {
        let color = UIColor(resource: .tangerine)

        KRProgressHUD
           .set(style: .custom(background: color, text: .white, icon: nil))
           .set(activityIndicatorViewColors: [.white, color])
           .show()
    }

    /// Hides the app-wide loading spinner.
    ///
    /// - Parameter completion: An optional closure that runs after `KRProgressHUD` finishes
    ///   dismissing the spinner.
    func hideSpinner(_ completion: (() -> Void)? = nil) {
        KRProgressHUD.dismiss(completion)
    }
}
