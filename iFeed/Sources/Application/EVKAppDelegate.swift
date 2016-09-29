//
//  EVKAppDelegate.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


@UIApplicationMain

class EVKAppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - UIApplicationDelegate APIs
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        EVKBrain.brain.startServices()
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        EVKBrain.brain.presenter.openURL(url)
        return true
    }
}
