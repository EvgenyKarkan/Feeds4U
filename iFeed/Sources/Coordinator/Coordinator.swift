//
//  Coordinator.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit

/// Defines the basic requirements for a coordinator, which is responsible for coordinating the navigation
/// flow within the application.
protocol Coordinating {
    /// Starts a flow and creates an initial screen of a flow.
    @MainActor func start()

    /// Handles a deep-link by navigating to the root feeds screen
    /// and presenting the "add feed" alert pre-filled with the URL's resource specifier.
    @MainActor func handleDeepLink(url: URL)
}

/// Aggregates all module-level coordinating delegates that the app coordinator must handle.
protocol AppCoordinating: FeedsCoordinatingDelegate, FeedItemsCoordinatingDelegate {}

@MainActor
final class Coordinator {
    // MARK: - Properties
    private let moduleFactory: any ModuleFactoryProtocol
    private(set) weak var navigationController: UINavigationController?
    private var activeCloudflareBypass: (any CloudflareBypassModuleInput)?
    private var feedExplorationChallengeCallback: (() -> Void)?
    private var feedExplorationResultCallback: ((Result<ExploreFeedsDTO, any Error>) -> Void)?

    // MARK: - Init
    init(container: any DIContainerProtocol, controller: UINavigationController?) {
        navigationController = controller

        moduleFactory = ModuleFactory(container: container)
    }
}

// MARK: - Coordinating
extension Coordinator: Coordinating {

    @MainActor func start() {
        let feedsVC = moduleFactory.makeFeedsModule(delegate: self)
        navigationController?.viewControllers = [feedsVC]
    }

    @MainActor func handleDeepLink(url: URL) {
        guard let specifier = (url as NSURL).resourceSpecifier,
              !specifier.isEmpty else {
            return
        }

        navigationController?.presentedViewController?.dismiss(animated: false)
        navigationController?.popToRootViewController(animated: false)

        if let feedsVC = navigationController?.topViewController as? FeedsViewController {
            feedsVC.showEnterFeedAlertView(specifier)
        }
    }
}

// MARK: - AppCoordinating
extension Coordinator: AppCoordinating {

    func onNeedToShowFeedDetails(for feed: Feed) {
        guard let navigationController else {
            return
        }
        let feedItemsVC = moduleFactory.makeFeedItemsModule(for: feed, delegate: self)
        navigationController.pushViewController(feedItemsVC, animated: true)
    }

    func onNeedToShowSearchResults(with items: [FeedItem], matching query: String) {
        guard let navigationController else {
            return
        }
        let feedItemsVC = moduleFactory.makeFeedItemsModuleForSearchResults(with: items, matching: query, delegate: self)
        navigationController.pushViewController(feedItemsVC, animated: true)
    }

    func onNeedToShowExploreFeeds(with results: ExploreFeedsDTO, webPage: String) {
        guard let navigationController else {
            return
        }
        let exploreFeedsVC = moduleFactory.makeExploreFeedsModule(with: results, for: webPage)

        let navigationVC = UINavigationController(rootViewController: exploreFeedsVC)
        navigationVC.modalPresentationStyle = .fullScreen

        navigationController.present(navigationVC, animated: true)
    }

    func onNeedToStartFeedExploration(for webPage: String,
                                      onChallengePresented: @escaping () -> Void,
                                      onResult: @escaping (Result<ExploreFeedsDTO, any Error>) -> Void) {
        guard let navigationController else {
            return
        }

        feedExplorationChallengeCallback = onChallengePresented
        feedExplorationResultCallback = onResult

        let module = moduleFactory.makeCloudflareBypassModule(
            for: webPage,
            presentingController: navigationController,
            moduleOutput: self
        )
        activeCloudflareBypass = module
        module.startSearch()
    }

    func onNeedToShowArticleReader(for title: String, htmlContent: String, articleURL: URL?) {
        guard let navigationController else {
            return
        }
        let articleReaderVC = moduleFactory.makeArticleReaderModule(
            for: title,
            htmlContent: htmlContent,
            articleURL: articleURL
        )
        navigationController.pushViewController(articleReaderVC, animated: true)
    }
}

// MARK: - CloudflareBypassModuleOutput
extension Coordinator: CloudflareBypassModuleOutput {

    func cloudflareBypassDidPresentChallenge() {
        feedExplorationChallengeCallback?()
        feedExplorationChallengeCallback = nil
    }

    func cloudflareBypassDidFinish(with result: Result<ExploreFeedsDTO, any Error>) {
        activeCloudflareBypass = nil
        feedExplorationResultCallback?(result)
        feedExplorationResultCallback = nil
    }
}
