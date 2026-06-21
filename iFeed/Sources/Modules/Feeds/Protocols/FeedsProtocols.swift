//
//  FeedsProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData.NSManagedObjectID
#if DEBUG
import Mocking
#endif

#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
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
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol FeedsInteractorProtocol {
    // get fedds from local storage
    func getAllFeeds() -> [Feed]

    /// Runs `completion` once the persistent store is available (delivered on
    /// the main queue) — lets the presenter rebuild the list that was shown
    /// before the asynchronous store load finished at launch.
    func performWhenStorageReady(_ completion: @escaping @Sendable () -> Void)

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool
    func startParsingFeed(_ url: String, completion: @escaping (Result<Feed, any Error>) -> Void)

    /// Extracts the feed URLs contained in an OPML export, ignoring its folder
    /// structure (the app's feed list is flat). Returns an empty array when the
    /// data is not valid OPML or holds no usable feeds.
    func parseOPML(_ data: Data) -> [String]

    // prepares semantic search engine
    func fillSearchMatchingEngine() async

    // local search
    func performSearch(by searchTerm: String) async -> [FeedItem]?

    // recent searches
    func recentSearches() -> [String]
    func saveRecentSearch(_ query: String)
    func clearRecentSearches()

    // explore if a web site has RSS feeds
    func exploreFeeds(on webSite: String, completion: @escaping ExploreFeedsServiceResultCompletion)

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed?

    func unreadCountsByFeed() -> [NSManagedObjectID: Int]

    /// Returns the number of items stored for `feed` via a SQL `COUNT(*)` —
    /// never fires the `feedItems` relationship fault.
    func itemCount(for feed: Feed) -> Int

    func saveContext() throws

    func deleteFeed(_ feed: Feed)

    // folder operations
    func getAllFolders() -> [FeedFolder]
    @discardableResult
    func createFolder(name: String, feedURLs: [String]) -> FeedFolder
    func addFeedToFolder(url: String, folderId: UUID)
    func removeFeedFromFolder(url: String)
    func toggleFolderExpanded(id: UUID)
    func cleanupFolders(existingFeedURLs: Set<String>)
}

/// Presenter ---> View
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol FeedsViewProtocol: AnyObject {
    func updateOnDidLoad(with viewState: FeedsViewState)
    func updateOnWillAppear(with viewState: FeedsViewState)

    func showActivityIndicator()
    func hideActivityIndicator(_ completion: (() -> Void)?)

    func showEnterSearch()
    func configureSearchButtonMenu(_ searches: [String])
    func showNoSearchResultsAlert()
    func showNoFeedsDiscoveredAlert()

    func disableTableViewEditingStateIfNeeded()

    func showError(_ error: any Error)
    func showFeedIsAlreadySavedError()
    func showFeedParsingError(_ message: String)

    /// Presents the system file picker so the user can choose an OPML file to import.
    func showOPMLPicker()

    /// Reports the outcome of an OPML import once all feeds have been processed.
    /// - Parameters:
    ///   - added: Feeds newly parsed and saved.
    ///   - skipped: Feeds already present, left untouched.
    ///   - failed: Feeds whose URL could not be parsed.
    func showImportSummary(added: Int, skipped: Int, failed: Int)
    func showImportFoundNoFeeds()
    func showImportFileUnreadable()

    func updateOnDidEndParsingFeed(with viewState: FeedsViewState)
    func animateFeedDeletion(at indexPath: IndexPath, removeSectionAt sectionIndex: Int?, with viewState: FeedsViewState)

    func reloadFeedsList(with viewState: FeedsViewState)
    func animateFolderToggle(at sectionIndex: Int, with viewState: FeedsViewState)
}

/// View ---> Presenter
@MainActor
protocol FeedsViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewWillAppear()

    func onViewNeedsToAddFeed(from url: String)
    func onViewNeedsToExploreFeeds(on webSite: String)
    func onViewNeedsToShowOPMLPicker()
    func onViewNeedsToImportOPML(data: Data)

    func onViewNeedsToShowSearchInput()
    func onViewNeedsToSearchFeeds(by searchTerm: String)
    func onViewNeedsToClearRecentSearches()

    func onViewDidSelectFeedAtIndexPath(_ indexPath: IndexPath)
    func onViewNeedsToDeleteFeedAtIndexPath(_ indexPath: IndexPath)

    // folder operations
    func onViewNeedsToCreateFolder(name: String, feedURLs: [String])
    func onViewNeedsToMoveFeedToFolder(feedURL: String, folderId: UUID)
    func onViewNeedsToRemoveFeedFromFolder(feedURL: String)
    func onViewNeedsToToggleFolder(id: UUID)
}

/// Defines Feeds module dependencies
@MainActor
protocol FeedsDependencies {
    func parser() -> any ParserProtocol
    func storage() -> any StorageProtocol
    func localSearch() -> any Searchable
    func exploreService() -> any ExploreFeedsServiceProtocol
    func foldersManager() -> any FeedFolderManaging
    func keyedStorage() -> any KeyedStorageProtocol
    func opmlParser() -> any OPMLParsing
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
