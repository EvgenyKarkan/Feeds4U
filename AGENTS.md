# Repository Guidelines

## Project Structure & Module Organization

Feeds4U is an iOS Swift project under `iFeed/`. App lifecycle files, assets, localizations, settings, and the Core Data model live in `iFeed/App/`. Production Swift code is in `iFeed/Sources/`, organized by responsibility: `Modules/` contains VIPER-style feature modules, `Services/` contains parser, search, Core Data, and feed discovery logic, `Coordinator/` owns navigation, `DIContainer/` wires dependencies, and `UI/` contains shared views and cells. Tests mirror the source layout in `iFeed/Tests/`.

## Build, Test, and Development Commands

Open `iFeed/iFeed.xcodeproj` in Xcode and use one of the shared schemes: `iFeed - DEV`, `iFeed - ADHOC`, or `iFeed - RELEASE`.

```bash
xcodebuild clean -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV"
xcodebuild build-for-testing -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild test -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" -destination 'platform=iOS Simulator,name=iPhone 15'
```

Swift Package Manager dependencies are resolved through the Xcode project and pinned in `iFeed/iFeed.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Coding Style & Naming Conventions

Follow the existing Swift style: 4-space indentation, explicit access control where useful, and descriptive type names such as `FeedsPresenter`, `ExploreFeedsInteractor`, and `ParsedFeedDataTests`. New features should follow the existing VIPER module shape: `View`, `Interactor`, `Presenter`, `Protocols`, and `InputOutput` files. Use protocol-based dependency injection through `DIContainer` instead of direct global access. Keep navigation in `Coordinator` or wireframes.

SwiftLint is configured in `iFeed/.swiftlint.yml`; it disables length-related rules and enables `force_unwrapping`, `private_outlet`, and `private_action`. Avoid force unwraps unless there is a clear, testable reason.

## Testing Guidelines

Use XCTest. Place tests in `iFeed/Tests/` following the source directory they cover, with names ending in `Tests.swift`, for example `FeedsInteractorTests.swift` or `ParsedFeedDataTests.swift`. Add focused tests for parser changes, Core Data behavior, feed discovery, presenters, interactors, and view state transformations. Run the `xcodebuild test` command above before opening a pull request.

## Commit & Pull Request Guidelines

Recent commits use short imperative summaries such as `Improve tests.`, `Add Swift 6 support.`, and `Cover FeedsInteractor with tests.` Keep commit messages concise and outcome-focused.

Direct pull requests to the `develop` branch. Include a brief description, test results, linked issues when applicable, and screenshots or screen recordings for UI changes. Do not include App Store-only branding assets or app icons in reusable contributions; the README notes those assets are restricted.

## Security & Configuration Tips

Do not commit personal Xcode user data, derived data, credentials, or local signing changes. Keep changes to `Settings.bundle`, localization files, and `Package.resolved` intentional and easy to review.
