//
//  ExploreFeedsPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

final class ExploreFeedsPresenter {
    // MARK: - Properties
    private let wireframe: any ExploreFeedsWireframeProtocol
    private let interactor: any ExploreFeedsInteractorProtocol
    private weak var view: (any ExploreFeedsViewProtocol)?

    // MARK: - Init
    init(interactor: any ExploreFeedsInteractorProtocol,
         wireframe: any ExploreFeedsWireframeProtocol,
         view: any ExploreFeedsViewProtocol) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.view = view
    }
}

// MARK: - ExploreFeedsViewDelegate
extension ExploreFeedsPresenter: ExploreFeedsViewDelegate {

    func onViewDidLoad() {
        let state = ExploreFeedsViewState(
            webPageTitle: interactor.getWebPageTitle(),
            exploreResults: interactor.getResultsWithSavedStatus()
        )

        view?.updateOnDidLoad(with: state)
    }

    func onViewNeedsToAddFeed(from url: String) {
        guard !interactor.checkIfFeedIsAlreadySaved(with: url) else {
            view?.showFeedIsAlreadySavedError()
            return
        }

        view?.showActivityIndicator()

        interactor.startParsingFeed(url) { [weak self] result in
            guard let self else {
                return
            }
            self.view?.hideActivityIndicator()

            switch result {
            case .success:
                try? self.interactor.saveContext()

                let state = ExploreFeedsViewState(
                    webPageTitle: self.interactor.getWebPageTitle(),
                    exploreResults: self.interactor.getResultsWithSavedStatus()
                )

                self.view?.update(with: state)

            case .failure:
                self.view?.showFeedParsingError()
            }
        }
    }
}
