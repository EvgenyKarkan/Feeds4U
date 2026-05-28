//
//  ArticleReaderPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

final class ArticleReaderPresenter {

    // MARK: - Properties
    private let interactor: any ArticleReaderInteractorProtocol
    private let wireframe: any ArticleReaderWireframeProtocol
    private weak var view: (any ArticleReaderViewProtocol)?

    // MARK: - Init
    init(interactor: any ArticleReaderInteractorProtocol,
         wireframe: any ArticleReaderWireframeProtocol,
         view: any ArticleReaderViewProtocol) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.view = view
    }
}

// MARK: - ArticleReaderViewDelegate
extension ArticleReaderPresenter: ArticleReaderViewDelegate {

    func onViewDidLoad() {
        let fullHTML = ReaderHTMLTemplate.wrapInReaderTemplate(
            interactor.htmlContent,
            isDarkMode: interactor.isDarkMode
        )

        let viewState = ArticleReaderViewState(
            title: interactor.articleTitle,
            fullHTML: fullHTML,
            baseURL: interactor.articleURL,
            isDarkMode: interactor.isDarkMode,
            hasArticleURL: interactor.articleURL != nil
        )

        view?.configureInitialState(with: viewState)
    }

    func onViewWillAppear() {
        view?.applyThemeChange(isDarkMode: interactor.isDarkMode)
    }

    func onToggleThemeTapped() {
        interactor.isDarkMode.toggle()
        interactor.persistThemePreference()
        view?.applyThemeChange(isDarkMode: interactor.isDarkMode)
    }

    func onOpenInSafariTapped() {
        guard let url = interactor.articleURL else {
            return
        }
        wireframe.openInSafari(url: url)
    }

    func onLinkActivated(url: URL) {
        wireframe.openInSafari(url: url)
    }
}
