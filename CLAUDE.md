# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Feeds4U (`iFeed`) is an iOS RSS/Atom/JSON Feed reader app built with UIKit and Core Data. The Xcode project is at `iFeed/iFeed.xcodeproj`.

**External dependencies (SPM):** `FeedKit` (parsing), `SimpleSimilarity` (fuzzy search), `KRProgressHUD`, `KRActivityIndicatorView`. Pins are in `iFeed/iFeed.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

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

## Conventions

- All VIPER inter-layer communication goes through protocols defined in each module's `Protocols/` file.
- Navigation callbacks from wireframes to the Coordinator use `CoordinatingDelegate` protocols (e.g., `FeedsCoordinatingDelegate`).
- Always use `[weak self]` in closures crossing VIPER layer boundaries.
- Test files live in `iFeed/Tests/` mirroring the source layout, named `*Tests.swift`.
- PRs target the `develop` branch. Use short imperative commit messages.
- Never use force unwrap !
