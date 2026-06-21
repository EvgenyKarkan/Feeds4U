//
//  OPMLParser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Parses OPML subscription exports with Foundation's `XMLParser`.
///
/// Only the `xmlUrl` attribute of an `<outline>` is of interest — that is the
/// feed endpoint. Folder outlines (which have no `xmlUrl`) are walked into but
/// not recorded, because the app's feed list is flat. URLs are validated with
/// ``Swift/String/isValidURL`` and de-duplicated, so a malformed or repetitive
/// file can never inject garbage or the same feed twice.
struct OPMLParser: OPMLParsing {

    func feedURLs(from data: Data) -> [String] {
        let collector = OutlineURLCollector()
        let parser = XMLParser(data: data)
        parser.delegate = collector
        parser.parse()
        return collector.urls
    }
}

/// `XMLParser` delegate that accumulates valid, unique feed URLs as the document
/// is streamed. Kept private to ``OPMLParser`` — it exists only to bridge the
/// `NSObject`-based delegate API into a value-type result.
private final class OutlineURLCollector: NSObject, XMLParserDelegate {

    private(set) var urls: [String] = []
    private var seen: Set<String> = []

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        guard elementName.lowercased() == "outline" else {
            return
        }

        /// The OPML spec spells the attribute `xmlUrl`, but real-world exporters
        /// vary the casing — match case-insensitively so those files still import.
        let rawURL = attributeDict.first { $0.key.lowercased() == "xmlurl" }?.value

        guard let candidate = rawURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !candidate.isEmpty,
              candidate.isValidURL,
              seen.insert(candidate).inserted else {
            return
        }

        urls.append(candidate)
    }
}
