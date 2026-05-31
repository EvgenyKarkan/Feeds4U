//
//  ArticleReaderProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Mocking

/// Presenter ---> Wireframe
@Mocked(compilationCondition: .debug)
protocol ArticleReaderWireframeProtocol: AnyObject {
    func openInSafari(url: URL)
}

/// Presenter ---> Interactor
@Mocked(compilationCondition: .debug)
protocol ArticleReaderInteractorProtocol: AnyObject {
    var articleTitle: String { get }
    var htmlContent: String { get }
    var articleURL: URL? { get }
    var isDarkMode: Bool { get }
    func toggleDarkMode()
    func persistThemePreference()
}

/// Presenter ---> View
@Mocked(compilationCondition: .debug)
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

/// Defines dependencies of current module
protocol ArticleReaderDependencies: AnyObject {
    func keyedStorage() -> any KeyedStorageProtocol
}
