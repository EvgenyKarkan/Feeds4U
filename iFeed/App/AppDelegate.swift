//
//  AppDelegate.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import Foundation

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties
    var window: UIWindow?
    private var navigationVC: UINavigationController?

    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        showStartScreen()
        return true
    }

    // Modern URL handling (iOS 9+)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        openURL(url)
        return true
    }
}

// MARK: - Private
private extension AppDelegate {

    func showStartScreen() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: .tangerine)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.systemBackground]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .systemBackground

        navigationVC = UINavigationController()
        navigationVC?.viewControllers = [FeedsViewController()]

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationVC
        window?.makeKeyAndVisible()
    }

    func openURL(_ url: URL) {
        guard let specifier = (url as NSURL).resourceSpecifier,
              !specifier.isEmpty else {
            return
        }

        navigationVC?.popToRootViewController(animated: false)

        if let feedListVC = navigationVC?.topViewController as? FeedsViewController {
            feedListVC.showEnterFeedAlertView(specifier)
        }
    }
}
