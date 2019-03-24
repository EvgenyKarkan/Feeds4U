//
//  EVKPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//

import UIKit

class EVKPresenter: NSObject {

    // MARK: - Singleton
    static let presenter = EVKPresenter()
    
    // MARK: - Properties
    fileprivate let appDelegate  = UIApplication.shared.delegate as! EVKAppDelegate
    fileprivate (set) var window = UIWindow(frame: UIScreen.main.bounds)
    fileprivate var navigationVC = UINavigationController()
    
    // MARK: - Public APIs
    func showStartScreen() {
        let feedListViewController = EVKFeedListViewController()
        
        self.navigationVC                                   = UINavigationController()
        self.navigationVC.viewControllers                   = [feedListViewController]
        self.navigationVC.navigationBar.isTranslucent       = false
        self.navigationVC.navigationBar.barTintColor        = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        self.navigationVC.navigationBar.tintColor           = UIColor.white
        self.navigationVC.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        
        self.window.rootViewController = self.navigationVC
        self.window.makeKeyAndVisible()
        
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: false)
        UIApplication.shared.isStatusBarHidden = false
    }
    
    func openURL(_ url: URL) {
        let nsURL = url as NSURL
        
        if let aCount = nsURL.resourceSpecifier?.characters.count, aCount > 0 {
            self.navigationVC.popToRootViewController(animated: false)
            
            let topViewController = self.navigationVC.topViewController
            
            if let vc = topViewController as? EVKFeedListViewController {
                vc.showEnterFeedAlertView(url.absoluteString)
            }
        }
    }
}
