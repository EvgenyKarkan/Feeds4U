//
//  CloudflareBypassWireframe.swift
//  iFeed
//
//  Created by Evgeny Karkan on 24.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import WebKit

final class CloudflareBypassWireframe {
    // MARK: - Properties
    weak var presentingController: UIViewController?
    weak var presenter: (any CloudflareBypassViewDelegate)?
    private var challengeNavController: UINavigationController?
    private weak var challengeViewController: CloudflareBypassViewController?
}

// MARK: - CloudflareBypassWireframeProtocol
extension CloudflareBypassWireframe: CloudflareBypassWireframeProtocol {

    func presentChallenge(with webView: WKWebView) {
        guard let presentingController else {
            return
        }

        let challengeVC = CloudflareBypassViewController()
        challengeVC.presenter = presenter
        challengeVC.loadViewIfNeeded()
        challengeVC.configureWithWebView(webView)
        challengeViewController = challengeVC

        let nav = UINavigationController(rootViewController: challengeVC)
        nav.modalPresentationStyle = .fullScreen
        challengeNavController = nav

        presentingController.presentGuarded(nav)
    }

    func dismissChallenge(completion: (() -> Void)?) {
        if let nav = challengeNavController {
            challengeViewController?.markDismissalAsHandled()
            challengeViewController = nil
            challengeNavController = nil
            nav.dismiss(animated: true) {
                completion?()
            }
        } else {
            challengeViewController = nil
            completion?()
        }
    }
}
