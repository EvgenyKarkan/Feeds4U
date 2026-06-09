# iFeed Project Revision -- June 9, 2026

**Previous review:** May 17, 2026

---

## What Changed Since Last Review

Significant progress on concurrency modernization, dead code removal, test coverage, and code hygiene.

| Previous Issue | Status | Notes |
|---|---|---|
| Brain.swift is dead code (1.2) | RESOLVED | File deleted |
| BaseListViewController legacy parsing (1.3) | RESOLVED | `startParsingURL` and Brain references removed |
| Legacy CoreDataManager.swift (1.4) | RESOLVED | Old manager replaced; single modern `CoreDataManager` remains |
| nonisolated(unsafe) in FeedsPresenter (2.1) | RESOLVED | All presenters now `@MainActor`; no `nonisolated(unsafe)` or `DispatchQueue.main.async` in presenters/interactors |
| Parser creates Core Data objects on main thread (2.2) | RESOLVED | Parser delegates object creation to interactors via `ParsedFeedData` |
| #warning directives in Parser.swift (5.1) | RESOLVED | Removed |
| print() statements in production code (5.2) | RESOLVED | All removed from Sources/ |
| NSError(domain: #function, code: #line) (5.3) | RESOLVED | Replaced with typed `StorageError` enum |
| TODO comments in production code (5.4) | RESOLVED | All removed from Sources/ |
| "searhTitle" typo (5.5) | RESOLVED | Fixed to `searchTitle` |
| Dual Core Data manager confusion (8.1) | RESOLVED | Single modern manager with typed `CoreDataError` |
| StorageProtocol returns NSManagedObject? (8.2) | RESOLVED | `makeFeed()` returns `Feed?`, `makeFeedItem()` returns `FeedItem?` |
| No async/await in VIPER modules (9.1) | PARTIALLY RESOLVED | Parser and Search fully modernized with async/await; interactor parsing still uses completion handler pattern |
| Parser async/await migration (9.2) | RESOLVED | Parser uses `withCheckedContinuation`, `@MainActor`, version-based cancellation |
| @MainActor not used (9.3) | RESOLVED | All presenters, view protocols, interactor protocols, and wireframe protocols annotated with `@MainActor` |
| parsingCompletion retained across calls (3.1) | RESOLVED | Niled out in `didEndParsingFeed`, `didFailParsingFeed`, and `didCancelParsingFeed` |
| No tests for VIPER modules (7.1) | RESOLVED | 20 test files covering presenters, interactors, services, and models |
| No Core Data tests (7.1) | RESOLVED | `CoreDataManagerTests` with in-memory store |
| No Parser tests (7.1) | RESOLVED | `ParserTests` suite |
| No Search tests (7.1) | RESOLVED | `SearchTests` suite |

---

## Updated Scores

| Category        | May 2026 | June 2026 | Delta |
|---|---|---|---|
| Overall Quality | 8.0/10   | 8.5/10    | +0.5 |
| Crashworthiness | 7.5/10   | 8.0/10    | +0.5 |
| Performance     | 8/10     | 8/10      | -- |
| Maintainability | 8.5/10   | 9.0/10    | +0.5 |
| Modern Swift    | 7/10     | 9.0/10    | +2 |
| Security        | 7/10     | 7/10      | -- |
| Testing         | 4/10     | 7.5/10    | +3.5 |
| Architecture    | 8.5/10   | 8.5/10    | -- |

---

## Findings

### 1. ARCHITECTURE

#### 1.1 FeedsViewDelegate Protocol Has Data-Pull Methods

`FeedsViewDelegate` exposes `getAllFeeds()` and `feedForIndexPath()` as synchronous getters. This lets the View pull data from the Presenter on demand, breaking VIPER's unidirectional data flow. The Presenter should push all data to the View via `FeedsViewState`.

Note: `feedForIndexPath()` is also used by the Presenter internally (for section-based indexing in `onViewDidSelectFeedAtIndexPath`, `onViewNeedsToDeleteFeedAtIndexPath`). The internal usage is fine; the issue is exposing it on the View-to-Presenter protocol.

**File:** `Sources/Modules/Feeds/Protocols/FeedsProtocols.swift:139-140`

---

### 2. PERFORMANCE

#### 2.1 loadFeeds() Called Multiple Times Per View Cycle

`FeedsPresenter.buildViewState()` calls `interactor.getAllFeeds()` and `interactor.unreadCountsByFeed()` on every `viewWillAppear`, `onViewDidLoad`, and after every mutation (add, delete, folder toggle). Each triggers Core Data fetches. Consider caching and invalidating only on mutation.

**File:** `Sources/Modules/Feeds/Presenter/FeedsPresenter.swift:244-270`

#### 2.2 UIScreen.main Usage (Deprecated in iOS 16)

`UIScreen.main` is deprecated for multi-scene apps. Four call sites remain:

- `FeedsViewController.swift:104` -- `FeedsView(frame: UIScreen.main.bounds)`
- `FeedItemsViewController.swift:22` -- `FeedItemsView(frame: UIScreen.main.bounds)`
- `FeedCell.swift:90` -- `UIScreen.main.scale`
- `FeedFolderHeaderView.swift:87` -- `UIScreen.main.scale`

The `loadView` usages can be replaced with `.zero` since Auto Layout resizes the view. The `.scale` usages can use `traitCollection.displayScale` instead.

#### 2.3 FeedItemsView.hideRefreshControl() Uses removeFromSuperview

`FeedItemsView.swift:48` calls `refreshControl.removeFromSuperview()`. This should be `tableView.refreshControl = nil` to properly decouple the refresh control from the table view's scroll-to-refresh machinery without corrupting internal state.

**File:** `Sources/Modules/FeedItems/View/FeedItemsView.swift:47-49`

---

### 3. MEMORY

#### 3.1 FeedItemsWireframe Safari Zoom Closure Captures Cell

`FeedItemsWireframe.presentSafari` captures a `UITableViewCell` in the zoom transition closure. The closure is retained by `SFSafariViewController` for the presentation lifetime. The cell cannot be recycled while Safari is shown. This is generally fine for a single cell but worth noting.

**File:** `Sources/Modules/FeedItems/InputOutput/FeedItemsWireframe.swift:94-96`

---

### 4. SECURITY

#### 4.1 Pasteboard Auto-Fill and Clear

`BaseListViewController+Alert.swift` reads `UIPasteboard.general.url` and auto-fills it into the feed URL text field, then clears both `.url` and `.string` from the pasteboard. On iOS 16+ the system paste permission prompt provides consent. Clearing `.string` alongside `.url` may delete unrelated clipboard content.

**File:** `Sources/UI/Base/BaseListViewController+Alert.swift:160-167`
**Risk:** Low.

#### 4.2 No HTTPS Enforcement for Feed URLs

Users can enter `http://` feed URLs. ATS provides baseline protection, but RSS feeds often use HTTP. Feed content is rendered as text in cells (not web views), so XSS risk is minimal.

#### 4.3 Deep Link URL Handling

`SceneDelegate.openURL` delegates to `appCoordinator.handleDeepLink(url:)`. The URL resource specifier is extracted and pre-filled in the alert text field. A malicious deep link could pre-fill an arbitrary string, but the user must still tap "Add" and the URL goes through feed parsing.

**File:** `App/SceneDelegate.swift:79-81`
**Risk:** Low.

---

### 5. TESTING

#### 5.1 Current State

20 test files exist with comprehensive coverage:

| Area | Test Files |
|---|---|
| Feeds module | FeedsInteractorTests, FeedsPresenterTests, FeedsViewStateTests, FeedTests |
| FeedItems module | FeedItemsInteractorTests, FeedItemsPresenterTests |
| ArticleReader module | ArticleReaderInteractorTests, ArticleReaderPresenterTests, ArticleReaderViewStateTests |
| Services | CoreDataManagerTests, ParserTests, SearchTests, ExploreFeedsServiceTests |
| Models | ParsedFeedDataTests, ParsedFeedItemDataTests, ExploreFeedsElementTests, FeedFolderTests, FeedFolderManagerTests |
| DI | SharedInstancesContainerTests |

Missing test coverage:
- **Coordinator** -- no navigation flow tests
- **Wireframes** -- no tests for navigation routing
- **UI tests** -- no XCUIAutomation tests
- **CloudflareBypass module** -- no tests
- **ExploreFeeds presenter** -- no tests

---

### 6. UI AND UX IMPROVEMENTS

#### 6.1 Empty State Views

`BaseListView` has a basic `emptyLabel` but no rich empty state design. A proper first-launch experience with icons and call-to-action (e.g., "No feeds yet -- tap + to add your first feed") would improve onboarding.

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

**Files:** `Sources/Modules/Feeds/Protocols/FeedsProtocols.swift:62`, `Sources/Modules/FeedItems/Protocols/FeedItemsProtocols.swift:39`

---

## Priority Recommendations

### Do Now (low effort, high impact)
1. Fix `hideRefreshControl()` to use `tableView.refreshControl = nil` (2.3)
2. Replace `UIScreen.main.bounds` with `.zero` in `loadView` methods (2.2)
3. Replace `UIScreen.main.scale` with `traitCollection.displayScale` (2.2)

### Do Soon (medium effort, medium impact)
4. Remove `getAllFeeds()` / `feedForIndexPath()` from `FeedsViewDelegate` -- push data via ViewState (1.1)
5. Migrate interactor `startParsingFeed` to `async throws` (8.1)
6. Add haptic feedback on pull-to-refresh (6.2)
7. Improve empty state views with icons and call-to-action (6.1)
8. Add tests for CloudflareBypass and ExploreFeeds presenter (5.1)

### Do Later (higher effort, architectural improvement)
9. Adopt `NSFetchedResultsController` for reactive feed list updates (7.1)
10. Write UI tests using XCUIAutomation framework (5.1)
11. Perform accessibility audit -- VoiceOver labels, Dynamic Type, accessibility traits (6.3)
