//
//  CloudflareBypassPresenterTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
import Mocking
import WebKit
@testable import iFeed

@Suite("CloudflareBypass Presenter Tests")
@MainActor
struct CloudflareBypassPresenterTests {

    private let interactor = CloudflareBypassInteractorProtocolMock()
    private let wireframe = CloudflareBypassWireframeProtocolMock()
    private let output = CloudflareBypassModuleOutputMock()
    private let webPage = "https://example.com"

    private func makeSUT() -> CloudflareBypassPresenter {
        CloudflareBypassPresenter(interactor: interactor, wireframe: wireframe,
                                  moduleOutput: output, webPage: webPage)
    }

    // MARK: - startSearch

    @Test func startSearch_startsInteractorSearchForTheWebPage() {
        // Given
        let sut = makeSUT()

        // When
        sut.startSearch()

        // Then
        #expect(interactor._startFeedSearch.callCount == 1)
        #expect(interactor._startFeedSearch.lastInvocation?.0 == webPage)
    }

    @Test func startSearch_onChallengeDetected_presentsChallengeAndNotifiesOutput() {
        // Given — the interactor reports a Cloudflare challenge.
        let webView = WKWebView()
        interactor._startFeedSearch.implementation = .uncheckedInvokes { _, onChallenge, _ in
            onChallenge(webView)
        }
        let sut = makeSUT()

        // When
        sut.startSearch()

        // Then — the challenge surfaces and the parent is told once.
        #expect(wireframe._presentChallenge.callCount == 1)
        #expect(output._cloudflareBypassDidPresentChallenge.callCount == 1)
    }

    @Test func startSearch_onResult_dismissesChallengeThenNotifiesFinish() {
        // Given — the interactor finishes; the wireframe runs its dismissal completion.
        interactor._startFeedSearch.implementation = .uncheckedInvokes { _, _, completion in
            completion(.success([]))
        }
        wireframe._dismissChallenge.implementation = .uncheckedInvokes { completion in
            completion?()
        }
        let sut = makeSUT()

        // When
        sut.startSearch()

        // Then — finish is delivered only after dismissal.
        #expect(wireframe._dismissChallenge.callCount == 1)
        #expect(output._cloudflareBypassDidFinish.callCount == 1)
    }

    // MARK: - onViewDidPressDone

    @Test func onViewDidPressDone_cancelsSearchAndNotifiesCancel() {
        // Given
        let sut = makeSUT()

        // When — the user dismisses the verification screen.
        sut.onViewDidPressDone()

        // Then
        #expect(interactor._cancelSearch.callCount == 1)
        #expect(output._cloudflareBypassDidCancel.callCount == 1)
    }
}
