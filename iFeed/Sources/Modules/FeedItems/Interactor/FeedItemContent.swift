//
//  FeedItemContent.swift
//  iFeed
//
//  Created by Evgeny Karkan on 11.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData

/// Stores a feed item's HTML body separately from its list metadata.
///
/// One-to-one child of ``FeedItem``. Kept out of the `FeedItem` row so that
/// list fetches and deduplication never pay the memory cost of article HTML;
/// the body is faulted in only when ``FeedItem/htmlContent`` is accessed
/// (e.g. when opening the article reader).
@objc(FeedItemContent)
final class FeedItemContent: NSManagedObject {

    @NSManaged var htmlContent: String?

    /// Relationship
    @NSManaged var item: FeedItem?
}
