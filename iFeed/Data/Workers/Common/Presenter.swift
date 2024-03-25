//
//  Presenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//

import UIKit

final class Presenter {

    // MARK: - Singleton
    static let presenter = Presenter()

    // MARK: - Properties
    lazy var window = UIWindow(frame: UIScreen.main.bounds)
    private lazy var navigationVC = UINavigationController()

    // MARK: - Public APIs
    func showStartScreen() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: .tangerine)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.systemBackground]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .systemBackground

        navigationVC.viewControllers = [FeedsViewController()]

        window.rootViewController = navigationVC
        window.makeKeyAndVisible()
    }

    func openURL(_ url: URL) {
        guard let specifier = (url as NSURL).resourceSpecifier,
            !specifier.isEmpty else {
            return
        }

        navigationVC.popToRootViewController(animated: false)

        if let feedListVC = navigationVC.topViewController as? FeedsViewController {
            feedListVC.showEnterFeedAlertView(specifier)
        }
    }
}
