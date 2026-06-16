# iFeed Project Revision -- June 16, 2026

**Previous review:** June 13, 2026

This document is a snapshot of the **open** issues as of June 16, 2026. Items
fixed in prior rounds — including the recent UI-test/stress suites, the
re-entrancy and continuation crash fixes (navigation double-push, pull-to-refresh
stranded spinner, double-present, search resume-once, folder `performBatchUpdates`
desync), the `FeedsViewDelegate` data-pull cleanup, the `hideRefreshControl`
decoupling, and the app-wide accessibility audit — have been dropped. They are
recoverable from git history and no longer describe the current code.

---

## General Results

| Category        | Score   | Notes |
|---|---|---|
| Overall Quality | 9.0/10  | Clean VIPER + Coordinator; remaining items are polish, not structural |
| Crashworthiness | 9.0/10  | No force unwraps; single-flight / resume-once / authoritative-count guards in place |
| Performance     | 8.5/10  | Background Core Data, projection fetches, SQL `COUNT`; feed list still refetches each cycle (1.1) |
| Maintainability | 9.0/10  | One-type-one-file, DI behind protocols, doc comments kept in sync |
| Modern Swift    | 9.0/10  | Swift 6 concurrency throughout; interactor parsing still completion-handler based (6.1) |
| Security        | 7.5/10  | HTTP feed URLs allowed (3.1); deep-link prefill is low risk (3.2) |
| Testing         | 9.0/10  | 400+ unit tests + XCUITest/stress suites + Test Plans; gaps in CloudflareBypass / ExploreFeeds presenter / wireframes (4.1) |
| Architecture    | 9.0/10  | Clean unidirectional flow; the View no longer pulls data from the Presenter |

---

## Findings

### 1. PERFORMANCE

#### 1.1 buildViewState() Refetches Feeds and Unread Counts Every Cycle

`FeedsPresenter.buildViewState()` calls `interactor.getAllFeeds()` (→ `storage.loadFeeds()`) and `interactor.unreadCountsByFeed()` on every `onViewDidLoad`, `onViewWillAppear`, and after every mutation (add, delete, folder create/move/remove/toggle). Each is a Core Data fetch. Consider caching and invalidating only on mutation.

The folder side of this method is already optimized: folder-URL matching uses a `feedsByURL` dictionary (not a per-URL `allFeeds.first` scan), and `FeedFolderManager.loadFolders()` caches its decoded list. The two Core Data round-trips for feeds and unread counts remain the open part.

**File:** `Sources/Modules/Feeds/Presenter/FeedsPresenter.swift`

---

### 2. MEMORY

#### 2.1 FeedItemsWireframe Safari Zoom Closure Captures Cell

`FeedItemsWireframe.presentSafari` captures a `UITableViewCell` in the zoom transition closure. The closure is retained by `SFSafariViewController` for the presentation lifetime, so the cell cannot be recycled while Safari is shown. This is generally fine for a single cell but worth noting.

**File:** `Sources/Modules/FeedItems/InputOutput/FeedItemsWireframe.swift`

---

### 3. SECURITY

#### 3.1 No HTTPS Enforcement for Feed URLs

Users can enter `http://` feed URLs. ATS provides baseline protection, but RSS feeds often use HTTP. Feed content is rendered as text in cells (not web views), so XSS risk is minimal.

**Risk:** Low.

#### 3.2 Deep Link URL Handling

`SceneDelegate.openURL` delegates to `Coordinator.handleDeepLink(url:)`, which strips the custom-scheme wrapper, prepends `https://` when no scheme is present, and pre-fills the result in the add-feed alert. A malicious deep link could pre-fill an arbitrary string, but the user must still tap "Add" and the URL goes through feed parsing.

**File:** `Sources/Coordinator/Coordinator.swift`
**Risk:** Low.

---

### 4. TESTING

#### 4.1 Remaining Coverage Gaps

Unit (Swift Testing) and UI (XCUITest + stress/chaos, via Xcode Test Plans) coverage is broad, but these areas remain untested:
- **CloudflareBypass module** — no tests
- **ExploreFeeds presenter** — no tests
- **Wireframes** — no dedicated routing tests (the Coordinator's push paths are partly covered by the re-entrancy-guard tests)

---

### 5. UI AND UX IMPROVEMENTS

#### 5.1 Empty State Views

`BaseListView` has a basic `label` (centered, single line of text) but no rich empty state design. A proper first-launch experience with an icon and call-to-action (e.g., "No feeds yet — tap + to add your first feed") would improve onboarding.

**File:** `Sources/UI/Base/BaseListView.swift`

---

### 6. MODERN SWIFT CONCURRENCY

#### 6.1 Interactor Parsing Still Uses Completion Handlers

While the Parser and Search services are fully modernized with async/await, `FeedsInteractorProtocol.startParsingFeed` and `FeedItemsInteractorProtocol.startParsingFeed` still use `@escaping (Result<...>) -> Void` completion handlers. Migrating these to `async throws` would simplify the presenters and complete the async/await adoption. (Note: `FeedItemsInteractor.startParsingFeed` carries an `isParsing` single-flight guard — preserve that behaviour through any migration.)

**Files:** `Sources/Modules/Feeds/Protocols/FeedsProtocols.swift`, `Sources/Modules/FeedItems/Protocols/FeedItemsProtocols.swift`

---

### 7. DATA LAYER IMPROVEMENTS

#### 7.1 NSFetchedResultsController for Reactive Feed List

`FeedsPresenter.buildViewState()` manually fetches all feeds on every mutation and appearance. `NSFetchedResultsController` would observe Core Data changes and push updates reactively, eliminating the redundant fetches (see 1.1) and enabling automatic table view animations.

---

## Priority Recommendations

### Do Soon (medium effort, medium impact)
1. Migrate interactor `startParsingFeed` to `async throws`, preserving the single-flight guard (6.1)
2. Cache feeds/unread counts in `buildViewState()` and invalidate on mutation (1.1)
3. Improve empty state views with an icon and call-to-action (5.1)
4. Add tests for CloudflareBypass and the ExploreFeeds presenter (4.1)

### Do Later (higher effort, architectural improvement)
6. Adopt `NSFetchedResultsController` for reactive feed list updates (7.1)
