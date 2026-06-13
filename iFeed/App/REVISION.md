# iFeed Project Revision -- June 13, 2026

**Previous review:** June 9, 2026

This document is a snapshot of the **open** issues as of June 13, 2026. Items
fixed in prior rounds (dead-code removal, the dual Core Data manager, Parser
async/await migration, `@MainActor` adoption, the print/`#warning`/TODO cleanup,
the pasteboard-clearing behaviour, the quadratic folder-URL matching, and the
row-tap / refresh-dedup / search-index race bugs) have been dropped — they are
recoverable from git history and no longer describe the current code.

---

## General Results

| Category        | June 13, 2026 | Notes |
|---|---|---|
| Overall Quality | 8.5/10  | Clean VIPER + Coordinator; remaining items are polish, not structural |
| Crashworthiness | 8.5/10  | No force unwraps in Sources; to-many fault, refresh-dedup, and search-race bugs fixed |
| Performance     | 8.5/10  | Folder cache, dictionary feed matching, `IN`-fetch search, SQL `COUNT`, article HTML release |
| Maintainability | 9.0/10  | One-type-one-file, DI behind protocols, doc comments kept in sync |
| Modern Swift    | 9.0/10  | Swift 6 concurrency throughout; only interactor parsing still uses completion handlers (8.1) |
| Security        | 7.5/10  | HTTP feed URLs still allowed (4.1); deep-link prefill is low risk (4.2) |
| Testing         | 8.0/10  | 21 test files; gaps in wireframes, UI tests, CloudflareBypass, ExploreFeeds presenter (5.1) |
| Architecture    | 8.5/10  | Unidirectional flow, one data-pull leak left on `FeedsViewDelegate` (1.1) |

---

## Findings

### 1. ARCHITECTURE

#### 1.1 FeedsViewDelegate Protocol Has Data-Pull Methods

`FeedsViewDelegate` exposes `getAllFeeds()` and `feedForIndexPath()` as synchronous getters. This lets the View pull data from the Presenter on demand, breaking VIPER's unidirectional data flow. The Presenter should push all data to the View via `FeedsViewState`.

Neither method is actually called from the View (`FeedsViewController`/`FeedsView`) — both are dead on this protocol. `feedForIndexPath()` is used internally by the Presenter (for section-based indexing in `onViewDidSelectFeedAtIndexPath`, `onViewNeedsToDeleteFeedAtIndexPath`), which is fine. `getAllFeeds()` has no internal caller at all. Both can simply be removed from `FeedsViewDelegate`.

**File:** `Sources/Modules/Feeds/Protocols/FeedsProtocols.swift:148-149`

---

### 2. PERFORMANCE

#### 2.1 buildViewState() Refetches Feeds and Unread Counts Every Cycle

`FeedsPresenter.buildViewState()` calls `interactor.getAllFeeds()` (→ `storage.loadFeeds()`) and `interactor.unreadCountsByFeed()` on every `onViewDidLoad`, `onViewWillAppear`, and after every mutation (add, delete, folder create/move/remove/toggle). Each is a Core Data fetch. Consider caching and invalidating only on mutation.

The folder side of this method is already optimized: folder-URL matching uses a `feedsByURL` dictionary (not a per-URL `allFeeds.first` scan), and `FeedFolderManager.loadFolders()` caches its decoded list. The two Core Data round-trips for feeds and unread counts remain the open part.

**File:** `Sources/Modules/Feeds/Presenter/FeedsPresenter.swift:262-292`

#### 2.2 FeedItemsView.hideRefreshControl() Uses removeFromSuperview

`FeedItemsView.swift:48` calls `refreshControl.removeFromSuperview()`. This should be `tableView.refreshControl = nil` to properly decouple the refresh control from the table view's scroll-to-refresh machinery without corrupting internal state.

**File:** `Sources/Modules/FeedItems/View/FeedItemsView.swift:47-49`

---

### 3. MEMORY

#### 3.1 FeedItemsWireframe Safari Zoom Closure Captures Cell

`FeedItemsWireframe.presentSafari` captures a `UITableViewCell` in the zoom transition closure. The closure is retained by `SFSafariViewController` for the presentation lifetime. The cell cannot be recycled while Safari is shown. This is generally fine for a single cell but worth noting.

**File:** `Sources/Modules/FeedItems/InputOutput/FeedItemsWireframe.swift:103-105`

---

### 4. SECURITY

#### 4.1 No HTTPS Enforcement for Feed URLs

Users can enter `http://` feed URLs. ATS provides baseline protection, but RSS feeds often use HTTP. Feed content is rendered as text in cells (not web views), so XSS risk is minimal.

**Risk:** Low.

#### 4.2 Deep Link URL Handling

`SceneDelegate.openURL` delegates to `Coordinator.handleDeepLink(url:)`, which calls `feedURL(fromDeepLink:)` to strip the custom-scheme wrapper, prepend `https://` when no scheme is present, and pre-fill the result in the add-feed alert. A malicious deep link could pre-fill an arbitrary string, but the user must still tap "Add" and the URL goes through feed parsing.

**File:** `Sources/Coordinator/Coordinator.swift:52-98`
**Risk:** Low.

---

### 5. TESTING

#### 5.1 Current State

21 test files exist with broad coverage:

| Area | Test Files |
|---|---|
| Coordinator | CoordinatorTests |
| Feeds module | FeedsInteractorTests, FeedsPresenterTests, FeedsViewStateTests, FeedTests |
| FeedItems module | FeedItemsInteractorTests, FeedItemsPresenterTests |
| ArticleReader module | ArticleReaderInteractorTests, ArticleReaderPresenterTests, ArticleReaderViewStateTests |
| Services | CoreDataManagerTests, ParserTests, ParseContinuationBoxTests, SearchTests, ExploreFeedsServiceTests |
| Models | ParsedFeedDataTests, ParsedFeedItemDataTests, ExploreFeedsElementTests, FeedFolderTests, FeedFolderManagerTests |
| DI | SharedInstancesContainerTests |

Missing test coverage:
- **Wireframes** -- no tests for navigation routing
- **UI tests** -- no XCUIAutomation tests
- **CloudflareBypass module** -- no tests
- **ExploreFeeds presenter** -- no tests

---

### 6. UI AND UX IMPROVEMENTS

#### 6.1 Empty State Views

`BaseListView` has a basic `label` (centered, single line of text) but no rich empty state design. A proper first-launch experience with icons and call-to-action (e.g., "No feeds yet -- tap + to add your first feed") would improve onboarding.

**File:** `Sources/UI/Base/BaseListView.swift`

#### 6.2 Haptic Feedback on Pull-to-Refresh

Adding `UIImpactFeedbackGenerator(style: .light).impactOccurred()` when pull-to-refresh triggers provides tactile confirmation.

#### 6.3 Accessibility Audit

- Table view cells lack `accessibilityLabel` and `accessibilityHint` for feed items
- Unread badge counts are not announced via VoiceOver
- Pull-to-refresh action is not discoverable via accessibility traits
- Dynamic Type support should be verified across all screens

---

### 7. DATA LAYER IMPROVEMENTS

#### 7.1 NSFetchedResultsController for Reactive Feed List

`FeedsPresenter.buildViewState()` manually fetches all feeds on every mutation and appearance. `NSFetchedResultsController` would observe Core Data changes and push updates reactively, eliminating redundant fetches (see 2.1) and enabling automatic table view animations.

---

### 8. MODERN SWIFT CONCURRENCY

#### 8.1 Interactor Parsing Still Uses Completion Handlers

While the Parser and Search services have been fully modernized with async/await, `FeedsInteractorProtocol.startParsingFeed` and `FeedItemsInteractorProtocol.startParsingFeed` still use `@escaping (Result<...>) -> Void` completion handlers. Migrating these to `async throws` would simplify the presenters and complete the async/await adoption.

**Files:** `Sources/Modules/Feeds/Protocols/FeedsProtocols.swift:67`, `Sources/Modules/FeedItems/Protocols/FeedItemsProtocols.swift:44`

---

## Priority Recommendations

### Do Now (low effort, high impact)
1. Fix `hideRefreshControl()` to use `tableView.refreshControl = nil` (2.2)
2. Remove the dead `getAllFeeds()` / `feedForIndexPath()` from `FeedsViewDelegate` (1.1)

### Do Soon (medium effort, medium impact)
3. Migrate interactor `startParsingFeed` to `async throws` (8.1)
4. Cache feeds/unread counts in `buildViewState()` and invalidate on mutation (2.1)
5. Add haptic feedback on pull-to-refresh (6.2)
6. Improve empty state views with icons and call-to-action (6.1)
7. Add tests for CloudflareBypass and ExploreFeeds presenter (5.1)

### Do Later (higher effort, architectural improvement)
8. Adopt `NSFetchedResultsController` for reactive feed list updates (7.1)
9. Write UI tests using XCUIAutomation framework (5.1)
10. Perform accessibility audit -- VoiceOver labels, Dynamic Type, accessibility traits (6.3)
