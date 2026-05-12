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
    private var appCoordinator: (any AppCoordinating)?

    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Quick return if running unit tests
        #if DEBUG || __DEBUG__
        if isRunningUnitTests {
            return true
        }
        #endif

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

        let coordinator = Coordinator(
            container: DIContainer(),
            controller: navigationVC
        )

        navigationVC?.viewControllers = [coordinator.makeFeedsViewController()]

        appCoordinator = coordinator

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationVC
        window?.makeKeyAndVisible()
    }

    func openURL(_ url: URL) {
        // TODO: handle by coordinator
        guard let specifier = (url as NSURL).resourceSpecifier,
              !specifier.isEmpty else {
            return
        }

        navigationVC?.popToRootViewController(animated: false)

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
