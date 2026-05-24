//
//  CloudflareBypassPresenter.swift
//  iFeed
//
//  Created by Evgeny Karkan on 24.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import WebKit

@MainActor
final class CloudflareBypassPresenter {
    // MARK: - Properties
    private let wireframe: any CloudflareBypassWireframeProtocol
    private let interactor: any CloudflareBypassInteractorProtocol
    private weak var moduleOutput: (any CloudflareBypassModuleOutput)?

    private let webPage: String

    // MARK: - Init
    init(interactor: any CloudflareBypassInteractorProtocol,
         wireframe: any CloudflareBypassWireframeProtocol,
         moduleOutput: any CloudflareBypassModuleOutput,
         webPage: String) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.moduleOutput = moduleOutput
        self.webPage = webPage
    }
}

// MARK: - CloudflareBypassModuleInput
extension CloudflareBypassPresenter: CloudflareBypassModuleInput {

    func startSearch() {
        interactor.startFeedSearch(
            for: webPage,
            onChallengeDetected: { [weak self] webView in
                self?.handleChallengeDetected(with: webView)
            },
            completion: { [weak self] result in
                self?.handleSearchResult(result)
            }
        )
    }
}

// MARK: - CloudflareBypassViewDelegate
extension CloudflareBypassPresenter: CloudflareBypassViewDelegate {

    func onViewDidPressDone() {
        interactor.cancelSearch()
    }
}

// MARK: - Private
private extension CloudflareBypassPresenter {

    func handleChallengeDetected(with webView: WKWebView) {
        wireframe.presentChallenge(with: webView)
        moduleOutput?.cloudflareBypassDidPresentChallenge()
    }

    func handleSearchResult(_ result: Result<ExploreFeedsDTO, any Error>) {
        wireframe.dismissChallenge { [weak self] in
            self?.moduleOutput?.cloudflareBypassDidFinish(with: result)
        }
    }
}
