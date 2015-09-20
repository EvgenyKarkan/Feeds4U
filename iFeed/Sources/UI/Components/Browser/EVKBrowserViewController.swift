//
//  EVKBrowserViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/7/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKBrowserViewController: KINWebBrowserViewController {
    
    // MARK: - Init
    override init!(configuration: WKWebViewConfiguration!) {
        super.init(configuration: configuration)
        
        self.actionButtonHidden = false
    }
    
    deinit {
        NSURLCache.sharedURLCache().removeAllCachedResponses()
     }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // MARK: - Life cycle
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tintColor = self.navigationController?.navigationBar.barTintColor
        
        self.progressView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.progressView.frame.size.height)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
}

