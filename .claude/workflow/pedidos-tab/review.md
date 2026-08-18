# Code review — Pedidos tab

**VERDICT: CHANGES_REQUESTED — 2 critical, 5 warnings**

Reviewed: `git diff` for the 4 modified files + full read of the 6 new files, against
`plan.md`, `DESIGN.md`, `changes.md` and `CLAUDE.md`.

Build/test/lint/grep results were independently verified by the launching agent and are not
re-litigated here. Everything below is either a code-reading finding or an empirically
reproduced one; every claim marked "proved" was reproduced in a throwaway copy of the repo
under `scratchpad/`, which has since been deleted. **The working tree is exactly as I found
it** (`git status --porcelain`: 4 ` M`, 4 `??`, no stray edits).

---

## Verdict summary

The feature is well built. It follows the plan closely, the design transcription is
reproduced accurately (I checked the six DESIGN.md details flagged as fragile — all correct),
view bodies are 8–22 lines, there are no force-unwraps, no `AnyView`, no colour literals
outside `Theme.swift`, and no retain cycles. Two things block: the deviation-1 crash fix
treats a symptom and leaves the underlying trap armed, and the deviation-2 accessibility bug
was fixed in one place but not the other place it occurs.

---

## Acceptance criteria audit

| # | Criterion | Status |
|---|---|---|
| 1 | Zero-warning build; `pbxproj`/`PideYaApp.swift` untouched | PASS |
| 2 | Inicio ↔ Pedidos round trip | PASS |
| 3 | Active card content incl. U+00A0 | PASS |
| 4 | `EN CAMINO` ×2, other stages ×1 | PASS |
| 5 | First three `ANTERIORES` rows **in that order** | **PARTIAL** — order is not asserted (W1) |
| 6 | Rated vs unrated rows | **PARTIAL** — passes via an a11y-cascade artifact (C2) |
| 7 | All five controls are no-ops | PASS |
| 8 | Bolt a11y label | PASS |
| 9 | Four source greps | PASS (I re-ran all four; clean) |
| 10 | Dynamic Type growth | PASS |
| 11 | Last row clears the tab bar | PASS — **proved load-bearing** (see below) |
| 12 | Header stays pinned | PASS |
| 13 | `swift-format lint` clean | PASS |
| 14 | Bodies < 40 lines, `#Preview` per view file | PASS |
| 15 | Pre-existing tests still pass | PASS |

Design-spec details verified by reading: segments 1–3 accent / segment 4 `outline`
(§3.4) ✓; only the *current* stage label accent, completed stages secondary (§3.4) ✓;
`Ver seguimiento` label left-inset — `.padding(.horizontal)` correctly precedes
`.frame(maxWidth:.infinity, alignment: .leading)` (§3.5) ✓; separators at full content width
with one after the last row and **no** thumbnail indent (§4.4) ✓; zero corner radius ✓;
`REPETIR` bordered with `Theme.Palette.outline`, not ink (§4.3) ✓; `surface` (white) on the
bolt button ✓.

---

# MUST FIX

## [CRITICAL] `PideYa/Home/Orders/OrdersModels.swift:73` & `:91` (also `:10`, `:69`) — the display-formatting layer is silently `@MainActor`-isolated; deviation #1 is a symptom fix, and the trap is still armed

`changes.md` deviation #1 attributes the `EXC_BREAKPOINT` / `_dispatch_assert_queue_fail` in
`swift_task_checkIsolatedSwift` to "an interaction between this toolchain's
`NonisolatedNonsendingByDefault` / `InferIsolatedConformances` … and a closure passed into a
generic higher-order function (`Optional.map`)". **That diagnosis is wrong, and the `guard let`
rewrite papers over a real, general isolation defect.**

### What is actually happening

`nonisolated` on a type declaration does **not** propagate into a plain `extension` block under
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Compiling the real file confirms it:

```
$ xcrun swiftc -swift-version 6 -default-isolation MainActor \
    -enable-upcoming-feature NonisolatedNonsendingByDefault \
    -enable-upcoming-feature InferIsolatedConformances -emit-sil OrdersModels.swift

nonisolated enum OrderStage : ... {
  nonisolated var label: String { get }        <-- primary declaration: nonisolated
  nonisolated var stepIndex: Int { get }
}
private func itemCountText(_ count: Int) -> String     <-- NOT nonisolated
extension ActiveOrder {
  var totalText: String { get }                        <-- NOT nonisolated
  ...
}
extension PastOrder {
  var ratingText: String? { get }                      <-- NOT nonisolated
}
```

SIL reports `// Isolation: global_actor. type: MainActor` for `itemCountText(_:)` and for all
nine extension members. Consequence: **every closure literal written inside those extensions is
inferred `@MainActor`**, and SILGen plants a runtime main-thread precondition
(`_checkExpectedExecutor` → `swift_task_isCurrentExecutor` / `swift_task_reportUnexpectedExecutor`)
at the top of the closure body. I verified this is not specific to `Optional.map`, not specific
to generic higher-order functions, and not related to capturing `esES`:

| closure in a plain `extension` of a `nonisolated` type | inferred isolation | runtime check |
|---|---|---|
| `rating.map { $0.formatted(...esES) }` | `@MainActor` | yes |
| `rating.map { "\($0)" }` (captures nothing) | `@MainActor` | yes |
| `names.map { $0.uppercased() }` | `@MainActor` | yes |
| `names.filter { !$0.isEmpty }` | `@MainActor` | yes |
| `names.sorted { $0 < $1 }` | `@MainActor` | yes |
| `guard let` (no closure) | — | no |

So the next `.map` / `.filter` / `.sorted` / `.first(where:)` anyone writes in
`OrdersModels.swift` — or in the identically-shaped `FeedModels.swift:42`/`:60` — reintroduces
the exact same crash, and `changes.md` currently teaches the next implementer to avoid
`Optional.map` as a cargo cult instead of fixing the isolation.

### Reproduced end-to-end

Scratchpad copy, `ratingText` reverted to the `Optional.map` form, `-only-testing:PideYaTests`:

```
◇ Test pastOrderRatingTextUsesCommaDecimal() started.
Restarting after unexpected exit, crash, or test timeout; ...
Failing tests:
  OrdersFormattingTests.pastOrderTotalsUseNonBreakingSpaceBeforeEuro()
  OrdersFormattingTests.activeOrderSubtitleComposesItemsAndOrderNumber()
  OrdersFormattingTests.itemCountTextIsSingularForOne()
  OrdersFormattingTests.activeOrderArrivalTextIsPrefixed()
  OrdersFormattingTests.pastOrderSubtitleComposesDateAndItems()
** TEST FAILED **
```

### Root-cause fix (verified green with the `Optional.map` form *restored*)

```swift
private nonisolated let esES = Locale(identifier: "es_ES")          // :10
nonisolated private func itemCountText(_ count: Int) -> String      // :69
nonisolated extension ActiveOrder { … }                             // :73
nonisolated extension PastOrder { … }                               // :91
```

With those four annotations and `ratingText` written as
`rating.map { $0.formatted(.number.precision(.fractionLength(1)).locale(esES)) }`, the
scratchpad copy reports `✔ Test run with 31 tests in 10 suites passed`.

`nonisolated` on `esES` is **not** optional. Marking only the two extensions fails the build
with three copies of:

```
Main actor-isolated let 'esES' can not be referenced from a nonisolated context
```

which is the proof that the file as landed compiles *only because* its formatting layer really
is MainActor-isolated. That directly contradicts plan task 3, which requires these types to be
"usable from the provider without hopping", and it silently defeats the intent behind marking
the structs `nonisolated` at all. `FeedModels.swift:35` already uses the correct
`nonisolated extension` form — the new code just did not follow it.

Keeping `guard let` after the annotations is fine; the point is the annotations, not the
control flow. Please also correct deviation #1 in `changes.md`.

---

## [CRITICAL] `PideYa/Home/Orders/OrdersSubviews.swift:283` — `orders.rating` cascades; this is deviation #2's bug, still present in the second container

Deviation #2 correctly diagnosed and fixed the identifier cascade on `OrdersHeaderView`. The
identical bug exists on `ratingOrChip`'s `HStack`, which gets
`.accessibilityIdentifier("orders.rating")` with **no** `.accessibilityElement(children: .contain)`.

Proved with a throwaway probe test against an unmodified build:

```
PROBE anyRating.count = 16                       // 8 rated rows × 2
PROBE otherElements orders.rating count = 8
PROBE staticTexts  orders.rating count = 8
PROBE[0] type=1  label=5 de 5 estrellas          // the StarRatingView group
PROBE[1] type=48 label=5,0                       // the Text — wrongly carries the id
...
PROBE headerCascade staticTexts orders.header count = 0   // header fix works
```

There is no container element with identifier `orders.rating`; the id is stamped onto two
descendants per rated row. Criterion 6's
`fornoBiancoRow.otherElements["orders.rating"].label == "5 de 5 estrellas"` passes only because
the `.otherElements` type filter happens to exclude the mislabelled `staticText`. Adding any
second `.other` element to that `HStack`, or querying via `descendants(matching:)`, makes it
ambiguous.

**Fix (minimal, keeps the existing test green)** — put the identifier on `StarRatingView`,
which is already exactly one accessibility element (`children: .ignore` + an explicit label):

```swift
if let rating = order.rating, let ratingText = order.ratingText {
    HStack(spacing: Theme.Spacing.xs) {
        StarRatingView(score: rating)
            .accessibilityIdentifier("orders.rating")
        Text(ratingText)…
    }
}
```

If you prefer `.accessibilityElement(children: .contain)` on the `HStack` instead (symmetric
with the header), criterion 6 must change too: a `.contain` container has no label of its own,
so `ratingElement.label == "5 de 5 estrellas"` will stop holding.

**Add a regression assertion either way**, since nothing currently guards against the cascade
coming back:

```swift
XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "orders.rating").count, 8)
```

(8 = one per rated seed row.)

---

## [WARNING] `PideYaUITests/OrdersUITests.swift:80-92` — `testFirstThreePastOrdersMatchDesign` does not verify order, but criterion 5 says "in that order"

The test asserts nine strings exist somewhere on screen; it says nothing about which row they
belong to or what sequence they appear in. Proved by mutation: I reversed the first three
entries of `MockOrdersContentProvider.seedPast` (Sakura → Casa Lola → Forno) in a scratchpad
copy and the test still passed:

```
Test Case '-[PideYaUITests.OrdersUITests testFirstThreePastOrdersMatchDesign]' passed (12.923 seconds).
```

Suggested fix — assert both grouping and sequence, reusing the `pastOrderRowIdentifier(_:)`
helper that already exists at line 98:

```swift
let forno  = app.otherElements[pastOrderRowIdentifier(21)]
let casa   = app.otherElements[pastOrderRowIdentifier(22)]
let sakura = app.otherElements[pastOrderRowIdentifier(23)]
XCTAssertTrue(forno.staticTexts["18,90\u{00A0}€"].exists)
XCTAssertTrue(forno.staticTexts["12 ago · 2 artículos"].exists)
// … same for casa / sakura …
XCTAssertLessThan(forno.frame.minY, casa.frame.minY)
XCTAssertLessThan(casa.frame.minY, sakura.frame.minY)
```

For contrast, criterion 11's test *is* load-bearing — I removed `OrdersView`'s
`.safeAreaInset(edge: .bottom)` and `testLastPastOrderRowIsReachableAboveTabBar` failed with
`XCTAssertLessThanOrEqual failed: ("783.3333333333329") is greater than ("780.0") - Last row
extends into the tab bar.` Good test; keep it.

---

## [WARNING] `PideYa/DesignSystem/DesignSystemViews.swift:262` — `StarRatingView` bakes user-facing Spanish copy into the design system

```swift
.accessibilityLabel("\(filledCount) de \(outOf) estrellas")
```

Every other component in this file takes its user-facing text as a parameter — `ChipView(text:)`,
`SectionHeaderView(title:)`, `HardRule` (no text), and the new `OutlinedActionButton(title:)`.
This is the first literal Spanish string in the design-system layer, so it is the one that gets
missed when a localization catalogue lands, and it couples a generic component to one app's
language.

On the API-design question the plan raised: `OutlinedActionButton` clearly belongs in the
design system — it is a pure visual primitive with no domain knowledge. `StarRatingView` belongs
there only once its copy moves out. Fix:

```swift
init(score: Double, outOf: Int = 5, accessibilityLabel: (Int, Int) -> String)
// or simply: init(score:outOf:accessibilityLabel: String)
```

and build the Spanish phrase in `PastOrderRowView`, next to the other Spanish literals.

---

## [WARNING] `PideYa/DesignSystem/DesignSystemViews.swift:264-266` — `StarRatingView.filledCount` is the only logic in the new design-system code and has zero coverage

The doc comment promises clamping ("an out-of-range `score` … simply saturates"), but nothing
proves it, and because it is `private` on a `View` it is unreachable from `PideYaTests`. A
future edit to `min`/`max`/`rounded()` is silently reversible (this is the recurring
"structural fix with no test guarding it" pattern).

Fix: extract a free function and test it.

```swift
nonisolated func filledStars(score: Double, outOf: Int) -> Int {
    min(outOf, max(0, Int(score.rounded())))
}
```
```swift
#expect(filledStars(score: -3,  outOf: 5) == 0)
#expect(filledStars(score: 9,   outOf: 5) == 5)
#expect(filledStars(score: 4.5, outOf: 5) == 5)
#expect(filledStars(score: 4.0, outOf: 5) == 4)
```

---

## [WARNING] `PideYa/Home/Orders/OrdersModels.swift:12-18` — the pre-formatted-dates doc comment is attached to the wrong symbol

The `///` block explaining why `dateText` / `etaText` are stored as `String`s sits directly
above `nonisolated enum OrderStage`, which has neither field. It will surface in Quick Help and
generated docs as documentation *for `OrderStage`*. Plan task 3 asked for "a doc comment in the
file"; this satisfies the letter but misfiles the content.

Fix: turn it into a `//` file-level comment above `private let esES` (line 10), or split it onto
`ActiveOrder` and `PastOrder` where the fields actually live.

---

## [WARNING] `PideYaUITests/OrdersUITests.swift:98-101` — row selectors re-implement `MockOrdersContentProvider.stableID` in the test target

```swift
private func pastOrderRowIdentifier(_ lastByte: UInt8) -> String {
    let id = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, lastByte))
    return "orders.past.\(id.uuidString)"
}
```

Scoping the queries per row (deviation #3) was the right call, but the key is now coupled to
mock seed internals that a UI test process cannot import. The day a real provider lands, every
one of these lookups fails at `waitForExistence` with an unhelpful "element not found" rather
than a diagnostic message — and the byte-tuple is duplicated in three places
(`MockFeedContentProvider`, `MockOrdersContentProvider`, this helper).

Not blocking while the provider is a mock. Preferred shape: give `PastOrderRowView` a
content-independent identifier — pass the row index down and use
`.accessibilityIdentifier("orders.past.row.\(index)")` — so the selector survives a data-source
swap. (Keep `order.id` as the `ForEach` identity; only the a11y identifier changes.)

---

# NICE TO HAVE

- **[NIT] `OrdersSubviews.swift:276`** — `if let rating = order.rating, let ratingText = order.ratingText`
  binds two optionals where the second is derived from the first and cannot be `nil` when the
  first is not. It correctly avoids a force-unwrap, but reads as though the two could disagree.
  Either leave it (it is safe) or gate on `order.rating` alone and have the view format via a
  non-optional helper.
- **[NIT] `OrdersView.swift:16-18`** — the doc comment says the ViewModel is owned by
  `HomeTabViewModel` "so its state survives tab switches". True of ViewModel state, but
  `HomeTabView`'s `@ViewBuilder switch` still tears the view down, so **scroll position is not
  preserved** across a tab round trip. `FeedView` has the same behaviour, so this is consistent
  rather than wrong — just worth wording precisely so nobody assumes scroll restoration works.
- **[NIT] `Theme.swift:38`** — `Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255)`.
  `255 / 255` is noise; `Color(red: 1, green: 1, blue: 1)` is clearer. Keeping the `/ 255` form
  for visual symmetry with its neighbours is a defensible counter-argument — reviewer's
  preference only.
- **[NIT] `OrdersModels.swift:125-135`** — `seedActive`'s single-element literal has no trailing
  comma while `seedPast` does. `swift-format` does not flag it; purely cosmetic.
- Criterion 14's "every new file has at least one `#Preview`" is unmet by `OrdersModels.swift`
  and `OrdersViewModel.swift`. Previews on non-view files are meaningless — the criterion's
  wording is at fault, not the code. **No action.**

---

# Things done well (do not change)

- **Concurrency, memory, SwiftUI checklists are otherwise clean.** No `Task`, no Combine, no
  detached work, nothing blocking the main actor. All closures are `{}` no-ops passed into
  structs — no `self` capture anywhere, so no retain cycles and no `[weak self]` needed.
  `OrdersViewModel` is correctly `@MainActor @Observable` with `private(set)` state, a defaulted
  protocol-injected provider that is not stored, and both derived values (`summaryText`,
  `hasActiveOrders`) computed from the arrays so the header cannot contradict the list.
- **ViewModel ownership follows CLAUDE.md exactly**: `HomeTabViewModel` owns, `OrdersView` holds
  a plain `let`, and no `Bindable` was added out of pattern-matching (the plan explicitly warned
  about that).
- **`ForEach` identity is stable** — `stableID(_:)` seeds rather than `UUID()` per call, and
  `mockProviderIDsAreStableAcrossCalls` guards it. That is the correct guard for the
  full-`ForEach`-rebuild failure mode.
- **The injection tests are the right shape**: `StubOrdersContentProvider` and
  `EmptyOrdersContentProvider` return data `MockOrdersContentProvider` cannot produce
  (`"Stub Activo"`, 1 past order, 0 orders), so `viewModelSurfacesInjectedProviderData`,
  `summaryTextIsDerivedFromArrays` and `hasActiveOrdersIsFalseForEmptyProvider` cannot pass by
  coincidence. The singular/plural cases (`1 anterior`, `1 artículo`) are covered even though the
  mockup never shows them.
- **The model/provider suites are deliberately *not* `@MainActor`**, so the nonisolated test
  target genuinely exercises the isolation contract — which is exactly why the deviation-1 crash
  was caught at all. Keep that; do not "fix" it by annotating the suites `@MainActor`.
- `Rectangle().strokeBorder` (not `.stroke`) everywhere, so borders sit inside the frame — the
  right call in this border-driven design language.
- `.accessibilityIdentifier` is inert and is the sanctioned UI-test hook; `.contain` keeps
  descendants navigable. Neither is test pollution.
- SF Symbols sized via `.themeFont(_:)` rather than `.font(.system(size:))`, so the glyphs scale
  with Dynamic Type — a genuine improvement over `HomeTabBar`, and correctly left un-retrofitted.
- Deviation #3 (scoping row queries to their container) is a correct and well-explained test fix.

---

**VERDICT: CHANGES_REQUESTED — 2 critical, 5 warnings**

---
---

# RE-REVIEW (round 2) — Pedidos tab

**VERDICT: APPROVED**

Scope: the same 4 modified + 5 untracked paths, re-read in full against round 1's MUST FIX and
NICE TO HAVE lists, `plan.md`, `DESIGN.md` and the rewritten `changes.md`. Build/test/lint
results were independently verified by the launching agent and are not re-litigated. Everything
below is either code-reading or empirically reproduced. **The working tree is exactly as I found
it** — `git status --porcelain` after all experiments: 4 ` M` (`DesignSystemViews.swift`,
`Theme.swift`, `HomeTabView.swift`, `HomeTabViewModel.swift`) and 5 `??`
(`.claude/workflow/pedidos-tab/`, `PideYa/Home/Orders/`, `PideYaTests/DesignSystemViewsTests.swift`,
`PideYaTests/OrdersTests.swift`, `PideYaUITests/OrdersUITests.swift`). All three scratchpad
mutants and the SIL probe directory have been deleted.

## Resolution of round 1

| # | Round-1 item | Status |
|---|---|---|
| C1 | `OrdersModels.swift` formatting layer silently `@MainActor` | **RESOLVED** |
| C2 | `orders.rating` identifier cascade in `ratingOrChip` | **RESOLVED** |
| W1 | Criterion 5 asserts presence, not order | **RESOLVED** |
| W2 | `StarRatingView` bakes Spanish copy into the design system | **RESOLVED** |
| W3 | `filledCount` clamping logic untestable / uncovered | **RESOLVED** |
| W4 | Pre-formatted-dates doc comment on the wrong symbol | **RESOLVED** |
| W5 | UI-test row selectors re-implement `stableID` | **RESOLVED** |

---

## [CRITICAL 1] RESOLVED — proved at the root, not patched at the call site

`OrdersModels.swift` now carries `private nonisolated let esES` (:17), `nonisolated private func
itemCountText` (:69), `nonisolated extension ActiveOrder` (:73) and `nonisolated extension
PastOrder` (:91), and `ratingText` (:100-102) is back to the `Optional.map` form that originally
crashed. Verified with the same probe that produced the round-1 finding, run against the file as
it stands (scratchpad, since deleted):

```
$ xcrun swift-frontend -typecheck -swift-version 6 -default-isolation MainActor \
    -enable-upcoming-feature NonisolatedNonsendingByDefault \
    -enable-upcoming-feature InferIsolatedConformances -print-ast OrdersModels.swift

@_hasInitialValue private nonisolated let esES: Locale
nonisolated internal enum OrderStage : …
nonisolated private func itemCountText(_ count: Int) -> String
nonisolated extension ActiveOrder {
  nonisolated internal var totalText / statusText / arrivalText / subtitleText
nonisolated extension PastOrder {
  nonisolated internal var totalText / subtitleText / ratingText / isRated
nonisolated internal protocol OrdersContentProviding : Sendable
nonisolated internal struct MockOrdersContentProvider : OrdersContentProviding
```

`-emit-sil` on the same file: **0 occurrences of `// Isolation: global_actor`** and **0
occurrences of `swift_task_isCurrentExecutor` / `_checkExpectedExecutor`** across all 3177 lines.
Every declaration in the file — including the `private static` `stableID` / `seedActive` /
`seedPast` members — is `nonisolated` or `unspecified`. The trap is disarmed, not stepped around.

**No remaining declaration in `PideYa/Home/Orders/` is unintentionally MainActor-isolated.**
`OrdersViewModel` is `@MainActor` by design; `OrdersView`/`OrdersSubviews` are `View`s and are
correctly MainActor by the target default.

**The same trap is not present in the new design-system code either.** SIL on
`DesignSystemViews.swift` + `Theme.swift`:

```
// filledStars(score:outOf:)
// Isolation: nonisolated
sil hidden @$s2DS11filledStars5score5outOfSiSd_SitF : $@convention(thin) (Double, Int) -> Int
```

`filledStars` is genuinely nonisolated, which is what lets the non-`@MainActor`
`FilledStarsTests` suite call it. `StarRatingView.body` and its `ForEach` closures print
`Isolation: global_actor. type: MainActor` — that is **correct and harmless**: they are `View`
code, only ever invoked by SwiftUI on the main actor.

I specifically checked the new `accessibilityLabel: (Int, Int) -> String` stored closure for the
same shape. It is safe: the only two closure literals supplied
(`OrdersSubviews.swift:287`, `DesignSystemViews.swift:343-344`) are written inside MainActor
contexts and are invoked only from `StarRatingView.body`. Nothing off the main actor can reach
them, and nothing nonisolated stores a `StarRatingView`.

**This fix is now guarded by a test** (round-1 item 11, "a fix landing with no test guarding it").
`OrdersFormattingTests` is deliberately *not* `@MainActor` and `pastOrderRatingTextUsesCommaDecimal`
exercises the restored `Optional.map` closure from a nonisolated context — the exact call that
crashed the test host before. Reverting any of the four annotations reintroduces either a compile
error (`Main actor-isolated let 'esES' can not be referenced from a nonisolated context`) or the
crash. Do not annotate those suites `@MainActor`.

`changes.md` deviation #1 has been rewritten and is now an accurate account of the root cause.

## [CRITICAL 2] RESOLVED — and the regression assertion is mutation-proved load-bearing

The identifier moved off the `ratingOrChip` `HStack` onto `StarRatingView`
(`OrdersSubviews.swift:287-288`), which is already exactly one element via
`.accessibilityElement(children: .ignore)` + explicit label. The inline comment explains why.

**The count of 8 is correct.** `seedPast` rows with a non-`nil` rating are indices
0, 2, 3, 5, 6, 7, 9, 10 → 8 rated, 4 unrated, of 12.

**Mutation-proved.** Scratchpad copy, identifier moved back onto the `HStack` (the exact round-1
bug), `-only-testing:PideYaUITests/OrdersUITests/testRatedAndUnratedRowsRenderDifferently`:

```
OrdersUITests.swift:146: error: XCTAssertEqual failed: ("16") is not equal to ("8")
  - orders.rating must resolve to exactly one element per rated row (8 of 12 seeded past orders).
Test Case '…testRatedAndUnratedRowsRenderDifferently' failed (10.401 seconds).
```

16 = 8 rated rows × 2 stamped descendants — which independently confirms both that the cascade is
what the assertion catches and that 8 is the true rated-row count.

## [WARNING 1] RESOLVED — mutation-proved

`testFirstThreePastOrdersMatchDesign` now scopes all nine strings to `orders.past.row.0/1/2`.
Scratchpad copy with the first three `seedPast` entries reversed (Sakura → Casa Lola → Forno) —
the mutation that stayed **green** in round 1:

```
OrdersUITests.swift:102: error: XCTAssertTrue failed
Test Case '…testFirstThreePastOrdersMatchDesign' failed (8.339 seconds).
```

Line 102 is `XCTAssertTrue(forno.staticTexts["Forno Bianco"].exists)`. Criterion 5's "in that
order" is now genuinely enforced.

Also mutation-tested a *layout*-order regression with the seed array untouched
(`ForEach(Array(viewModel.pastOrders.enumerated()).reversed(), …)`): the test failed at line 98
(`forno.waitForExistence`), because row 0 then renders below the fold. Caught — see the NIT below
about which assertion is doing the work.

## [WARNING 2] RESOLVED

`StarRatingView.init(score:outOf:accessibilityLabel:)` takes the copy as a closure;
`PastOrderRowView` supplies `{ filled, outOf in "\(filled) de \(outOf) estrellas" }` alongside the
other Spanish literals. No user-facing string remains in `DesignSystem/`. `OutlinedActionButton`
is correctly copy-free (`title:` parameter).

## [WARNING 3] RESOLVED

`filledStars(score:outOf:)` is a top-level `nonisolated func` (`DesignSystemViews.swift:245-247`)
covered by four tests in `PideYaTests/DesignSystemViewsTests.swift` — below zero, above `outOf`,
`4.5 → 5`, `4.0 → 4`. Exactly the four cases the doc comment promises, reachable from a
non-`@MainActor` suite.

## [WARNING 4] RESOLVED

The pre-formatted-dates rationale is now a `//` file-scope block at `OrdersModels.swift:10-16`,
directly above `private nonisolated let esES` and above the two types whose fields it describes.
It no longer attaches to `OrderStage`.

## [WARNING 5] RESOLVED

`PastOrderRowView` takes `index: Int` and exposes `orders.past.row.\(index)`
(`OrdersSubviews.swift:232, 243`); `OrdersUITests.pastOrderRowIdentifier(_:)` is a one-line string
interpolation with no `stableID` byte-tuple. `OrdersView.pastList:83` threads the index via
`ForEach(Array(viewModel.pastOrders.enumerated()), id: \.element.id)`.

**`ForEach` identity is intact.** The explicit `id: \.element.id` keypath means SwiftUI still
diffs on the seeded `UUID`, not on the enumeration offset — so no identity/index mismatch, no
spurious `LazyVStack` teardown, and `mockProviderIDsAreStableAcrossCalls` still guards the
stable-`UUID` invariant. The `index` is passed as plain data and affects only the a11y identifier.
`Array(_:)` materializes 12 tuples per body evaluation; irrelevant at this size.

**The new identifiers are stable in the right way.** They are positional, so they survive a
data-source swap (the point of W5) while still making criterion 5's row-content assertions
position-sensitive (the point of W1). No test depends on seed *content* through a selector any
more; only through assertions, which is where criterion 5 wants the coupling.

## DESIGN.md details — no regression

All six round-1 spot-checks re-verified after the refactor: segments 1-3 accent / segment 4
`Theme.Palette.outline` (`OrdersSubviews.swift:193`) ✓; only the current stage label accent, prior
stages `secondary` (:206) ✓; `Ver seguimiento`'s `.padding(.horizontal)` still precedes
`.frame(maxWidth:.infinity, minHeight:, alignment: .leading)` (:151-152) ✓; `ANTERIORES`
separators full content width with one after the last row and no thumbnail indent
(`OrdersView.swift:79-89`) ✓; zero corner radius ✓; `REPETIR` bordered with
`Theme.Palette.outline` — preserved through the move into `OutlinedActionButton`
(`DesignSystemViews.swift:283`) ✓; `Theme.Palette.surface` on the bolt button (:166) ✓.

I re-ran all four criterion-9 greps plus `try!|as!|catch {}` over the feature: all clean, `.font(`
matching only inside `ThemeFontModifier`.

---

# NICE TO HAVE (round 2 — none blocking)

- **[NIT] `PideYaUITests/OrdersUITests.swift:112-113`** — the two `XCTAssertLessThan(… frame.minY …)`
  comparisons are now tautological. Once identifiers became index-keyed (W5),
  `orders.past.row.N` *is* the Nth row emitted into a top-to-bottom `LazyVStack`, so
  `minY(row.0) < minY(row.1)` is guaranteed by construction. I tried to break it — reversing the
  render order while leaving the seed array alone — and the test failed one assertion earlier, at
  `forno.waitForExistence` (line 98), never reaching the `minY` lines. So criterion 5's ordering is
  really carried by the row-scoped *content* assertions, which are mutation-proved. Harmless
  redundancy; keep or drop, but do not mistake it for the load-bearing part.
- **[NIT] `PideYaUITests/OrdersUITests.swift:140-150`** — the `orders.rating` count is taken
  app-wide after scrolling to the bottom, so it depends on the `LazyVStack` still holding all 12
  materialized rows in the accessibility tree (recurring pattern: "scroll to the bottom, then
  assert on rows above"). It passes today and the mutation proves it catches the cascade, but a
  row-scoped form would be deterministic, need no scrolling, and catch the same bug:
  `XCTAssertEqual(fornoBiancoRow.descendants(matching: .any).matching(identifier: "orders.rating").count, 1)`.
- **[NIT] `PideYa/DesignSystem/DesignSystemViews.swift:245`** — `filledStars(score:outOf:)` is a
  top-level `internal` symbol with a very generic, un-namespaced name, now visible to every file in
  the app module. `StarRatingView.filledStars(score:outOf:)` as a `static` would keep it equally
  reachable from `@testable import PideYa` while keeping the module namespace clean.
- **[NIT] `PideYa/DesignSystem/DesignSystemViews.swift:255`** — `accessibilityLabel: (Int, Int) -> String`
  is more machinery than the job needs, and a stored function makes `StarRatingView` structurally
  non-comparable so SwiftUI can never skip its `body` via equality. Immaterial in practice (the
  enclosing `PastOrderRowView` already stores `onRepeat`), and the closure form does have the merit
  of handing the caller the *clamped* count rather than the raw score. The simpler
  `accessibilityLabel: String` remains a defensible alternative — reviewer's preference only.
- Round-1 NITs left unaddressed and still fine as-is: the double `if let rating … let ratingText`
  bind (`OrdersSubviews.swift:280`), `OrdersView.swift:16-18`'s doc comment wording about scroll
  position, `Theme.swift`'s `255 / 255`, and `seedActive`'s missing trailing comma. None blocking.

---

# Things done well in this round

- Critical 1 was fixed **at the root and proved to stay fixed**: restoring the `Optional.map` form
  under a non-`@MainActor` test suite converts a structural annotation into something a test can
  actually break. That is the correct answer to the "structural fixes are silently reversible"
  problem, and better than what the round-1 review asked for.
- Both critical fixes shipped **with the regression assertion attached**, and both assertions
  survived mutation testing with targeted failure messages (`("16") is not equal to ("8")`,
  `XCTAssertTrue failed` at the Forno Bianco content line).
- W1 and W5 were resolved **together** rather than independently: making the identifiers positional
  is what makes the row-scoped content assertions order-sensitive. That is a better outcome than
  either fix alone.
- The `ForEach(Array(…enumerated()), id: \.element.id)` form is the right one — index threaded as
  data, `UUID` retained as identity. The easy mistake here (`id: \.offset`) was not made.
- Inline comments were added at both former bug sites (`OrdersSubviews.swift:28-33` and
  `:282-286`) explaining *why* the identifier placement matters, so the next person does not undo
  it. `changes.md` deviation #1 now teaches the real rule instead of a cargo cult.

---

**VERDICT: APPROVED**
