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

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
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

        let readerBackground: UIColor = viewState.isDarkMode ? .black : .white
        view.backgroundColor = readerBackground

        configureNavigationBarButtons(hasArticleURL: viewState.hasArticleURL)

        webView.isOpaque = false
        webView.backgroundColor = readerBackground
        webView.scrollView.backgroundColor = readerBackground
        webView.scrollView.indicatorStyle = viewState.isDarkMode ? .white : .default

        webView.loadHTMLString(viewState.fullHTML, baseURL: viewState.baseURL)
    }

    func applyThemeChange(isDarkMode: Bool) {
        let readerBackground: UIColor = isDarkMode ? .black : .white

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.view.backgroundColor = readerBackground
            self.webView.backgroundColor = readerBackground
            self.webView.scrollView.backgroundColor = readerBackground
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

    func configureNavigationBarButtons(hasArticleURL: Bool) {
        let buttonSize: CGFloat = 28

        let themeButton = UIButton(type: .system)
        themeButton.setImage(UIImage(systemName: "moon"), for: .normal)
        themeButton.addTarget(self, action: #selector(toggleThemeTapped), for: .touchUpInside)
        themeButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true

        let stack = UIStackView(arrangedSubviews: [themeButton])
        stack.axis = .horizontal
        stack.spacing = 10

        if hasArticleURL {
            let safariButton = UIButton(type: .system)
            safariButton.setImage(UIImage(systemName: "safari"), for: .normal)
            safariButton.addTarget(self, action: #selector(openInSafariTapped), for: .touchUpInside)
            safariButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
            stack.insertArrangedSubview(safariButton, at: 0)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stack)
    }

    @objc func toggleThemeTapped() {
        presenter?.onToggleThemeTapped()
    }

    @objc func openInSafariTapped() {
        presenter?.onOpenInSafariTapped()
    }

    func setNavBarHidden(_ hidden: Bool) {
        guard hidden != navBarHidden else { return }
        navBarHidden = hidden
        navigationController?.setNavigationBarHidden(hidden, animated: true)
    }
}
