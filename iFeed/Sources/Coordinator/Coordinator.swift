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
        navigationController?.navigationBar.tintColor = .systemBlue

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
        guard let feedURL = Self.feedURL(fromDeepLink: url) else {
            return
        }

        navigationController?.presentedViewController?.dismiss(animated: false)
        navigationController?.popToRootViewController(animated: false)

        if let feedsVC = navigationController?.topViewController as? FeedsViewController {
            feedsVC.showEnterFeedAlertView(feedURL)
        }
    }

    /// Converts a deep-link URL into a prefill-ready feed URL.
    ///
    /// The custom scheme is a transport wrapper, not part of the feed address:
    /// `feed://www.example.com/rss` must surface `https://www.example.com/rss`
    /// in the input field — not the raw resource specifier `//www.example.com/rss`.
    ///
    /// Rules:
    /// - the resource specifier's leading `//` is dropped;
    /// - when the remainder carries no `http(s)` scheme of its own, `https://`
    ///   is prepended (`feed://https://…`-style links keep their explicit scheme).
    ///
    /// - Returns: An absolute URL string, or `nil` when the link carries no
    ///   resource specifier at all.
    static func feedURL(fromDeepLink url: URL) -> String? {
        guard let specifier = (url as NSURL).resourceSpecifier, !specifier.isEmpty else {
            return nil
        }

        var candidate = specifier
        if candidate.hasPrefix("//") {
            candidate.removeFirst(2)
        }

        guard !candidate.isEmpty else {
            return nil
        }

        let lowercased = candidate.lowercased()
        if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") {
            candidate = "https://" + candidate
        }

        return candidate
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
        finishCloudflareBypass(with: result)
    }

    func cloudflareBypassDidCancel() {
        /// The user closed the verification screen themselves — clean up silently.
        /// Routing this through the failure path would surface a misleading
        /// "blocked by Cloudflare" error alert right after a deliberate cancel.
        /// The activity indicator is not stuck: it was already hidden when the
        /// challenge was presented (`onChallengePresented`).
        activeCloudflareBypass = nil
        feedExplorationChallengeCallback = nil
        feedExplorationResultCallback = nil
    }
}

// MARK: - CloudflareBypass Cleanup
private extension Coordinator {

    func finishCloudflareBypass(with result: Result<ExploreFeedsDTO, any Error>) {
        activeCloudflareBypass = nil
        feedExplorationChallengeCallback = nil

        let resultCallback = feedExplorationResultCallback
        feedExplorationResultCallback = nil
        resultCallback?(result)
    }
}
