//
//  EVKAppDelegate.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import Crashlytics
@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - properties
    var window: UIWindow?
    
    // MARK: - UIApplicationDelegate API
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let feedListViewController = EVKFeedListViewController()
        
        let navigationViewController                               = UINavigationController()
        navigationViewController.viewControllers                   = [feedListViewController]
        navigationViewController.navigationBar.translucent         = false
        navigationViewController.navigationBar.barTintColor        = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        navigationViewController.navigationBar.tintColor           = UIColor.whiteColor()
        navigationViewController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.window                     = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = navigationViewController
        self.window?.makeKeyAndVisible()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        UIApplication.sharedApplication().statusBarHidden = false
        
        #if __RELEASE__
            Crashlytics.startWithAPIKey("4760756e56b00e661fdfca38443023c06fd79797")
        #endif
        
        //https://forums.developer.apple.com/thread/18365
    
        //configure cache to minimize its capacity
        let appCache = NSURLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: "nsurlcashe")

        NSURLCache.setSharedURLCache(appCache)
        
        return true
    }
}
