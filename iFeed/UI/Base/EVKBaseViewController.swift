//
//  EVKBaseViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/27/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKBaseViewController: UIViewController, EVKParserDelegate {

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Feeds4U"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
    
    func didEndParsingFeed(_ feed: Feed) {}
    
    func didFailParsingFeed() {
        showInvalidRSSAlert()
    }
}
