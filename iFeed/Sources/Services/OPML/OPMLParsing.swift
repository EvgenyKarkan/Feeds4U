//
//  OPMLParsing.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
#if DEBUG
import Mocking
#endif

/// Extracts feed URLs from an OPML subscription export.
///
/// OPML nests `<outline>` elements arbitrarily to represent folders, but this
/// app's feed list is flat — so the parser ignores grouping entirely and returns
/// every feed URL it finds at any depth, validated and de-duplicated. Abstracted
/// behind a protocol so the import flow can be unit-tested with a mock.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol OPMLParsing {
    /// Parses OPML data and returns the `xmlUrl` of every feed outline.
    ///
    /// - Parameter data: Raw bytes of an `.opml`/XML subscription export.
    /// - Returns: De-duplicated, valid feed URL strings in document order. Empty
    ///   when the data is not valid OPML or contains no usable feed outlines.
    func feedURLs(from data: Data) -> [String]
}
