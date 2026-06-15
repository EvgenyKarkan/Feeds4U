//
//  ModuleFactory.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import UIKit
#if DEBUG
import Mocking
#endif

#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ModuleFactoryProtocol {
    func makeFeedsModule(delegate: any FeedsCoordinatingDelegate) -> UIViewController

    func makeFeedItemsModule(for feed: Feed,
                             delegate: any FeedItemsCoordinatingDelegate) -> UIViewController
    func makeFeedItemsModuleForSearchResults(with items: [FeedItem],
                                             matching query: String,
                                             delegate: any FeedItemsCoordinatingDelegate) -> UIViewController
    func makeExploreFeedsModule(with results: ExploreFeedsDTO,
                                for webPage: String) -> UIViewController
    func makeCloudflareBypassModule(for webPage: String,
                                    presentingController: UIViewController,
                                    moduleOutput: any CloudflareBypassModuleOutput) -> any CloudflareBypassModuleInput
    func makeArticleReaderModule(for title: String,
                                 htmlContent: String,
                                 articleURL: URL?) -> UIViewController
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
extension ModuleFactory: @MainActor ModuleFactoryProtocol {

    func makeFeedsModule(delegate: any FeedsCoordinatingDelegate) -> UIViewController {
        return FeedsBuilder.viewController(container: container, delegate: delegate)
    }

    @MainActor
    func makeFeedItemsModule(for feed: Feed, delegate: any FeedItemsCoordinatingDelegate) -> UIViewController {
        return FeedItemsBuilder.viewController(feed: feed, container: container, delegate: delegate)
    }

    @MainActor
    func makeFeedItemsModuleForSearchResults(with items: [FeedItem], matching query: String,
                                             delegate: any FeedItemsCoordinatingDelegate) -> UIViewController {
        return FeedItemsBuilder.searchResultsViewController(for: query, items: items, container: container, delegate: delegate)
    }

    @MainActor
    func makeExploreFeedsModule(with results: ExploreFeedsDTO, for webPage: String) -> UIViewController {
        return ExploreFeedsBuilder.viewController(with: results, webPage: webPage, container: container)
    }

    @MainActor
    func makeCloudflareBypassModule(for webPage: String,
                                    presentingController: UIViewController,
                                    moduleOutput: any CloudflareBypassModuleOutput) -> any CloudflareBypassModuleInput {
        return CloudflareBypassBuilder.module(
            for: webPage,
            presentingController: presentingController,
            moduleOutput: moduleOutput
        )
    }

    @MainActor
    func makeArticleReaderModule(for title: String,
                                 htmlContent: String,
                                 articleURL: URL?) -> UIViewController {
        return ArticleReaderBuilder.viewController(
            title: title,
            htmlContent: htmlContent,
            articleURL: articleURL
        )
    }
}
