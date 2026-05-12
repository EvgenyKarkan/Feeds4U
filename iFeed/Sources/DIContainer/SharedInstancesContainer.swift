//
//  SharedInstancesContainer.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Provides base functionality for storing shared instances in own scope.
nonisolated open class SharedInstancesContainer: @unchecked Sendable {
    // MARK: - Properties
    private let sharedInstanceLock = NSRecursiveLock()
    private(set) var sharedInstances: [String: Any] = [:]

    // MARK: - Init
    init() {}

    // MARK: - Deinit
    nonisolated deinit {}

    // MARK: - Public APIs

    /// Share the enclosed object as a singleton at this scope. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads
    /// as it may cause a deadlock.
    ///
    /// - parameters:
    ///  - sharedIdentifier:
    ///   A unique identifier of a shared dependency in scope of the current container (by default it uses caller function name).
    ///   **It's assumed to NOT be used by a developer directly.**
    ///
    ///  - factory: The closure to construct the dependency object.
    ///
    /// - returns: The dependency object instance.
    final func shared<T>(sharedIdentifier: String = #function, _ factory: () -> T) -> T {
        // Use function name as the key, since this is unique per component
        // class. At the same time, this is also 150 times faster than
        // interpolating the type to convert to string, `"\(T.self)"`.
        sharedInstanceLock.lock()

        defer {
            sharedInstanceLock.unlock()
        }

        // Additional nil coalescing is needed to mitigate a Swift bug appearing
        // in Xcode 10. see https://bugs.swift.org/browse/SR-8704. Without this
        // measure, calling `shared` from a function that returns an optional type
        // will always pass the check below and return nil if the instance is not
        // initialized.
        if let instance = (sharedInstances[sharedIdentifier] as? T?) ?? nil {
            return instance
        }

        let instance = factory()
        sharedInstances[sharedIdentifier] = instance

        return instance
    }
}
