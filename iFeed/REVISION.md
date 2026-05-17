# iFeed Project Revision -- May 17, 2026

**Previous review:** March 27, 2026

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
| URLSession configuration | RESOLVED | ExploreFeedsService uses ephemeral session with 10s timeout |
| Set-based duplicate detection | RESOLVED | FeedItemsInteractor uses Set<String> for link deduplication |

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

#### ✅ 1.1 Clean VIPER Implementation (Strength)

Both Feeds and FeedItems modules follow VIPER with well-defined protocol boundaries. 
The Builder pattern cleanly assembles modules, the Coordinator owns navigation, and the ModuleFactory abstracts module creation. 
This is a major improvement.

#### ✅ 1.2 Brain Singleton is Dead Code

`Brain.swift` still exists and creates a `Parser` and `NewCoreDataManager.shared`, but nothing in the VIPER modules references it. 
The only live code path goes through `DIContainer`. 
Brain should be deleted to avoid confusion. 
If it is referenced from legacy code paths (e.g., `BaseListViewController.startParsingURL` at line 46 which uses `Brain.brain.parser`), those paths should be audited.

**File:** `Sources/Services/Brain.swift`
**Action:** Delete after confirming no live callers.

#### ✅ 1.3 BaseListViewController Still Has Legacy Parsing

`BaseListViewController.swift:40-48` contains `startParsingURL` which uses `Brain.brain.parser` directly, bypassing the DI system. 
It also conforms to `ParserDelegateProtocol` with `hideSpinner()` and `showInvalidFeedAlert()`. 
Since the VIPER modules handle parsing through their interactors, this base class parsing logic is now dead code that could confuse future readers.

**File:** `Sources/UI/Base/BaseListViewController.swift:40-48`
**Risk:** Low (dead code), but someone could accidentally call it and hit the Brain singleton path.

#### ✅ 1.4 CoreDataManager (Legacy) is Still in the Project

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

`Parser.swift:68` dispatches to `DispatchQueue.main.async` after parsing, then calls `finishParsing` which creates Core Data entities (Feed, FeedItem) via `storage.makeFeed()` / `storage.makeFeedItem()`. 
Since `NewCoreDataManager` uses `viewContext` for entity creation, this is technically correct (main thread + main queue context). 
However, creating potentially hundreds of FeedItem objects on the main thread blocks the UI.

**File:** `Sources/Services/Parser/Parser.swift:68-78, 89-111`
**Impact:** UI stutter during initial parse of large feeds (50+ items). The parsing itself is on a background queue, but the Core Data object creation is on main.

#### ⚠️ 2.3 Search Engine Fills on Arbitrary Queue

`Search.fillMatchingEngine` loads all feed items from Core Data (`storage.loadFeedItems()`) and then indexes them. 
The `MatchingEngine.fillMatchingEngine` callback fires on an arbitrary queue. 
The caller (`FeedsPresenter.onViewDidPressSearch`) dispatches back to main. 
The Core Data fetch itself happens on whatever thread calls `fillMatchingEngine`, which is the main thread (called from presenter). 
This is safe but could be slow with many items.

**File:** `Sources/Services/Search/Search.swift:68-93`

#### 2.4 NewCoreDataManager Static Properties — **No action needed**

`CoreDataManager` uses `nonisolated(unsafe)` for static cached sort descriptors and predicates. These are `static let` constants of non-`Sendable` `NSObject` subclasses (`NSSortDescriptor`, `NSPredicate`, `NSExpressionDescription`). Wrapping them in a struct or using `@unchecked Sendable` would just move the same "trust me" annotation without improving safety. The current pattern is the idiomatic Swift 6 approach: `static let` gives dispatch-once thread-safe initialisation, and the objects are never mutated after creation.

**File:** `Sources/Services/CoreData/CoreDataManager.swift:55-69`

---

### 3. MEMORY

#### ✅ 3.1 ParsingCompletion Retained Across Calls

Both `FeedsInteractor.parsingCompletion` and `FeedItemsInteractor.parsingCompletion` store a closure that captures `[weak self]` from the presenter. 
These are never explicitly niled out after being called. 
If parsing completes and the closure fires, it executes but the reference persists until the next parse or until the interactor is deallocated. 
This means the closure (and anything it captures) stays in memory longer than necessary.

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

This closure is retained by the SFSafariViewController for the lifetime of its presentation. 
The cell is a UITableViewCell which holds a reference to its parent table view. If the user stays on the Safari screen for a long time, the cell cannot be recycled. 
This is generally fine for a single cell but worth noting.

**File:** `Sources/Modules/FeedItems/InputOutput/FeedItemsWireframe.swift:91-93`

#### 3.3 ExploreFeedsService Session Lifecycle

`ExploreFeedsService` creates a lazy `URLSession` and invalidates it in `deinit`. 
Since the service is created through `DIContainer.shared`, it lives for the container's lifetime (effectively the app lifetime). 
This is fine, but if the container is ever recreated (e.g., in tests), the session invalidation in deinit correctly cleans up.

---

### 4. PERFORMANCE

#### 4.1 loadFeeds() Called Multiple Times Per View Cycle

`FeedsPresenter.onViewWillAppear` calls `interactor.getAllFeeds()` and `interactor.unreadCountsByFeed()` on every `viewWillAppear`. 
Each of these hits Core Data (fetch + group-by aggregate query). 
For the Feeds screen that appears frequently during navigation, this means two Core Data fetches per appearance. 
Consider caching the result in the ViewState and only refreshing when data changes.

**File:** `Sources/Modules/Feeds/Presenter/FeedsPresenter.swift:41-47`

#### 4.2 FeedItemsView.hideRefreshControl() Uses removeFromSuperview

The current code at line 48 still uses `refreshControl.removeFromSuperview()`. 
As discussed earlier, this should be `tableView.refreshControl = nil` to avoid corrupting the refresh control's state.

**File:** `Sources/Modules/FeedItems/View/FeedItemsView.swift:47-49`

#### ✅ 4.3 NSDataDetector Created Per Validation Call

`String.isValidURL` creates a new `NSDataDetector` on every call. `NSDataDetector` compilation is expensive. 
If URL validation is called frequently (e.g., during text field editing), this could cause micro-stutters. 
Consider caching the detector as a static property.

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

These generate compiler warnings on every build. 
Either address the underlying issue or remove the directives with a TODO comment.

**File:** `Sources/Services/Parser/Parser.swift:17, 73`

#### 5.2 print() Statements in Production Code

Debug print statements remain in:
- `FeedItemsInteractor.swift:98, 103` -- "existFeedItems ----", "incomingItems ----"
- `Parser.swift:74` -- "GOT PARSING ERROR --->"
- `CoreDataManager.swift:70, 130, 160, 178, 186, 193` -- various debug prints (dead code but still present)
- `FeedsPresenter.swift:100` -- `print(filteredData)`

**Action:** Replace with `os.Logger` or remove entirely.

#### 5.3 NSError with #function/#line as Domain/Code

Both interactors create errors as `NSError(domain: #function, code: #line)`. 
This produces meaningless error information at runtime (the function name as a domain, the source line as a code). 
These should be proper typed errors.

**File:** `Sources/Modules/Feeds/Interactor/FeedsInteractor.swift:100`
**File:** `Sources/Modules/FeedItems/Interactor/FeedItemsInteractor.swift:130`

#### 5.4 TODO Comments Indicating Unfinished Work

- `Parser.swift:39` -- "Remove storage from parser, let client create the data objects"
- `FeedItemsInteractor.swift:89-90` -- "Detect if new feed_items appeared"
- `FeedsPresenter.swift:95` -- "Handle this case on UI" (empty explore results)
- `SceneDelegate.swift:87` -- "handle it by coordinator"
- `NewCoreDataManager.swift:48` -- "remove singleton"
- `FeedsProtocols.swift:93` -- "on view needs to show Search Input ?"

#### ✅ 5.5 Typo: "searhTitle"

`FeedItemsViewState.swift:18` has property `searhTitle` (missing 'c'). 
This propagates to `FeedItemsViewController.swift:80` and `FeedItemsPresenter.swift:37`.

**File:** `Sources/Modules/FeedItems/Presenter/FeedItemsViewState.swift:18`

---

### 6. SECURITY

#### 6.1 Pasteboard Auto-Fill and Clear

`BaseListViewController+Alert.swift:160-167` reads `UIPasteboard.general.url` and auto-fills it into the feed URL text field, then clears the pasteboard. 
This is user-friendly but means the app reads and deletes clipboard content without explicit user consent. 
On iOS 16+ the system shows a paste permission prompt, which is fine. 
The clearing behavior is aggressive -- it deletes both `.url` and `.string` from the pasteboard even if the user had other content there.

**File:** `Sources/UI/Base/BaseListViewController+Alert.swift:160-167`
**Risk:** Low. User sees the paste prompt. But clearing `.string` alongside `.url` may delete unrelated clipboard content.

#### 6.2 No HTTPS Enforcement for Feed URLs

Users can enter any URL including `http://` feeds. 
The app does not enforce HTTPS. While ATS (App Transport Security) provides some protection, RSS feeds often use HTTP and ATS exceptions may be configured. 
Feed content is displayed as text in cells (not in web views), so XSS risk is minimal.

#### 6.3 Deep Link URL Handling

`SceneDelegate.openURL` extracts the resource specifier from the URL and passes it to `showEnterFeedAlertView`. 
There is no validation of the URL scheme or sanitization of the specifier before it is displayed in the alert text field and potentially parsed as a feed URL. 
A malicious deep link could pre-fill an arbitrary string.

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
This is a significant improvement over the previous MVC architecture. 
The infrastructure is there -- the tests just need to be written.

---

### 8. SUPPORTABILITY AND FLEXIBILITY

#### ✅ 8.1 Dual Core Data Manager Confusion

Having both `CoreDataManager.swift` and `NewCoreDataManager.swift` in the project creates confusion about which one is active. 
The DIContainer wires `NewCoreDataManager.shared`, but `Brain.swift` also creates one. 
Remove the legacy manager to eliminate ambiguity.

#### ✅ 8.2 StorageProtocol Returns Optionals and NSManagedObject

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

#### 9.2 Parser async/await Migration

The current `Parser.beginParsingURL` uses a delegate callback pattern with GCD. This can be replaced with a clean `async throws` API using `withCheckedThrowingContinuation` to bridge FeedKit's completion-based `parseAsync`:

```swift
// Current (delegate + GCD)
func beginParsingURL(_ url: URL) {
    delegate?.didStartParsingFeed()
    let parser = FeedParser(URL: url)
    parser.parseAsync(queue: Self.parsingQueue) { result in
        DispatchQueue.main.async { [weak self] in
            switch result { ... }
        }
    }
}

// Proposed (async/await)
func parseFeed(from url: URL) async throws -> Feed {
    let parser = FeedParser(URL: url)

    let parsedResult: FeedKit.Feed = try await withCheckedThrowingContinuation { continuation in
        parser.parseAsync(queue: Self.parsingQueue) { result in
            switch result {
            case .success(let feed):
                continuation.resume(returning: feed)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }

    let feedData = ParsedFeedData(parsedFeed: parsedResult)
    return try await MainActor.run {
        try finishParsing(feedData: feedData, url: url)
    }
}
```

This eliminates the delegate protocol entirely for parsing, makes error propagation explicit via `throws`, and lets callers use structured concurrency:

```swift
// In interactor
func startParsingFeed(_ url: String) async throws -> Feed {
    guard let feedURL = URL(string: url) else { throw ParsingError.invalidURL }
    return try await parser.parseFeed(from: feedURL)
}

// In presenter
func onViewNeedsToAddFeed(from url: String) {
    Task { @MainActor in
        view?.showActivityIndicator()
        do {
            let feed = try await interactor.startParsingFeed(url)
            view?.hideActivityIndicator(nil)
            view?.appendParsedFeed(feed)
        } catch {
            view?.hideActivityIndicator(nil)
            view?.showFeedParsingError()
        }
    }
}
```

Benefits:
- Eliminates `ParserDelegateProtocol` (one less protocol to maintain)
- Eliminates stored `parsingCompletion` closures (no more memory concern from 3.1)
- Removes all `nonisolated(unsafe)` workarounds
- Linear control flow instead of nested callbacks
- Compiler-enforced main-thread UI updates via `@MainActor`

#### 9.3 @MainActor Not Used

None of the view controllers or presenters are annotated with `@MainActor`. 
Since all UI updates must happen on the main thread, marking the View protocol and Presenter as `@MainActor` would let the compiler enforce thread safety rather than relying on `DispatchQueue.main.async` calls.

---

### 10. LOGGING AND DIAGNOSTICS

#### 10.1 Replace print() with os.Logger (Previously Suggested)

The previous review recommended structured logging with `os.Logger`. All current `print()` calls should be replaced with categorized loggers:

```swift
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.ekarkan.iFeed"

    static let coreData  = Logger(subsystem: subsystem, category: "CoreData")
    static let network   = Logger(subsystem: subsystem, category: "Network")
    static let parsing   = Logger(subsystem: subsystem, category: "Parsing")
    static let ui        = Logger(subsystem: subsystem, category: "UI")
}

// Usage in FeedItemsInteractor (instead of print("existFeedItems ----"))
Logger.parsing.debug("Existing items: \(existingItems.count), incoming: \(incomingItems.count)")

// Usage in Parser (instead of print("GOT PARSING ERROR --->"))
Logger.parsing.error("Feed parsing failed: \(error.localizedDescription)")

// Usage in FeedsPresenter (instead of print(filteredData))
Logger.network.debug("Explore results: \(filteredData)")
```

Benefits:
- Logs are visible in Console.app with filtering by category
- `debug` level logs are stripped from release builds automatically
- No performance overhead in production unlike `print()`
- Structured data can be attached without string interpolation overhead

---

### 11. ERROR HANDLING

#### 11.1 Unified FeedError Enum (Previously Suggested)

The previous review recommended a unified error type. 
Currently errors are scattered: `NSError(domain: #function, code: #line)` in interactors, `ExploreFeedsError` in the explore service, and raw `Error` from FeedKit. 
A single `FeedError` enum would unify error handling across the app:

```swift
enum FeedError: LocalizedError {
    case invalidURL
    case alreadySaved
    case parsingFailed(underlying: Error)
    case storageFailed(underlying: Error)
    case networkUnavailable
    case noFeedFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "The URL is not valid."
        case .alreadySaved:          return "This feed is already saved."
        case .parsingFailed(let e):  return "Could not parse feed: \(e.localizedDescription)"
        case .storageFailed(let e):  return "Storage error: \(e.localizedDescription)"
        case .networkUnavailable:    return "No network connection."
        case .noFeedFound:           return "No RSS feed found at this URL."
        }
    }
}
```

This replaces the `NSError` anti-pattern (5.3) and gives the presenter meaningful cases to match on for UI feedback.

---

### 12. UI AND UX IMPROVEMENTS

#### ✅ 12.1 Hardcoded Strings (Previously Suggested)

`BaseListViewController.swift:20` hardcodes `"Feeds4U"` as the navigation title. 
All user-facing strings should be centralized -- either in a constants enum or in a Localizable strings file for future localization support.

**File:** `Sources/UI/Base/BaseListViewController.swift:20`

#### 12.2 Empty State Views (Previously Suggested)

`BaseListView` has a basic `emptyLabel` but no proper empty state design. 
The previous review recommended rich empty states with icons and call-to-action buttons (e.g., "No feeds yet -- tap + to add your first feed"). 
This improves first-launch experience significantly.

**File:** `Sources/UI/Base/BaseListView.swift`

#### 12.3 Haptic Feedback on Pull-to-Refresh (Previously Suggested)

The previous review recommended adding `UIImpactFeedbackGenerator` when pull-to-refresh triggers. 
A light impact at the start of refresh provides tactile confirmation:

```swift
let generator = UIImpactFeedbackGenerator(style: .light)
generator.impactOccurred()
```

#### 12.4 Accessibility Audit (Previously Suggested)

The previous review's roadmap included an accessibility pass (Phase 5). Current gaps:
- Table view cells lack `accessibilityLabel` and `accessibilityHint` for feed items
- Unread badge counts are not announced via VoiceOver
- Pull-to-refresh action is not discoverable via accessibility traits
- Dynamic Type support should be verified across all screens

---

### 13. DATA LAYER IMPROVEMENTS

#### 13.1 NSFetchedResultsController for Reactive Feed List (Previously Suggested)

`FeedsPresenter.onViewWillAppear` manually fetches all feeds on every appearance. 
The previous review recommended `NSFetchedResultsController` to observe Core Data changes and update the table view reactively. 
This eliminates redundant fetches (see 4.1) and provides automatic animations for insertions/deletions:

```swift
lazy var fetchedResultsController: NSFetchedResultsController<Feed> = {
    let request = Feed.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    let frc = NSFetchedResultsController(
        fetchRequest: request,
        managedObjectContext: viewContext,
        sectionNameKeyPath: nil,
        cacheName: nil
    )
    frc.delegate = self
    return frc
}()
```

This pairs well with moving data ownership out of the View (see 1.5) -- the interactor owns the FRC and pushes updates to the presenter.

---

### ✅ 14. PREVIOUSLY SUGGESTED -- NOW RESOLVED

| Original Suggestion | Status |
|---|---|
| URLSession configuration (timeouts, caching) | RESOLVED -- `ExploreFeedsService` uses ephemeral session with 10s timeout |
| Set-based duplicate detection | RESOLVED -- `FeedItemsInteractor` uses `Set<String>` for link deduplication |
| Coordinator pattern | RESOLVED -- `Coordinator` + `ModuleFactory` |
| Protocol-based DI | RESOLVED -- `DIContainer` + `SharedInstancesContainer` |

---

## Priority Recommendations

### Do Now (low effort, high impact)
1. ✅ Delete `Brain.swift` and `CoreDataManager.swift` (dead code cleanup)
2. Remove `#warning` directives from `Parser.swift` -- either fix the API or use TODO
3. Replace `print()` statements with `os.Logger` categories (10.1)
4. Fix `hideRefreshControl()` to use `tableView.refreshControl = nil`
5. ✅ Nil out `parsingCompletion` after calling it in both interactors
6. ✅ Fix "searhTitle" typo
7. ✅ Extract hardcoded `"Feeds4U"` string to a constants enum (12.1)

### Do Soon (medium effort, medium impact)
8. ✅ Remove legacy `startParsingURL` from `BaseListViewController`
9. Remove `getAllFeeds()` / `feedForIndexPath()` from `FeedsViewDelegate` -- push data via ViewState
10. ✅ Cache `NSDataDetector` in `String.isValidURL`
11. Replace `UIScreen.main.bounds` with `.zero` in `loadView` methods
12. Introduce unified `FeedError` enum to replace `NSError(domain: #function, code: #line)` (11.1)
13. Add haptic feedback on pull-to-refresh (12.3)
14. Improve empty state views with icons and call-to-action (12.2)

### Do Later (higher effort, architectural improvement)
15. Migrate interactor protocols to `async throws`
16. Add `@MainActor` to presenter and view protocols
17. Adopt `NSFetchedResultsController` for reactive feed list updates (13.1)
18. Write unit tests for presenters and interactors (the architecture supports it now)
19. ✅ Write Core Data tests using in-memory persistent store
20. Write UI tests using XCUIAutomation framework
21. Perform accessibility audit -- VoiceOver labels, Dynamic Type, accessibility traits (12.4)
22. Move Core Data object creation out of Parser into the caller (as the existing TODO suggests)
