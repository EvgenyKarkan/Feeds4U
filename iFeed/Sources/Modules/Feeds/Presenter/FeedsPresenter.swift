//
//  FeedsPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import Dispatch

@MainActor
final class FeedsPresenter {
    // MARK: - Properties
    private let wireframe: any FeedsWireframeProtocol
    private let interactor: any FeedsInteractorProtocol
    private weak var view: (any FeedsViewProtocol)?

    private var currentSections: [FeedsSection] = []

    // MARK: - Init
    init(interactor: any FeedsInteractorProtocol,
         wireframe: any FeedsWireframeProtocol,
         view: any FeedsViewProtocol) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.view = view
    }
}

// MARK: - FeedsViewDelegate
extension FeedsPresenter: @MainActor FeedsViewDelegate {

    func onViewDidLoad() {
        let viewState = buildViewState()
        view?.updateOnDidLoad(with: viewState)

        /// The persistent store loads asynchronously at launch — rebuild the
        /// list once it is available so the first screen is not stuck empty.
        interactor.performWhenStorageReady { [weak self] in
            /// Storage contractually delivers this callback on the main queue.
            MainActor.assumeIsolated {
                guard let self else {
                    return
                }
                let viewState = self.buildViewState()
                self.view?.reloadFeedsList(with: viewState)
            }
        }
    }

    func onViewWillAppear() {
        let viewState = buildViewState()
        view?.updateOnWillAppear(with: viewState)
        refreshSearchButtonMenu()
    }

    func onViewNeedsToAddFeed(from url: String) {
        view?.disableTableViewEditingStateIfNeeded()

        guard !interactor.checkIfFeedIsAlreadySaved(with: url) else {
            view?.showFeedIsAlreadySavedError()
            return
        }

        view?.showActivityIndicator()

        interactor.startParsingFeed(url) { [weak self] result in
            self?.view?.hideActivityIndicator(nil)

            switch result {
            case .success:
                guard let self = self else {
                    return
                }
                /// The interactor saves in `didEndParsingFeed` — saving here again is not needed.
                let viewState = self.buildViewState()
                self.view?.updateOnDidEndParsingFeed(with: viewState)

            case .failure(let error):
                self?.view?.showFeedParsingError(error.localizedDescription)
            }
        }
    }

    @MainActor
    func onViewNeedsToExploreFeeds(on webSite: String) {
        view?.disableTableViewEditingStateIfNeeded()
        view?.showActivityIndicator()

        wireframe.presentFeedExplorer(
            for: webSite,
            onChallengePresented: { [weak self] in
                self?.view?.hideActivityIndicator(nil)
            },
            onResult: { [weak self] result in
                Task { @MainActor [weak self] in
                    self?.view?.hideActivityIndicator(nil)

                    switch result {
                    case .success(let data):
                        /// Filter data from items with invalid URL
                        let filteredData: ExploreFeedsDTO = data.compactMap { element -> ExploreFeedsElement? in
                            if let urlString = element.rssURL, URL(string: urlString) != nil {
                                return element
                            }
                            return nil
                        }
                        guard !filteredData.isEmpty else {
                            self?.view?.showNoFeedsDiscoveredAlert()
                            return
                        }

                        let callback: ((String) -> Void) = { selectedURL in
                            self?.onViewNeedsToAddFeed(from: selectedURL)
                        }

                        self?.wireframe.presentDiscoveredFeeds(
                            filteredData,
                            for: webSite,
                            onFeedSelected: callback
                        )

                    case .failure(let error):
                        self?.view?.showError(error)
                    }
                }
            }
        )
    }

    func onViewNeedsToShowOPMLPicker() {
        view?.showOPMLPicker()
    }

    func onViewNeedsToImportOPML(data: Data) {
        view?.disableTableViewEditingStateIfNeeded()

        let urls = interactor.parseOPML(data)
        guard !urls.isEmpty else {
            view?.showImportFoundNoFeeds()
            return
        }

        view?.showActivityIndicator()

        /// Feeds are imported one at a time on purpose: the parser holds a single
        /// delegate and cancels any in-flight parse when a new one starts, so
        /// firing them concurrently would clobber each other. Awaiting each parse
        /// serialises the run and keeps a clean added/skipped/failed tally.
        Task { [weak self] in
            guard let self else {
                return
            }

            var added = 0
            var skipped = 0
            var failed = 0

            for url in urls {
                if self.interactor.checkIfFeedIsAlreadySaved(with: url) {
                    skipped += 1
                    continue
                }
                let imported = await self.importFeed(from: url)
                imported ? (added += 1) : (failed += 1)
            }

            self.view?.hideActivityIndicator { [weak self] in
                guard let self else {
                    return
                }
                let viewState = self.buildViewState()
                self.view?.updateOnDidEndParsingFeed(with: viewState)
                self.view?.showImportSummary(added: added, skipped: skipped, failed: failed)
            }
        }
    }

    func onViewNeedsToShowSearchInput() {
        view?.showEnterSearch()
    }

    func onViewNeedsToClearRecentSearches() {
        interactor.clearRecentSearches()
        refreshSearchButtonMenu()
    }

    // local search
    func onViewNeedsToSearchFeeds(by searchTerm: String) {
        view?.disableTableViewEditingStateIfNeeded()
        view?.showActivityIndicator()

        Task { [weak self] in
            guard let self else {
                return
            }

            await interactor.fillSearchMatchingEngine()

            let feedItems = await interactor.performSearch(by: searchTerm)

            view?.hideActivityIndicator { [weak self] in
                guard let results = feedItems, !results.isEmpty else {
                    self?.view?.showNoSearchResultsAlert()
                    return
                }

                /// Remember only queries that produced results — typos and dead
                /// queries must not pollute the recent-searches menu.
                self?.interactor.saveRecentSearch(searchTerm)
                self?.refreshSearchButtonMenu()

                self?.wireframe.navigateToSearchResults(with: results, matching: searchTerm)
            }
        }
    }

    /// Internal section-indexing helper — resolves the feed at a table index path
    /// from the current sections. Used by the selection/deletion handlers below;
    /// no longer part of the View-facing protocol (the View never pulls data).
    func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        guard indexPath.section < currentSections.count else {
            return nil
        }
        let section = currentSections[indexPath.section]

        guard indexPath.row < section.feeds.count else {
            return nil
        }

        return section.feeds[indexPath.row]
    }

    @MainActor
    func onViewDidSelectFeedAtIndexPath(_ indexPath: IndexPath) {
        /// Item presence is checked with a SQL `COUNT(*)` — reading
        /// `feed.feedItems.count` here would fire the to-many fault and
        /// materialise every item of the feed on the main thread per tap.
        guard let feed = feedForIndexPath(indexPath),
              interactor.itemCount(for: feed) > .zero else {
            return
        }
        wireframe.navigateToFeedItems(for: feed)
    }

    func onViewNeedsToDeleteFeedAtIndexPath(_ indexPath: IndexPath) {
        guard let feed = feedForIndexPath(indexPath) else {
            return
        }

        let oldSectionCount = currentSections.count
        interactor.deleteFeed(feed)

        let viewState = buildViewState()
        let removedSection = viewState.sections.count < oldSectionCount ? indexPath.section : nil

        view?.animateFeedDeletion(at: indexPath, removeSectionAt: removedSection, with: viewState)
    }

    // MARK: - Folder operations
    func onViewNeedsToCreateFolder(name: String, feedURLs: [String]) {
        interactor.createFolder(name: name, feedURLs: feedURLs)

        let viewState = buildViewState()
        view?.reloadFeedsList(with: viewState)
    }

    func onViewNeedsToMoveFeedToFolder(feedURL: String, folderId: UUID) {
        interactor.addFeedToFolder(url: feedURL, folderId: folderId)

        let viewState = buildViewState()
        view?.reloadFeedsList(with: viewState)
    }

    func onViewNeedsToRemoveFeedFromFolder(feedURL: String) {
        interactor.removeFeedFromFolder(url: feedURL)

        let viewState = buildViewState()
        view?.reloadFeedsList(with: viewState)
    }

    func onViewNeedsToToggleFolder(id: UUID) {
        guard let sectionIndex = currentSections.firstIndex(where: { $0.folder?.id == id }) else {
            interactor.toggleFolderExpanded(id: id)
            let viewState = buildViewState()
            view?.reloadFeedsList(with: viewState)
            return
        }

        interactor.toggleFolderExpanded(id: id)

        let viewState = buildViewState()
        view?.animateFolderToggle(at: sectionIndex, with: viewState)
    }
}

// MARK: - Private
private extension FeedsPresenter {

    /// Bridges the callback-based single-feed parse into `async`, resolving to
    /// `true` on success and `false` on any failure. Used by the OPML import loop
    /// to await each feed before starting the next.
    func importFeed(from url: String) async -> Bool {
        await withCheckedContinuation { continuation in
            interactor.startParsingFeed(url) { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func refreshSearchButtonMenu() {
        let recent = interactor.recentSearches()
        view?.configureSearchButtonMenu(recent.reversed())
    }

    func buildViewState() -> FeedsViewState {
        let allFeeds = interactor.getAllFeeds()
        let counts = interactor.unreadCountsByFeed()

        let existingURLs = Set(allFeeds.map(\.rssURL))
        interactor.cleanupFolders(existingFeedURLs: existingURLs)

        let folders = interactor.getAllFolders()
        let folderedURLs = Set(folders.flatMap(\.feedURLs))

        /// O(1) lookups while matching folder URLs below — scanning `allFeeds`
        /// once per foldered URL made every rebuild quadratic. "First feed wins"
        /// on a duplicate URL, matching the previous `allFeeds.first` semantics.
        let feedsByURL = Dictionary(allFeeds.map { ($0.rssURL, $0) }, uniquingKeysWith: { first, _ in first })

        var sections: [FeedsSection] = []

        for folder in folders {
            let folderFeeds = folder.feedURLs.compactMap { feedsByURL[$0] }
            sections.append(FeedsSection(folder: folder, feeds: folderFeeds))
        }

        let ungroupedFeeds = allFeeds.filter { !folderedURLs.contains($0.rssURL) }
        if !ungroupedFeeds.isEmpty || folders.isEmpty {
            sections.append(FeedsSection(folder: nil, feeds: ungroupedFeeds))
        }

        currentSections = sections

        return FeedsViewState(sections: sections, unreadCounts: counts)
    }
}
