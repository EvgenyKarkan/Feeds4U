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

    /// Re-entrancy guard for module pushes. A second tap on a row can request
    /// another push while the first push transition is still animating, which
    /// double-pushes the module and trips UIKit's "unbalanced calls to begin/end
    /// appearance transitions". The flag is raised for the duration of a push and
    /// cleared on the transition's completion, so only the first of a rapid burst
    /// is honoured.
    private var isPushInFlight = false

    // MARK: - Init
    /// - Parameter moduleFactory: Injectable for testing. Defaults to the
    ///   production `ModuleFactory` built from the DI container.
    init(container: any DIContainerProtocol,
         controller: UINavigationController?,
         moduleFactory: (any ModuleFactoryProtocol)? = nil) {
        navigationController = controller
        navigationController?.navigationBar.tintColor = .systemBlue

        self.moduleFactory = moduleFactory ?? ModuleFactory(container: container)
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
        pushModule { [self] in
            moduleFactory.makeFeedItemsModule(for: feed, delegate: self)
        }
    }

    func onNeedToShowSearchResults(with items: [FeedItem], matching query: String) {
        pushModule { [self] in
            moduleFactory.makeFeedItemsModuleForSearchResults(with: items, matching: query, delegate: self)
        }
    }

    func onNeedToShowExploreFeeds(with results: ExploreFeedsDTO, webPage: String) {
        guard let navigationController else {
            return
        }
        let exploreFeedsVC = moduleFactory.makeExploreFeedsModule(with: results, for: webPage)

        let navigationVC = UINavigationController(rootViewController: exploreFeedsVC)
        navigationVC.modalPresentationStyle = .fullScreen

        navigationController.presentGuarded(navigationVC)
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
        pushModule { [self] in
            moduleFactory.makeArticleReaderModule(
                for: title,
                htmlContent: htmlContent,
                articleURL: articleURL
            )
        }
    }
}

// MARK: - Navigation
private extension Coordinator {

    /// Pushes a freshly built module, ignoring the request when a push transition
    /// is already in flight. This serialises rapid "double-trigger" taps into a
    /// single push and prevents a corrupted navigation stack.
    ///
    /// - Parameter makeViewController: Builds the view controller to push. Called
    ///   only when the push is actually performed (never for a suppressed burst).
    func pushModule(_ makeViewController: () -> UIViewController) {
        guard let navigationController, !isPushInFlight else {
            return
        }

        isPushInFlight = true
        navigationController.pushViewController(makeViewController(), animated: true)

        /// The transition coordinator exists immediately after an animated push;
        /// its completion fires when the push animation finishes. The fallback
        /// covers the (unexpected) non-animated case so the guard never sticks.
        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.isPushInFlight = false
            }
        } else {
            /// No active transition (e.g. no window in a test, or a non-animated
            /// push). Clear on the next run-loop tick rather than synchronously,
            /// so a same-tick double-trigger is still collapsed to one push.
            DispatchQueue.main.async { [weak self] in
                self?.isPushInFlight = false
            }
        }
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
