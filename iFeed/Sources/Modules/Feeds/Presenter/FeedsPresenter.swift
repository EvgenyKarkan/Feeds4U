//
//  FeedsPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import Dispatch

final class FeedsPresenter {
    // MARK: - Properties
    private let wireframe: any FeedsWireframeProtocol
    private let interactor: any FeedsInteractorProtocol
    private weak var view: (any FeedsViewProtocol)?

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
extension FeedsPresenter: FeedsViewDelegate {

    func onViewDidLoad() {
        let allFeeds = interactor.getAllFeeds()
        let counts = interactor.unreadCountsByFeed()
        let viewState = FeedsViewState(feeds: allFeeds, unreadCounts: counts)

        view?.updateOnDidLoad(with: viewState)
    }

    func onViewWillAppear() {
        let allFeeds = interactor.getAllFeeds()
        let counts = interactor.unreadCountsByFeed()
        let viewState = FeedsViewState(feeds: allFeeds, unreadCounts: counts)

        view?.updateOnWillAppear(with: viewState)
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
            case .success( _):
                guard let self = self else {
                    return
                }
                try? self.interactor.saveContext()

                let allFeeds = self.interactor.getAllFeeds()
                let counts = self.interactor.unreadCountsByFeed()
                let viewState = FeedsViewState(feeds: allFeeds, unreadCounts: counts)

                self.view?.updateOnDidEndParsingFeed(with: viewState)

            case .failure( _):
                self?.view?.showFeedParsingError()
            }
        }
    }

    func onViewNeedsToExploreFeeds(on webSite: String) {
        view?.disableTableViewEditingStateIfNeeded()
        view?.showActivityIndicator()

        interactor.exploreFeeds(on: webSite) { [weak self] result in
            nonisolated(unsafe) let presenter = self

            DispatchQueue.main.async {
                presenter?.view?.hideActivityIndicator(nil)

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
                        // TODO: - Handle this case on UI
                        presenter?.view?.showError(NSError(domain: #function, code: #line))
                        return
                    }

                    print(filteredData)

                    let callback: ((String) -> Void) = { selectedURL in
                        presenter?.onViewNeedsToAddFeed(from: selectedURL)
                    }

                    presenter?.wireframe.presentDiscoveredFeeds(
                        filteredData,
                        for: webSite,
                        onFeedSelected: callback
                    )

                case .failure(let error):
                    presenter?.view?.showError(error)
                }
            }
        }
    }

    func onViewDidPressSearch() {
        view?.showActivityIndicator()

        interactor.fillSearchMatchingEngine { [weak self] in
            nonisolated(unsafe) let presenter = self

            DispatchQueue.main.async {
                presenter?.view?.hideActivityIndicator {
                    presenter?.view?.showEnterSearch()
                }
            }
        }
    }

    // local search
    func onViewNeedsToSearchFeeds(by searchTerm: String) {
        view?.disableTableViewEditingStateIfNeeded()

        interactor.performSearch(by: searchTerm) { [weak self] feedItems in
            nonisolated(unsafe) let feedItems = feedItems
            nonisolated(unsafe) let presenter = self

            DispatchQueue.main.async {
                guard let results = feedItems, !results.isEmpty else {
                    presenter?.view?.showNoSearchResultsAlert()
                    return
                }
                presenter?.wireframe.navigateToSearchResults(with: results, matching: searchTerm)
            }
        }
    }

    func getAllFeeds() -> [Feed] {
        return interactor.getAllFeeds()
    }

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        return interactor.feedForIndexPath(indexPath)
    }

    func onViewDidSelectFeedAtIndexPath(_ indexPath: IndexPath) {
        guard indexPath.row < getAllFeeds().count,
              let feed = feedForIndexPath(indexPath),
              feed.feedItems.count > .zero else {
            return
        }
        wireframe.navigateToFeedItems(for: feed)
    }

    func onViewNeedsToDeleteFeedAtIndexPath(_ indexPath: IndexPath) {
        guard indexPath.row < getAllFeeds().count,
            let feed: Feed = feedForIndexPath(indexPath) else {
            return
        }
        interactor.deleteFeed(feed)

        view?.updateViewAfterFeedDeletionAtIndexPath(indexPath, feeds: getAllFeeds())
    }
}
