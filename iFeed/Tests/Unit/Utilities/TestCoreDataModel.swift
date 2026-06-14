//
//  TestCoreDataModel.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 06.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import CoreData
@testable import iFeed

/// Provides a single, process-wide `NSManagedObjectModel` for all test suites that create
/// in-memory Core Data containers.
///
/// **Why this exists:**
/// When multiple test suites each load their own `NSManagedObjectModel` (even from the same
/// `.momd` file), Core Data treats the resulting entity descriptions as distinct types.
/// Assigning a managed object created under one model instance to a relationship defined by
/// another triggers a runtime crash:
/// `"Unacceptable type of value for to-one relationship: desired type = Feed; given type = Feed"`.
///
/// Because the Swift Testing framework runs test suites in parallel by default, this
/// cross-model conflict surfaces reliably when suites like `SearchTests`,
/// `FeedsInteractorTests`, `FeedsViewStateTests`, and `CoreDataManagerTests` each spin
/// up their own containers concurrently.
///
/// Sharing a single `NSManagedObjectModel` instance guarantees that every
/// `NSPersistentContainer` in the test target uses the same entity descriptions,
/// eliminating the crash.
enum TestCoreDataModel {

    static let shared: NSManagedObjectModel = {
        guard let modelURL = Bundle(for: Feed.self).url(forResource: "iFeed", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model")
        }
        return model
    }()
}
