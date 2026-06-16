# iFeed Project Revision -- June 17, 2026

**Previous review:** June 16, 2026

This document is a snapshot of the **open** issues as of June 17, 2026. Items
fixed in prior rounds are dropped — they are recoverable from git history and no
longer describe the current code. Most recently resolved and removed:

- **Feed-URL security hardening** — `http`/`https` scheme allowlist in
  `String.isValidURL`, enforced at the add-feed input and both parsing
  interactors; deep links forced to a web scheme.
- **Safari zoom-transition cell capture** — now `[weak cell]`, so a recycled row
  can no longer be pinned by `SFSafariViewController`.
- Earlier rounds: UI-test/stress suites, the re-entrancy and continuation crash
  fixes (navigation double-push, pull-to-refresh stranded spinner, double-present,
  search resume-once, folder `performBatchUpdates` desync), the
  `FeedsViewDelegate` data-pull cleanup, the `hideRefreshControl` decoupling, and
  the app-wide accessibility audit.

---

## General Results

| Category        | Score   | Notes |
|---|---|---|
| Overall Quality | 9.0/10  | Clean VIPER + Coordinator; remaining items are polish, not structural |
| Crashworthiness | 9.0/10  | No force unwraps; single-flight / resume-once / authoritative-count guards in place |
| Performance     | 8.5/10  | Background Core Data, projection fetches, SQL `COUNT`; feed list still refetches each cycle (1.1) |
| Maintainability | 9.0/10  | One-type-one-file, DI behind protocols, doc comments kept in sync |
| Modern Swift    | 9.0/10  | Swift 6 concurrency throughout; interactor parsing still completion-handler based (4.1) |
| Security        | 9.0/10  | Feed URLs restricted to `http`/`https` (scheme allowlist); deep links forced to a web scheme |
| Testing         | 9.0/10  | 400+ unit tests + XCUITest/stress suites + Test Plans; gaps in CloudflareBypass / ExploreFeeds presenter / wireframes (2.1) |
| Architecture    | 9.0/10  | Clean unidirectional flow; the View no longer pulls data from the Presenter |

---

## Findings

### 1. PERFORMANCE

#### 1.1 buildViewState() Refetches Feeds and Unread Counts Every Cycle

`FeedsPresenter.buildViewState()` calls `interactor.getAllFeeds()` (→ `storage.loadFeeds()`) and `interactor.unreadCountsByFeed()` on every `onViewDidLoad`, `onViewWillAppear`, and after every mutation (add, delete, folder create/move/remove/toggle). Each is a Core Data fetch. Consider caching and invalidating only on mutation.

The folder side of this method is already optimized: folder-URL matching uses a `feedsByURL` dictionary (not a per-URL `allFeeds.first` scan), and `FeedFolderManager.loadFolders()` caches its decoded list. The two Core Data round-trips for feeds and unread counts remain the open part.

**File:** `Sources/Modules/Feeds/Presenter/FeedsPresenter.swift`

---

### 2. TESTING

#### 2.1 Remaining Coverage Gaps

Unit (Swift Testing) and UI (XCUITest + stress/chaos, via Xcode Test Plans) coverage is broad, but these areas remain untested:
- **CloudflareBypass module** — no tests
- **ExploreFeeds presenter** — no tests
- **Wireframes** — no dedicated routing tests (the Coordinator's push paths are partly covered by the re-entrancy-guard tests)

---

### 3. UI AND UX IMPROVEMENTS

#### 3.1 Empty State Views

`BaseListView` has a basic `label` (centered, single line of text) but no rich empty state design. A proper first-launch experience with an icon and call-to-action (e.g., "No feeds yet — tap + to add your first feed") would improve onboarding.

**File:** `Sources/UI/Base/BaseListView.swift`

---

### 4. MODERN SWIFT CONCURRENCY

#### 4.1 Interactor Parsing Still Uses Completion Handlers

While the Parser and Search services are fully modernized with async/await, `FeedsInteractorProtocol.startParsingFeed` and `FeedItemsInteractorProtocol.startParsingFeed` still use `@escaping (Result<...>) -> Void` completion handlers. Migrating these to `async throws` would simplify the presenters and complete the async/await adoption. (Note: `FeedItemsInteractor.startParsingFeed` carries an `isParsing` single-flight guard — preserve that behaviour through any migration.)

**Files:** `Sources/Modules/Feeds/Protocols/FeedsProtocols.swift`, `Sources/Modules/FeedItems/Protocols/FeedItemsProtocols.swift`

---

### 5. DATA LAYER IMPROVEMENTS

#### 5.1 NSFetchedResultsController for Reactive Feed List

`FeedsPresenter.buildViewState()` manually fetches all feeds on every mutation and appearance. `NSFetchedResultsController` would observe Core Data changes and push updates reactively, eliminating the redundant fetches (see 1.1) and enabling automatic table view animations.

---

## Priority Recommendations

### Do Soon (medium effort, medium impact)
1. Migrate interactor `startParsingFeed` to `async throws`, preserving the single-flight guard (4.1)
2. Cache feeds/unread counts in `buildViewState()` and invalidate on mutation (1.1)
3. Improve empty state views with an icon and call-to-action (3.1)
4. Add tests for CloudflareBypass and the ExploreFeeds presenter (2.1)

### Do Later (higher effort, architectural improvement)
5. Adopt `NSFetchedResultsController` for reactive feed list updates (5.1)
