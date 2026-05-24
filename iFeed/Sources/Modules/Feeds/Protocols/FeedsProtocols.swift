//
//  FeedsProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData.NSManagedObjectID

@MainActor
protocol FeedsWireframeProtocol {
    /// Pushes the screen that displays items belonging to the selected feed.
    ///
    /// - Parameter feed: The feed whose sorted items should be displayed.
    func navigateToFeedItems(for feed: Feed)

    /// Pushes the screen that displays local feed-item search matches.
    ///
    /// - Parameters:
    ///   - results: Feed items matched by the local search engine.
    ///   - query: Original search query shown in the results title.
    func navigateToSearchResults(with results: [FeedItem], matching query: String)

    /// Presents the WebView-based feed explorer that handles Cloudflare challenges.
    ///
    /// - Parameters:
    ///   - webPage: Web page URL used as the discovery source.
    ///   - onResult: Callback invoked with the feed search result.
    func presentFeedExplorer(for webPage: String,
                             onChallengePresented: @escaping () -> Void,
                             onResult: @escaping (Result<ExploreFeedsDTO, any Error>) -> Void)

    /// Presents discovered feed candidates for a web page.
    ///
    /// - Parameters:
    ///   - results: Feed candidates returned by the feed discovery service.
    ///   - webPage: Web page URL used as the discovery source.
    ///   - onFeedSelected: Callback invoked with the selected feed URL.
    func presentDiscoveredFeeds(_ results: ExploreFeedsDTO,
                                for webPage: String,
                                onFeedSelected: @escaping ((String) -> Void))
}

/// Presenter ---> Interactor
protocol FeedsInteractorProtocol {
    // get fedds from local storage
    func getAllFeeds() -> [Feed]

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool
    func startParsingFeed(_ url: String, completion: @escaping (Result<Feed, any Error>) -> Void)

    // prepares semantic search engine
    func fillSearchMatchingEngine(completion: @escaping () -> Void)

    // local search
    func performSearch(by searchTerm: String, completion: @escaping ([FeedItem]?) -> Void)

    // explore if a web site has RSS feeds
    func exploreFeeds(on webSite: String, completion: @escaping ExploreFeedsServiceResultCompletion)

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed?

    func unreadCountsByFeed() -> [NSManagedObjectID: Int]

    func saveContext() throws

    func deleteFeed(_ feed: Feed)
}

/// Presenter ---> View
protocol FeedsViewProtocol: AnyObject {
    func updateOnDidLoad(with viewState: FeedsViewState)
    func updateOnWillAppear(with viewState: FeedsViewState)

    func showActivityIndicator()
    func hideActivityIndicator(_ completion: (() -> Void)?)

    func showEnterSearch()
    func showNoSearchResultsAlert()

    func disableTableViewEditingStateIfNeeded()

    func showError(_ error: any Error)
    func showFeedIsAlreadySavedError()
    func showFeedParsingError()

    func updateOnDidEndParsingFeed(with viewState: FeedsViewState)
    func updateViewAfterFeedDeletionAtIndexPath(_ indexPath: IndexPath, feeds: [Feed])
}

/// View ---> Presenter
protocol FeedsViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewWillAppear()

    func onViewNeedsToAddFeed(from url: String)
    func onViewNeedsToExploreFeeds(on webSite: String)

    func onViewNeedsToShowSearchInput()
    func onViewNeedsToSearchFeeds(by searchTerm: String)

    func getAllFeeds() -> [Feed]
    func feedForIndexPath(_ indexPath: IndexPath) -> Feed?

    func onViewDidSelectFeedAtIndexPath(_ indexPath: IndexPath)
    func onViewNeedsToDeleteFeedAtIndexPath(_ indexPath: IndexPath)
}

/// Defines Feeds module dependencies
protocol FeedsDependencies {
    func parser() -> any ParserProtocol
    func storage() -> any StorageProtocol
    func localSearch() -> any Searchable
    func exploreService() -> any ExploreFeedsServiceProtocol
}

/// Wireframe -> AppCoordinator
@MainActor
protocol FeedsCoordinatingDelegate: AnyObject {
    func onNeedToShowFeedDetails(for feed: Feed)
    func onNeedToShowSearchResults(with items: [FeedItem], matching query: String)
    func onNeedToShowExploreFeeds(with results: ExploreFeedsDTO, webPage: String)
    func onNeedToStartFeedExploration(for webPage: String,
                                      onChallengePresented: @escaping () -> Void,
                                      onResult: @escaping (Result<ExploreFeedsDTO, any Error>) -> Void)
}
