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
            title: "Oops...",
            message: message,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)

        present(alertController, animated: true)
    }

    // MARK: - Specific alerts
    func showInvalidFeedAlert() {
        showAlert("It's not possible to read this feed. Try again later or check the URL to make sure it's valid.")
    }

    func showAlreadySavedFeedAlert() {
        showAlert("It looks like this feed already exists.\n Enter a different one to continue.")
    }
}
