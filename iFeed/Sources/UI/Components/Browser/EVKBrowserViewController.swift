//
//  EVKBrowserViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/7/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


class EVKBrowserViewController: KINWebBrowserViewController {
    
    // MARK: - Init
    override init!(configuration: WKWebViewConfiguration!) {
        super.init(configuration: configuration)
        
        self.actionButtonHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    deinit {
        URLCache.shared.removeAllCachedResponses()
    }
    
    // MARK: - Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.tintColor = self.navigationController?.navigationBar.barTintColor
        
        self.progressView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.progressView.frame.size.height)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
}

