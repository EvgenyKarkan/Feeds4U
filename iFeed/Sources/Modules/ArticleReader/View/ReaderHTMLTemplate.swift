//
//  ReaderHTMLTemplate.swift
//  iFeed
//
//  Created by Evgeny Karkan on 28.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

enum ReaderHTMLTemplate {

    // swiftlint:disable line_length
    static let readerCSS = """
    :root {
        color-scheme: light dark;
        --label: rgba(0, 0, 0, 1.0);
        --secondary-label: rgba(60, 60, 67, 0.6);
        --tertiary-label: rgba(60, 60, 67, 0.3);
        --bg: #ffffff;
        --secondary-bg: rgba(118, 118, 128, 0.12);
        --grouped-bg: #f2f2f7;
        --separator: rgba(60, 60, 67, 0.29);
        --opaque-separator: rgba(198, 198, 200, 1.0);
        --accent: #007aff;
        --fill: rgba(120, 120, 128, 0.2);
        --secondary-fill: rgba(120, 120, 128, 0.16);
    }
    @media (prefers-color-scheme: dark) {
        :root {
            --label: rgba(255, 255, 255, 1.0);
            --secondary-label: rgba(235, 235, 245, 0.6);
            --tertiary-label: rgba(235, 235, 245, 0.3);
            --bg: #000000;
            --secondary-bg: rgba(118, 118, 128, 0.24);
            --grouped-bg: #1c1c1e;
            --separator: rgba(84, 84, 88, 0.6);
            --opaque-separator: rgba(56, 56, 58, 1.0);
            --accent: #0a84ff;
            --fill: rgba(120, 120, 128, 0.36);
            --secondary-fill: rgba(120, 120, 128, 0.32);
        }
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
        font: -apple-system-body;
        color: var(--label);
        background-color: var(--bg);
        padding: 20px 16px 64px;
        -webkit-text-size-adjust: 100%;
        -webkit-font-smoothing: antialiased;
        word-wrap: break-word;
        overflow-wrap: break-word;
        -webkit-overflow-scrolling: touch;
        transition: background-color 0.3s ease-in-out, color 0.3s ease-in-out;
    }
    body, h1, h2, h3, h4, h5, h6, p, a, figcaption, blockquote, code, pre, th, td, hr {
        transition: background-color 0.3s ease-in-out, border-color 0.3s ease-in-out, color 0.3s ease-in-out;
    }
    p {
        line-height: 1.75;
        margin: 0 0 1.1em;
        letter-spacing: -0.003em;
    }
    a {
        color: var(--accent);
        text-decoration: none;
        -webkit-tap-highlight-color: rgba(0, 122, 255, 0.15);
    }
    a:active { opacity: 0.6; }
    h1, h2, h3, h4, h5, h6 {
        color: var(--label);
        font-weight: 700;
        letter-spacing: -0.022em;
        line-height: 1.2;
        margin: 1.6em 0 0.5em;
    }
    h1 { font-size: 1.65em; letter-spacing: -0.028em; font-weight: 800; }
    h2 { font-size: 1.35em; }
    h3 { font-size: 1.15em; }
    h4 { font-size: 1.0em; font-weight: 600; }
    h1:first-child, h2:first-child, h3:first-child { margin-top: 0; }
    strong, b { font-weight: 600; }
    em, i { font-style: italic; }
    img, video {
        max-width: 100%;
        height: auto;
        border-radius: 12px;
        margin: 16px 0;
        display: block;
    }
    iframe {
        max-width: 100%;
        border: none;
        border-radius: 12px;
        margin: 16px 0;
    }
    figure {
        margin: 20px 0;
        text-align: center;
    }
    figure img { margin: 0 auto; }
    figcaption {
        font: -apple-system-caption1;
        color: var(--secondary-label);
        margin-top: 8px;
        line-height: 1.4;
    }
    pre, code {
        font-family: ui-monospace, "SF Mono", SFMono-Regular, Menlo, monospace;
        font-size: 0.85em;
        -webkit-font-smoothing: auto;
    }
    code {
        background-color: var(--secondary-bg);
        border-radius: 6px;
        padding: 2px 6px;
    }
    pre {
        background-color: var(--grouped-bg);
        border-radius: 12px;
        padding: 16px;
        overflow-x: auto;
        line-height: 1.5;
        margin: 16px 0;
        border: 0.5px solid var(--opaque-separator);
    }
    pre code { padding: 0; background: none; border-radius: 0; font-size: 1em; }
    blockquote {
        border-left: 3px solid var(--accent);
        margin: 1.2em 0;
        padding: 0 0 0 16px;
        color: var(--secondary-label);
        font-style: italic;
    }
    blockquote p:last-child { margin-bottom: 0; }
    hr {
        border: none;
        height: 0.5px;
        background-color: var(--opaque-separator);
        margin: 2em 0;
    }
    table {
        border-collapse: collapse;
        width: 100%;
        max-width: 100%;
        overflow-x: auto;
        display: block;
        margin: 16px 0;
        border-radius: 10px;
    }
    td, th {
        border: 0.5px solid var(--opaque-separator);
        padding: 10px 12px;
        text-align: left;
        line-height: 1.5;
    }
    th { font-weight: 600; background: var(--grouped-bg); }
    ul, ol { padding-left: 1.5em; margin: 0 0 1em; }
    li { margin-bottom: 0.35em; line-height: 1.65; }
    li > ul, li > ol { margin-top: 0.35em; margin-bottom: 0; }
    ::selection { background: rgba(0, 122, 255, 0.2); }
    ::-webkit-scrollbar { display: none; }
    html[data-theme="light"] {
        --label: rgba(0, 0, 0, 1.0);
        --secondary-label: rgba(60, 60, 67, 0.6);
        --tertiary-label: rgba(60, 60, 67, 0.3);
        --bg: #ffffff;
        --secondary-bg: rgba(118, 118, 128, 0.12);
        --grouped-bg: #f2f2f7;
        --separator: rgba(60, 60, 67, 0.29);
        --opaque-separator: rgba(198, 198, 200, 1.0);
        --accent: #007aff;
        --fill: rgba(120, 120, 128, 0.2);
        --secondary-fill: rgba(120, 120, 128, 0.16);
        color-scheme: light;
    }
    html[data-theme="dark"] {
        --label: rgba(255, 255, 255, 1.0);
        --secondary-label: rgba(235, 235, 245, 0.6);
        --tertiary-label: rgba(235, 235, 245, 0.3);
        --bg: #000000;
        --secondary-bg: rgba(118, 118, 128, 0.24);
        --grouped-bg: #1c1c1e;
        --separator: rgba(84, 84, 88, 0.6);
        --opaque-separator: rgba(56, 56, 58, 1.0);
        --accent: #0a84ff;
        --fill: rgba(120, 120, 128, 0.36);
        --secondary-fill: rgba(120, 120, 128, 0.32);
        color-scheme: dark;
    }
    """
    // swiftlint:enable line_length

    static func wrapInReaderTemplate(_ body: String, isDarkMode: Bool) -> String {
        """
        <!DOCTYPE html>
        <html lang="en" data-theme="\(isDarkMode ? "dark" : "light")">
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=3">
            <style>
              \(readerCSS)
            </style>
          </head>
          <body>
            \(body)
          </body>
        </html>
        """
    }
}
