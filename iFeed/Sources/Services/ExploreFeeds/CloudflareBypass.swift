//
//  CloudflareBypass.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import WebKit

@MainActor
final class CloudflareBypass: NSObject {

    // MARK: - Properties

    private var webView: WKWebView?
    private var completion: ((Result<ExploreFeedsDTO, any Error>) -> Void)?
    private var onChallengePresented: (() -> Void)?
    private weak var presentingViewController: UIViewController?
    private var webPage = ""
    private var challengeNavController: UINavigationController?

    // MARK: - API

    func searchFeeds(for webPage: String,
                     from viewController: UIViewController,
                     onChallengePresented: (() -> Void)? = nil,
                     completion: @escaping (Result<ExploreFeedsDTO, any Error>) -> Void) {
        self.webPage = webPage
        self.presentingViewController = viewController
        self.onChallengePresented = onChallengePresented
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
}

// MARK: - WKNavigationDelegate

extension CloudflareBypass: WKNavigationDelegate {

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

private extension CloudflareBypass {

    func extractHTMLAndProcess() {
        webView?.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, _ in
            guard let self, let html = result as? String else {
                self?.finishWith(.failure(ExploreFeedsError.dataDecoding))
                return
            }

            if html.isCloudflareChallengePage {
                self.showChallenge()
                return
            }

            webView?.alpha = 0
            self.parseJSONFromWebView()
        }
    }

    func parseJSONFromWebView() {
        webView?.evaluateJavaScript("document.body.innerText") { [weak self] result, _ in
            guard let self, let text = result as? String,
                  let data = text.data(using: .utf8) else {
                self?.finishWith(.failure(ExploreFeedsError.dataDecoding))
                return
            }

            do {
                let dto = try JSONDecoder().decode(ExploreFeedsDTO.self, from: data)
                self.finishWith(.success(dto))
            } catch {
                self.finishWith(.failure(ExploreFeedsError.dataDecoding))
            }
        }
    }

    func showChallenge() {
        guard let webView, let presenter = presentingViewController else {
            finishWith(.failure(ExploreFeedsError.cloudflareBlocked))
            return
        }

        let challengeVC = UIViewController()
        challengeVC.view.backgroundColor = .systemBackground
        challengeVC.navigationItem.title = "Verify you are human"
        challengeVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(challengeCancelled)
        )

        webView.translatesAutoresizingMaskIntoConstraints = false
        challengeVC.view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: challengeVC.view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: challengeVC.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: challengeVC.view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: challengeVC.view.bottomAnchor)
        ])

        let nav = UINavigationController(rootViewController: challengeVC)
        nav.modalPresentationStyle = .fullScreen
        challengeNavController = nav

        onChallengePresented?()
        onChallengePresented = nil
        presenter.present(nav, animated: true)
    }

    @objc func challengeCancelled() {
        finishWith(.failure(ExploreFeedsError.cloudflareBlocked))
    }

    func finishWith(_ result: Result<ExploreFeedsDTO, any Error>) {
        guard let callback = completion else { return }
        completion = nil

        if let nav = challengeNavController {
            challengeNavController = nil
            nav.dismiss(animated: true) { [weak self] in
                self?.cleanup()
                callback(result)
            }
        } else {
            cleanup()
            callback(result)
        }
    }

    func cleanup() {
        webView?.navigationDelegate = nil
        webView = nil
    }
}
