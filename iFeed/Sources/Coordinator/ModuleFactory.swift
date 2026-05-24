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
    @MainActor func makeFeedsModule(delegate: any FeedsCoordinatingDelegate) -> UIViewController
    func makeFeedItemsModule(for feed: Feed, delegate: any FeedsCoordinatingDelegate) -> UIViewController
    func makeFeedItemsModuleForSearchResults(with items: [FeedItem], matching query: String) -> UIViewController
    func makeExploreFeedsModule(with results: ExploreFeedsDTO, for webPage: String) -> UIViewController

    @MainActor
    func makeCloudflareBypassModule(for webPage: String,
                                    presentingController: UIViewController,
                                    moduleOutput: any CloudflareBypassModuleOutput) -> any CloudflareBypassModuleInput
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

    func makeFeedsModule(delegate: any FeedsCoordinatingDelegate) -> UIViewController {
        return FeedsBuilder.viewController(container: container, delegate: delegate)
    }

    func makeFeedItemsModule(for feed: Feed, delegate: any FeedsCoordinatingDelegate) -> UIViewController {
        return FeedItemsBuilder.viewController(feed: feed, container: container)
    }

    func makeFeedItemsModuleForSearchResults(with items: [FeedItem], matching query: String) -> UIViewController {
        return FeedItemsBuilder.searchResultsViewController(for: query, items: items, container: container)
    }

    func makeExploreFeedsModule(with results: ExploreFeedsDTO, for webPage: String) -> UIViewController {
        return ExploreFeedsBuilder.viewController(with: results, webPage: webPage, container: container)
    }

    @MainActor
    func makeCloudflareBypassModule(for webPage: String,
                                    presentingController: UIViewController,
                                    moduleOutput: any CloudflareBypassModuleOutput) -> any CloudflareBypassModuleInput {
        return CloudflareBypassBuilder.module(for: webPage,
                                              presentingController: presentingController,
                                              moduleOutput: moduleOutput)
    }
}
