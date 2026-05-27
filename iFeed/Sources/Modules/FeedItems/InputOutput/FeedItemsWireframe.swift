//
//  FeedItemsWireframe.swift
//  iFeed
//
//  Created by Evgeny Karkan on 16.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import SafariServices

final class FeedItemsWireframe {
    // MARK: - Properties
    weak var viewController: FeedItemsViewController?

    private var prewarmingToken: SFSafariViewController.PrewarmingToken?
}

// MARK: - FeedItemsWireframeProtocol
extension FeedItemsWireframe: FeedItemsWireframeProtocol {

    /// Pre-warms Safari connections for up to 10 unique feed item URLs.
    ///
    /// Called from `viewDidLoad` on initial load and from `didEndParsingFeed`
    /// after a pull-to-refresh. Both call sites pass the full sorted item list
    /// so the most relevant items are always covered.
    ///
    /// - Parameter items: Feed items whose URLs should be prewarmed.
    func prewarmSafari(for feedItems: [FeedItem]) {
        // Step 1: Clean up any existing prewarming token
        // -----------------------------------------------
        // If we previously prewarmed connections, invalidate that token to free up system resources.
        // This prevents resource leaks when the method is called multiple times (e.g., during refresh).
        prewarmingToken?.invalidate()

        // Step 2: Extract and deduplicate valid URLs from feed items
        // -----------------------------------------------------------
        // - Filter out items with empty link strings (prevents URL creation failures)
        // - Convert link strings to URL objects (compactMap removes nil values from invalid URLs)
        // - Use Set to automatically eliminate duplicate URLs, improving both:
        //   * Performance: O(n) deduplication
        //   * Resource efficiency: Don't prewarm the same URL multiple times
        let uniqueURLs = Set(feedItems.compactMap { item -> URL? in
            guard !item.link.isEmpty else {
                return nil
            }
            return URL(string: item.link)
        })

        // Step 3: Validate we have URLs to prewarm
        // -----------------------------------------
        // If no valid URLs were found, clear the token and exit early
        guard !uniqueURLs.isEmpty else {
            prewarmingToken = nil
            return
        }

        // Step 4: Limit the number of connections to prewarm
        // ---------------------------------------------------
        // Safari's connection prewarming has practical system limits. Prewarming too many connections
        // can be wasteful and may not provide benefits beyond the first few items the user is likely
        // to tap. Limiting to 10 URLs balances performance with resource usage.
        // Note: Set is unordered, so prefix() gives arbitrary 10 items, not necessarily the "first" ones
        let urlsToPrewarm = Array(uniqueURLs.prefix(10))

        // Step 5: Request Safari to prewarm connections
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

        safariVC.preferredTransition = .zoom(options: zoomOptions) { _ in
            return cell
        }

        controller.present(safariVC, animated: true)
    }

    func pushArticleReader(title: String, htmlContent: String, articleURL: URL?) {
        let readerVC = ArticleReaderViewController(
            title: title,
            htmlContent: htmlContent,
            articleURL: articleURL
        )
        viewController?.navigationController?.pushViewController(readerVC, animated: true)
    }
}
