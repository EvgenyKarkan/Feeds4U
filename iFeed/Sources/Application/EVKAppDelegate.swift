//
//  EVKAppDelegate.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - properties
    var window: UIWindow?
    

    // MARK: - UIApplicationDelegate API
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        var feedListViewController = EVKFeedListViewController()
        
        var navigationViewController                               = UINavigationController()
        navigationViewController.viewControllers                   = [feedListViewController]
        navigationViewController.navigationBar.translucent         = false
        navigationViewController.navigationBar.barTintColor        = UIColor(red:0.98, green:0.64, blue:0.15, alpha:1)
        navigationViewController.navigationBar.tintColor           = UIColor.whiteColor()
        navigationViewController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.window                     = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = navigationViewController
        self.window?.makeKeyAndVisible()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        UIApplication.sharedApplication().statusBarHidden = false
        
        //web cache setup
        NSURLProtocol.registerClass(RNCachingURLProtocol)
        
        return true
    }
}
