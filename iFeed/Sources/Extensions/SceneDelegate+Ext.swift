//
//  SceneDelegate+Ext.swift
//  iFeed
//
//  Created by Evgeny Karkan on 31.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

extension SceneDelegate {

    var isRunningUnitTests: Bool {
        let processInfo = ProcessInfo.processInfo
        let environment = processInfo.environment

        // XCTest sets configuration and bundle environment values when it launches
        // the app as a unit-test host.
        if environment["XCTestConfigurationFilePath"] != nil ||
            environment["XCTestBundlePath"] != nil ||
            environment.keys.contains(where: { $0.hasPrefix("XCTest") }) {
            return true
        }

        // Some Xcode/test runner versions pass the XCTest configuration through
        // process arguments instead of, or in addition to, environment values.
        let arguments = processInfo.arguments
        if arguments.contains(where: { $0 == "-XCTestConfigurationFilePath" }) ||
            arguments.contains(where: { $0.hasSuffix(".xctest") || $0.hasSuffix(".xctestconfiguration") }) {
            return true
        }

        // When XCTest is already loaded, the test bundle or XCTestCase runtime
        // type is visible even if launch metadata differs between runners.
        if Bundle.allBundles.contains(where: { $0.bundlePath.hasSuffix(".xctest") }) ||
            NSClassFromString("XCTest.XCTestCase") != nil {
            return true
        }

        return false
    }
}
