//
//  ArticleReaderProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Presenter ---> Wireframe
protocol ArticleReaderWireframeProtocol: AnyObject {
    func openInSafari(url: URL)
}

/// Presenter ---> Interactor
protocol ArticleReaderInteractorProtocol: AnyObject {
    var articleTitle: String { get }
    var htmlContent: String { get }
    var articleURL: URL? { get }
    var isDarkMode: Bool { get set }
    func persistThemePreference()
}

/// Presenter ---> View
protocol ArticleReaderViewProtocol: AnyObject {
    func configureInitialState(with viewState: ArticleReaderViewState)
    func applyThemeChange(isDarkMode: Bool)
}

/// View ---> Presenter
protocol ArticleReaderViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewWillAppear()
    func onToggleThemeTapped()
    func onOpenInSafariTapped()
    func onLinkActivated(url: URL)
}
