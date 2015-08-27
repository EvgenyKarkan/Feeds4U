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

    //MARK: - properties
    
    var window: UIWindow?
    

    //MARK: - UIApplicationDelegate API
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        var feedListViewController = EVKFeedListViewController (nibName: nil, bundle: nil) //wtf
        
        var navigationViewController                               = UINavigationController ()
        navigationViewController.viewControllers                   = [feedListViewController]
        navigationViewController.navigationBar.barTintColor        = UIColor.blackColor()
        navigationViewController.navigationBar.tintColor           = UIColor.whiteColor()
        navigationViewController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.window                     = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = navigationViewController
        self.window?.makeKeyAndVisible()
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        UIApplication.sharedApplication().statusBarHidden = false
        
        return true
    }
}

