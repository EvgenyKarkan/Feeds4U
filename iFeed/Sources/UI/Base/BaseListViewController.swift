//
//  BaseListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/27/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

private enum Constants {
    static let appName = "Feeds4U"
}

class BaseListViewController: UIViewController {

    // MARK: - Properties
    var nextAction: UIAlertAction?

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Constants.appName

        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: String(),
            style: .plain,
            target: nil,
            action: nil
        )
    }

    func addFeedPressed(_ URL: String) {
        fatalError()
    }

    func searchForFeedsPressed(with webPage: String) {
        fatalError()
    }
}
