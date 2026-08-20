# Cuenta tab — implementation changes

Implements `.claude/workflow/cuenta-tab/plan.md` in full (all 9 tasks, all 15 acceptance
criteria). All tasks are ticked `[x]` in `plan.md`.

## Files added

| File | Lines | Notes |
|---|---|---|
| `PideYa/Home/Account/AccountModels.swift` | 207 | Data model, formatting extensions, `AccountContentProviding` + `MockAccountContentProvider`. |
| `PideYa/Home/Account/AccountViewModel.swift` | 25 | `@MainActor @Observable` VM, constructor-injected provider, synchronous init. |
| `PideYa/Home/Account/AccountSubviews.swift` | 264 | `AccountHeaderView`, `AccountTileView`, `AccountTileGridView`, `AccountWalletView` + 4 `#Preview`s. |
| `PideYa/Home/Account/AccountView.swift` | 54 | Screen composition: header + grid + wallet in one `ScrollView`. |
| `PideYaTests/AccountTests.swift` | 221 | Swift Testing: 17 tests across 6 suites (model/formatting/chunking/mock suites deliberately not `@MainActor`). |
| `PideYaUITests/AccountUITests.swift` | 251 | XCUITest: 12 tests covering acceptance criteria 2–10, 12. |

## Files edited (additive only)

| File | Change |
|---|---|
| `PideYa/DesignSystem/Theme.swift` | + `Typeface.displayName` (34/heavy), `.caption` (11/regular), `.captionBold` (11/bold); + `Size.accountTile` (120). No existing token touched. |
| `PideYa/DesignSystem/DesignSystemViews.swift` | + `ChipView.Style.outlinedSubtle` (one arm added to each of 3 existing switches); + `EyebrowLabel`; + 2 `#Preview`s. No existing switch arm or behaviour changed. |
| `PideYa/Home/HomeTabViewModel.swift` | + `let account: AccountViewModel`, defaulted init parameter `account: AccountViewModel = AccountViewModel()`. `HomeTabViewModel()` still compiles with zero arguments. |
| `PideYa/Home/HomeTabView.swift` | + `case .cuenta: AccountView(viewModel: viewModel.account, bottomInset: tabBarHeight)` in the `selectedScreen` switch. |

`PideYa.xcodeproj/project.pbxproj` and `PideYa/PideYaApp.swift` are **not modified**
(`git diff --stat` for both is empty — verified below).

## Verification output

**1. Build — zero warnings**

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -scheme PideYa \
  -destination 'platform=iOS Simulator,name=iPhone 17'
...
** BUILD SUCCEEDED **
```
No `warning:` lines attributable to project code (the only line matching `warning:` in the log
is Xcode's unrelated `appintentsmetadataprocessor` boilerplate: "Metadata extraction skipped. No
AppIntents.framework dependency found." — present on a clean checkout before this feature too,
not a compiler warning).

**2. Full test suite**

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -scheme PideYa \
  -destination 'platform=iOS Simulator,name=iPhone 17'
...
** TEST SUCCEEDED **
```
`xcresulttool get test-results summary`: `"passedTests" : 84, "failedTests" : 0, "result" :
"Passed"` (84 rather than 55 + 29 = 84 exactly — the pre-existing 55 plus 17 new `AccountTests`
plus 12 new `AccountUITests`; the `devicesAndConfigurations` sub-count of 87 double-counts one
parametrized launch test run 4× and one performance-metrics run, which the top-level
`totalTestCount: 84` does not).

**3. Acceptance criterion 11 greps (run from repo root)**

```
$ rg -n '\.cornerRadius\(|RoundedRectangle\(|AnyView\(|ObservableObject|@Published|try\?|\.textCase\(' PideYa/ PideYaTests/ PideYaUITests/
(no matches)

$ rg -n '#[0-9A-Fa-f]{6}|Color\(red:|Color\.\w|\.white|\.black|\.gray|\.red' PideYa/ --glob '!PideYa/DesignSystem/Theme.swift'
(no matches)

$ rg -n '\.font\(' PideYa/Home/Account/
(no matches)

$ rg -n 'frame\(height: Theme\.Size\.accountTile|frame\(width: 120|height: 120' PideYa/Home/Account/
(no matches)

$ rg -n 'nonisolated extension' PideYa/Home/Account/AccountModels.swift
118:nonisolated extension AccountBadge {
135:nonisolated extension AccountProfile {
146:nonisolated extension AccountWallet {
153:nonisolated extension PaymentMethod {

$ rg -n '^extension ' PideYa/Home/Account/
(no matches)
```
All five checks pass exactly as specified.

**4. `swift-format lint`**

```
$(xcrun --find swift-format) lint --configuration .swift-format --recursive PideYa PideYaTests PideYaUITests
(no output — zero findings)
```

**5. `git status --porcelain` / pbxproj+App untouched**

```
 M PideYa/DesignSystem/DesignSystemViews.swift
 M PideYa/DesignSystem/Theme.swift
 M PideYa/Home/HomeTabView.swift
 M PideYa/Home/HomeTabViewModel.swift
?? PideYa/Home/Account/
?? PideYaTests/AccountTests.swift
?? PideYaUITests/AccountUITests.swift
?? .claude/workflow/cuenta-tab/   (was already untracked before this feature — plan.md/DESIGN.md
                                    themselves were never committed)

$ git diff --stat -- PideYa.xcodeproj/project.pbxproj PideYa/PideYaApp.swift
(empty)
```

## Deviations

Two real, empirically-driven deviations from the letter of the plan were required to make the
plan's own stated intent (an exact `Button` accessibility label/identifier, and a genuinely
measurable ≥120pt tile height) actually hold at runtime on this SDK (Xcode 17F113 /
iPhoneSimulator26.5 / iOS 17.6 deployment target). Both are documented here with the evidence
that led to them, per the brief's instruction to diagnose the real root cause rather than work
around a symptom.

1. **`AccountTileView` does not apply `.accessibilityElement(children: .ignore)`, contrary to
   plan §5's literal spec.** The plan specifies, for the tile button: `.accessibilityElement(children:
   .ignore)` + `.accessibilityLabel(...)` + `.accessibilityIdentifier(...)`. Implemented exactly
   as written, this compiled cleanly but produced a query mismatch at runtime, measured by the
   reviewer with a probe test that dumped every button, `otherElement` and `staticText`:
   `.accessibilityElement(children: .ignore)` layered on top of the `Button` makes SwiftUI
   synthesise **two** accessibility elements for the tile — the `Button`'s own node (empty
   identifier, auto-generated comma-joined label, `type=9`/`.button`) and a second, additional
   `.other` node (`type=1`) that carries the explicit `account.tile.perfil` identifier and the
   exact `"Perfil. Nombre, foto, direcciones"` label. `app.buttons.matching(identifier:
   BEGINSWITH "account.tile.")` resolves the former and returns `0`, because the identifier/label
   live on the latter, which does not carry the `.button` trait. **Both `.accessibilityLabel` and
   `.accessibilityIdentifier` did take effect** — just on the wrapper element, not on the
   control; `app.otherElements` would have found it with the exact label. This is also, in its
   own right, a VoiceOver defect (the tile is duplicated in the accessibility tree), an extra
   reason to have removed the modifier rather than change the test query to `app.otherElements`.
   The tile's inner `Text`s (`"Perfil"`, `"Nombre, foto, direcciones"`, etc.) remain reachable via
   `app.staticTexts` with or without `.ignore` — the dumped static-text trees are identical either
   way — so nothing was lost by dropping it. Removing `.accessibilityElement(children: .ignore)`
   (leaving `.accessibilityLabel` + `.accessibilityIdentifier` directly on the `Button`, exactly
   the pattern already shipped and tested in `OrdersSubviews.swift`'s `quickActionButton`, lines
   160–171) fixed this immediately and reproducibly, because a `Button` already collapses its own
   subtree into a single accessibility element by default — that is the entire reason
   `quickActionButton` never needed `.accessibilityElement` in the first place. **The reusable
   rule: never layer `.accessibilityElement(children:)` on a view that is already a control.** It
   synthesises a new element for the modified subtree that does not inherit the control's trait,
   so the identifier/label move off the queryable element while duplicating it in the tree.
   Fixed for all six tiles in `AccountSubviews.swift`; verified by
   `testSixTilesHaveExactLabelsAndUniqueIdentifiers` and the four other tests that depend on
   `account.tile.*` identifiers/labels, all passing.

2. **`AccountTileView`'s `.frame(...)` gained an explicit `minHeight: Theme.Size.accountTile` and
   a trailing `.contentShape(Rectangle())`.** The `.contentShape(Rectangle())` addition is load-
   bearing and was the sole cause of the original failure: with only the row-level
   `.frame(minHeight:)` from plan §5 and no `.contentShape`, `testGridIsTwoEqualColumnsAtDefaultTextSize`
   measured `perfil.frame` as `(16.0, 240.33, 136.0, 66.00)` — collapsed in **both** axes (x=16 not
   0, width=136 not 200), the signature of hit-test/accessibility geometry tracking the label's
   ink rather than the padded frame box. Adding `.contentShape(Rectangle())` alone, with the
   row-level `minHeight` still in place and no tile-level `minHeight`, is sufficient to fix the
   measurement: frame becomes `(0.0, 222.33, 200.0, 119.99999999999997)` and both grid tests pass.
   It is also a real hit-target fix, not just a measurement one — without it, taps on the empty
   lower half of a tile miss.

   The row-level `.frame(minHeight: Theme.Size.accountTile)` on `AccountTileGridView.rowView`'s
   `HStack` **has since been removed**, and the tile-level `minHeight` kept as the single floor —
   but this is a deliberate **choice of layer**, not a required fix. Both layers independently
   produce a 120pt tile: with only the row-level frame (tile-level `minHeight` absent), the tile
   still measures 120.0 and passes; with only the tile-level frame (row-level absent), it also
   measures 120.0 and passes. The earlier claim that a row-level `.frame(minHeight:)` inside a
   `ScrollView` does not propagate its proposed height down to the row's children was **wrong**:
   `.frame(minHeight:)` does resolve its own height and propose it down, and the tile's
   `maxHeight: .infinity` consumes it. The tile-level `minHeight` was kept, and the row-level one
   dropped, because the tile-level floor makes a *single* tile honour DESIGN.md §4.1's 120pt even
   outside a row — not because the row-level one was inadequate. Keeping only one floor (rather
   than both, as the working tree briefly had) avoids a comment/code state where two independent
   120pt floors coexist, each documented as if the other did not work.
   `AccountTileGridView.rowView`'s `HStack` now carries no `.frame` modifier of its own. Verified
   by `testGridIsTwoEqualColumnsAtDefaultTextSize` and `testGridCollapsesToOneColumnAtAccessibilitySize`,
   both passing, with the criterion-11 grep for fixed 120pt frames still returning no matches (a
   `minHeight`, never a `height`, is used).

   One follow-on, purely cosmetic adjustment: the resulting measured height on-device is
   `119.99999999999997`, not exactly `120.0` — floating-point rounding noise from the
   point→pixel→point round trip, not a real 3×10⁻¹⁴pt deficit. `AccountUITests` asserts
   `perfil.frame.height >= 120 - 0.1` rather than `>= 120` to absorb this; this tolerance is
   documented inline in the test and does not weaken the check in any way a visual or Dynamic
   Type regression could hide behind.

3. **Two doc-comment wordings were adjusted to avoid false-positive self-matches against
   criterion 11's own load-bearing greps** — not a deviation from the plan's *behaviour*, but
   worth recording since it is exactly the trap DESIGN.md's plan calls out ("this exact pattern
   was verified empty against the pre-feature tree… the pattern matches the prose in
   `Theme.swift:14`… and the criterion fails on an untouched checkout — which is what happened in
   `pedidos-tab`"). `EyebrowLabel`'s doc comment originally read `` `.textCase(.uppercase)` `` (a
   literal match for the `\.textCase\(` grep) and was reworded to describe the same fact in prose
   without the literal call syntax. `AccountModels.swift`'s file-header comment originally wrote
   out `` `nonisolated extension X { … }` `` verbatim (a literal match for the `nonisolated
   extension` grep, producing a 5th match against the 4 real extension blocks) and was reworded
   to reference "that keyword" instead of repeating the token pair. Both greps now return exactly
   the intended matches (zero and four, respectively) — verified above.

No other deviations. All 15 acceptance criteria hold as measured above; the test plan's full
table of unit and UI tests is implemented one-to-one by name.

## Review fixes

Everything below responds to `.claude/workflow/cuenta-tab/review.md` §2 (2 WARNINGs, 9 NITs).

**WARNINGs**

- **`AccountSubviews.swift:70-78` (with `:153`) — two independent 120pt floors, one comment
  wrong.** Fixed: removed the row-level `.frame(minHeight: Theme.Size.accountTile)` from
  `AccountTileGridView.rowView`'s `HStack` (it is no longer present anywhere in the file — grep
  confirms), kept the tile-level floor as the single source of the 120pt requirement, and
  rewrote the comment at `AccountTileView`'s `.frame`/`.contentShape` to state only what the
  reviewer's mutation testing actually measured: the tile-level `minHeight` is the design's
  120pt floor kept at the tile layer by choice (so a lone tile honours it outside a row), and
  `.contentShape(Rectangle())` is what makes the measured/hit-test frame match that box — not a
  claim that the row-level frame "doesn't propagate."
- **`changes.md` (Deviations §2) — two factual errors.** Fixed: rewrote Deviation 2 in full (see
  above) to (i) state correctly that the row `HStack` now carries no `.frame` modifier — true as
  of this fix, not before it — and (ii) attribute the original 66pt failure solely to the missing
  `.contentShape(Rectangle())`, with the "row `minHeight` doesn't propagate" claim removed and
  replaced by the measured fact that either layer alone produces a 120pt tile.

**NITs**

- **Deviations §1 wording** — replaced the inaccurate "neither `.accessibilityLabel` nor
  `.accessibilityIdentifier` was taking effect" with the measured truth (both took effect, on a
  synthesised `.other` element without the `.button` trait) and added the reusable rule: never
  layer `.accessibilityElement(children:)` on a view that is already a control. Done in the
  rewritten Deviation 1 above.
- **`AccountModels.swift:15-20` / `AccountTests.swift:143-146` — runtime-trap wording.** Fixed:
  both comments now say dropping `nonisolated` stops the nonisolated test suites from compiling
  (a compile-time error, for this file specifically), and keep the general runtime-trap note only
  as the reason the project-wide rule (DESIGN.md §8.8) exists on other call shapes.
- **`AccountUITests.swift:226-228` — vacuous `if header.exists` guard.** Fixed:
  `testHeaderScrollsAndIsNotPinned` now asserts the disjunction explicitly
  (`!header.exists || header.frame.minY < originalHeaderMinY`) and additionally asserts
  `account.grid`'s `minY` decreased, so "nothing scrolled at all" cannot pass either path.
- **`AccountUITests.swift:206` — thin 0.67pt inset guard.** Fixed: added an explicit footer
  assertion (`footer.frame.maxY <= tabBar.frame.minY - 4`) alongside the existing sign-out button
  check, so a small spacing tweak can no longer hide a regression the way a flush `<=` on the
  button alone could.
- **`AccountTests.swift:189-194` — `mockPagosSubtitleIsDerivedFromTheSameWallet` could pass with
  a hardcoded literal.** Fixed: exposed `MockAccountContentProvider.paymentMethod()` and the test
  now asserts `pagos?.subtitle == provider.paymentMethod().summaryText(wallet: provider.wallet())`,
  which no hardcoded string can satisfy by accident.
- **`AccountSubviews.swift:211-217` — `.lineLimit(1)`/`.layoutPriority(1)` applying in both
  balance-row branches.** Fixed: confined to the `HStack` (non-accessibility-size) branch only;
  the accessibility-size `VStack` branch has full-width room and now wraps rather than truncates.
- **`AccountSubviews.swift:230` — hardcoded footer string will drift from
  `CFBundleShortVersionString`.** Deliberately left unchanged. The reviewer filed this as a note
  for the follow-up localization/string-catalogue list, not a change request — it matches
  DESIGN.md §5 and versioning/localization is out of this feature's scope.
- **`AccountSubviews.swift:122-127` — `rows` recomputed per access inside `body`.** Fixed:
  hoisted `let rows = rows` at the top of `AccountTileGridView.body`, so `AccountTileRow.rows(from:
  columns:)` runs once per render instead of once per `ForEach`/count access.
- **`AccountModels.swift:82-90` — `AccountTile.id == kind.rawValue` breaks under duplicate
  kinds.** Fixed: documented the uniqueness precondition directly on
  `AccountContentProviding.tiles()` (a duplicate `kind` produces two equal `ForEach` ids in
  `AccountTileGridView`) rather than adding defensive de-duplication, per the reviewer's
  "cheapest fix" recommendation — unreachable from the shipped mock.

**Re-verification after the review fixes above** (build 0 warnings; `xcresulttool get
test-results summary`: `"passedTests": 84, "failedTests": 0, "totalTestCount": 84` — same count as
the pre-fix baseline, no regression; both grid tests
(`testGridIsTwoEqualColumnsAtDefaultTextSize`, `testGridCollapsesToOneColumnAtAccessibilitySize`)
pass with the row-level frame removed; all five criterion-11 greps unchanged; `swift-format lint`
zero findings; `git status --porcelain` byte-identical to the original 4 modified + 3 untracked
paths).

BUILD: PASS
TESTS: 84 passed / 0 failed
