//
//  EVKBaseViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/27/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKBaseViewController: UIViewController, EVKParserDelegate {

    // MARK: - Properties
    private var spinner: UIActivityIndicatorView?

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Feeds4U"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    // MARK: - Add feed
    func addFeedPressed(_ URL: String) {
        fatalError()
    }
    
    // MARK: - Parsing
    func startParsingURL(_ string: String) {
        guard !string.isEmpty, let url = URL(string: string) else {
            showInvalidRSSAlert()
            return
        }

        let parser = EVKBrain.brain.parser
        parser.delegate = self
        parser.beginParseURL(url)
    }
    
    // MARK: - EVKParserDelegate
    func didStartParsingFeed() {}
    
    func didEndParsingFeed(_ feed: Feed) {
        hideSpinner()
    }
    
    func didFailParsingFeed() {
        hideSpinner()
        showInvalidRSSAlert()
    }
}

// MARK: - Spinner helper
extension EVKBaseViewController {

    func showSpinner() {
        spinner = UIActivityIndicatorView(style: .large)
        spinner?.center = view.center
        spinner?.startAnimating()

        guard let activitySpinner = spinner else {
            return
        }

        view.addSubview(activitySpinner)
        view.bringSubviewToFront(activitySpinner)
    }

    func hideSpinner() {
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
    }
}
