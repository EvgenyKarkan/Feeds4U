# Project: iFeed (Feeds4U)

iFeed (marketed as Feeds4U) is a personal RSS reader for iPhone and iPad, supporting RSS, Atom, and JSON Feed formats. It features offline article reading, folder organization, fuzzy search, and handles Cloudflare-protected websites.

## Project Overview

- **Purpose**: A comprehensive RSS/Atom/JSON feed reader for iOS.
- **Main Technologies**:
  - **Language**: Swift
  - **Frameworks**: UIKit, Core Data, SFSafariViewController
  - **External Libraries**: `FeedKit` (parsing), `SimpleSimilarity` (fuzzy search), `KRProgressHUD`, `KRActivityIndicatorView`.
  - **Dependency Management**: Swift Package Manager (SPM).
- **Architecture**: Modern VIPER (View-Interactor-Presenter-Entity-Router/Wireframe) architecture.
  - **Coordinator Pattern**: Manages navigation flow.
  - **ModuleFactory**: Abstracts module instantiation.
  - **DIContainer**: Implements protocol-based Dependency Injection with Interface Segregation.

## Building and Running

### Build via Xcode
1. Open `iFeed/iFeed.xcodeproj`.
2. Select a scheme: `iFeed - DEV`, `iFeed - ADHOC`, or `iFeed - RELEASE`.
3. Build and run (Cmd + R).

### Command Line
```bash
# Clean build
xcodebuild clean -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV"

# Build for testing
xcodebuild build-for-testing -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Testing

The project uses the `XCTest` framework. Tests are located in the `iFeed/Tests/` directory.

```bash
# Run all tests
xcodebuild test -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage Areas
- **Services**: Core Data, ExploreFeeds, Parser.
- **Modules**: Interactors, Presenters, ViewStates (partial coverage).
- **DI**: Shared instance behavior.

## Development Conventions

- **VIPER Architecture**: Every new feature should be implemented as a VIPER module. Refer to `iFeed/Sources/Modules/` for existing implementations.
- **Protocols**: Use protocols for all communication between VIPER layers (View, Interactor, Presenter, Router).
- **Dependency Injection**: Dependencies must be registered in `DIContainer` and passed via protocols. Do not use singletons directly if a DI-based alternative exists.
- **Coordinator Pattern**: Navigation logic belongs in the `Coordinator`. Do not trigger segues or push view controllers directly from within ViewControllers or Presenters.
- **Memory Management**: Always use `[weak self]` in closures to prevent retain cycles, especially in Interactor -> Presenter or Presenter -> View callbacks.
- **Core Data**: Use `NewCoreDataManager` for persistence. Prefer background contexts for heavy operations and only use the `viewContext` for UI-related data.
- **SwiftLint**: Adhere to the rules defined in `.swiftlint.yml`. SwiftLint runs as a build phase in the Xcode project.
- **Error Handling**: Use the `FeedError` (or similar typed errors) instead of `NSError`.
- **Logging**: Prefer `os.Logger` for structured logging over `print()`.

## Key Files & Directories

- `iFeed/Sources/App/`: App and Scene delegates, app lifecycle.
- `iFeed/Sources/Coordinator/`: Navigation flow management.
- `iFeed/Sources/DIContainer/`: Dependency Injection configuration.
- `iFeed/Sources/Modules/`: VIPER modules (Feeds, FeedItems, ExploreFeeds, etc.).
- `iFeed/Sources/Services/`: Business logic services (Parser, Core Data, Search).
- `iFeed/iFeed.xcdatamodeld/`: Core Data model definition.
- `iFeed/Tests/`: Unit and integration tests.
