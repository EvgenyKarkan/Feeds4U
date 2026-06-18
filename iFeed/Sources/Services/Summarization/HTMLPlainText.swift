//
//  HTMLPlainText.swift
//  iFeed
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Converts feed HTML into compact plain text suitable as a language-model
/// prompt.
///
/// Feeding raw markup to the model would waste the (small) on-device context
/// window on tags and inflate latency, so the article body is reduced to its
/// readable text before summarization. This is intentionally lightweight — a
/// best-effort strip, not a full HTML parser — because the model tolerates minor
/// noise. The caller runs it off the main actor so the regex passes never hitch
/// the UI.
enum HTMLPlainText {

    /// How much raw HTML to keep per output character before stripping. Tags
    /// inflate the source well beyond the readable text, so a 4× window over the
    /// requested `maxLength` comfortably yields enough plain text after stripping
    /// while keeping the regex passes off the *entire* (possibly huge) document.
    private static let rawCharactersPerOutputCharacter = 4

    /// Compiled once and reused — `replacingOccurrences(options: .regularExpression)`
    /// recompiles the pattern on every call, which is needless here.
    private static let scriptStyleRegex = try? NSRegularExpression(
        pattern: "<(script|style)[^>]*>[\\s\\S]*?</\\1>", options: [.caseInsensitive])
    private static let tagRegex = try? NSRegularExpression(pattern: "<[^>]+>")
    private static let whitespaceRegex = try? NSRegularExpression(pattern: "\\s+")

    /// Strips markup from `html` and returns collapsed plain text.
    ///
    /// - Parameters:
    ///   - html: The raw article HTML.
    ///   - maxLength: Upper bound on the returned character count; the text is
    ///     truncated to bound the model's input size. Defaults to no limit.
    /// - Returns: Whitespace-collapsed, tag-free text (possibly empty).
    static func extract(from html: String, maxLength: Int = .max) -> String {
        // Clip the raw HTML up front so the regex passes scan a bounded window
        // rather than the whole document, which is then thrown away by the final
        // truncation anyway.
        var text = clippedRawHTML(html, maxLength: maxLength)

        // Drop <script>/<style> bodies first so their contents don't leak into
        // the text once their tags are removed, then remove the remaining tags.
        text = replacingMatches(scriptStyleRegex, in: text, with: " ")
        text = replacingMatches(tagRegex, in: text, with: " ")

        // Decode the handful of entities common in feed content.
        let entities = ["&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
                        "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&mdash;": "—", "&ndash;": "–"]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        // Collapse runs of whitespace into single spaces and trim the edges.
        text = replacingMatches(whitespaceRegex, in: text, with: " ")
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.count > maxLength {
            text = String(text.prefix(maxLength))
        }
        return text
    }

    // MARK: - Private

    private static func clippedRawHTML(_ html: String, maxLength: Int) -> String {
        guard maxLength != .max else {
            return html
        }
        let (cap, overflow) = maxLength.multipliedReportingOverflow(by: rawCharactersPerOutputCharacter)
        guard !overflow, html.count > cap else {
            return html
        }
        return String(html.prefix(cap))
    }

    private static func replacingMatches(_ regex: NSRegularExpression?,
                                         in string: String,
                                         with template: String) -> String {
        guard let regex else {
            return string
        }
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
    }
}
