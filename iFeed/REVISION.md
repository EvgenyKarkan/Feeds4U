# iFeed Project Revision -- May 17, 2026

**Previous review:** March 27, 2026 (see CODE_REVIEW_IMPROVEMENTS.md, REVIEW_SUMMARY.md)

---

## What Changed Since Last Review

The project underwent a significant architectural overhaul. Here is what was addressed from the original review:

| Original Issue | Status | Notes |
|---|---|---|
| Massive view controllers (MVC) | RESOLVED | Both modules now use VIPER with clean protocol boundaries |
| Brain singleton coupling | PARTIALLY RESOLVED | DIContainer + SharedInstancesContainer introduced; Brain.swift still exists but is bypassed by DI |
| No dependency injection | RESOLVED | Protocol-based DI container with interface segregation (FeedsDependencies, FeedItemsDependencies) |
| O(n^2) duplicate detection | RESOLVED | Uses Set-based lookups |
| Memory leaks in closures | RESOLVED | Consistent [weak self] usage throughout |
| No tests | PARTIALLY RESOLVED | Unit tests now exist for ParsedFeedData, ParsedFeedItemData, ExploreFeedsService, ExploreFeedsElement |
| No Coordinator pattern | RESOLVED | Coordinator + ModuleFactory handle all navigation |
| No SceneDelegate | RESOLVED | Proper scene lifecycle with deep link handling |
| NewCoreDataManager | RESOLVED | Modern NSPersistentContainer-based manager with batch operations, proper error types |

---

## Updated Scores

| Category        | March 2026 | May 2026 | Delta |

| Overall Quality | 6.5/10     | 8.0/10   | +1.5 |
| Crashworthiness | 5/10       | 7.5/10   | +2.5 |
| Performance     | 6/10       | 8/10     | +2 |
| Maintainability | 7/10       | 8.5/10   | +1.5 |
| Modern Swift    | 6/10       | 7/10     | +1 |
| Security        | 7/10       | 7/10     | -- |
| Testing         | 2/10       | 4/10     | +2 |
| Architecture    | 5/10       | 8.5/10   | +3.5 |

---

## Findings

### 1. ARCHITECTURE

#### 1.1 Clean VIPER Implementation (Strength)

Both Feeds and FeedItems modules follow VIPER with well-defined protocol boundaries. 
The Builder pattern cleanly assembles modules, the Coordinator owns navigation, and the ModuleFactory abstracts module creation. 
This is a major improvement.

#### 1.2 Brain Singleton is Dead Code

`Brain.swift` still exists and creates a `Parser` and `NewCoreDataManager.shared`, but nothing in the VIPER modules references it. 
The only live code path goes through `DIContainer`. 
Brain should be deleted to avoid confusion. 
If it is referenced from legacy code paths (e.g., `BaseListViewController.startParsingURL` at line 46 which uses `Brain.brain.parser`), those paths should be audited.

**File:** `Sources/Services/Brain.swift`
**Action:** Delete after confirming no live callers.

#### 1.3 BaseListViewController Still Has Legacy Parsing

`BaseListViewController.swift:40-48` contains `startParsingURL` which uses `Brain.brain.parser` directly, bypassing the DI system. 
It also conforms to `ParserDelegateProtocol` with `hideSpinner()` and `showInvalidFeedAlert()`. 
Since the VIPER modules handle parsing through their interactors, this base class parsing logic is now dead code that could confuse future readers.

**File:** `Sources/UI/Base/BaseListViewController.swift:40-48`
**Risk:** Low (dead code), but someone could accidentally call it and hit the Brain singleton path.

#### 1.4 CoreDataManager (Legacy) is Still in the Project

`CoreDataManager.swift` (242 lines) is the old Core Data stack. 
The app uses `NewCoreDataManager.shared` everywhere via DI. 
The old manager has known issues:
- `#if __DEBUG__` (wrong flag, never triggers)
- `abort()` calls
- No merge policy
- Synchronous main-thread saves with `print("CONTEXT HAS CHANGES!!!")`
- `containsFeed` loads ALL feeds to check one URL (O(n))
- `savedFeedURLs()` calls `fatalError()`

**File:** `Sources/Services/CoreData/CoreDataManager.swift`
**Action:** Delete. It is not wired up through DIContainer.

#### 1.5 FeedsViewDelegate Protocol is Too Fat

`FeedsViewDelegate` (the View -> Presenter protocol) contains `getAllFeeds()` and `feedForIndexPath()` which are synchronous data-fetch methods. 
This means the View pulls data from the Presenter on demand (via `FeedsViewController:260-266`), breaking the unidirectional data flow that VIPER is designed for. 
The Presenter should push data to the View through ViewState, not expose getters.

**File:** `Sources/Modules/Feeds/Protocols/FeedsProtocols.swift:96-97`

---

### 2. CONCURRENCY AND THREADING

#### 2.1 nonisolated(unsafe) Usage

`FeedsPresenter.swift` uses `nonisolated(unsafe)` in three places (lines 80, 123, 138-139) to capture `self` or values across `DispatchQueue.main.async` boundaries. 
This silences the Swift 6 concurrency checker but does not actually make the code safe. 
The pattern is:

```swift
nonisolated(unsafe) let presenter = self
DispatchQueue.main.async {
    presenter?.view?.hideActivityIndicator(nil)
}
```

The real fix is to either mark the presenter as `@MainActor` (since all its outputs go to the view) or use `[weak self]` with a standard main-queue dispatch without the `nonisolated(unsafe)` annotation.

**File:** `Sources/Modules/Feeds/Presenter/FeedsPresenter.swift:80, 123, 138-139`
**Risk:** Medium. Currently works because the presenter is only accessed from the main thread in practice, but the annotation masks a real design issue.

#### 2.2 Parser Creates Core Data Objects on Main Thread

`Parser.swift:68` dispatches to `DispatchQueue.main.async` after parsing, then calls `finishParsing` which creates Core Data entities (Feed, FeedItem) via `storage.makeFeed()` / `storage.makeFeedItem()`. Since `NewCoreDataManager` uses `viewContext` for entity creation, this is technically correct (main thread + main queue context). However, creating potentially hundreds of FeedItem objects on the main thread blocks the UI.

**File:** `Sources/Services/Parser/Parser.swift:68-78, 89-111`
**Impact:** UI stutter during initial parse of large feeds (50+ items). The parsing itself is on a background queue, but the Core Data object creation is on main.

#### 2.3 Search Engine Fills on Arbitrary Queue

`Search.fillMatchingEngine` loads all feed items from Core Data (`storage.loadFeedItems()`) and then indexes them. The `MatchingEngine.fillMatchingEngine` callback fires on an arbitrary queue. The caller (`FeedsPresenter.onViewDidPressSearch`) dispatches back to main. The Core Data fetch itself happens on whatever thread calls `fillMatchingEngine`, which is the main thread (called from presenter). This is safe but could be slow with many items.

**File:** `Sources/Services/Search/Search.swift:68-93`

#### 2.4 NewCoreDataManager Static Properties

`NewCoreDataManager` uses `nonisolated(unsafe)` for static cached sort descriptors and predicates (lines 60-66). Since these are initialized once and never mutated, they are effectively safe, but a cleaner approach would be to use `static let` on a non-Sendable type or wrap them in a struct.

**File:** `Sources/Services/CoreData/NewCoreDataManager.swift:60-66`

---

### 3. MEMORY

#### 3.1 ParsingCompletion Retained Across Calls

Both `FeedsInteractor.parsingCompletion` and `FeedItemsInteractor.parsingCompletion` store a closure that captures `[weak self]` from the presenter. These are never explicitly niled out after being called. If parsing completes and the closure fires, it executes but the reference persists until the next parse or until the interactor is deallocated. This means the closure (and anything it captures) stays in memory longer than necessary.

**File:** `Sources/Modules/Feeds/Interactor/FeedsInteractor.swift:19`
**File:** `Sources/Modules/FeedItems/Interactor/FeedItemsInteractor.swift:19`
**Fix:** Set `parsingCompletion = nil` after calling it in both `didEndParsingFeed` and `didFailParsingFeed`.

#### 3.2 FeedItemsWireframe Safari Zoom Closure Captures Cell

`FeedItemsWireframe.presentSafari` (line 91) captures the `cell` parameter in the zoom transition closure:

```swift
safariVC.preferredTransition = .zoom(options: zoomOptions) { _ in
    return cell
}
```

This closure is retained by the SFSafariViewController for the lifetime of its presentation. The cell is a UITableViewCell which holds a reference to its parent table view. If the user stays on the Safari screen for a long time, the cell cannot be recycled. This is generally fine for a single cell but worth noting.

**File:** `Sources/Modules/FeedItems/InputOutput/FeedItemsWireframe.swift:91-93`

#### 3.3 ExploreFeedsService Session Lifecycle

`ExploreFeedsService` creates a lazy `URLSession` and invalidates it in `deinit`. Since the service is created through `DIContainer.shared`, it lives for the container's lifetime (effectively the app lifetime). This is fine, but if the container is ever recreated (e.g., in tests), the session invalidation in deinit correctly cleans up.

---

### 4. PERFORMANCE

#### 4.1 loadFeeds() Called Multiple Times Per View Cycle

`FeedsPresenter.onViewWillAppear` calls `interactor.getAllFeeds()` and `interactor.unreadCountsByFeed()` on every `viewWillAppear`. Each of these hits Core Data (fetch + group-by aggregate query). For the Feeds screen that appears frequently during navigation, this means two Core Data fetches per appearance. Consider caching the result in the ViewState and only refreshing when data changes.

**File:** `Sources/Modules/Feeds/Presenter/FeedsPresenter.swift:41-47`

#### 4.2 FeedItemsView.hideRefreshControl() Uses removeFromSuperview

The current code at line 48 still uses `refreshControl.removeFromSuperview()`. As discussed earlier, this should be `tableView.refreshControl = nil` to avoid corrupting the refresh control's state.

**File:** `Sources/Modules/FeedItems/View/FeedItemsView.swift:47-49`

#### 4.3 NSDataDetector Created Per Validation Call

`String.isValidURL` creates a new `NSDataDetector` on every call. `NSDataDetector` compilation is expensive. If URL validation is called frequently (e.g., during text field editing), this could cause micro-stutters. Consider caching the detector as a static property.

**File:** `Sources/Extensions/String+Ext.swift:60-76`

#### 4.4 UIScreen.main.bounds Deprecation

Both `FeedsViewController.loadView` and `FeedItemsViewController.loadView` use `UIScreen.main.bounds` which is deprecated in iOS 16+. Should use the view's own bounds or `.zero` and rely on Auto Layout.

**File:** `Sources/Modules/Feeds/View/FeedsViewController.swift:79`
**File:** `Sources/Modules/FeedItems/View/FeedItemsViewController.swift:22`

---

### 5. CODE SMELLS

#### 5.1 #warning Directives in Production Code

`Parser.swift` has two `#warning` directives:
- Line 17: `#warning("ADD ERROR ARGUMENT HERE")` in `ParserDelegateProtocol`
- Line 73: `#warning("HANDLE ERROR ON UI")`

These generate compiler warnings on every build. Either address the underlying issue or remove the directives with a TODO comment.

**File:** `Sources/Services/Parser/Parser.swift:17, 73`

#### 5.2 print() Statements in Production Code

Debug print statements remain in:
- `FeedItemsInteractor.swift:98, 103` -- "existFeedItems ----", "incomingItems ----"
- `Parser.swift:74` -- "GOT PARSING ERROR --->"
- `CoreDataManager.swift:70, 130, 160, 178, 186, 193` -- various debug prints (dead code but still present)
- `FeedsPresenter.swift:100` -- `print(filteredData)`

**Action:** Replace with `os.Logger` or remove entirely.

#### 5.3 NSError with #function/#line as Domain/Code

Both interactors create errors as `NSError(domain: #function, code: #line)`. This produces meaningless error information at runtime (the function name as a domain, the source line as a code). These should be proper typed errors.

**File:** `Sources/Modules/Feeds/Interactor/FeedsInteractor.swift:100`
**File:** `Sources/Modules/FeedItems/Interactor/FeedItemsInteractor.swift:130`

#### 5.4 TODO Comments Indicating Unfinished Work

- `Parser.swift:39` -- "Remove storage from parser, let client create the data objects"
- `FeedItemsInteractor.swift:89-90` -- "Detect if new feed_items appeared"
- `FeedsPresenter.swift:95` -- "Handle this case on UI" (empty explore results)
- `SceneDelegate.swift:87` -- "handle it by coordinator"
- `NewCoreDataManager.swift:48` -- "remove singleton"
- `FeedsProtocols.swift:93` -- "on view needs to show Search Input ?"

#### 5.5 Typo: "searhTitle"

`FeedItemsViewState.swift:18` has property `searhTitle` (missing 'c'). This propagates to `FeedItemsViewController.swift:80` and `FeedItemsPresenter.swift:37`.

**File:** `Sources/Modules/FeedItems/Presenter/FeedItemsViewState.swift:18`

---

### 6. SECURITY

#### 6.1 Pasteboard Auto-Fill and Clear

`BaseListViewController+Alert.swift:160-167` reads `UIPasteboard.general.url` and auto-fills it into the feed URL text field, then clears the pasteboard. This is user-friendly but means the app reads and deletes clipboard content without explicit user consent. On iOS 16+ the system shows a paste permission prompt, which is fine. The clearing behavior is aggressive -- it deletes both `.url` and `.string` from the pasteboard even if the user had other content there.

**File:** `Sources/UI/Base/BaseListViewController+Alert.swift:160-167`
**Risk:** Low. User sees the paste prompt. But clearing `.string` alongside `.url` may delete unrelated clipboard content.

#### 6.2 No HTTPS Enforcement for Feed URLs

Users can enter any URL including `http://` feeds. The app does not enforce HTTPS. While ATS (App Transport Security) provides some protection, RSS feeds often use HTTP and ATS exceptions may be configured. Feed content is displayed as text in cells (not in web views), so XSS risk is minimal.

#### 6.3 Deep Link URL Handling

`SceneDelegate.openURL` extracts the resource specifier from the URL and passes it to `showEnterFeedAlertView`. There is no validation of the URL scheme or sanitization of the specifier before it is displayed in the alert text field and potentially parsed as a feed URL. A malicious deep link could pre-fill an arbitrary string.

**File:** `App/SceneDelegate.swift:79-91`
**Risk:** Low -- the user still has to tap "Add" and the URL goes through feed parsing, not web rendering.

---

### 7. TESTING

#### 7.1 Current State

Tests exist for:
- `ParsedFeedDataTests` -- RSS, Atom, JSON Feed normalization (well-structured, good fixture approach)
- `ParsedFeedItemDataTests` -- individual item normalization
- `ExploreFeedsServiceTests` -- service layer
- `ExploreFeedsElementTests` -- DTO parsing

Missing test coverage for:
- **Core Data operations** (NewCoreDataManager) -- critical path, no tests
- **VIPER modules** -- no presenter, interactor, or wireframe tests
- **Parser** -- no tests for the actual parsing flow + Core Data object creation
- **Search** -- no tests for MatchingEngine integration
- **Coordinator** -- no navigation tests
- **DIContainer** -- no tests for shared instance behavior

#### 7.2 Testability of Current Architecture

The VIPER architecture with protocol-based DI makes the codebase highly testable. 
Every interactor, presenter, and wireframe can be tested with mock protocol conformances. 
This is a significant improvement over the previous MVC architecture. The infrastructure is there -- the tests just need to be written.

---

### 8. SUPPORTABILITY AND FLEXIBILITY

#### 8.1 Dual Core Data Manager Confusion

Having both `CoreDataManager.swift` and `NewCoreDataManager.swift` in the project creates confusion about which one is active. 
The DIContainer wires `NewCoreDataManager.shared`, but `Brain.swift` also creates one. Remove the legacy manager to eliminate ambiguity.

#### 8.2 StorageProtocol Returns Optionals and NSManagedObject

`StorageProtocol.makeFeed()` returns `NSManagedObject?`, requiring callers to cast to `Feed`. 
The modern `NewCoreDataManager.createFeed()` returns `Feed` directly and throws on failure. 
The protocol forces the weaker API surface. 
Consider updating the protocol to use generics or concrete types.

**File:** `Sources/Services/CoreData/StorageProtocol.swift:18-23`

---

### 9. MODERN SWIFT CONCURRENCY

#### 9.1 No async/await in VIPER Modules

All interactor methods use completion handlers. 
The `ExploreFeedsService` already has an `async` variant but it is not used. 
Migrating interactor protocols to `async throws` would simplify the presenters significantly and eliminate the `nonisolated(unsafe)` workarounds.

#### 9.2 @MainActor Not Used

None of the view controllers or presenters are annotated with `@MainActor`. 
Since all UI updates must happen on the main thread, marking the View protocol and Presenter as `@MainActor` would let the compiler enforce thread safety rather than relying on `DispatchQueue.main.async` calls.

---

## Priority Recommendations

### Do Now (low effort, high impact)
1. Delete `Brain.swift` and `CoreDataManager.swift` (dead code cleanup)
2. Remove `#warning` directives from `Parser.swift` -- either fix the API or use TODO
3. Remove `print()` statements from production code
4. Fix `hideRefreshControl()` to use `tableView.refreshControl = nil`
5. Nil out `parsingCompletion` after calling it in both interactors
6. Fix "searhTitle" typo

### Do Soon (medium effort, medium impact)
7. Remove legacy `startParsingURL` from `BaseListViewController`
8. Remove `getAllFeeds()` / `feedForIndexPath()` from `FeedsViewDelegate` -- push data via ViewState
9. Cache `NSDataDetector` in `String.isValidURL`
10. Replace `UIScreen.main.bounds` with `.zero` in `loadView` methods
11. Replace `NSError(domain: #function, code: #line)` with typed errors

### Do Later (higher effort, architectural improvement)
12. Migrate interactor protocols to `async throws`
13. Add `@MainActor` to presenter and view protocols
14. Write unit tests for presenters and interactors (the architecture supports it now)
15. Write Core Data tests using in-memory persistent store
16. Move Core Data object creation out of Parser into the caller (as the existing TODO suggests)
