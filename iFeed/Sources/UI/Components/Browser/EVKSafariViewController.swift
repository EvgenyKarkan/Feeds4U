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
        
        //TODO:- Add constant for colors
        preferredBarTintColor = UIColor(named: "Tangerine")
        preferredControlTintColor = .white
    }
    
    deinit {
        URLCache.shared.removeAllCachedResponses()
    }
}
