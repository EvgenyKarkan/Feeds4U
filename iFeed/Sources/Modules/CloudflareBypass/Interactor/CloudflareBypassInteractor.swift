//
//  CloudflareBypassInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 24.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import WebKit

@MainActor
final class CloudflareBypassInteractor: NSObject {
    // MARK: - Properties
    private var webView: WKWebView?
    private var completion: ((Result<ExploreFeedsDTO, any Error>) -> Void)?
    private var onChallengeDetected: ((WKWebView) -> Void)?
}

// MARK: - CloudflareBypassInteractorProtocol
extension CloudflareBypassInteractor: CloudflareBypassInteractorProtocol {

    func startFeedSearch(for webPage: String,
                         onChallengeDetected: @escaping (WKWebView) -> Void,
                         completion: @escaping (Result<ExploreFeedsDTO, any Error>) -> Void) {
        self.onChallengeDetected = onChallengeDetected
        self.completion = completion

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        self.webView = webView

        guard !webPage.isEmpty,
              let encoded = webPage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://feedsearch.dev/api/v1/search?url=\(encoded)") else {
            finishWith(.failure(ExploreFeedsError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)
    }

    func cancelSearch() {
        finishWith(.failure(ExploreFeedsError.cloudflareBlocked))
    }
}

// MARK: - WKNavigationDelegate
extension CloudflareBypassInteractor: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        extractHTMLAndProcess()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        finishWith(.failure(ExploreFeedsError.endpoint(error)))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        finishWith(.failure(ExploreFeedsError.endpoint(error)))
    }
}

// MARK: - Private
private extension CloudflareBypassInteractor {

    /// Tries to decode the expected feed JSON first; only when the body is not
    /// valid JSON does it fall back to Cloudflare challenge detection.
    ///
    /// Order matters: a legitimate feedsearch.dev response can contain
    /// challenge-looking keywords (e.g. a site description mentioning
    /// "Cloudflare" or a "Ray ID"), so running the keyword heuristics before
    /// attempting to decode would produce false-positive challenge screens.
    func extractHTMLAndProcess() {
        webView?.evaluateJavaScript("document.body.innerText") { [weak self] result, _ in
            guard let self else {
                return
            }

            if let text = result as? String,
               let data = text.data(using: .utf8),
               let dto = try? JSONDecoder().decode(ExploreFeedsDTO.self, from: data) {
                self.webView?.alpha = 0
                self.finishWith(.success(dto))
                return
            }

            self.detectChallengePage()
        }
    }

    /// Inspects the full document HTML for Cloudflare challenge markers.
    /// Reached only after JSON decoding has failed in ``extractHTMLAndProcess()``.
    func detectChallengePage() {
        webView?.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, _ in
            guard let self, let html = result as? String else {
                self?.finishWith(.failure(ExploreFeedsError.dataDecoding))
                return
            }

            if html.isCloudflareChallengePage {
                if let webView = self.webView {
                    self.onChallengeDetected?(webView)
                    self.onChallengeDetected = nil
                } else {
                    self.finishWith(.failure(ExploreFeedsError.cloudflareBlocked))
                }
                return
            }

            self.finishWith(.failure(ExploreFeedsError.dataDecoding))
        }
    }

    func finishWith(_ result: Result<ExploreFeedsDTO, any Error>) {
        guard let callback = completion else { return }
        completion = nil
        onChallengeDetected = nil
        cleanup()
        callback(result)
    }

    func cleanup() {
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        webView = nil
    }
}
