# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Feeds4U (`iFeed`) is an iOS RSS/Atom/JSON Feed reader app built with UIKit and Core Data. The project uses the **Swift 6 compiler** — all generated code must be free of Swift concurrency errors and warnings. The Xcode project is at `iFeed/iFeed.xcodeproj`.

**External dependencies (SPM):** `FeedKit` (parsing), `SimpleSimilarity` (fuzzy search), `KRProgressHUD`, `KRActivityIndicatorView`, `swift-mocking` (test mocks). Pins are in `iFeed/iFeed.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Build & Test Commands

```bash
# Run all tests
xcodebuild test -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for testing
xcodebuild build-for-testing -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV"
```

Schemes: `iFeed - DEV`, `iFeed - ADHOC`, `iFeed - RELEASE`. Use `iFeed - DEV` for development and testing.

SwiftLint runs as an Xcode build phase; config is in `iFeed/.swiftlint.yml`. It disables length rules and enables `force_unwrapping` and `private_outlet`/`private_action`. Avoid force unwraps.

## Architecture

VIPER architecture with a Coordinator and DI container.

### Layer Responsibilities

- **Coordinator** (`Sources/Coordinator/Coordinator.swift`) — owns all navigation. Receives delegation callbacks from wireframes and pushes/presents view controllers. Never navigate from ViewControllers or Presenters directly.
- **ModuleFactory** (`Sources/Coordinator/ModuleFactory.swift`) — instantiates VIPER modules; used exclusively by the Coordinator.
- **DIContainer** (`Sources/DIContainer/DIContainer.swift`) — wires shared service instances using `SharedInstancesContainer`. Exposes services through narrow dependency protocols (e.g., `FeedsDependencies`, `FeedItemsDependencies`) via Interface Segregation.
- **Modules** (`Sources/Modules/`) — feature modules each containing:
  - `Protocols/` — all inter-layer communication protocols (`ViewProtocol`, `ViewDelegate`, `InteractorProtocol`, `WireframeProtocol`)
  - `Interactor/` — business logic and data entities
  - `Presenter/` — view state transformation
  - `View/` — UIViewController and UIView subclasses
  - `InputOutput/` — Builder (wires the module) and Wireframe (routes out)
- **Services** (`Sources/Services/`) — `Parser` (FeedKit wrapper), `CoreDataManager` (persistence), `Search` (SimpleSimilarity wrapper), `ExploreFeedsService` (feed discovery via WKWebView).

### Data Flow

View events → `FeedsViewDelegate` (Presenter) → `FeedsInteractorProtocol` (Interactor) → Services
Results flow back via closures/callbacks: Interactor → Presenter → `FeedsViewProtocol` (View updates itself with a `ViewState` value type).

### Core Data

`CoreDataManager` implements `StorageProtocol`. Use background contexts for heavy operations; only use `viewContext` for UI reads. The data model is in `iFeed/App/`.

## Testing & Mocks

Use the `swift-mocking` library (`import Mocking`) for all test mocks — never hand-write mock classes. Protocols are annotated with `@Mocked(compilationCondition: .debug)` in source files (wrapped in `#if DEBUG`), which auto-generates `<ProtocolName>Mock` classes at compile time.

**Adding a new mock:** annotate the protocol in its source file:
```swift
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol MyProtocol { ... }
```

**Using mocks in tests:**
```swift
import Mocking

let mock = MyProtocolMock()
mock._methodName.implementation = .returns(value)       // stub return value
mock._methodName.implementation = .invokes { args in }  // stub with closure
mock._methodName.callCount                              // verify call count
mock._methodName.lastInvocation                         // captured arguments
mock._propertyName.getter.implementation = .returns(v)  // mock property getter
```

For protocols with overloaded methods, use `@MockedMembers` on a hand-written mock class with `@MockableMethod(mockMethodName:)` to disambiguate (see `KeyedStorageProtocolMock` in `FeedsInteractorTests.swift`).

## Conventions

- All VIPER inter-layer communication goes through protocols defined in each module's `Protocols/` file.
- **Dependency injection only.** A unit (class/struct) must never create its dependencies internally — every dependency is injected through the initializer and hidden behind a protocol (see `StorageProtocol`, `ParserProtocol`, `Searchable`), so it can be mocked in tests. Wiring happens in `DIContainer`/builders.
- **One new type — one new file.** When introducing a new class or struct, create a dedicated file named after the type instead of appending it to a pre-existing file, and register the file in `project.pbxproj`. Cover the new type with its own tests.
- Navigation callbacks from wireframes to the Coordinator use `CoordinatingDelegate` protocols (e.g., `FeedsCoordinatingDelegate`).
- Always use `[weak self]` in closures crossing VIPER layer boundaries.
- Test files live in `iFeed/Tests/` mirroring the source layout, named `*Tests.swift`.
- PRs target the `develop` branch. Use short imperative commit messages.
- **Preserve existing comments during refactors.** When changing a method's signature, behaviour, or implementation, update the doc comment to match — do not delete it. Only remove a comment if the code it describes no longer exists at all.
- **STRICT: Never use force unwrap `!` anywhere** — not in source, not in tests. Use `guard let`, `if let`, nil-coalescing (`??`), or `try #require()` in tests. SwiftLint enforces `force_unwrapping`. No exceptions.
- **Swift 6 concurrency:** All code must compile without concurrency warnings. Mark types `Sendable` (or `@unchecked Sendable` when needed), use `@MainActor` for UI-bound code, avoid mutable captures in `@Sendable` closures (use `nonisolated(unsafe)` or reference-type boxes when necessary), and use `@preconcurrency import` for third-party modules that lack `Sendable` conformances.
