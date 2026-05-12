//
//  ModuleFactory.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit

protocol ModuleFactoryProtocol {
    func makeFeedsModule() -> UIViewController
}

final class ModuleFactory {
    // MARK: - Properties
    private let container: any DIContainerProtocol

    // MARK: - Init
    init(container: any DIContainerProtocol) {
        self.container = container
    }
}

// MARK: - ModuleFactoryProtocol
extension ModuleFactory: ModuleFactoryProtocol {

    func makeFeedsModule() -> UIViewController {
        return FeedsBuilder.viewController(container: container)
    }
}
