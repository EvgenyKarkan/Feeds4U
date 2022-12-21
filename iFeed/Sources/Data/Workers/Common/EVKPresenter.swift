//
//  EVKPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//

import UIKit

final class EVKPresenter {

    // MARK: - Singleton
    static let presenter = EVKPresenter()
    
    // MARK: - Properties
    lazy var window = UIWindow(frame: UIScreen.main.bounds)
    private lazy var navigationVC = UINavigationController()
    
    // MARK: - Public APIs
    func showStartScreen() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "Tangerine")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationVC.navigationBar.standardAppearance = appearance
        navigationVC.navigationBar.scrollEdgeAppearance = appearance
        navigationVC.navigationBar.tintColor = .white

        navigationVC.viewControllers = [EVKFeedListViewController()]

        window.rootViewController = navigationVC
        window.makeKeyAndVisible()
    }
    
    func openURL(_ url: URL) {
        guard let specifier = (url as NSURL).resourceSpecifier,
            !specifier.isEmpty else {
            return
        }

        navigationVC.popToRootViewController(animated: false)

        if let feedListVC = navigationVC.topViewController as? EVKFeedListViewController {
            feedListVC.showEnterFeedAlertView(url.absoluteString)
        }
    }
}
