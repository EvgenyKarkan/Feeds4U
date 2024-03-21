//
//  BaseViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/27/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import KRProgressHUD

class BaseViewController: UIViewController {

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Feeds4U"
        
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: String(),
            style: .plain,
            target: nil,
            action: nil
        )
    }

    // MARK: - Add feed
    func addFeedPressed(_ URL: String) {
        fatalError()
    }

    func searchForFeedsPressed(with webPage: String) {
        fatalError()
    }
    
    // MARK: - Parsing
    func startParsingURL(_ string: String) {
        guard !string.isEmpty, let url = URL(string: string) else {
            didFailParsingFeed()
            return
        }

        let parser = Brain.brain.parser
        parser.delegate = self
        parser.beginParsingURL(url)
    }
}

// MARK: - ParserDelegateProtocol
extension BaseViewController: ParserDelegateProtocol {

    @objc func didEndParsingFeed(_ feed: Feed) {
        hideSpinner()
    }

    func didFailParsingFeed() {
        hideSpinner()
        showInvalidFeedAlert()
    }
}

// MARK: - Spinner helper
extension UIViewController {

    func showSpinner() {
        let color = UIColor(resource: .tangerine)

        KRProgressHUD
           .set(style: .custom(background: color, text: .white, icon: nil))
           .set(activityIndicatorViewColors: [.white, color])
           .show()
    }

    func hideSpinner() {
        KRProgressHUD.dismiss()
    }
}
