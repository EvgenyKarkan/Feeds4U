//
//  UIViewController+Ext.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit.UIViewController

extension UIViewController {

    // MARK: - Instance From Nib
    static func instanceFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>(_ viewType: T.Type) -> T {
            return T.init(nibName: String(describing: T.self), bundle: nil)
        }
        return instantiateFromNib(self)
    }

    // MARK: - Common alert
    func showAlert(_ message: String) {
        let alertController = UIAlertController(
            title: String.localized(key: LocalizableKeys.Errors.generic),
            message: message,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: String.localized(key: LocalizableKeys.confirmation), style: .default)
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }

    // MARK: - Specific alerts
    func showInvalidFeedAlert() {
        showAlert(String.localized(key: LocalizableKeys.Errors.unreadableFeed))
    }

    func showAlreadySavedFeedAlert() {
        showAlert(String.localized(key: LocalizableKeys.Errors.preExistedFeed))
    }
}
