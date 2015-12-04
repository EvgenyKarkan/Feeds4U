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
    var navigationViewController: UINavigationController!
    
    // MARK: - UIApplicationDelegate API
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let feedListViewController = EVKFeedListViewController()
        
        self.navigationViewController                                   = UINavigationController()
        self.navigationViewController.viewControllers                   = [feedListViewController]
        self.navigationViewController.navigationBar.translucent         = false
        self.navigationViewController.navigationBar.barTintColor        = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        self.navigationViewController.navigationBar.tintColor           = UIColor.whiteColor()
        self.navigationViewController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.window                     = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = navigationViewController
        self.window?.makeKeyAndVisible()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        UIApplication.sharedApplication().statusBarHidden = false
        
        #if __RELEASE__
            
        #endif
    
        //configure cache to minimize its capacity
        let appCache = NSURLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: "nsurlcache")

        NSURLCache.setSharedURLCache(appCache)
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject)-> Bool {
        
        if !url.resourceSpecifier.isEmpty {
            self.navigationViewController.popToRootViewControllerAnimated(false)
            
            let topViewController = self.navigationViewController.topViewController
            
            if let vc = topViewController as? EVKFeedListViewController {
                vc.showEnterFeedAlertView(url.absoluteString)
            }
        }
        
        return true
    }
}
