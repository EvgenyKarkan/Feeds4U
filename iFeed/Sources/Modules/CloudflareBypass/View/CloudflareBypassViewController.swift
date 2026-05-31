//
//  CloudflareBypassViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 24.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit
import WebKit

final class CloudflareBypassViewController: UIViewController {
    // MARK: - Properties
    weak var presenter: (any CloudflareBypassViewDelegate)?

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Verify you are human"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(donePressed)
        )
    }

    // MARK: - Action
    @objc private func donePressed() {
        presenter?.onViewDidPressDone()
    }
}

// MARK: - CloudflareBypassViewProtocol
extension CloudflareBypassViewController: CloudflareBypassViewProtocol {

    func configureWithWebView(_ webView: WKWebView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
