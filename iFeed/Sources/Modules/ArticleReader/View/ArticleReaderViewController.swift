//
//  ArticleReaderViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 27.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import WebKit

final class ArticleReaderViewController: UIViewController {
    // MARK: - Properties
    var presenter: (any ArticleReaderViewDelegate)?

    private var navBarHidden = false
    private weak var summaryButton: UIButton?

    /// Whether the TL;DR card has been injected into the page. Lets the streaming
    /// updates skip re-sending the (one-time) card-creation script on every snapshot.
    private var summaryCardCreated = false

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.accessibilityIdentifier = AccessibilityID.articleReaderWebView
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        return webView
    }()

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        presenter?.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presenter?.onViewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.standardAppearance = nil
        navigationItem.scrollEdgeAppearance = nil

        if isMovingFromParent || isBeingDismissed {
            webView.stopLoading()
            webView.navigationDelegate = nil
            webView.scrollView.delegate = nil
        }
    }
}

// MARK: - ArticleReaderViewProtocol
extension ArticleReaderViewController: @MainActor ArticleReaderViewProtocol {

    func configureInitialState(with viewState: ArticleReaderViewState) {
        navigationItem.title = viewState.title

        let readerBackground = readerBackground(isDarkMode: viewState.isDarkMode)
        updateNavBarAppearance(isDarkMode: viewState.isDarkMode)

        view.backgroundColor = readerBackground

        configureNavigationBarButtons(hasArticleURL: viewState.hasArticleURL,
                                      canSummarize: viewState.isSummarizationAvailable)

        webView.isOpaque = false
        webView.backgroundColor = readerBackground
        webView.scrollView.backgroundColor = readerBackground
        webView.scrollView.indicatorStyle = viewState.isDarkMode ? .white : .default

        webView.loadHTMLString(viewState.fullHTML, baseURL: viewState.baseURL)
    }

    func applyThemeChange(isDarkMode: Bool) {
        let background = readerBackground(isDarkMode: isDarkMode)
        updateNavBarAppearance(isDarkMode: isDarkMode)

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.view.backgroundColor = background
            self.webView.backgroundColor = background
            self.webView.scrollView.backgroundColor = background
            self.webView.scrollView.indicatorStyle = isDarkMode ? .white : .black
        }

        let theme = isDarkMode ? "dark" : "light"
        let script = "document.documentElement.setAttribute('data-theme', '\(theme)');"
        webView.evaluateJavaScript(script)

        let iconName = isDarkMode ? "sun.max" : "moon"
        if let stack = navigationItem.rightBarButtonItem?.customView as? UIStackView,
           let themeButton = stack.arrangedSubviews.last as? UIButton {
            UIView.transition(with: themeButton, duration: 0.3, options: .transitionCrossDissolve) {
                themeButton.setImage(UIImage(systemName: iconName), for: .normal)
            }
        }
    }

    func setSummaryLoading(_ isLoading: Bool) {
        summaryButton?.isEnabled = !isLoading
        // Show the card immediately with a "Summarizing…" placeholder instead of a
        // blocking spinner, so the tap feels instant; the real text overwrites the
        // placeholder when the first token arrives. Nothing to do on `false` — the
        // first `renderSummary`/`showSummaryError` takes over.
        if isLoading {
            showSummaryPlaceholder()
        }
    }

    func renderSummary(_ summary: ArticleSummary) {
        // The card is created once; each streamed snapshot then ships only the two
        // text-node writes (not the whole creation script), keeping the per-snapshot
        // bridge payload minimal. Updating `textContent`/`innerHTML` in place (rather
        // than swapping the node) avoids flicker without a DOM rebuild.
        ensureSummaryCard()

        let summaryText = escapedForJavaScript(summary.summary)
        let pointsHTML = escapedForJavaScript(keyPointsHTML(summary.keyPoints))

        let script = """
        (function() {
            if (window.iFeedTLDRPulse) { window.iFeedTLDRPulse.cancel(); window.iFeedTLDRPulse = null; }
            var sum = document.getElementById('ifeed-tldr-sum');
            if (sum) { sum.textContent = "\(summaryText)"; }
            var pts = document.getElementById('ifeed-tldr-pts');
            if (pts) { pts.innerHTML = "\(pointsHTML)"; }
        })();
        """
        webView.evaluateJavaScript(script)
    }

    func showSummaryError() {
        // Tear down the placeholder card (and stop its pulse) — there is no summary
        // to show — before surfacing the alert.
        webView.evaluateJavaScript("""
        (function() {
            if (window.iFeedTLDRPulse) { window.iFeedTLDRPulse.cancel(); window.iFeedTLDRPulse = null; }
            var card = document.getElementById('ifeed-tldr');
            if (card) { card.remove(); }
        })();
        """)
        summaryCardCreated = false

        let alert = UIAlertController(
            title: String.localized(key: LocalizableKeys.ArticleReader.summaryFailedTitle),
            message: String.localized(key: LocalizableKeys.ArticleReader.summaryFailedMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String.localized(key: LocalizableKeys.cancel), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ArticleReaderViewController: UIScrollViewDelegate {

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top

        if atTop {
            setNavBarHidden(false)
        } else if velocity.y > 0.3 {
            setNavBarHidden(true)
        } else if velocity.y < -0.3 {
            setNavBarHidden(false)
        }
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        setNavBarHidden(false)
        return true
    }
}

// MARK: - WKNavigationDelegate
extension ArticleReaderViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            presenter?.onLinkActivated(url: url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

// MARK: - Private
private extension ArticleReaderViewController {

    func readerBackground(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? .black : .white
    }

    func updateNavBarAppearance(isDarkMode: Bool) {
        let titleColor: UIColor = isDarkMode ? .white : .black
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }

    /// Builds the trailing nav-bar buttons. The theme toggle is kept **last** in
    /// the stack because ``applyThemeChange(isDarkMode:)`` swaps the icon on the
    /// stack's final arranged subview.
    func configureNavigationBarButtons(hasArticleURL: Bool, canSummarize: Bool) {
        let buttonSize: CGFloat = 28

        let themeButton = UIButton(type: .system)
        themeButton.setImage(UIImage(systemName: "moon"), for: .normal)
        themeButton.addTarget(self, action: #selector(toggleThemeTapped), for: .touchUpInside)
        themeButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        themeButton.accessibilityLabel = String.localized(key: LocalizableKeys.Accessibility.readingTheme)

        let stack = UIStackView(arrangedSubviews: [themeButton])
        stack.axis = .horizontal
        stack.spacing = 10

        if hasArticleURL {
            let safariButton = UIButton(type: .system)
            safariButton.setImage(UIImage(systemName: "safari"), for: .normal)
            safariButton.addTarget(self, action: #selector(openInSafariTapped), for: .touchUpInside)
            safariButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
            safariButton.accessibilityLabel = String.localized(key: LocalizableKeys.Accessibility.openInSafari)
            stack.insertArrangedSubview(safariButton, at: 0)
        }

        if canSummarize {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "sparkles"), for: .normal)
            button.addTarget(self, action: #selector(summarizeTapped), for: .touchUpInside)
            button.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
            button.accessibilityLabel = String.localized(key: LocalizableKeys.Accessibility.summarize)
            button.accessibilityIdentifier = AccessibilityID.articleReaderSummaryButton
            stack.insertArrangedSubview(button, at: 0)
            summaryButton = button
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stack)
    }

    @objc func toggleThemeTapped() {
        presenter?.onToggleThemeTapped()
    }

    @objc func openInSafariTapped() {
        presenter?.onOpenInSafariTapped()
    }

    @objc func summarizeTapped() {
        presenter?.onSummarizeTapped()
    }

    func setNavBarHidden(_ hidden: Bool) {
        guard hidden != navBarHidden else { return }
        navBarHidden = hidden
        navigationController?.setNavigationBarHidden(hidden, animated: true)
    }

    /// Builds the inner markup for the key-points block (heading + list), or an
    /// empty string when there are no points yet. Model text is HTML-escaped to
    /// keep the page well-formed. Returned as a fragment so it can be assigned to
    /// the points container's `innerHTML` in place, without rebuilding the card.
    func keyPointsHTML(_ keyPoints: [String]) -> String {
        guard !keyPoints.isEmpty else {
            return ""
        }
        let keyPointsTitle = String.localized(key: LocalizableKeys.ArticleReader.keyPointsTitle)
        let items = keyPoints
            .map { "<li>\(htmlEscaped($0))</li>" }
            .joined()
        return """
        <p style="font-weight:600;margin:12px 0 6px;">\(htmlEscaped(keyPointsTitle))</p>
        <ul style="margin:0;padding-left:1.2em;">\(items)</ul>
        """
    }

    /// Shows the summary card immediately with a pulsing "Summarizing…"
    /// placeholder, so tapping feels instant instead of staring at a blocking
    /// spinner while the model prefills. The pulse is a lightweight composited
    /// opacity animation (Web Animations API), cancelled once real text arrives.
    func showSummaryPlaceholder() {
        ensureSummaryCard()

        let placeholder = escapedForJavaScript(String.localized(key: LocalizableKeys.ArticleReader.summarizing))
        let script = """
        (function() {
            var sum = document.getElementById('ifeed-tldr-sum');
            if (sum) {
                sum.textContent = "\(placeholder)";
                if (window.iFeedTLDRPulse) { window.iFeedTLDRPulse.cancel(); }
                window.iFeedTLDRPulse = sum.animate(
                    [{ opacity: 0.4 }, { opacity: 1 }],
                    { duration: 850, iterations: Infinity, direction: 'alternate', easing: 'ease-in-out' }
                );
            }
        })();
        """
        webView.evaluateJavaScript(script)
    }

    /// Injects the TL;DR card once. Subsequent placeholder/summary updates only
    /// touch its text nodes, so the one-time creation script never rides along on
    /// the streaming hot path.
    func ensureSummaryCard() {
        guard !summaryCardCreated else {
            return
        }
        summaryCardCreated = true
        let headText = escapedForJavaScript("✨ " + String.localized(key: LocalizableKeys.ArticleReader.summaryTitle))
        webView.evaluateJavaScript("(function() { \(summaryCardCreationJS(headText: headText)) })();")
    }

    /// JS fragment that creates the TL;DR card (with its head text) if it isn't
    /// already on the page.
    func summaryCardCreationJS(headText: String) -> String {
        return """
        var card = document.getElementById('ifeed-tldr');
        if (!card) {
            card = document.createElement('div');
            card.id = 'ifeed-tldr';
            // Start collapsed and grow to content height so the article below slides
            // down smoothly instead of snapping when the card is inserted at the top.
            card.style.cssText = 'background-color:var(--secondary-bg);border-left:4px solid var(--accent);'
                + 'border-radius:0 12px 12px 0;padding:16px 18px;margin:0 0 24px;'
                + 'overflow:hidden;max-height:0;opacity:0;transition:max-height .28s ease, opacity .28s ease;';
            card.innerHTML = '<p id="ifeed-tldr-head" style="font-weight:800;letter-spacing:-0.02em;margin:0 0 8px;"></p>'
                + '<p id="ifeed-tldr-sum" style="margin:0;"></p>'
                + '<div id="ifeed-tldr-pts"></div>';
            document.body.insertBefore(card, document.body.firstChild);
            document.getElementById('ifeed-tldr-head').textContent = "\(headText)";
            // Once expanded, drop the clamp so later streamed text isn't clipped.
            var release = function() { card.style.maxHeight = 'none'; card.style.overflow = 'visible'; };
            card.addEventListener('transitionend', function te(e) {
                if (e.propertyName === 'max-height') { release(); card.removeEventListener('transitionend', te); }
            });
            setTimeout(release, 400);
            requestAnimationFrame(function() {
                card.style.maxHeight = card.scrollHeight + 'px';
                card.style.opacity = '1';
                // Reveal the card if the reader was scrolled down into the article.
                if (window.pageYOffset > 4) {
                    card.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            });
        }
        """
    }

    /// Escapes the five HTML metacharacters so model output cannot break the page.
    func htmlEscaped(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    /// Escapes a string for embedding inside a double-quoted JavaScript literal.
    func escapedForJavaScript(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}
