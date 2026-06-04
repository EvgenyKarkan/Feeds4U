//
//  CloudflareBypassProtocols.swift
//  iFeed
//
//  Created by Evgeny Karkan on 24.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import WebKit

/// Presenter ---> Wireframe
@MainActor
protocol CloudflareBypassWireframeProtocol: AnyObject {
    func presentChallenge(with webView: WKWebView)
    func dismissChallenge(completion: (() -> Void)?)
}

/// Presenter ---> Interactor
@MainActor
protocol CloudflareBypassInteractorProtocol: AnyObject {
    func startFeedSearch(for webPage: String,
                         onChallengeDetected: @escaping (WKWebView) -> Void,
                         completion: @escaping (Result<ExploreFeedsDTO, any Error>) -> Void)
    func cancelSearch()
}

/// Presenter ---> View
@MainActor
protocol CloudflareBypassViewProtocol: AnyObject {
    func configureWithWebView(_ webView: WKWebView)
}

/// View ---> Presenter
@MainActor
protocol CloudflareBypassViewDelegate: AnyObject {
    func onViewDidPressDone()
}

/// Module input (parent ---> CloudflareBypass module)
@MainActor
protocol CloudflareBypassModuleInput: AnyObject {
    func startSearch()
}

/// Module output (CloudflareBypass module ---> parent)
@MainActor
protocol CloudflareBypassModuleOutput: AnyObject {
    func cloudflareBypassDidPresentChallenge()
    func cloudflareBypassDidFinish(with result: Result<ExploreFeedsDTO, any Error>)
    func cloudflareBypassDidCancel()
}
