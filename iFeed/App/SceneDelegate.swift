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
    private var appCoordinator: (any AppCoordinating)?

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

        setupAppearance()

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

    func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: .tangerine)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.systemBackground]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .systemBackground
    }

    func setupWindow(with windowScene: UIWindowScene) {
        navigationVC = UINavigationController()

        let coordinator = Coordinator(
            container: DIContainer(),
            controller: navigationVC
        )

        navigationVC?.viewControllers = [coordinator.makeFeedsViewController()]

        appCoordinator = coordinator

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigationVC
        window?.makeKeyAndVisible()
    }

    func openURL(_ url: URL) {
        guard let specifier = (url as NSURL).resourceSpecifier,
              !specifier.isEmpty else {
            return
        }

        navigationVC?.popToRootViewController(animated: false)

        // TODO: - handle it by coordinator
        if let feedListVC = navigationVC?.topViewController as? FeedsViewController {
            feedListVC.showEnterFeedAlertView(specifier)
        }
    }

    var isRunningUnitTests: Bool {
        let processInfo = ProcessInfo.processInfo
        let environment = processInfo.environment
        let arguments = processInfo.arguments

        // XCTest sets configuration and bundle environment values when it launches
        // the app as a unit-test host.
        let hasXCTestEnvironment = environment["XCTestConfigurationFilePath"] != nil ||
                                   environment["XCTestBundlePath"] != nil ||
                                   environment.keys.contains { $0.hasPrefix("XCTest") }

        // Some Xcode/test runner versions pass the XCTest configuration through
        // process arguments instead of, or in addition to, environment values.
        let hasXCTestArguments = arguments.contains { $0 == "-XCTestConfigurationFilePath" } ||
                                 arguments.contains { $0.hasSuffix(".xctest") || $0.hasSuffix(".xctestconfiguration") }

        // When XCTest is already loaded, the test bundle or XCTestCase runtime
        // type is visible even if launch metadata differs between runners.
        let hasLoadedXCTestRuntime = Bundle.allBundles.contains { $0.bundlePath.hasSuffix(".xctest") } ||
                                     NSClassFromString("XCTest.XCTestCase") != nil

        return hasXCTestEnvironment ||
               hasXCTestArguments ||
               hasLoadedXCTestRuntime
    }
}
