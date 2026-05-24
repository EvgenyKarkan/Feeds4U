//
//  CloudflareBypassBuilder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 24.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

enum CloudflareBypassBuilder {

    @MainActor
    static func module(for webPage: String,
                       presentingController: UIViewController,
                       moduleOutput: any CloudflareBypassModuleOutput) -> any CloudflareBypassModuleInput {
        /// Interactor
        let interactor = CloudflareBypassInteractor()

        /// Wireframe
        let wireframe = CloudflareBypassWireframe()
        wireframe.presentingController = presentingController

        /// Presenter
        let presenter = CloudflareBypassPresenter(
            interactor: interactor,
            wireframe: wireframe,
            moduleOutput: moduleOutput,
            webPage: webPage
        )

        wireframe.presenter = presenter

        return presenter
    }
}
