//
//  EVKSafariViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 3/24/19.
//  Copyright © 2019 Evgeny Karkan. All rights reserved.
//

import SafariServices

class EVKSafariViewController: SFSafariViewController {

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredBarTintColor = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        preferredControlTintColor = UIColor.white
    }
    
    deinit {
        URLCache.shared.removeAllCachedResponses()
    }
}
