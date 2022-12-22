//
//  EVKSafariViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 3/24/19.
//  Copyright © 2019 Evgeny Karkan. All rights reserved.
//

import SafariServices

final class EVKSafariViewController: SFSafariViewController {

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        preferredBarTintColor = UIColor(named: "Tangerine")
        preferredControlTintColor = .white
    }
    
    deinit {
        URLCache.shared.removeAllCachedResponses()
    }
}
