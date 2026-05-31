//
//  SharedInstancesContainerTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
@testable import iFeed

@Suite("SharedInstancesContainer Tests")
struct SharedInstancesContainerTests {

    // MARK: - Factory Invocation

    @Test("shared calls factory on first access")
    func factoryCalledOnFirstAccess() {
        // Given
        let container = SharedInstancesContainer()
        var callCount = 0

        // When
        let _: String = container.shared {
            callCount += 1
            return "hello"
        }

        // Then
        #expect(callCount == 1)
    }

    @Test("shared does not call factory on subsequent accesses")
    func factoryNotCalledOnSubsequentAccess() {
        // Given
        let container = SharedInstancesContainer()
        var callCount = 0
        let factory: () -> String = {
            callCount += 1
            return "hello"
        }

        // When
        _ = container.shared(factory)
        _ = container.shared(factory)
        _ = container.shared(factory)

        // Then
        #expect(callCount == 1)
    }

    // MARK: - Singleton Behaviour

    @Test("shared returns the same instance for the same identifier")
    func returnsSameInstance() {
        // Given
        let container = SharedInstancesContainer()

        // When
        let first: NSObject = container.shared { NSObject() }
        let second: NSObject = container.shared { NSObject() }

        // Then
        #expect(first === second)
    }

    @Test("shared returns different instances for different identifiers")
    func returnsDifferentInstancesForDifferentKeys() {
        // Given
        let container = SharedInstancesContainer()

        // When
        let objectA: NSObject = container.shared(sharedIdentifier: "keyA") { NSObject() }
        let objectB: NSObject = container.shared(sharedIdentifier: "keyB") { NSObject() }

        // Then
        #expect(objectA !== objectB)
    }

    // MARK: - Scope Isolation

    @Test("different containers have independent scopes")
    func independentScopes() {
        // Given
        let container1 = SharedInstancesContainer()
        let container2 = SharedInstancesContainer()

        // When
        let obj1: NSObject = container1.shared(sharedIdentifier: "key") { NSObject() }
        let obj2: NSObject = container2.shared(sharedIdentifier: "key") { NSObject() }

        // Then
        #expect(obj1 !== obj2)
    }

    // MARK: - Value Types

    @Test("shared works with value types")
    func worksWithValueTypes() {
        // Given
        let container = SharedInstancesContainer()

        // When
        let value1: Int = container.shared(sharedIdentifier: "int") { 42 }
        let value2: Int = container.shared(sharedIdentifier: "int") { 99 }

        // Then
        #expect(value1 == 42)
        #expect(value2 == 42)
    }

    // MARK: - Storage

    @Test("sharedInstances dictionary is populated after shared call")
    func dictionaryPopulated() {
        // Given
        let container = SharedInstancesContainer()

        // When
        #expect(container.sharedInstances.isEmpty)
        let _: String = container.shared(sharedIdentifier: "greeting") { "hi" }

        // Then
        #expect(container.sharedInstances.count == 1)
        #expect(container.sharedInstances["greeting"] as? String == "hi")
    }

    // MARK: - Optional Type Coalescing (SR-8704)

    @Test("shared calls factory and returns value when T is an optional type")
    func sharedReturnsValueWhenTypeIsOptional() {
        // Given
        let container = SharedInstancesContainer()
        var callCount = 0

        // When — closure explicitly returns String? so T resolves to Optional<String>,
        // exercising the ?? nil path on the first (uncached) lookup
        let first: String? = container.shared(sharedIdentifier: "opt") { () -> String? in
            callCount += 1
            return "cached"
        }
        let second: String? = container.shared(sharedIdentifier: "opt") { () -> String? in
            callCount += 1
            return "should not be called"
        }

        // Then
        #expect(first == "cached")
        #expect(second == "cached")
        #expect(callCount == 1)
    }

    // MARK: - Thread Safety

    @Test("shared returns the same instance under concurrent access")
    func threadSafety() async {
        // Given
        let container = SharedInstancesContainer()
        let iterationCount = 1000

        // When — spawn 1000 concurrent tasks that all request the same shared key.
        // Each task races to call `shared(sharedIdentifier: "concurrent")`.
        // If the NSRecursiveLock inside `shared` works correctly, exactly one
        // task will run the factory and the rest will get the cached instance.
        let results = await withTaskGroup(of: ObjectIdentifier.self, returning: [ObjectIdentifier].self) { group in
            for _ in 0..<iterationCount {
                group.addTask {
                    // Every task asks for the same key — only the first arrival
                    // should execute the factory closure; the rest should hit
                    // the cache and return the already-created object.
                    let obj: NSObject = container.shared(sharedIdentifier: "concurrent") { NSObject() }
                    // Convert the object reference to an ObjectIdentifier (a
                    // hashable wrapper around the pointer) so we can compare
                    // identity across tasks without sending NSObject itself.
                    return ObjectIdentifier(obj)
                }
            }

            // Collect all 1000 identifiers as tasks complete.
            var ids: [ObjectIdentifier] = []
            ids.reserveCapacity(iterationCount)
            for await id in group {
                ids.append(id)
            }
            return ids
        }

        // Then — if the lock is working, every task got the exact same object,
        // so collapsing to a Set should yield exactly one unique identifier.
        // More than one means the factory ran multiple times concurrently —
        // a data race.
        let uniqueIDs = Set(results)
        #expect(uniqueIDs.count == 1)
    }
}
