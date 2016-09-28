//
//  EVKPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//


class EVKPresenter: NSObject {

    // MARK: - Singleton
    static let presenter = EVKPresenter()
    
    // MARK: - Properties
    private let appDelegate  = UIApplication.sharedApplication().delegate as! EVKAppDelegate
    private (set) var window = UIWindow(frame: UIScreen.mainScreen().bounds)
    private var navigationVC = UINavigationController()
    
    // MARK: - Public APIs
    func showStartScreen() {
        let feedListViewController = EVKFeedListViewController()
        
        self.navigationVC                                   = UINavigationController()
        self.navigationVC.viewControllers                   = [feedListViewController]
        self.navigationVC.navigationBar.translucent         = false
        self.navigationVC.navigationBar.barTintColor        = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        self.navigationVC.navigationBar.tintColor           = UIColor.whiteColor()
        self.navigationVC.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.window.rootViewController = self.navigationVC
        self.window.makeKeyAndVisible()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        UIApplication.sharedApplication().statusBarHidden = false
    }
    
    func openURL(url: NSURL) {
        if !url.resourceSpecifier.isEmpty {
            self.navigationVC.popToRootViewControllerAnimated(false)
            
            let topViewController = self.navigationVC.topViewController
            
            if let vc = topViewController as? EVKFeedListViewController {
                vc.showEnterFeedAlertView(url.absoluteString)
            }
        }
    }
}
