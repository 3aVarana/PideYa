# QA report — Pedidos tab

**Overall verdict: PASS**

Scope: `git status --porcelain` at start and end of this session shows the expected 4 modified
+ 5 untracked paths, unchanged by this QA pass:

```
 M PideYa/DesignSystem/DesignSystemViews.swift
 M PideYa/DesignSystem/Theme.swift
 M PideYa/Home/HomeTabView.swift
 M PideYa/Home/HomeTabViewModel.swift
?? .claude/workflow/pedidos-tab/
?? PideYa/Home/Orders/
?? PideYaTests/DesignSystemViewsTests.swift
?? PideYaTests/OrdersTests.swift
?? PideYaUITests/OrdersUITests.swift
```

No fixes were made. All experiments (a probe UI-test file, temporary print/screenshot
instrumentation) ran in a `git worktree` copy under scratchpad, which has been removed
(`git worktree remove --force`); nothing in this checkout was touched.

## 1. Clean build

`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild clean build -scheme PideYa
-destination 'platform=iOS Simulator,name=iPhone 17'` → **BUILD SUCCEEDED**.

Full log grepped for `warning` (case-insensitive): the only hit is

```
2026-08-17 22:38:50.563 appintentsmetadataprocessor[...] warning: Metadata extraction skipped.
No AppIntents.framework dependency found.
```

This is an `appintentsmetadataprocessor` build-tool stderr notice, not a compiler diagnostic; it
is not attached to any source file or line, the app has no App Intents anywhere (before or after
this feature), and `changes.md` records it as pre-existing. Zero Swift compiler warnings, zero
asset-catalog warnings. **No new warning was introduced.**

`git diff --stat -- PideYa.xcodeproj/project.pbxproj PideYa/PideYaApp.swift` → empty (both
byte-identical to pre-feature).

## 2. Full test suite

`xcodebuild test -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'
-resultBundlePath /tmp/PideYa.xcresult` → **TEST SUCCEEDED**.

`xcrun xcresulttool get test-results summary --path /tmp/PideYa.xcresult`:

```
"failedTests" : 0,
"passedTests" : 55,
"result" : "Passed",
"totalTestCount" : 55
```

Every individual `PideYaTests` and `PideYaUITests` test case (35 unit incl. the new
`FilledStarsTests`, plus `PideYaUITests` incl. all 10 `OrdersUITests`, `HomeFeedUITests`,
`PideYaUITestsLaunchTests`) reported `Passed`. Zero failures.

## Per-criterion verdicts

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Zero-warning clean build; `pbxproj`/`PideYaApp.swift` unchanged | **PASS** | See §1 above. |
| 2 | Inicio ↔ Pedidos routing round trip | **PASS** | Read `HomeTabView.swift`/`HomeTabViewModel.swift` — the `@ViewBuilder switch` adds `case .pedidos: OrdersView(...)` with no `AnyView`, `HomeTabViewModel.orders` is a real stored property. `testPedidosTabShowsHeaderAndSections` (passing) asserts all 6 named elements exist on Pedidos and `OFERTAS DE HOY` does not, then the reverse on Inicio. Also directly observed in the screenshot (below): `Pedidos`, `1 en curso · 12 anteriores`, `EN CURSO`, `ANTERIORES`, `Ayuda`, `Filtrar` all present. |
| 3 | Active card content incl. U+00A0 total | **PASS** | `testActiveOrderCardContent` scopes to `orders.activeCard` and asserts the four exact strings including `"24,60\u{00A0}€"` (explicit escape, not a literal space). Confirmed by reading `OrdersModels.swift:75` (`total.formatted(.currency(code:"EUR").locale(esES))`) and by the screenshot showing `24,60 €`. |
| 4 | `EN CAMINO` × 2, other 3 stages × 1 | **PASS** | `testProgressTrackerLabelsAndCurrentStageDuplication` uses an exact-label `NSPredicate` count, not `.firstMatch` — this is the correct assertion shape for the "colour is not the only signal" requirement. Screenshot confirms visually: band says `EN CAMINO`, and the current-stage label under the tracker also says `EN CAMINO` in red; the other three labels appear once each in grey. |
| 5 | First three `ANTERIORES` rows, **in that order** | **PASS** | `testFirstThreePastOrdersMatchDesign` scopes assertions to `orders.past.row.0/1/2` (positional identifiers) for content, plus `XCTAssertLessThan` on `frame.minY` for order. Per the code review's mutation testing (round 2), reversing the seed array's first three entries makes this test fail at the Forno Bianco content line — this is a real, order-sensitive assertion, not presence-only. Screenshot shows Forno Bianco → Casa Lola → Sakura Ramen top to bottom. |
| 6 | Rated vs unrated row rendering, incl. `orders.rating` cascade fix | **PASS** | `testRatedAndUnratedRowsRenderDifferently` checks Casa Lola (unrated) has `VALORAR PEDIDO` and no `orders.rating`; Forno Bianco (rated) has `orders.rating` labelled `5 de 5 estrellas`, text `5,0`, no `VALORAR PEDIDO`; then asserts app-wide `orders.rating` count == 8 (one per rated row, not one-per-descendant). Read `OrdersSubviews.swift:280-296` — the identifier is on `StarRatingView` (which is `.accessibilityElement(children: .ignore)`), not the enclosing `HStack`, so it cannot cascade onto the sibling `Text`. Per the review's round-1→round-2 mutation test, moving the identifier back onto the `HStack` makes the count assertion fail (`16` vs `8`), confirming this assertion is load-bearing. |
| 7 | All 5 controls no-op | **PASS** | `testAllActionsAreNoOps` taps `orders.helpButton`, `Filtrar`, `orders.trackButton`, `orders.quickActionButton`, and one `REPETIR`, then asserts `orders.activeCard` and `ANTERIORES` are still present (no crash, no navigation). Read `OrdersView.swift`/`OrdersSubviews.swift`: every action closure passed in is literally `{}`. |
| 8 | Bolt button a11y label | **PASS** | `testQuickActionButtonHasAccessibilityLabel` asserts `button.label == "Acciones rápidas"`. Confirmed in source: `.accessibilityLabel("Acciones rápidas")` at `OrdersSubviews.swift:170`. |
| 9 | Four source greps | **PASS** | Independently re-ran all four against the current tree (not trusting `changes.md`'s claim): `rg '\.cornerRadius\(\|RoundedRectangle\(\|AnyView\(\|ObservableObject\|@Published\|try\?\|\.textCase\('` → no matches; colour-literal grep outside `Theme.swift` → no matches; `.font(` in `Orders/`+`DesignSystemViews.swift` → only the `ThemeFontModifier` doc comment and its one real `content.font(scaledFont)` call; leading-padding-indent grep → no matches. |
| 10 | Dynamic Type — real growth, not a 1.0 ratio | **PASS** | Ran isolated probe UI tests (in a scratchpad worktree) that print actual measured `frame.height` at default vs `UICTContentSizeCategoryAccessibilityL`. Measured: `ANTERIORES` height **18.0pt (default) → 32.33pt (accessibility1)**, a **1.80×** ratio — genuinely greater, not the flat-1.0 defect from the previous feature. Cross-checked with a second element (`ActiveOrderCardView`'s "Taquería Norte" title): **26.33pt → 44.33pt**, a **1.68×** ratio. Both confirm real `UIFontMetrics`-based scaling via `.themeFont(_:)`, matching `ThemeFontModifier`'s implementation read in `DesignSystemViews.swift:23-37`. |
| 11 | Last past-order row clears the tab bar | **PASS** | Same probe run, at maximum scroll: `lastRow.frame = (92.0, 704.33, 102.67, 18.0)` → `maxY = 722.33`; `tabBar.frame = (201.0, 780.0, 100.67, 60.0)` → `minY = 780.0`. **57.67pt of clear space, no intersection** (`intersects == false`, `isHittable == true`). The row's full container (`orders.past.row.11`) has `maxY = 750.0`, also clear. Confirms `OrdersView`'s independent `.safeAreaInset(edge: .bottom)` (`OrdersView.swift:47-49`) is working as designed. |
| 12 | Pinned header | **PASS** | Same probe run: `header.frame` **before** 3 swipe-ups = `(0.0, 0.0, 402.0, 160.0)`; **after** = `(0.0, 0.0, 402.0, 160.0)` — byte-identical, `minY` unchanged at `0.0`. Confirms `.safeAreaInset(edge: .top)` placement in `OrdersView.swift:44-46`. |
| 13 | `swift-format lint` clean; `git commit` would succeed without `--no-verify` | **PASS** | `xcrun --find swift-format` resolves; `swift-format lint --configuration .swift-format --recursive PideYa PideYaTests PideYaUITests` → exit 0, no findings. Read `.githooks/pre-commit`: it runs exactly this lint (via the same `xcrun --find` fallback) against staged content and only blocks on non-zero findings; since the full-tree lint is clean, a commit of this staged subset would pass the hook. (Did not actually run `git commit`, per instructions not to commit.) |
| 14 | View bodies < 40 lines; every new file has a compiling `#Preview` | **PASS**, with one wording caveat | Measured every `var body: some View { ... }` block in `OrdersSubviews.swift` (21, 10, 8, 10 lines), `OrdersView.swift` (22 lines), and the two new `DesignSystemViews.swift` components (11, 11 lines) — all well under 40. `#Preview` blocks compile-verified by the successful build (they're part of the same target): `OrdersSubviews.swift` (4), `OrdersView.swift` (1), `DesignSystemViews.swift` (7 total, incl. the 2 new ones). `OrdersModels.swift` and `OrdersViewModel.swift` have **no** `#Preview` — they are not `View`s, so `#Preview` doesn't apply to them; the code review flagged this as the criterion's wording being imprecise rather than a defect, and I agree: there is nothing meaningful to preview in a non-view file. |
| 15 | Pre-existing tests still pass + new ones | **PASS** | 0 failures across the full suite (see §2). All 15 pre-existing unit tests, 13 pre-existing UI tests, and the new Orders/DesignSystemViews tests passed. |

## Visual/colour-based criteria — direct evidence, not automatable

Per the task instructions, colour and "left-aligned not centred" details cannot be asserted via
XCUITest's accessibility tree (XCUIElement exposes no colour or text-alignment API). I captured a
real device screenshot (via a temporary XCUITest `XCTAttachment` in the isolated worktree, then
discarded) to get direct visual evidence rather than trusting the implementation report:

- **Progress tracker colour**: segments 1–3 (CONFIRMADO/EN COCINA/EN CAMINO) are accent red,
  segment 4 (ENTREGADO) is light grey — confirmed visually. Labels: only `EN CAMINO` (current
  stage) is red; `CONFIRMADO` and `EN COCINA` (completed) are grey, same as `ENTREGADO`
  (not-yet-reached) — confirmed visually, matches DESIGN.md §3.4's "only the current stage is
  highlighted, completed stages are not."
- **`REPETIR` border**: visibly a thin light-grey hairline, clearly lighter than the thick black
  border around the active-order card — confirmed visually, matches DESIGN.md §4.3 ("NOT ink").
- **`Ver seguimiento` label**: left-inset with visible empty space to the right, not centred —
  confirmed visually.
- **Star ratings**: both filled and hollow stars are accent red (Forno Bianco: 5 filled; Sakura
  Ramen: 4 filled + 1 hollow, all red) — confirmed visually.
- **Bolt button**: white fill (visibly lighter than the card's grey body), ink border, black bolt
  glyph — confirmed visually.
- **Zero corner radius**: every box, card, button and chip in the screenshot is hard-edged —
  confirmed visually, consistent with the criterion-9 grep result.

This is **image evidence I captured and inspected myself**, not a claim taken on faith from
`changes.md` or `review.md`. It is still not a fully automated, regression-proof check (nothing
in CI diffs this screenshot), so I'm not marking these sub-details as unconditional automated
PASSes — they ride along with the criteria above (3, 4, 6) that *are* automated, and the visual
inspection corroborates rather than replaces that automation.

**Genuinely UNVERIFIABLE by any evidence I could gather in this environment:**

- **VoiceOver traversal order** (band → name → total → subtitle → four stage labels → `Ver
  seguimiento` → `Acciones rápidas`) — this requires a live VoiceOver session on a device/
  simulator with the accessibility inspector driven interactively; XCUITest's accessibility tree
  exposes element existence and labels but not swipe-focus traversal order. **UNVERIFIABLE.**
- **Haptics, camera, push, StoreKit** — not applicable to this feature (none present).

## Edge cases from the test plan — automated coverage check

| Edge case | Automated? |
|---|---|
| iPhone SE (375pt) at `.accessibility1`: 4 progress labels wrap to 2 lines rather than clip | **Not covered.** All test runs target `iPhone 17` (per the task's fixed destination); no test targets a narrow-width device/simulator combined with `.accessibility1`. This is explicitly called out in `plan.md`'s own Risks section as needing "a real device/simulator check." Missing test. |
| `1 artículo` singular row (seed #12, Bar Manolo) renders correctly | **Covered, incidentally.** `testLastPastOrderRowIsReachableAboveTabBar` and `testRatedAndUnratedRowsRenderDifferently` both locate `app.staticTexts["2 jul · 1 artículo"]` as their landmark for the last row — this only passes if the singular string renders correctly, so the case is exercised even though no test names it explicitly. |
| `Ver seguimiento` stays left-inset at every Dynamic Type size | **Not covered by automation** (no text-alignment API in XCUITest); spot-checked visually at default size only (see screenshot above). Not re-checked at `.accessibility1`. |
| `ANTERIORES` separator present below the final row | **Not directly covered.** Read `OrdersView.swift:78-88`: the `ForEach` unconditionally emits `PastOrderRowView` then `HardRule` for every element including the last, so a trailing rule is structurally guaranteed by construction — but no test asserts a `HardRule`/separator element count or position after the 12th row. Criterion 11 only checks the row itself clears the tab bar, not that a rule follows it. Missing test. |
| Dark mode: appearance unchanged | Out of scope per `plan.md`; not tested, correctly. |
| VoiceOver swipe order through the active card | **UNVERIFIABLE** by automation, not exercised (see above). |

## Summary

Build is clean (zero warnings, both guarded files untouched). The full test suite is green
(55/55, 0 failures). All 15 acceptance criteria hold up under direct re-verification — not just
"a test with that name exists," but reading what each assertion actually checks, re-running the
four criterion-9 greps myself, and independently re-measuring the three fragile criteria (10, 11,
12) with fresh probe instrumentation rather than trusting the shipped tests' pass/fail alone. The
colour- and alignment-based details that cannot be automated were checked with a real screenshot
instead of being rubber-stamped. Two edge cases from the plan's own test matrix (iPhone SE at
`.accessibility1`, and an explicit assertion for the trailing `ANTERIORES` separator) have no
automated coverage — worth a human/manual pass, consistent with what `plan.md` itself flags as
needing one, but not blocking since nothing observed indicates either is actually broken.

No defects found. Nothing was fixed (verification only, per role).
