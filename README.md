Feeds4U
===========

Your personal RSS reader for iPhone and iPad.    
Subscribe to your favorite websites, blogs, and news sources — all in one place.    
Supports **RSS**, **Atom**, and **JSON Feed** formats.

Requires iOS 18.0 or later.

## Features

### Subscribe to Anything
- Add a feed by pasting its URL — the clipboard is auto-detected so the field pre-fills for you
- Don't know the feed URL? **Discover feeds from any website** — the app crawls the page and lists what it finds
- Transparently handles **Cloudflare-protected** sites via a built-in human-verification flow
- One unified inbox for RSS, Atom, and JSON Feed sources

### Read Comfortably
- Pull to refresh for the latest articles
- Unread badges and a per-article dot indicator show what's new at a glance
- **Mark a whole feed as read** with one tap; individual articles are marked read as you open them
- A built-in **offline reader** renders articles with clean, readable typography
- Immersive reading — the navigation bar hides as you scroll, and a fluid **zoom transition** opens articles from their row
- Need the full site? Open any article in **Safari** — pre-warmed for an instant launch

### Organize Your Way
- Group feeds into **folders** by topic, project, or however you like
- **Drag & drop** feeds to create folders, move them between folders, or ungroup them
- Collapse and expand folders to keep your list tidy
- Swipe to delete, or enter edit mode for bulk cleanup

### Find What You Need
- **Fuzzy full-text search** across every article in all your feeds at once
- Recent searches are saved to a pull-down menu for quick repeats — and clearable when you're done
- Results are sorted newest-first so the most relevant content is on top

### Made for the Platform
- iPhone and iPad, every orientation
- Full **dark mode**, following your system appearance, with an **adaptive app icon** (light / dark / tinted)
- **Deep linking** — open `feed://…` or `Feeds4U://…` links straight from other apps or Safari
- Integrates with the iOS **Settings** app

### Localized
Available in **23 languages**: Albanian, Arabic, Belarusian, Bengali, Chinese (Simplified), English, Filipino, French, German, Hindi, Indonesian, Italian, Japanese, Korean, Polish, Portuguese (Brazil), Portuguese (Portugal), Punjabi, Russian, Spanish, Thai, Turkish, and Ukrainian.

## Tech Stack

### Language & Platform
- **Swift 6** with the strict-concurrency model — compiles clean of data-race diagnostics
- **UIKit**, programmatic, scene-based lifecycle (`AppDelegate` + `SceneDelegate`); scene-safe APIs throughout (no deprecated `UIScreen.main`)
- **Core Data** persistence with a lightweight-migration store loaded asynchronously off the launch path
- **WKWebView** powering on-site feed discovery and the Cloudflare verification flow
- **String Catalogs** (`.xcstrings`) for localization across 23 languages, plus a **Settings bundle** and a **custom URL scheme** for deep links
- Minimum deployment target: **iOS 18.0**

### Architecture
- **VIPER** — every feature module (Feeds, FeedItems, ArticleReader, ExploreFeeds, CloudflareBypass) is split into View · Interactor · Presenter · Wireframe · Builder layers that talk only through protocols
- **Coordinator** — a single object owns all navigation; wireframes report outward via coordinating-delegate protocols, keeping view controllers navigation-free
- **DI container** — shared services are wired centrally and exposed through narrow, per-module dependency protocols (Interface Segregation); every collaborator is injected behind a protocol and mockable
- **State as value types** — the view renders from immutable `ViewState` snapshots produced by the presenter

### Concurrency & Performance Engineering
- **`Sendable`** types and **`@MainActor`** isolation for UI-bound code; `Synchronization.Mutex` (iOS 18) guards shared state instead of locks
- **async/await bridging** of callback APIs via `withCheckedContinuation` + `withTaskCancellationHandler`, with a **resume-once continuation box** that guarantees the bridge can never leak or double-resume — cancellation unblocks it immediately
- **Re-entrancy guards** across the UI: navigation keeps a single push in flight, pull-to-refresh ignores overlapping parses, and modal/alert presentation collapses rapid "double-trigger" taps — no double-pushes, stranded spinners, or "present while presenting" warnings
- **Background Core Data** for imports, refreshes, and the search index — only `Sendable` `NSManagedObjectID`s cross actor boundaries; the `viewContext` is reserved for UI reads
- **Projection fetches** (`dictionaryResultType`) build the search index and run link-identity de-duplication without materialising a single `NSManagedObject` or faulting article HTML; unread counts come from a grouped `NSExpressionDescription` aggregate (`COUNT(*)`), never by loading items
- **Storage shaped for memory** — each article's heavy HTML lives in a separate `FeedItemContent` row, so list/search/dedup fetches stay lightweight and the body is faulted in (and explicitly released) only when read
- **Crash-proof table animations** — folder expand/collapse drives `performBatchUpdates` from the table's *authoritative* row counts, so it stays consistent under rapid/chaotic input

### UI
- Programmatic UIKit with a handful of XIBs (launch screen, cells)
- **UITableView drag & drop** (`NSItemProvider`) for feed reorganization between folders
- **SFSafariViewController** with a zoom transition for the in-app web experience
- `KRProgressHUD` / `KRActivityIndicatorView` for progress affordances

### Dependencies (Swift Package Manager)
- [FeedKit](https://github.com/nmdias/FeedKit) — RSS / Atom / JSON Feed parsing
- [SimpleSimilarity](https://github.com/EvgenyKarkan/SimpleSimilarity) — fuzzy text matching for search
- [KRProgressHUD](https://github.com/krimpedance/KRProgressHUD) & [KRActivityIndicatorView](https://github.com/krimpedance/KRActivityIndicatorView) — progress / activity indicators

### Testing & Quality
- **400+ unit tests** in **Swift Testing** (`@Test`, `#expect`, `#require`), mirroring the source layout — every type is covered behind its protocol seam, including regression tests for the concurrency guards (single-flight navigation, pull-to-refresh re-entrancy, continuation resume-once)
- [swift-mocking](https://github.com/fetch-rewards/swift-mocking) — compile-time `@Mocked` mocks; no hand-written doubles. [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) for network stubbing
- **Layered XCUITest suite** covering the Feeds and FeedItems flows end-to-end — empty state, list rendering, navigation, swipe/edit-mode deletion, folders, add/explore/search, the in-app reader, and Safari routing
  - Driven by **deterministic, isolated seeding**: a DEBUG-only launch path (`-uiTesting` / `-uiScenario`) boots the app on an **ephemeral, wiped-on-launch** Core Data store and a private `UserDefaults` suite — fully offline, fast, and never touching real user data or polluting the disk
  - A stubbed parser makes pull-to-refresh resolve instantly offline; elements are addressed through shared **`AccessibilityID`** constants compiled into both targets so identifiers never drift
- **Stress / monkey / chaos tests** — seeded random-gesture fuzzing (a reproducible SplitMix64 generator) plus targeted churn and re-entrancy "double-trigger" probes, asserting the app never crashes and always recovers
- **Xcode Test Plans** decouple selection from the scheme: **Unit** (default, app-scoped coverage) · **UITests** (functional only) · **Stress** (monkey/chaos, randomized order with on-failure retries)
- **SwiftLint** as a build phase enforcing a strict **no-force-unwrapping** policy, among others
- Build schemes: **DEV / ADHOC / RELEASE**

## Contributions
Please ensure that all pull requests are directed to the `develop` branch.

## Important Note
You are free to use the code as you see fit, but please refrain from using any app icons or image assets, as their usage is strictly prohibited.
Thank you.

## Copyright
The source code is licensed under the MIT license.
However, exclusive rights to distribute the Feeds4U application through the Apple App Store are reserved only for me.
Copyright (c) 2015-2026 Evgeny Karkan. All rights reserved.
