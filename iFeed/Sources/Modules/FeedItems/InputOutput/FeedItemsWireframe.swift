//
//  FeedItemsWireframe.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import SafariServices

@MainActor
final class FeedItemsWireframe {
    // MARK: - Properties
    weak var viewController: FeedItemsViewController?
    weak var delegate: (any FeedItemsCoordinatingDelegate)?

    private var prewarmingToken: SFSafariViewController.PrewarmingToken?
}

// MARK: - FeedItemsWireframeProtocol
extension FeedItemsWireframe: @MainActor FeedItemsWireframeProtocol {

    /// The maximum number of connections to prewarm.
    ///
    /// Safari's connection prewarming has practical system limits. Prewarming too many connections
    /// can be wasteful and may not provide benefits beyond the first few items the user is likely
    /// to tap. Limiting to 10 URLs balances performance with resource usage.
    private static let maxPrewarmedConnections = 10

    /// Pre-warms Safari connections for the first 10 unique feed item URLs.
    ///
    /// Called from `viewDidLoad` on initial load and from `didEndParsingFeed`
    /// after a pull-to-refresh. Both call sites pass the items in display order
    /// (newest first), so the prewarmed connections are exactly the rows at the
    /// top of the list — the ones the user is most likely to tap.
    ///
    /// - Parameter items: Feed items whose URLs should be prewarmed, in display order.
    @MainActor func prewarmSafari(for feedItems: [FeedItem]) {
        // Step 1: Clean up any existing prewarming token
        // -----------------------------------------------
        // If we previously prewarmed connections, invalidate that token to free up system resources.
        // This prevents resource leaks when the method is called multiple times (e.g., during refresh).
        prewarmingToken?.invalidate()

        // Step 2: Collect the first N unique valid URLs in display order
        // ---------------------------------------------------------------
        // - Filter out items with empty link strings (prevents URL creation failures)
        // - Skip invalid URLs (URL(string:) returns nil)
        // - The `seenURLs` set deduplicates in O(1) per item while the array
        //   preserves display order — unlike a plain Set, whose unordered
        //   prefix() would prewarm 10 arbitrary URLs instead of the newest ones.
        var seenURLs = Set<URL>()
        var urlsToPrewarm: [URL] = []

        for item in feedItems {
            guard !item.link.isEmpty,
                  let url = URL(string: item.link),
                  seenURLs.insert(url).inserted else {
                continue
            }

            urlsToPrewarm.append(url)
            if urlsToPrewarm.count == Self.maxPrewarmedConnections {
                break
            }
        }

        // Step 3: Validate we have URLs to prewarm
        // -----------------------------------------
        // If no valid URLs were found, clear the token and exit early
        guard !urlsToPrewarm.isEmpty else {
            prewarmingToken = nil
            return
        }

        // Step 4: Request Safari to prewarm connections
        // ----------------------------------------------
        // Store the token so we can invalidate it later when:
        // - The view controller is dismissed/popped (in viewWillDisappear)
        // - New items are being prewarmed (Step 1 of this method)
        prewarmingToken = SFSafariViewController.prewarmConnections(to: urlsToPrewarm)
    }

    func invalidateSafariPrewarm() {
        prewarmingToken?.invalidate()
        prewarmingToken = nil
    }

    func presentSafari(for url: URL, zoomingFrom cell: UITableViewCell) {
        guard let controller = viewController else {
            return
        }

        let safariVC = SFSafariViewController(
            url: url,
            configuration: SFSafariViewController.Configuration()
        )

        let zoomOptions = UIViewController.Transition.ZoomOptions()
        zoomOptions.dimmingVisualEffect = UIBlurEffect(style: .systemUltraThinMaterial)

        // Capture the cell weakly: the zoom provider is retained by Safari for the
        // whole presentation, so a strong capture would pin the cell and block its
        // reuse. If the row is recycled while Safari is up, the provider simply
        // returns nil and the dismissal falls back to a non-zoom transition.
        safariVC.preferredTransition = .zoom(options: zoomOptions) { [weak cell] _ in
            return cell
        }

        controller.presentGuarded(safariVC)
    }

    func pushArticleReader(title: String, htmlContent: String, articleURL: URL?) {
        delegate?.onNeedToShowArticleReader(for: title, htmlContent: htmlContent, articleURL: articleURL)
    }
}
