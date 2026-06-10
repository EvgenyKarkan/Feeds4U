//
//  SceneDelegate.swift
//  iFeed
//
//  Created by Evgeny Karkan on 12.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Properties
    var window: UIWindow?
    private var navigationVC: UINavigationController?
    private var appCoordinator: (any Coordinating)?

    // MARK: - UIWindowSceneDelegate
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Quick return if running unit tests
        #if DEBUG || __DEBUG__
        if isRunningUnitTests {
            return
        }
        #endif

        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        setupWindow(with: windowScene)

        /// Handle a URL that caused the app to cold-launch (e.g. "feed://..." or "Feeds4U://...").
        /// When the app is already running, `scene(_:openURLContexts:)` is called instead.
        if let urlContext = connectionOptions.urlContexts.first {
            openURL(urlContext.url)
        }
    }

    /// Handles URLs received while the app is already running (warm launch).
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        openURL(url)
    }
}

// MARK: - Private
private extension SceneDelegate {

    func setupWindow(with windowScene: UIWindowScene) {
        navigationVC = UINavigationController()

        let coordinator = Coordinator(container: DIContainer(), controller: navigationVC)
        coordinator.start()

        appCoordinator = coordinator

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigationVC
        window?.makeKeyAndVisible()
    }

    func openURL(_ url: URL) {
        appCoordinator?.handleDeepLink(url: url)
    }
}
