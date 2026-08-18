# QA Verification — Home Tab shell + Feed screen

Verifier: independent QA pass, run after code review APPROVED.
Environment: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (CommandLineTools was
the default `xcode-select` path; used the CLAUDE.md fallback). Simulator: iPhone 17 (UDID
`5DE766C0-2D33-489C-9CC6-A20AA1461893`), iOS 26.5. Everything below was reproduced myself, not
taken on trust from `changes.md` / `review.md`.

## 1. Clean build

```
xcodebuild clean build -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'
```
**BUILD SUCCEEDED.** Grepped the full log for `warning` case-insensitively: the only hits are
(a) the literal `--warnings`/`--notices` flags inside the `actool` invocation command lines
(not diagnostics), and (b) one unrelated info-level line —
`appintentsmetadataprocessor ... warning: Metadata extraction skipped. No AppIntents.framework
dependency found.` — which is not a compiler warning and predates/is unrelated to this feature.
**Zero compiler warnings introduced.**

Re-ran a second `xcodebuild build` (no `clean`) at the very end, after removing my temporary QA
test file (see §5), to confirm the tree still builds clean post-cleanup. Also succeeded.

`git diff HEAD -- PideYa/PideYaApp.swift PideYa.xcodeproj/project.pbxproj` → empty both times.
Criterion 1 and criterion 10 confirmed independently.

## 2. Full test suite

```
xcodebuild test -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:PideYaTests -resultBundlePath /tmp/.../PideYaTests.xcresult
```
**TEST SUCCEEDED — 16/16.** (`MockFeedContentProviderTests`, `HomeTabViewModelTests`,
`FeedFormattingTests`, `FeedViewModelTests`, `PideYaTests`.)

```
xcodebuild test -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:PideYaUITests -parallel-testing-enabled NO -resultBundlePath /tmp/.../PideYaUITests.xcresult
```
**TEST SUCCEEDED — 11/11**, no flakes, no "Busy" simulator-contention failure on this run (ran
once with `-parallel-testing-enabled NO` per the launch instructions; did not need a retry).

`xcrun xcresulttool get test-results tests --path .../PideYaUITests.xcresult` breakdown, all
`Passed`:
- `HomeFeedUITests`: `testCarouselPeekRatioAndHorizontalSwipeRevealsSecondCard`,
  `testChipCountsPerRecommendationRow`, `testLaunchShowsStaticFeedTextsAndSearchPlaceholder`,
  `testRecommendationFeesUseNonBreakingSpaceBeforeEuroSign`,
  `testTabBarIdentifiersExistAndInicioIsSelected`,
  `testTabRoundTripSwapsInicioAndPlaceholderContent`.
- `PideYaUITests.testLaunchPerformance`, `PideYaUITestsLaunchTests.testLaunch` × 4 device
  configurations (template tests).

## 3. Acceptance criteria — walked individually

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Clean build, 0 warnings, pbxproj untouched | **PASS** | §1 above; `git diff` on pbxproj empty |
| 2 | Static texts + search placeholder present at launch | **PASS** | `testLaunchShowsStaticFeedTextsAndSearchPlaceholder` passed; visually confirmed in `01-initial.png` screenshot (PIDEYA, VA, Calle Mayor 44, OFERTAS DE HOY, Ver todas, RECOMENDADOS PARA TI, Según tus últimos pedidos, search placeholder all present) |
| 3 | `tabbar.*` identifiers exist/hittable, `inicio` selected | **PASS** | `testTabBarIdentifiersExistAndInicioIsSelected` passed; screenshots show Inicio in red (selected) with the other three in black |
| 4 | Buscar↔Inicio round-trip shows/hides content | **PASS** | `testTabRoundTripSwapsInicioAndPlaceholderContent` passed (mutation-tested per `review.md`, independently re-run here); my own screenshot capture (`04-buscar-placeholder.png` → `07-back-to-inicio.png`) confirms visually: OFERTAS DE HOY disappears on Buscar, full feed (including offers carousel) is restored byte-for-byte on returning to Inicio |
| 5 | es-ES fee/rating strings incl. NBSP before € | **PASS** | `testRecommendationFeesUseNonBreakingSpaceBeforeEuroSign` passed against the corrected plan text (`\u{00A0}`); unit tests `deliveryFeeTextFormatsAsEuroWithComma`, `ratingTextUsesCommaDecimalSeparator` passed; screenshots show `1,90 €`, `2,50 €`, `0,00 €`, `4,8`, `4,7`, `4,9` |
| 6 | Chip counts (Casa Lola=1, Taquería Norte=2) | **PASS** | `testChipCountsPerRecommendationRow` passed; confirmed visually — Taquería Norte row shows outlined `25-35 min` + pale-red `-40%`; Casa Lola row's rendered content in my own screenshots shows only its ETA chip's row container with no visible second chip |
| 7 | Carousel peek 55–70%, second card revealed on scroll | **PASS** | `testCarouselPeekRatioAndHorizontalSwipeRevealsSecondCard` passed; visually the first card (`Taquería Norte`) occupies ~56–60% of screen width in the screenshot with `Forno Bianco` visibly peeking off the right edge |
| 8 | Colour/API greps clean | **PASS** | Re-ran both greps myself: `rg 'AnyView\|cornerRadius\|RoundedRectangle\|ObservableObject\|@Published\|try\?' PideYa/` → one hit, the `Theme.swift:13` doc comment only. `rg -n '#[0-9A-Fa-f]{6}\|Color\(red:\|Color\.\w\|\.white\|\.black' PideYa/ --glob '!PideYa/DesignSystem/Theme.swift'` → no matches |
| 9 | `swift-format lint` clean | **UNVERIFIABLE** | `swift-format` and `swiftlint` are confirmed absent (`which` returns nothing), consistent with CLAUDE.md's "Tooling Not Yet Installed." Per the task's explicit instruction, did **not** install it. Cannot be verified in this environment; manual style spot-checks (4-space indent, no force-unwrap/`try!`, no block comments, ASCII identifiers) turned up nothing across the touched files |
| 10 | `PideYaApp.swift` byte-identical to `main` | **PASS** | `git diff HEAD -- PideYa/PideYaApp.swift` empty, re-verified twice (before and after my temporary test file was added/removed) |
| 11 | Every `body` < 40 lines, every file has a compiling `#Preview` | **PASS** | Measured every `var body` block by hand: max 17 lines (`FeedView.swift`). `#Preview` present in `DesignSystemViews.swift` (5), `FeedSubviews.swift` (3), `FeedView.swift` (1), `HomeTabBar.swift` (2), `HomeTabView.swift` (1); build succeeded, which compiles previews too. `Theme.swift`, `FeedModels.swift`, `FeedViewModel.swift`, `HomeTabViewModel.swift` have no preview (no `View` in them), matching the review's reading of "every view file" |

**10 of 11 criteria PASS, 1 UNVERIFIABLE (tooling absent by design, not a defect).**

## 4. Visual verification on the simulator

Booted iPhone 17, installed the built `.app`, launched, and captured real on-device
screenshots — both a single manual `simctl io screenshot` and a set of automated screenshots
via a temporary throwaway XCUITest (added, run, exported, and deleted — see §5) since this
sandbox has no touch-injection tool (no `idb`, no `cliclick`; `Quartz`/PyObjC unavailable;
AppleScript/System Events GUI scripting times out with no accessibility permission granted).
The temporary test let me reach real scrolled and tab-switched states rather than relying on a
single static screenshot.

Point-by-point against `DESIGN.md`:

- **Pinned header, does not scroll**: Confirmed. Across every scroll position I captured (top,
  mid, forced-to-max-scroll), the header (`PIDEYA`, `VA` box, address row, search field) sits
  at identical pixel coordinates. `.safeAreaInset(edge: .top)` is doing its job.
- **Zero corner radius everywhere**: Confirmed visually — avatar box, search field, offer
  cards, hatched placeholders, chips are all hard rectangles.
- **Red offer band**: Confirmed — full-width red band, white uppercase bold text
  (`-40% · HASTA LAS 23:00`, `2X1 EN PIZZAS`), left-aligned with padding, matches `DESIGN.md`.
- **Carousel peek**: Confirmed. First card occupies roughly 56–60% of the 402pt-wide screen
  (matches the `testCarouselPeekRatioAndHorizontalSwipeRevealsSecondCard` 55–70% assertion);
  the second card (`Forno Bianco`) is visibly cut off at the right edge before scrolling.
- **Inset row dividers (not full-bleed)**: Confirmed — the thin gray rule between
  `Taquería Norte` and `Forno Bianco` rows starts at the text column, not under the thumbnail.
- **Outlined ETA chip + pale-red promo chip pair**: Confirmed — `Taquería Norte` shows a
  black-outlined `25-35 min` chip and a pale-red/red-text `-40%` chip side by side, matching
  spec exactly (`ChipView.Style.outlined` / `.promo`).
- **Casa Lola has only one chip**: Confirmed by the automated test (`.staticTexts.count == 1`
  inside `chips.Casa Lola`) — see the caveat below about whether that chip is actually visible
  above the tab bar.
- **Comma decimal separators**: Confirmed — `4,8`, `4,7`, `1,90 €`, `2,50 €`, `0,00 €` all
  render with commas, matching es-ES formatting.
- **Tab bar — Inicio in red, hard rule on top**: Confirmed — a solid 1px black rule spans the
  full width directly above the tab bar row in every screenshot; `Inicio` is red with the house
  icon red when selected, the other three tabs render in black/dark gray with red applied only
  to whichever tab is currently selected (confirmed for Buscar, Pedidos, and Cuenta each in
  turn).
- **Placeholder tabs**: `Buscar` / `Pedidos` / `Cuenta` each render a centered
  `ContentUnavailableView` with the tab's icon, title, and "Próximamente." — matches spec, no
  detail screens leaked in. (One cosmetic note: a screenshot taken immediately after the tap
  sometimes catches the `ContentUnavailableView`'s entrance fade mid-animation, at very low
  opacity. This is a transient rendering timing artifact of screenshotting mid-transition, not
  a persistent bug — the automated tests, which wait via `waitForExistence`, are unaffected.)

### New defect found during visual/interactive verification

**[DEFECT] The last recommendation row (`Casa Lola`) is not fully reachable above the tab
bar.** `plan.md:322-323` states the shell must use `.safeAreaInset(edge: .bottom)` "so the last
recommendation row is reachable rather than permanently hidden behind the bar" — this is an
explicit, named requirement, not incidental. I scrolled to the maximum extent two independent
ways (a targeted content-area drag gesture repeated 10×, and the shipped test's own
`app.swipeUp()` technique repeated well beyond its 6-swipe budget) and measured element frames
directly rather than eyeballing:

```
chips.Casa Lola  frame = (100.0, 788.33, 84.0, 23.67)   → y-range [788.33, 812.0]
tabbar.inicio    frame = (0.0, 780.33, 100.67, 59.33)   → y-range [780.33, 839.67]
```

`chips.Casa Lola`'s frame is entirely inside the tab bar's vertical span, and
`isHittable == false` at the true scroll maximum (confirmed stable — 10 additional swipes past
that point produced the identical frame). The `0,00 €` fee text is visible (its frame ends at
y=756.4, above the tab bar), but Casa Lola's ETA chip (`20-30 min`) — its only chip — is
rendered directly underneath the opaque tab bar and is neither visible nor tappable. Screenshot
evidence: the "scrolled to bottom" captures consistently show the `Casa Lola` row cut off right
after its subtitle line (`Casera · ★ 4,9`), with no chip row visible before the tab bar begins.

This explains why it slipped past both the shipped `HomeFeedUITests` and the reviewer's
mutation testing: `testChipCountsPerRecommendationRow` only asserts `.exists` and
`.staticTexts.count` on `chips.Casa Lola`, neither of which requires the element to be
un-obscured or hittable — an element can exist in the accessibility tree while sitting visually
behind another opaque view. The mutation test in `review.md` (flipping `promotion` to
non-`nil`) still correctly detects a chip-count regression, but it does not detect this
visibility regression because it never checked `isHittable` or compared frames against the tab
bar's frame.

Likely root cause (structural, not confirmed by source inspection but consistent with the
symptom): `HomeTabView` applies `.safeAreaInset(edge: .bottom)` for the tab bar one level above
`FeedView`'s own `NavigationStack`. A `NavigationStack` can re-establish its own safe-area frame
for its content, and it appears the bottom inset from the tab bar is not being fully propagated
into `FeedView`'s `ScrollView` content margin, so the scroll view believes it has ~59pt more
room at the bottom than is actually visible to the user.

**Impact**: Not a crash, not a data-loss bug, and it does not fail any of the 11 numbered
acceptance criteria as literally written (criterion 6 only requires the correct *chip count*,
which is still true). But it is a real UX defect against an explicit, named plan requirement,
and it will only get worse if a longer recommendations list or a taller last row is added later
(e.g., a real provider with more restaurants). Recommend it be picked up as a fast follow-up
fix (likely: give `FeedView`'s `ScrollView`/`LazyVStack` explicit bottom content padding equal
to the tab bar's height, or verify the safe-area propagation with the tab bar hosted outside a
`NavigationStack` boundary) before three more tabs are built on this shell.

### Dynamic Type at `.accessibility1` — probed, second finding

Launched with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityL` and
measured `"OFERTAS DE HOY"`'s frame against a normal launch rather than eyeballing screenshots
(which looked deceptively similar at first glance):

```
normal:         frame = (16.0, 257.67, 150.0, 18.0)
accessibility1: frame = (16.0, 277.0,  150.0, 18.0)
height ratio = 1.0
```

**The text does not scale at all.** `Theme.swift`'s doc comment / `plan.md:74-77` state
`Theme.Typeface` uses `.system(size:weight:)` "so they still honour Dynamic Type," but plain
`Font.system(size:weight:)` in SwiftUI is a **fixed-point-size** font and does not respond to
the user's Content Size Category — only text styles (`.body`, `.title`, etc.) or an explicit
`relativeTo:`/`@ScaledMetric` do that. This is a discrepancy between what the plan/design
system documents and what actually happens at runtime.

**Consequence, and why it's not blocking**: because nothing in the custom UI grows, the
`FlowLayout` chip-wrapping fix (review NICE-TO-HAVE #10, and the plan's edge case "chips wrap
rather than clip") never actually gets exercised in this app — there's nothing to wrap, because
none of the text ever gets larger regardless of the device's accessibility text-size setting.
None of the 11 acceptance criteria mention Dynamic Type, so this doesn't fail a numbered
criterion. But it is worth flagging plainly: a user who increases their system text size for
accessibility reasons will see **zero** change anywhere in this feature's UI, which is a
legitimate accessibility gap and contradicts the design system's own stated intent. Recommend
correcting the `Theme.swift` doc comment (either implement real scaling via
`relativeTo:`/`@ScaledMetric`, or stop claiming Dynamic Type is honoured) before other tabs
inherit the same false assumption.

## 5. Temporary QA-only test file — used and removed

To reach real scrolled/tab-switched states for visual verification (no touch-injection tool
available in this sandbox), I added a throwaway `PideYaUITests/QAScreenshotCaptureTests.swift`,
ran it via `xcodebuild test -only-testing:PideYaUITests/QAScreenshotCaptureTests`, exported its
screenshot attachments via `xcrun xcresulttool export attachments`, then **deleted the file**.
`git status` after deletion shows no residue — the file was never staged/committed and the
working tree matches its pre-QA state exactly (diffed the file list before and after). This was
purely a verification aid; nothing in `PideYa/` or the shipped `PideYaUITests/` was modified by
QA.

## 6. Tab behaviour "by hand"

Could not literally tap the simulator by hand — no touch-injection tool is available in this
environment (`idb`, `cliclick` absent; `Quartz` unavailable to Python; AppleScript/System
Events GUI automation times out, presumably lacking Accessibility permission for the
automation). Used the temporary XCUITest described in §5 as the closest equivalent: tapped
`tabbar.buscar` → `tabbar.pedidos` → `tabbar.cuenta` → `tabbar.inicio` via `XCUIElement.tap()`
(the same underlying `hid` synthetic-event mechanism a real tap uses) and screenshotted each
state. Confirmed: each placeholder shows its own title/icon/"Próximamente.", the tab bar
highlights the correct tab in red at each step, and returning to Inicio restores the full feed
(offers carousel, header, recommendations) exactly as at first launch — no stale state, no
crash. This matches criterion 4 and is additionally corroborated by the shipped
`testTabRoundTripSwapsInicioAndPlaceholderContent`, which is mutation-tested per `review.md`.

## 7. Edge cases from the test plan — automated coverage vs. gaps

From `plan.md`'s "Edge cases to exercise manually / in previews":
- **Casa Lola (no promo chip) renders without a gap**: Covered by `testChipCountsPerRecommendationRow` (count == 1) and visually confirmed. Not a UI test for "no gap" specifically, but the `HStack`-then-`FlowLayout` composition structurally can't produce a gap for a single chip.
- **Dynamic Type at `.accessibility1`**: **Not covered by any automated test** — genuinely probed by me for the first time in this pass (see §4 finding above). No `PideYaTests`/`PideYaUITests` test exercises this.
- **Longest name truncates with `.lineLimit(1)`**: Not covered by an automated test; not independently re-verified by me either (would need mock-data mutation to test a longer string than `Taquería Norte`, which the current fixed mock data doesn't provide, and I did not want to modify app code to test this since QA is verify-only).
- **Smallest supported device (iPhone SE, 375pt)**: Not covered by an automated test, and not verified by me — I only tested on iPhone 17 (402pt) as instructed. This remains genuinely unverified.
- **Scrolling to the bottom of recommendations, last row reachable above tab bar**: **Probed directly by me — and found to be a real defect**, see §4. This was an open risk in `review.md` ("not blocking... needs a container narrower than a single chip to manifest" — that specific note was about `FlowLayout`, but the broader "last row reachable" question was also flagged as an open risk and had no automated coverage at all).
- **Dark mode unchanged**: Not tested — fixed sRGB literals make this low-risk, and it's explicitly out of scope per the plan (no dark-mode requirement for this feature).

## Summary

Build and both test suites are genuinely green, reproduced independently rather than trusted
from prior reports. 10 of 11 acceptance criteria PASS; criterion 9 is UNVERIFIABLE because
`swift-format` is deliberately not installed in this environment, per explicit instruction not
to install it. Design fidelity is very high — every specific DESIGN.md check requested (pinned
header, zero corner radius, red band, carousel peek, inset dividers, chip pair, comma decimals,
tab bar rule/red-Inicio) is confirmed by direct visual inspection on-device.

Two real defects were found during the "probe further than the shipped tests" part of this QA
pass, both **outside** the 11 numbered acceptance criteria (so they do not, on their own,
constitute a criterion FAIL) but both contradict explicit statements in `plan.md`/`Theme.swift`:

1. The last recommendation row's chip is visually obscured behind the tab bar even at maximum
   scroll — contradicts `plan.md`'s explicit `.safeAreaInset` rationale.
2. `Theme.Typeface` fonts do not scale with Dynamic Type at all — contradicts the design
   system's own documented claim that they do.

Neither is a crash, data-loss, or regression against `main`, and neither fails a literal
acceptance criterion. Given the code review's own standard (documented tradeoffs are
acceptable, but undocumented/incorrect claims about behavior are not), I'm treating these as
qualifying "PASS with two follow-up defects to log," not a hard FAIL — the feature does what
its acceptance criteria require, but the plan.md prose overpromises in two places, and one of
the two open risks review.md explicitly asked to be verified turned out to be real once
verified with real interaction rather than an `.exists`-only test.

## Files referenced

- Plan: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/home-tab-feed-ui/plan.md`
- Design spec: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/home-tab-feed-ui/DESIGN.md`
- Review + re-review: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/home-tab-feed-ui/review.md`
- Deviation log: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/home-tab-feed-ui/changes.md`
- Shipped UI tests: `/Users/vicchorarana/Desktop/projects/PideYa/PideYaUITests/HomeFeedUITests.swift`
- Suspected root cause of the tab-bar-obscures-last-row defect: `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/Home/HomeTabView.swift`, `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/Home/Feed/FeedView.swift`
- Font tokens with the Dynamic Type claim that doesn't hold: `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/DesignSystem/Theme.swift`

VERDICT: PASS

---

# QA cycle 2 — defect fix verification

Verifier: independent re-verification, run after `@ios-dev`'s fix-cycle-2 pass addressing the
two defects logged in cycle 1 above. Environment: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
(CLAUDE.md fallback). Simulator: iPhone 17. Nothing below is taken on trust from `changes.md`;
every measurement and screenshot was reproduced independently, including re-deriving the two
"before/after" numbers `changes.md` claims, via my own temporary UI test (added, run, exported,
deleted — same pattern as cycle 1's §5).

## 1. Clean build

```
xcodebuild clean build -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'
```
**BUILD SUCCEEDED.** Grepped the full log for `warning`: only hits are the `actool` invocation's
literal `--warnings`/`--notices` flags and the same pre-existing, unrelated
`appintentsmetadataprocessor ... warning: Metadata extraction skipped. No AppIntents.framework
dependency found.` info line seen in every prior pass. **Zero compiler warnings introduced by
this fix cycle.**

## 2. Full test suite

```
xcodebuild test -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17' \
  -resultBundlePath /tmp/PideYa2.xcresult -parallel-testing-enabled NO
```
**TEST SUCCEEDED.** `xcrun xcresulttool get test-results tests --path /tmp/PideYa2.xcresult`
parsed programmatically: **25/25 test cases passed, 0 failed** — 15 `PideYaTests` (Swift
Testing, confirmed via the framework's own `✔ Test ... passed` console output since Swift
Testing results don't appear as classic XCTest "Test Suite" lines) + 10 `PideYaUITests`
(8 `HomeFeedUITests`, including the two new regression tests, + `testLaunchPerformance` +
`testLaunch`×4 device configs collapsed to one node in the JSON but confirmed as 4 executions
in the console log: `Executed 4 tests` under `PideYaUITestsLaunchTests`). This matches the
implementer's reported 16/16 + 13/13 (16 = 15 + the legacy XCTest `PideYaTests/example()`;
13 = 8 + 1 + 4).

## 3. Defect 1 — last recommendation row hidden behind the tab bar — re-verified by direct measurement

Ran the shipped regression test alone first (`testLastRecommendationRowIsReachableAboveTabBar`)
— passed. Then, distrusting a test I didn't write, added a temporary throwaway
`PideYaUITests/QAVerifyFixesTests.swift` that reproduces cycle 1's exact technique (scroll past
first existence by 10 extra swipes, then measure raw frames) with `print` statements, ran it,
captured the console output, then deleted the file (confirmed via `git status` afterward — no
residue, tree matches pre-QA state).

```
QA-MEASURE chips.CasaLola frame = (100.0, 727.33, 84.0, 23.67)   → y-range [727.33, 751.0]
QA-MEASURE tabbar.inicio frame  = (0.0, 780.33, 100.67, 59.33)   → y-range [780.33, 839.67]
QA-MEASURE intersects = false
isHittable = true
```

This is a genuine fix, not a cosmetic change: the chip row's `maxY` (751.0) sits **~29pt clear**
of the tab bar's `minY` (780.33), `intersects == false`, and `isHittable == true` — all three
independently confirmed, matching `changes.md`'s claimed numbers exactly. Screenshot evidence
(`05-default-scrolled-max.png`, captured by the same temporary test) visually shows a clear
white gap between the `20-30 min` chip and the black tab-bar rule at true maximum scroll. This
is the same defect, same reproduction technique, same element pair QA used originally — it is
now fixed.

## 4. Defect 2 — Dynamic Type not scaling — re-verified by direct measurement

Ran the shipped regression test alone first (`testSectionHeaderScalesWithDynamicType`) —
passed. Then independently re-measured with the same temporary test file, launching at default
and with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityL`:

```
QA-MEASURE normal frame        = (16.0, 257.67, 150.0, 18.0)
QA-MEASURE accessibility1 frame = (16.0, 280.0, 245.0, 32.33)
height ratio = 32.33 / 18.0 ≈ 1.80
```

This matches `changes.md`'s claimed measurement exactly (default baseline unchanged at 18.0pt;
accessibility1 grown to 32.33pt). A ratio of 1.0 would mean not fixed; 1.80 is a real,
substantial scale-up. Confirmed genuinely fixed, not merely reported as fixed.

## 5. Regression sweep at default content size — re-walked all 11 acceptance criteria against DESIGN.md

Re-ran the full suite (§2) and additionally captured fresh on-device screenshots at default
content size covering: initial launch, scrolled to true maximum, carousel swiped, and the full
Buscar→Inicio round trip.

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Clean build, 0 warnings, pbxproj untouched | **PASS** | §1; `git diff HEAD -- PideYa.xcodeproj/project.pbxproj` empty |
| 2 | Static texts + search placeholder present at launch | **PASS** | `testLaunchShowsStaticFeedTextsAndSearchPlaceholder` passed; `04-default-launch.png` shows all required texts |
| 3 | `tabbar.*` identifiers exist/hittable, `inicio` selected | **PASS** | `testTabBarIdentifiersExistAndInicioIsSelected` passed; screenshots confirm red Inicio, black others |
| 4 | Buscar↔Inicio round-trip shows/hides content | **PASS** | `testTabRoundTripSwapsInicioAndPlaceholderContent` passed; `07-default-buscar-placeholder.png` → `08-default-back-to-inicio.png` confirms visually, full feed restored including offers carousel |
| 5 | es-ES fee/rating strings incl. NBSP before € | **PASS** | `testRecommendationFeesUseNonBreakingSpaceBeforeEuroSign` passed; `1,90 €`, `2,50 €`, `0,00 €`, `4,8`/`4,7`/`4,9` all visible |
| 6 | Chip counts (Casa Lola=1, Taquería Norte=2) | **PASS** | `testChipCountsPerRecommendationRow` passed; visually confirmed in `05-default-scrolled-max.png` — Casa Lola has only `20-30 min`, Taquería Norte has `25-35 min` + `-40%` |
| 7 | Carousel peek 55–70%, second card revealed on scroll | **PASS** | `testCarouselPeekRatioAndHorizontalSwipeRevealsSecondCard` passed; `06-default-carousel-swiped.png` shows Forno Bianco fully revealed after swipe |
| 8 | Colour/API greps clean | **PASS** | Re-ran both greps myself this cycle: zero matches outside `Theme.swift`'s doc comment (the new `Theme.Palette.transparent`/`onAccent` tokens are correctly *inside* `Theme.swift`, so the grep against files excluding it stays clean) |
| 9 | `swift-format lint` clean | **UNVERIFIABLE** | Still not installed, per explicit task instruction not to install it. No change from cycle 1. |
| 10 | `PideYaApp.swift` byte-identical to `main` | **PASS** | `git diff HEAD -- PideYa/PideYaApp.swift` empty |
| 11 | Every `body` < 40 lines, every file has a compiling `#Preview` | **PASS** | Re-measured every `body` block by hand this cycle: max 20 lines (`FeedView.swift`, up from 17 in cycle 1 due to the new bottom-inset `.safeAreaInset`, still well under the cap). `#Preview` count unchanged per file, all still compile (build succeeded) |

Point-by-point visual re-check against `DESIGN.md` (all confirmed in the fresh screenshots,
same as cycle 1, no regression): pinned header (identical pixel position across all scroll
states), zero corner radius everywhere, full-width red offer band with white uppercase text,
carousel peek ~56–60% of screen width, inset row dividers (start at text column, not under
thumbnail), outlined ETA chip + pale-red promo chip pair, comma decimal separators throughout,
tab bar with red Inicio and a hard 1px top rule. **No regression found in any of the 11
numbered criteria or the general design fidelity.**

## 6. Layout at `.accessibility1` — probed for the first time now that scaling is real

Captured fresh screenshots at `.accessibility1` (`09-accessibility1-launch.png`,
`10-accessibility1-scrolled-max.png`) and measured element frames directly.

- **Header still fits, capped correctly**: `FeedHeaderView`'s `.dynamicTypeSize(...DynamicTypeSize.accessibility1)`
  cap holds — brand word, avatar box, address row and search field all render without
  clipping or overlap at exactly `.accessibility1` (the boundary of the cap). No visual defect.
- **`FlowLayout` chip wrapping — genuinely exercised and works.** At `.accessibility1`,
  Taquería Norte's two chips (`25-35 min` and `-40%`) now stack vertically instead of
  compressing or clipping horizontally — confirmed both visually (`10-accessibility1-scrolled-max.png`)
  and by frame measurement (`chips.Taquería Norte` frame height grew from ~24pt at default to
  76.67pt at accessibility1, consistent with two stacked chip rows plus spacing, not one).
  This closes the "reasoned rather than visually confirmed" caveat the implementer flagged in
  the review-fix pass — it is now visually confirmed, not just structurally reasoned.
- **Casa Lola's single chip**: still renders with no phantom gap where a second chip would go
  (`chips.Casa Lola` `staticTexts.count == 1`, confirmed at accessibility1 too).
  `RestaurantRowView`'s `.dynamicTypeSize` cap holds the 72pt thumbnail fixed and legible.
- **Longest name truncates correctly — a previously-unverified edge case, now exercised for
  the first time.** `plan.md`'s edge case "Longest name (`Taquería Norte` at XXL) truncates
  with `.lineLimit(1)` rather than pushing the fee off-screen" is directly visible in
  `10-accessibility1-scrolled-max.png`: `Taquería N…` and `Forno Bian…` both truncate with an
  ellipsis, and `1,90 €` / `2,50 €` remain fully visible and un-squeezed on the trailing edge.
  This is a genuine pass of a real edge case, not just a plausible-looking screenshot.
- **Tab bar remains readable**: `Inicio`, `Buscar`, `Pedidos`, `Cuenta` labels grow (tab bar
  is capped at `.accessibility1` too, per the original plan) with no overlap between adjacent
  tabs and no label wrapping/clipping. Measured `tabbar.inicio` frame height grew from 59.33pt
  (default) to 71.33pt (accessibility1) — a controlled, bounded growth, not unbounded.
- **`OfferCardView`, deliberately left uncapped, degrades acceptably but visibly**: at
  `.accessibility1`, the offer card's banner text wraps to two lines (`-40% · HASTA` /
  `LAS 23:00`) and the card grows tall enough that, at first launch before any scrolling, the
  restaurant name/subtitle beneath the banner is pushed mostly below the fold
  (`09-accessibility1-launch.png` — only `Mexicana ·` and a sliver of the ETA text remain
  visible for the first card; `Forno Bianco`'s subtitle is fully visible since its card is
  narrower on screen at that scroll position). **This is honest, acceptable degradation, not a
  defect**: nothing clips or overlaps, the content is still fully reachable by scrolling
  (confirmed — scrolling down reveals the rest of the card normally), and the implementer
  explicitly documented this as a deliberate, reasoned tradeoff in `changes.md` (card height
  isn't fixed, so it grows rather than breaking). Flagging it here as requested rather than
  glossing over it: a first-time user with `.accessibility1` text size turned on will see less
  of the first offer card's text above the fold than a default-size user does.
- **Search field placeholder — pre-existing low-contrast issue, confirmed unchanged, not a
  regression.** Cropped and compared the search field region at both content sizes
  (`searchfield-default-crop.png` vs `searchfield-a11y-crop.png`): the placeholder text
  `Buscar restaurantes o platos` is low-contrast (light gray on light gray fill) at **both**
  sizes identically, and does not clip or overflow the field's fixed 56pt height at either size
  — the `TextField` itself is not routed through `.themeFont` and isn't capped, but its
  system-default placeholder font apparently doesn't grow enough to overflow the field at
  `.accessibility1` in practice. This low-contrast rendering predates this fix cycle entirely
  (present, unremarked, in cycle 1's screenshots too) and is out of scope for the two defects
  being verified here — not raising it as a new finding, just confirming no new clipping
  regression was introduged by the Dynamic Type fix at this specific field.

**Overall accessibility1 verdict**: the fix works as intended. Nothing clips or overlaps
destructively; the one honestly-uncapped view (`OfferCardView`) pushes content below the fold
rather than breaking layout, exactly as documented. This is a reasonable, disclosed tradeoff,
not a hidden defect.

## 7. Invariants re-checked

- `git diff HEAD -- PideYa/PideYaApp.swift` → empty. `git diff HEAD -- PideYa.xcodeproj/project.pbxproj`
  → empty. Both byte-identical to `HEAD`, confirmed both before and after adding/removing the
  temporary QA test file.
- `rg 'AnyView|cornerRadius|RoundedRectangle|ObservableObject|@Published|try\?' PideYa/` → one
  hit, the pre-existing `Theme.swift` doc-comment line only (same as every prior pass).
- Force-unwrap / force-try grep across `PideYa/` → no matches.
- `rg -n '#[0-9A-Fa-f]{6}|Color\(red:|Color\.\w|\.white|\.black' PideYa/ --glob '!PideYa/DesignSystem/Theme.swift'`
  → no matches. The two new colour tokens this cycle introduced (`Theme.Palette.onAccent`,
  `Theme.Palette.transparent`) both live correctly inside `Theme.swift`.
- Every `body` re-measured: max 20 lines (`FeedView.swift`), still under the 40-line cap.
- `#Preview` count unchanged per touched file; build succeeding confirms all previews still
  compile.
- `PideYaTests/` directory has zero diff vs `HEAD` this cycle (`git diff --stat HEAD --
  PideYaTests/` → empty), consistent with `changes.md`'s claim that this cycle's changes were
  view-layer only and needed no unit test updates.

## 8. Temporary QA-only test file — used and removed

Added `PideYaUITests/QAVerifyFixesTests.swift` (four test methods: direct frame measurement
for each defect, plus two screenshot-sweep methods for §5/§6), ran it via `xcodebuild test
-only-testing:PideYaUITests/QAVerifyFixesTests`, exported its console output and screenshot
attachments via `xcrun xcresulttool`, then deleted the file. `git status` after deletion shows
no residue — confirmed the working tree's modified/untracked file list is identical to what it
was before this QA pass started, aside from the seven files the implementer's fix cycle
touched. A clean `xcodebuild build` after the deletion still succeeds, confirming no build
dependency was accidentally left on the removed file.

## Summary

Both defects logged in cycle 1 are **genuinely fixed**, verified independently by direct frame
measurement (not by trusting `changes.md`'s narrative or re-running only the tests the
implementer wrote):

1. **Last recommendation row reachability** — `chips.Casa Lola`'s frame now sits ~29pt clear of
   the tab bar's frame, `isHittable == true`, no intersection. Matches the claimed
   before/after numbers exactly.
2. **Dynamic Type scaling** — `"OFERTAS DE HOY"`'s frame height grows from 18.0pt (default) to
   32.33pt (`.accessibility1`), a ~1.80× ratio. Matches the claimed measurement exactly. A
   previously dead edge case (`FlowLayout` chip-wrapping, longest-name truncation) is now for
   the first time actually exercised and confirmed working.

**No regressions found.** All 11 acceptance criteria still PASS (criterion 9 remains
UNVERIFIABLE for the same tooling-absence reason as cycle 1, not a new gap). Design fidelity at
default content size is unchanged and still matches `DESIGN.md` on every specific point
requested. At `.accessibility1`, the layout holds up well: capped views (header, restaurant
rows, tab bar) stay within bounds with no clipping/overlap, and the one deliberately uncapped
view (`OfferCardView`) degrades honestly by pushing content below the fold rather than breaking
— a disclosed, reasonable tradeoff, not a hidden defect. The pre-existing low-contrast search
placeholder is unrelated to this cycle's changes and unchanged by it.

Both suites are green (25/25 test cases across `PideYaTests` + `PideYaUITests`), the build is
clean with zero introduced warnings, and every invariant (pbxproj/App entry point untouched,
no prohibited APIs, colour literals confined to `Theme.swift`, body length, previews) holds.

## Files referenced this cycle

- Implementer's fix-cycle-2 log: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/home-tab-feed-ui/changes.md`
- Fixed files: `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/DesignSystem/Theme.swift`, `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/DesignSystem/DesignSystemViews.swift`, `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/Home/Feed/FeedSubviews.swift`, `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/Home/Feed/FeedView.swift`, `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/Home/HomeTabBar.swift`, `/Users/vicchorarana/Desktop/projects/PideYa/PideYa/Home/HomeTabView.swift`
- New regression tests: `/Users/vicchorarana/Desktop/projects/PideYa/PideYaUITests/HomeFeedUITests.swift` (`testLastRecommendationRowIsReachableAboveTabBar`, `testSectionHeaderScalesWithDynamicType`)

VERDICT: PASS
