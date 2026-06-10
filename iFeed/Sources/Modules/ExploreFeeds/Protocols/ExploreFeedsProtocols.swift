//
//  ExploreFeedsProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Presenter ---> Wireframe
@MainActor
protocol ExploreFeedsWireframeProtocol: AnyObject {

}

/// Presenter ---> Interactor
@MainActor
protocol ExploreFeedsInteractorProtocol: AnyObject {
    func getWebPageTitle() -> String
    /// Cross-references explore results with already saved feed URLs, returning display-ready models.
    func getResultsWithSavedStatus() -> [ExploreFeedsResult]

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool
    func startParsingFeed(_ url: String, completion: @escaping (Result<Feed, any Error>) -> Void)

    func saveContext() throws
}

/// Presenter ---> View
@MainActor
protocol ExploreFeedsViewProtocol: AnyObject {
    func updateOnDidLoad(with viewState: ExploreFeedsViewState)
    func update(with viewState: ExploreFeedsViewState)

    func showFeedIsAlreadySavedError()
    func showFeedParsingError(_ message: String)

    func showActivityIndicator()
    func hideActivityIndicator()
}

/// View ---> Presenter
@MainActor
protocol ExploreFeedsViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewNeedsToAddFeed(from url: String)
}

/// Defines dependencies of current module
@MainActor
protocol ExploreFeedsDependencies: AnyObject {
    func parser() -> any ParserProtocol
    func storage() -> any StorageProtocol
    func localSearch() -> any Searchable
}
