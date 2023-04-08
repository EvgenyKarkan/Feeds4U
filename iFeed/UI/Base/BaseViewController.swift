//
//  BaseViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/27/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, ParserDelegate {

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
    
    // MARK: - ParserDelegate
    func didStartParsingFeed() {}
    
    func didEndParsingFeed(_ feed: Feed) {
        hideSpinner()
    }
    
    func didFailParsingFeed() {
        hideSpinner()
        showInvalidFeedAlert()
    }
}

// MARK: - Spinner helper
extension BaseViewController {

    func showSpinner() {
        spinner = UIActivityIndicatorView(style: .large)
        spinner?.center = view.center
        spinner?.color = UIColor(named: "Tangerine")
        spinner?.backgroundColor = .white
        spinner?.startAnimating()

        guard let spinner else {
            return
        }

        view.addSubview(spinner)
        view.bringSubviewToFront(spinner)
    }

    func hideSpinner() {
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
    }
}

// MARK: - Instance From Nib
extension UIViewController {

    static func instanceFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>(_ viewType: T.Type) -> T {
            return T.init(nibName: String(describing: T.self), bundle: nil)
        }
        return instantiateFromNib(self)
    }
}
