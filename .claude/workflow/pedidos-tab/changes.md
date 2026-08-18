# Pedidos tab — implementation changes

## Files created

- `PideYa/Home/Orders/OrdersModels.swift` — `OrderStage`, `ActiveOrder`, `PastOrder`, es-ES
  display formatting, `OrdersContentProviding` + `MockOrdersContentProvider` (1 active order + 12
  past orders; rows 4-12 commented as invented filler).
- `PideYa/Home/Orders/OrdersViewModel.swift` — `@MainActor @Observable` VM, provider injected via
  a defaulted init parameter, `summaryText`/`hasActiveOrders` computed from the arrays.
- `PideYa/Home/Orders/OrdersSubviews.swift` — `OrdersHeaderView`, `ActiveOrderCardView`,
  `OrderProgressView`, `PastOrderRowView`.
- `PideYa/Home/Orders/OrdersView.swift` — pinned header + `EN CURSO` + `ANTERIORES` composed in a
  `NavigationStack`/`ScrollView` with a double `safeAreaInset` (top header, bottom tab-bar inset).
- `PideYaTests/OrdersTests.swift` — Swift Testing coverage (16 tests: stage logic, formatting,
  mock-provider seed data, view-model injection/derivation, `HomeTabViewModel` ownership).
- `PideYaTests/DesignSystemViewsTests.swift` — added in review round 2 (see below); 4 tests for
  `StarRatingView`'s extracted `filledStars(score:outOf:)` clamping helper.
- `PideYaUITests/OrdersUITests.swift` — XCUITest coverage (10 tests) for the acceptance criteria
  that need a running app.

## Files edited (additive only, per plan)

- `PideYa/DesignSystem/Theme.swift` — added `Palette.outline`, `Palette.surface`,
  `Size.orderThumbnail`, `Size.actionButton`, `Size.progressSegment`. No existing token touched.
- `PideYa/DesignSystem/DesignSystemViews.swift` — added `StarRatingView` and
  `OutlinedActionButton`, each with a `#Preview`. No existing component touched.
- `PideYa/Home/HomeTabViewModel.swift` — added `let orders: OrdersViewModel` with a defaulted
  init parameter; `HomeTabViewModel()` still compiles with zero arguments.
- `PideYa/Home/HomeTabView.swift` — added `case .pedidos: OrdersView(...)` to the `@ViewBuilder`
  switch. No `AnyView`.

`PideYa/PideYaApp.swift` and `PideYa.xcodeproj/project.pbxproj` are byte-identical to their
pre-feature state (confirmed via `git status --porcelain` / `git diff --stat`).

## Key decisions (as specified by the plan)

- `PastOrder.ratingText` uses numeric `Decimal`/`Double` fields with computed `es-ES` formatted
  text properties, never storing pre-formatted currency strings.
- `dateText` (`"12 ago"`) and `etaText` (`"20:45"`) are stored as literal pre-formatted `String`s,
  documented in `OrdersModels.swift`, to avoid OS-version-dependent ICU month abbreviations.
- `stableID(_:)` is duplicated (3 lines) into `MockOrdersContentProvider` rather than hoisted out
  of `MockFeedContentProvider`, keeping `FeedModels.swift` untouched.
- Bolt button accessibility label: `"Acciones rápidas"`, identifier `orders.quickActionButton`,
  no-op action (Open question 2's resolution).
- All five interactive no-op controls (`Ayuda`, `Filtrar`, `Ver seguimiento`, bolt,
  `REPETIR`) are real `Button`s with `{}` actions.

## Deviations from the plan

1. **[Corrected after review — see "Review round 2" below] `OrdersModels.swift` — the
   `EXC_BREAKPOINT` crash was caused by the display-formatting `extension`s being silently
   `@MainActor`-isolated, not by `Optional.map`.** The original write-up here blamed "an apparent
   interaction between ... `NonisolatedNonsendingByDefault` / `InferIsolatedConformances` ... and
   a closure passed into a generic higher-order function (`Optional.map`)" and worked around it by
   rewriting `ratingText` as `guard let`/`return`. That diagnosis was wrong: `nonisolated` on a
   type *declaration* does not propagate into a separate `extension` block under
   `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so `extension ActiveOrder { ... }` and
   `extension PastOrder { ... }` — and the file-scope `itemCountText(_:)` / `esES` they depend on
   — were actually `@MainActor`-isolated the whole time, which silently plants a runtime
   main-thread executor check on *every* closure literal written inside them (not just
   `Optional.map`; `.filter`, `.sorted`, `.first(where:)`, any closure). The `guard let` rewrite
   only removed the one closure that happened to trip the check; the trap stayed armed for the
   next person who wrote a closure in that file. Fixed by annotating the isolation explicitly —
   `private nonisolated let esES`, `nonisolated private func itemCountText(_:)`,
   `nonisolated extension ActiveOrder`, `nonisolated extension PastOrder` — and restoring
   `ratingText` to the `Optional.map` form the plan originally specified. See "Review round 2".

2. **`OrdersSubviews.swift` — `OrdersHeaderView.body` gained
   `.accessibilityElement(children: .contain)` before its `.accessibilityIdentifier("orders.header")`.**
   The plan's task-5 spec for `OrdersHeaderView` listed the identifier but not this modifier
   (unlike `ActiveOrderCardView`, `OrderProgressView` and `PastOrderRowView`, which all pair the
   two). Without it, SwiftUI's `.accessibilityIdentifier` on a non-combined container cascades
   down and *overwrites* every descendant accessibility element's own identifier — verified via
   `app.debugDescription`: the `Ayuda` button's own `"orders.helpButton"` identifier was being
   silently replaced with `"orders.header"`, breaking `orders.helpButton` lookups (acceptance
   criteria 2 and 7). Adding `.accessibilityElement(children: .contain)` (the same fix already
   applied everywhere else in the file) makes the header itself a genuine container element and
   stops the cascade, without changing the visual output.

3. **`PideYaUITests/OrdersUITests.swift` — `testRatedAndUnratedRowsRenderDifferently` scopes its
   queries to each row's own `orders.past.<uuid>` container** (via a local
   `pastOrderRowIdentifier(_:)` helper mirroring `MockOrdersContentProvider.stableID`) instead of
   querying `app.otherElements["orders.rating"]` unscoped. Forno Bianco (rated) and Casa Lola
   (unrated) are both on screen simultaneously without scrolling, so an unscoped
   `XCTAssertFalse(app.otherElements["orders.rating"].exists)` while asserting on Casa Lola was
   spuriously failing because Forno Bianco's `orders.rating` element already existed elsewhere on
   screen. Scoping to each row's container makes the assertion mean what it says. This is a test
   fix, not a product-code change.

Both product-code deviations (1 and 2) were driven by empirical failures (a process crash and a
demonstrated accessibility-tree bug respectively), not stylistic preference, and neither changes
any visible behaviour, token, or file the plan marked out of scope.

## Review round 2 — fixes applied

The first pass came back `CHANGES_REQUESTED` (2 critical, 5 warnings). Fixes:

**[CRITICAL 1 — root cause, not symptom] `OrdersModels.swift` isolation.** See the corrected
deviation #1 above. `private nonisolated let esES`, `nonisolated private func itemCountText(_:)`,
`nonisolated extension ActiveOrder`, `nonisolated extension PastOrder` were added, and
`PastOrder.ratingText` was restored to `rating.map { $0.formatted(...) }`. Verified: the full
31-test `PideYaTests` suite (now 35 with the warning-3 addition below) passes with the closure
form back in place — the crash does not reproduce once the isolation is explicit.

**[CRITICAL 2] `OrdersSubviews.swift` — the `orders.rating` identifier cascade, still present in
`ratingOrChip`.** The identifier moved off the `HStack` (which was not itself an accessibility
element and so silently stamped its identifier onto both `StarRatingView` *and* the sibling
`Text`) and onto `StarRatingView` alone, which already collapses to exactly one element via
`.accessibilityElement(children: .ignore)`. Added the suggested regression assertion —
`app.descendants(matching: .any).matching(identifier: "orders.rating").count == 8` — to
`testRatedAndUnratedRowsRenderDifferently`, scrolling the `LazyVStack` to the bottom first so
every past-order row has been materialized before the count is taken.

**[WARNING 1] `testFirstThreePastOrdersMatchDesign` now asserts order, not just presence.** Rows
are located via their own container (`pastOrderRowIdentifier(_:)`, see warning 5) and
`XCTAssertLessThan` on `frame.minY` proves Forno Bianco precedes Casa Lola precedes Sakura Ramen,
in addition to each row's own text content.

**[WARNING 2] `StarRatingView` no longer bakes Spanish copy into the design system.** Its `init`
now takes `accessibilityLabel: (Int, Int) -> String`; `PastOrderRowView.ratingOrChip` supplies
`{ filled, outOf in "\(filled) de \(outOf) estrellas" }`, matching how `ChipView(text:)` and the
other design-system components take their user-facing text as a parameter.

**[WARNING 3] `StarRatingView`'s clamping logic is now covered.** Extracted to a top-level
`nonisolated func filledStars(score:outOf:) -> Int` in `DesignSystemViews.swift` (was `private`
on the view, hence unreachable from tests) and covered by four new tests in the new
`PideYaTests/DesignSystemViewsTests.swift` (`FilledStarsTests`): negative score, above-`outOf`
score, half-up rounding, and no-rounding cases.

**[WARNING 4] The pre-formatted-dates doc comment moved to the symbol it documents.** It was
attached to `nonisolated enum OrderStage` (which has neither `dateText` nor `etaText`); it is now
a plain `//` file-scope comment directly above `private nonisolated let esES`.

**[WARNING 5] `PastOrderRowView` identifier no longer duplicates `stableID` internals.** It now
takes an `index: Int` (the row's position in `ANTERIORES`) and exposes
`.accessibilityIdentifier("orders.past.row.\(index)")`; `OrdersView.pastList` supplies `index` via
`ForEach(Array(viewModel.pastOrders.enumerated()), id: \.element.id)`, keeping `order.id` as the
`ForEach` identity. `OrdersUITests.pastOrderRowIdentifier(_:)` was simplified to
`"orders.past.row.\(index)"`, so the UI-test selector no longer needs to reconstruct
`MockOrdersContentProvider`'s seed `UUID`s and will survive a future data-source swap.

`FeedModels.swift` was left untouched per instruction — the reviewer flagged the identically-shaped
latent isolation issue there (lines 42/60) as a separate, shipped-code decision for the user.

## Verification

- `xcodebuild build` — **BUILD SUCCEEDED**, zero warnings (only the pre-existing, unrelated
  `appintentsmetadataprocessor` "No AppIntents.framework dependency found" message, present before
  this feature too).
- `xcodebuild test -only-testing:PideYaTests` — **35 tests, all passed** (15 pre-existing + 16
  Orders + 4 new `FilledStarsTests`).
- `xcodebuild test -only-testing:PideYaUITests` — **23 test cases, all passed** (13 pre-existing +
  10 Orders, including the strengthened `testFirstThreePastOrdersMatchDesign` and
  `testRatedAndUnratedRowsRenderDifferently`).
- `swift-format lint --configuration .swift-format --recursive PideYa PideYaTests PideYaUITests`
  — zero findings.
- `git status --porcelain` — `PideYa/PideYaApp.swift` and `PideYa.xcodeproj/project.pbxproj` do
  not appear (unmodified); only the additive edits and new files listed above are present.
- All four acceptance-criterion-9 `rg` greps return exactly the expected (empty, except the
  `ThemeFontModifier`-only `.font(` match) results.
