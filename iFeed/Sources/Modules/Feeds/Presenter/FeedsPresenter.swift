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
                try? self.interactor.saveContext()

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

        interactor.saveRecentSearch(searchTerm)
        refreshSearchButtonMenu()

        interactor.fillSearchMatchingEngine { [weak self] in
            self?.interactor.performSearch(by: searchTerm) { [weak self] feedItems in
                Task { @MainActor [weak self] in
                    self?.view?.hideActivityIndicator { [weak self] in
                        guard let results = feedItems, !results.isEmpty else {
                            self?.view?.showNoSearchResultsAlert()
                            return
                        }
                        self?.wireframe.navigateToSearchResults(with: results, matching: searchTerm)
                    }
                }
            }
        }
    }

    func getAllFeeds() -> [Feed] {
        return interactor.getAllFeeds()
    }

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
        guard let feed = feedForIndexPath(indexPath),
              feed.feedItems.count > .zero else {
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

        let section = currentSections[sectionIndex]
        let oldRowCount = section.folder?.isExpanded == true ? section.feeds.count : 0

        interactor.toggleFolderExpanded(id: id)

        let viewState = buildViewState()
        view?.animateFolderToggle(at: sectionIndex, oldRowCount: oldRowCount, with: viewState)
    }
}

// MARK: - Private
private extension FeedsPresenter {

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

        var sections: [FeedsSection] = []

        for folder in folders {
            let folderFeeds = folder.feedURLs.compactMap { url in
                allFeeds.first { $0.rssURL == url }
            }
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
