Feeds4U
===========

Your personal RSS reader for iPhone and iPad.    
Subscribe to your favorite websites, blogs, and news sources — all in one place.    
Supports **RSS**, **Atom**, and **JSON Feed** formats.

Requires iOS 18.0 or later.

## Features

### Stay Up to Date
- Add feeds by entering their URL directly, or let the app discover available feeds from any website
- Pull down to refresh and get the latest articles
- Unread badges and visual indicators help you see what's new at a glance
- Mark a whole feed as read with a single tap

### Read Comfortably
- Built-in offline article reader with clean typography optimized for readability
- Full dark theme support across the entire app, following your system appearance
- App icon adapts to light, dark, and tinted Home Screen styles
- Open any article in Safari when you need the full website experience

### Organize Your Way
- Create folders to group feeds by topic, project, or however you like
- Drag and drop feeds between folders to reorganize effortlessly
- Collapse and expand folders to keep your list tidy

### Find What You Need
- Search across all your feeds at once with fuzzy text matching
- Recent searches are saved for quick repeat access via a pull-down menu
- Search results sorted by date so the most relevant content is always on top

### Works Where You Do
- Handles Cloudflare-protected websites with a built-in verification flow
- Deep link support — open feed URLs directly in the app from other apps or Safari
- Works on both iPhone and iPad in any orientation

### Localized
Available in 23 languages: Albanian, Arabic, Belarusian, Bengali, Chinese (Simplified), English, Filipino, French, German, Hindi, Indonesian, Italian, Japanese, Korean, Polish, Portuguese (Brazil), Portuguese (Portugal), Punjabi, Russian, Spanish, Thai, Turkish, and Ukrainian.

## Tech Stack

### Language & Platform
- **Swift 6** with strict concurrency checking — the codebase compiles free of data-race warnings, using `Sendable` types, `@MainActor` isolation, and modern primitives such as `Synchronization.Mutex`
- **UIKit** with the scene-based app lifecycle (`AppDelegate` + `SceneDelegate`), supporting iPhone and iPad in all orientations
- **Core Data** for persistence, with background contexts for heavy work and the view context reserved for UI reads
- **WKWebView** powering on-site feed discovery and the Cloudflare verification flow
- **async/await bridging** — callback-based APIs are wrapped into structured concurrency via `withCheckedContinuation`
- **String Catalogs** (`.xcstrings`) driving localization into 23 languages
- **Settings bundle** integration with the iOS Settings app
- **Custom URL scheme** for deep linking into the app
- Minimum deployment target: **iOS 18.0**

### Architecture
- **VIPER** — each feature module (Feeds, FeedItems, ArticleReader, ExploreFeeds, CloudflareBypass) is split into View, Interactor, Presenter, Wireframe, and Builder layers that communicate exclusively through protocols
- **Coordinator pattern** — a single Coordinator owns all navigation; wireframes report back via coordinating-delegate protocols
- **Dependency Injection container** — shared services are wired centrally and exposed through narrow, per-module dependency protocols (Interface Segregation)

### UI
- Programmatic UIKit with a small number of XIBs (launch screen, table view cells)
- **UITableView drag & drop API** powering feed reorganization between folders
- **SFSafariViewController** for the in-app Safari experience

### Dependencies
- Swift Package Manager
- [FeedKit](https://github.com/nmdias/FeedKit) — RSS / Atom / JSON Feed parsing
- [SimpleSimilarity](https://github.com/EvgenyKarkan/SimpleSimilarity) — fuzzy text matching for search
- [KRProgressHUD](https://github.com/krimpedance/KRProgressHUD) & [KRActivityIndicatorView](https://github.com/krimpedance/KRActivityIndicatorView) — progress and activity indicators

### Testing & Tooling
- **Swift Testing** (`@Test`, `#expect`, `#require`) for the unit test suite, mirroring the source layout
- [swift-mocking](https://github.com/fetch-rewards/swift-mocking) — compile-time generated mocks via the `@Mocked` macro; no hand-written mocks
- [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) — network stubbing in tests
- **SwiftLint** as an Xcode build phase, enforcing a no-force-unwrapping policy and others
- Three build schemes: **DEV / ADHOC / RELEASE**

## Contributions
Please ensure that all pull requests are directed to the `develop` branch.

## Important Note
You are free to use the code as you see fit, but please refrain from using any app icons or image assets, as their usage is strictly prohibited.
Thank you.

## Copyright
The source code is licensed under the MIT license.
However, exclusive rights to distribute the Feeds4U application through the Apple App Store are reserved only for me.
Copyright (c) 2015-2026 Evgeny Karkan. All rights reserved.
