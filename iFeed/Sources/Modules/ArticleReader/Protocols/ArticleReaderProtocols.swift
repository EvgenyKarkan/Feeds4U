//
//  ArticleReaderProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
#if DEBUG
import Mocking
#endif

/// Presenter ---> Wireframe
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ArticleReaderWireframeProtocol: AnyObject {
    func openInSafari(url: URL)
}

/// Presenter ---> Interactor
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ArticleReaderInteractorProtocol: AnyObject {
    var articleTitle: String { get }
    var htmlContent: String { get }
    var articleURL: URL? { get }
    var isDarkMode: Bool { get }
    func toggleDarkMode()
    func persistThemePreference()
}

/// Presenter ---> View
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
@MainActor
protocol ArticleReaderViewProtocol: AnyObject {
    func configureInitialState(with viewState: ArticleReaderViewState)
    func applyThemeChange(isDarkMode: Bool)
}

/// View ---> Presenter
@MainActor
protocol ArticleReaderViewDelegate: AnyObject {
    func onViewDidLoad()
    func onViewWillAppear()
    func onToggleThemeTapped()
    func onOpenInSafariTapped()
    func onLinkActivated(url: URL)
}

/// Defines dependencies of current module
@MainActor
protocol ArticleReaderDependencies: AnyObject {
    func keyedStorage() -> any KeyedStorageProtocol
}
