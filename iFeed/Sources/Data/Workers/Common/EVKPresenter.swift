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
    private let appDelegate  = UIApplication.shared.delegate as! EVKAppDelegate
    private (set) var window = UIWindow(frame: UIScreen.main.bounds)
    private var navigationVC = UINavigationController()
    
    // MARK: - Public APIs
    func showStartScreen() {
        let feedListViewController = EVKFeedListViewController()
        
        navigationVC.viewControllers = [feedListViewController]
        navigationVC.navigationBar.isTranslucent = false
        navigationVC.navigationBar.barTintColor = UIColor(named: "Tangerine")
        navigationVC.navigationBar.tintColor = UIColor.white
        navigationVC.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        
        window.rootViewController = navigationVC
        window.makeKeyAndVisible()
        
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: false)
        UIApplication.shared.isStatusBarHidden = false
    }
    
    func openURL(_ url: URL) {
        let nsURL = url as NSURL
        
        if let aCount = nsURL.resourceSpecifier?.count, aCount > 0 {
            navigationVC.popToRootViewController(animated: false)
            
            let topViewController = navigationVC.topViewController
            
            if let vc = topViewController as? EVKFeedListViewController {
                vc.showEnterFeedAlertView(url.absoluteString)
            }
        }
    }
}
