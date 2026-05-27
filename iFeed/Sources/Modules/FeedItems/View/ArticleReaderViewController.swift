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
    private let articleTitle: String
    private let htmlContent: String
    private let articleURL: URL?
    private static let readerThemeKey = "ArticleReaderDarkMode"
    private var isDarkMode: Bool

    private var navBarHidden = false

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        return webView
    }()

    // MARK: - Init
    init(title: String, htmlContent: String, articleURL: URL?) {
        self.articleTitle = title
        self.htmlContent = htmlContent
        self.articleURL = articleURL

        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.readerThemeKey) != nil {
            self.isDarkMode = defaults.bool(forKey: Self.readerThemeKey)
        } else {
            self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let readerBackground: UIColor = isDarkMode ? .black : .white
        view.backgroundColor = readerBackground
        navigationItem.title = articleTitle

        let buttonSize: CGFloat = 28

        let themeButton = UIButton(type: .system)
        themeButton.setImage(UIImage(systemName: themeIconName), for: .normal)
        themeButton.addTarget(self, action: #selector(toggleThemeTapped), for: .touchUpInside)
        themeButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true

        let stack = UIStackView(arrangedSubviews: [themeButton])
        stack.axis = .horizontal
        stack.spacing = 10

        if articleURL != nil {
            let safariButton = UIButton(type: .system)
            safariButton.setImage(UIImage(systemName: "safari"), for: .normal)
            safariButton.addTarget(self, action: #selector(openInSafariTapped), for: .touchUpInside)
            safariButton.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
            stack.insertArrangedSubview(safariButton, at: 0)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stack)

        webView.isOpaque = false
        webView.backgroundColor = readerBackground
        webView.scrollView.backgroundColor = readerBackground
        webView.scrollView.indicatorStyle = isDarkMode ? .white : .default

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let fullHTML = ReaderHTMLTemplate.wrapInReaderTemplate(htmlContent, isDarkMode: isDarkMode)
        webView.loadHTMLString(fullHTML, baseURL: articleURL)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
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

    private func setNavBarHidden(_ hidden: Bool) {
        guard hidden != navBarHidden else { return }
        navBarHidden = hidden
        navigationController?.setNavigationBarHidden(hidden, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension ArticleReaderViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

// MARK: - Private
private extension ArticleReaderViewController {

    var themeIconName: String {
        isDarkMode ? "sun.max" : "moon"
    }

    @objc func toggleThemeTapped() {
        isDarkMode.toggle()

        UserDefaults.standard.set(isDarkMode, forKey: Self.readerThemeKey)

        let readerBackground: UIColor = isDarkMode ? .black : .white

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.view.backgroundColor = readerBackground
            self.webView.backgroundColor = readerBackground
            self.webView.scrollView.backgroundColor = readerBackground
            self.webView.scrollView.indicatorStyle = self.isDarkMode ? .white : .black
        }

        let theme = isDarkMode ? "dark" : "light"
        let js = "document.documentElement.setAttribute('data-theme', '\(theme)');"
        webView.evaluateJavaScript(js)

        if let stack = navigationItem.rightBarButtonItem?.customView as? UIStackView,
           let themeButton = stack.arrangedSubviews.last as? UIButton {
            UIView.transition(with: themeButton, duration: 0.3, options: .transitionCrossDissolve) {
                themeButton.setImage(UIImage(systemName: self.themeIconName), for: .normal)
            }
        }
    }

    @objc func openInSafariTapped() {
        guard let articleURL else {
            return
        }
        UIApplication.shared.open(articleURL)
    }
}
