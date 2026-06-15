Feeds4U
===========

![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)
![Platform](https://img.shields.io/badge/iOS-18%2B-blue.svg)
![UIKit](https://img.shields.io/badge/UI-UIKit-2396F3.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Your personal RSS reader for iPhone and iPad.    
Subscribe to your favorite websites, blogs, and news sources — all in one place.    
Supports **RSS**, **Atom**, and **JSON Feed** formats.

Requires iOS 18.0 or later.

## Features

### Subscribe to Anything
- Add a feed by typing or pasting its URL — and if your clipboard already holds one, the field pre-fills automatically
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

### Platform
- **Swift 6** (strict concurrency) and programmatic **UIKit** — **Auto Layout** with **`UIStackView`** — targeting **iOS 18+** on iPhone and iPad
- **Core Data** for persistence, **WKWebView** for feed discovery and the Cloudflare flow
- Localization via **String Catalogs** (23 languages), with a Settings bundle and a deep-link URL scheme

### Architecture
- **VIPER** feature modules talking only through protocols, with a **Coordinator** owning all navigation
- A **dependency-injection** container wiring services behind narrow, mockable protocols
- Modern Swift Concurrency throughout — `async`/`await`, `Sendable`, `@MainActor`, and `Mutex`-guarded state

### Engineering highlights
- Heavy work (parsing, imports, search indexing) runs on **background Core Data** contexts; the UI reads from the view context only
- **Re-entrancy guards** keep navigation, pull-to-refresh, and modal presentation single-flight under rapid taps
- Memory-conscious storage — article HTML is split into its own row and faulted in only when read

### Dependencies (Swift Package Manager)
- [FeedKit](https://github.com/nmdias/FeedKit) — RSS / Atom / JSON Feed parsing
- [SimpleSimilarity](https://github.com/EvgenyKarkan/SimpleSimilarity) — fuzzy text matching for search
- [KRProgressHUD](https://github.com/krimpedance/KRProgressHUD) & [KRActivityIndicatorView](https://github.com/krimpedance/KRActivityIndicatorView) — progress / activity indicators

### Testing
- **Unit tests** in **Swift Testing**, with [swift-mocking](https://github.com/fetch-rewards/swift-mocking) mocks and [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs) network stubbing
- **UI tests** (XCUITest) over the main flows on deterministic, isolated seeded data — plus a stress / monkey suite, organized into Xcode **Test Plans**
- **SwiftLint** (strict no-force-unwrapping) and three build schemes: **DEV / ADHOC / RELEASE**

## Build & Run

Requires a recent **Xcode** with the **iOS 18 SDK** (or later). 
Dependencies are resolved automatically via Swift Package Manager on first build.

```bash
git clone https://github.com/EvgenyKarkan/Feeds4U.git
open iFeed/iFeed.xcodeproj
```

Select the **`iFeed - DEV`** scheme and run (⌘R). From the command line:

```bash
# Build
xcodebuild build -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Tests — pick a plan: Unit (default), UITests, or Stress
xcodebuild test -project iFeed/iFeed.xcodeproj -scheme "iFeed - DEV" -testPlan Unit \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Contributions
Please ensure that all pull requests are directed to the `develop` branch.

## Important Note
You are free to use the code as you see fit, but please refrain from using any app icons or image assets, as their usage is strictly prohibited.
Thank you.

## Copyright
The source code is licensed under the MIT license.
However, exclusive rights to distribute the Feeds4U application through the Apple App Store are reserved only for me.
Copyright (c) 2015-2026 Evgeny Karkan. All rights reserved.
