# Code Review — Home Tab shell + Feed screen

Reviewer: staff iOS review pass
Baseline: `git HEAD` = `4b48ed9`, working tree dirty, nothing committed.
Scope: 4 staged files (`FeedView`, `FeedViewModel`, `HomeTabView`, `HomeTabViewModel`) +
6 untracked files (`Theme`, `DesignSystemViews`, `FeedModels`, `FeedSubviews`, `HomeTabBar`,
`FeedTests`).

## Summary

This is a well-executed implementation. The view decomposition is genuinely good, the
design-token layer is a sound foundation, there are no force unwraps / `try!` / `try?` /
`AnyView` / `ObservableObject` / `@Published` / `cornerRadius` / `RoundedRectangle` anywhere,
no retain cycles (there is no escaping closure captured by a long-lived object, no `Task`,
no Combine — `[weak self]` is correctly absent because nothing needs it), and the ViewModel
pattern matches CLAUDE.md exactly. `body` lengths are well under the 40-line cap (max 17, in
`FeedView`). `PideYaApp.swift` and `project.pbxproj` are untouched, as required.

What holds it back is verification coverage, one design-system leak, and one inconsistency
in the `nonisolated` discipline that the brief specifically asked about.

## Acceptance criteria audit

| # | Criterion | Status |
|---|---|---|
| 1 | Build succeeds, 0 warnings, pbxproj untouched | PASS (verified by requester; `git status` confirms pbxproj clean) |
| 2 | Static texts + search placeholder present | PARTIAL — present in source, **not verified by any test** |
| 3 | `tabbar.*` identifiers exist/hittable, `inicio` selected | PARTIAL — identifiers in source, **unverified** |
| 4 | Tab round-trip shows/hides `placeholder.buscar` / `OFERTAS DE HOY` | AT RISK — see W3, **unverified** |
| 5 | es-ES fee/rating strings | PASS in substance, but the criterion's literal `1,90 €` is **wrong** (real output is NBSP U+00A0) |
| 6 | Chip counts per row (1 for Casa Lola, 2 for Taquería Norte) | UNVERIFIED — no unit or UI test asserts chip count |
| 7 | Carousel peek 55–70% of screen width | PASS by calculation (61.3% on both 375pt and 393pt), **unverified by test** |
| 8 | Colour/API greps clean | PARTIAL — greps pass, but a literal `.white` escapes the too-narrow grep (see F2) |
| 9 | `swift-format lint` clean | NOT RUN — tool not installed (consistent with CLAUDE.md); manual check done |
| 10 | `PideYaApp.swift` byte-identical | PASS (`git diff HEAD -- PideYa/PideYaApp.swift` empty) |
| 11 | `body` < 40 lines, `#Preview` per file | PASS for all view files; non-view files (`Theme`, `FeedModels`, both VMs) have no preview — reading the criterion as "every view file" |

I re-ran both criterion-8 greps myself. Confirmed: `#[0-9A-Fa-f]{6}|Color\(red:` outside
`Theme.swift` → no matches. `AnyView|cornerRadius|RoundedRectangle|ObservableObject|@Published`
→ one match, and it is the doc comment on `Theme.swift:13` explaining the rule, not code.

## Findings

### CRITICAL

**[CRITICAL]** `PideYaUITests/` (no new file) — Acceptance criteria 2, 3, 4, 6 and 7 have **zero**
automated verification. Five of eleven criteria rest on a single manual screenshot. The
implementer's rationale in `changes.md:53-63` — that `PideYaUITests` is not one of the nine
numbered tasks — reads the plan too narrowly: the "Acceptance criteria" and "Test plan"
sections are equally part of the contract, and the Test plan explicitly assigns these to
`PideYaUITests` while calling XCUITest "the one sanctioned XCTest exception." Criteria 6 (chip
counts) and 7 (carousel peek ratio) are structurally impossible to cover from `PideYaTests` —
if they are not covered here, they are not covered at all. The cost is one file with roughly
four test methods, and the context is fresh right now.
→ Add `PideYaUITests/HomeFeedUITests.swift` with: (a) launch assertions for the criterion-2
texts and the search placeholder; (b) `tabbar.*` existence/hittability + `isSelected` on
`tabbar.inicio`; (c) the buscar↔inicio round-trip; (d) chip counts per row; (e) a horizontal
swipe asserting `Forno Bianco` becomes visible and that card 1's width is 55–70% of screen
width. Replace the dead template `PideYaUITests/PideYaUITests.swift:25-33` (`testExample` has an
empty body) rather than leaving it alongside. **Write the fee assertion with `\u{00A0}`, not a
plain space** — see F5.

### WARNING

**[WARNING]** `FeedSubviews.swift:94` — `.foregroundStyle(.white)` is a hardcoded colour literal
outside `Theme.swift`. Criterion 8's prose is "all colour literals confined to `Theme.swift`";
the grep it prescribes (`#hex|Color(red:`) simply cannot see a named `Color` and so passed
vacuously. This is the only real leak in the design system, and it matters because the red band
is the one place the palette needs a foreground-on-accent token that the other three tabs will
also want.
→ Add `static let onAccent = Color.white` (or an explicit sRGB literal) to `Theme.Palette` and
use it here. Also widen the criterion-8 grep in the plan to include bare `Color.` / `.white` /
`.black` so it stops passing vacuously.

**[WARNING]** `HomeTabBar.swift:11-35` — the `nonisolated` discipline was applied to the Feed
models but **not** to `HomeTab`, so `HomeTab.title` and `HomeTab.systemImage` are MainActor-isolated
even though the type declares `Sendable`. I verified this empirically rather than assuming it:
compiling a reduced copy with `swiftc -swift-version 6 -default-isolation MainActor` produces
`error: main actor-isolated property 'title' can not be referenced from a nonisolated context`,
while the `nonisolated struct` copy compiles fine. It builds today only because every consumer
(`HomeTabViewModel`, `HomeTabBar`, and the `@MainActor struct HomeTabViewModelTests`) happens to
be MainActor. This is sharper than it looks: I checked `project.pbxproj` and
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set on the **app target only** (lines 418, 451) —
`PideYaTests` and `PideYaUITests` default to `nonisolated`. So the test module is a
nonisolated-by-default consumer of a MainActor-by-default module, which is exactly why
`nonisolated` on `Offer`/`Restaurant`/`FeedProfile` was load-bearing (it lets the
non-`@MainActor` `FeedFormattingTests` and `MockFeedContentProviderTests` structs compile).
`HomeTab` is the same kind of plain value type and got missed.
→ Mark `nonisolated enum HomeTab`. The underlying reasoning in `changes.md:35-45` is **sound and
correctly argued** — it is not papering over a design problem, it is the right fix for
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and matches CLAUDE.md's own "mark types that must
leave the main actor as `nonisolated`". It was just applied non-uniformly.

**[WARNING]** `HomeTabBar.swift:80-82` — `.accessibilityIdentifier("placeholder.\(tab.rawValue)")`
is attached to a `ContentUnavailableView`, which is an accessibility *container*, not a leaf.
SwiftUI propagates the identifier to descendant elements rather than creating one queryable
element with that id, so `app.otherElements["placeholder.buscar"]` may not resolve — and
acceptance criterion 4 depends on exactly that lookup. Nothing currently proves it works, since
there is no UI test.
→ Add `.accessibilityElement(children: .contain)` before the identifier so a single container
element carries the id, and assert it in the UI test from the CRITICAL finding.

**[WARNING]** `DesignSystemViews.swift:74-75, 85` — `SectionHeaderView` models the trailing action
as two independent optionals (`actionTitle: String?`, `action: (() -> Void)?`), which admits the
invalid state "title but no action". `Button(actionTitle, action: action ?? {})` then renders a
button that is focusable, hittable and announced to VoiceOver but silently does nothing — which
is precisely what `FeedView.swift:45` produces today for "Ver todas". That is intended *for this
feature*, but the `?? {}` makes an accidental no-op indistinguishable from a deliberate one, and
this component is the foundation for three more tabs.
→ Collapse to one parameter, e.g. `action: (title: String, perform: () -> Void)?` or a small
`SectionAction` struct, so the title and handler cannot diverge. If a deliberately inert button
is wanted now, make it explicit at the call site rather than defaulting inside the component.

**[WARNING]** `FeedSubviews.swift:144-151` — the chip row is a plain `HStack`, which cannot wrap.
The plan's edge-case list expects "chips wrap rather than clip" at `.accessibility1`, but an
`HStack` will compress and truncate instead. Unlike `HomeTabBar` (correctly capped at
`.accessibility1` on `HomeTabBar.swift:52`), `RestaurantRowView` has no Dynamic Type cap, and
neither `subtitleText`, the chips, nor the trailing fee `Text` carries a `lineLimit` or
`layoutPriority` — only the name does (`FeedSubviews.swift:136`). At large sizes the fee can be
squeezed.
→ Either use `ViewThatFits` / a wrapping layout for the chip row, or give the fee
`.layoutPriority(1)` + `.lineLimit(1)` and cap the row's Dynamic Type the same way the tab bar
is capped. At minimum, verify at `.accessibility1` before shipping, since the plan lists it as a
required manual check.

**[WARNING]** `HomeTabView.swift:26-32` — the `@ViewBuilder switch` is correct (no `AnyView`,
concrete branches), but it produces `_ConditionalContent`, so switching tabs **tears down**
`FeedView`'s entire view tree. `searchText` survives — correctly, because `HomeTabViewModel`
owns the `FeedViewModel` (`HomeTabViewModel.swift:15-19`), which is exactly the right call and
worth calling out as a good decision. But scroll position, keyboard focus, and (once it exists)
the `NavigationStack` path do **not** survive; native `TabView` would preserve them. Rejecting
`TabView` for design reasons was right, but this consequence is not documented anywhere.
→ Either accept and document it in `changes.md` as a known tradeoff, or keep all four screens
resident (e.g. `ZStack` with `.opacity` + `.allowsHitTesting`, or `.hidden()` branches) if
scroll restoration matters. Do not leave it implicit — it will surprise whoever builds Buscar.

**[WARNING]** `FeedModels.swift:74-124` — `MockFeedContentProvider.offers()` and
`recommendations()` mint fresh `UUID()` values on **every call**. Today this is harmless because
`FeedViewModel.init` calls each exactly once and stores the arrays, but it directly contradicts
the plan's stated reason for the explicit `id` field: "so mock data is stable across re-renders"
(`plan.md:106`). The moment anyone adds a `refresh()`, a pull-to-refresh, or calls the provider
twice, every `ForEach` identity changes and the whole list rebuilds with no diffing.
→ Make the seed data `static let` arrays (or use stable, hardcoded UUIDs) so repeated calls
return identical identities. This also makes the data trivially assertable from tests.

**[WARNING]** `PideYaTests/FeedTests.swift` — test gaps and two low-value tests:
- `MockFeedContentProvider.profile()` is **never** asserted, so `"VA"` and `"Calle Mayor 44"` —
  half of acceptance criterion 2 — are untested at any level (no UI test either).
- `Offer.etaText` and `Offer.subtitleText` (`FeedModels.swift:53-61`) have no coverage; only the
  `Restaurant` variants are tested, despite the plan listing both.
- `HomeTab.systemImage` is untested, even though the plan flags SF Symbol availability on iOS
  17.6 as an explicit risk (`plan.md:438-440`). Nothing guards against a typo'd or iOS 18-only
  symbol name regressing to a blank glyph.
- `searchTextStartsEmptyAndIsMutable` (`:171-176`) and the second half of
  `selectedTabDefaultsToInicioAndIsMutable` (`:183-185`) are tautological — they assert that a
  plain `var` can be assigned. Keep the default-value assertions, drop the round-trip halves.

  To be clear about the part the brief asked about: `initSurfacesInjectedProviderData`
  (`:164-169`) is **not** tautological. `StubFeedContentProvider` returns `"ZZ"` /
  `"Stub Restaurant"` / `"Stub Recommendation"`, values that are impossible for
  `MockFeedContentProvider` to produce, so the test genuinely proves constructor injection flows
  through. That is the right shape.

**[WARNING]** `DesignSystemViews.swift:11-26` — `HatchedPlaceholder` omits the `.clipped()` the
plan explicitly required (`plan.md:89-90`), and the omission is not recorded in `changes.md`. The
stripe loop runs `x` up to `size.width` and each line extends `size.height` to the right, so the
final stripes are drawn outside the bounds; this is currently masked by `Canvas`'s own clipping
behaviour, which is an implementation detail to be relying on when the placeholder sits inside a
1pt-bordered card (`FeedSubviews.swift:82-88`).
→ Add `.clipped()` as specified, or log the deliberate deviation with the reason.

### NIT

**[NIT]** `FeedView.swift:82-85` — the inter-row divider uses the default `HardRule` thickness
(`Theme.Stroke.rule` = 2pt), the same weight as the major section separators. `DESIGN.md:46`
calls for a "thin gray divider" for rows versus "~2pt" for the header rule (`DESIGN.md:27`).
→ Pass `thickness: Theme.Stroke.hairline` for row dividers. The inset itself
(`Theme.Size.rowThumbnail + Theme.Spacing.md`) is exactly right.

**[NIT]** `FeedModels.swift:44-46` and `:54-56` — `etaText` is duplicated verbatim across
`Restaurant` and `Offer`.
→ Hoist to `extension ClosedRange where Bound == Int { var etaText: String }` and have both
call it. One implementation, one test.

**[NIT]** `FeedSubviews.swift:46, 72, 88`, `DesignSystemViews.swift:65` — all borders use
`Rectangle().stroke(...)`, which centres the line on the path, so half of every 1pt border is
drawn *outside* the view's bounds. In a brutalist design where the border is the entire visual
language, this makes borders susceptible to half-pixel clipping by parents (notably the card
inside `containerRelativeFrame`).
→ Use `Rectangle().strokeBorder(...)`, which insets the stroke to sit fully inside the frame.
Worth fixing once in the design system before three more tabs copy the pattern.

**[NIT]** `Theme.swift:14-61` — every token is a MainActor-isolated `static let` (the app target
sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `Theme` is not annotated). Fine for views,
but it means no nonisolated code — including any future non-`@MainActor` test in `PideYaTests`,
which is nonisolated by default — can read a token without hopping actors.
→ Mark `nonisolated enum Theme` for a foundation type that has no reason to be actor-bound.
Same reasoning as the `HomeTab` finding.

**[NIT]** `DesignSystemViews.swift:74-75, 95-96` — `SectionHeaderView` and `HardRule` use `var`
stored properties with inline defaults to get the synthesized memberwise init, where the plan
specified explicit `init`s. The properties are never mutated, so `var` grants unnecessary
external mutability and pulls the memberwise init's parameter labels into the public-ish surface.
→ Use `let` + an explicit `init` as the plan specified.

**[NIT]** `DesignSystemViews.swift:57` — `.clear` is a colour literal outside `Theme.swift`. Far
less severe than the `.white` case (it denotes absence of fill, not a palette choice), but for
strict consistency consider `Theme.Palette.none` or restructuring `backgroundColor` to return
`Color?`.

**[NIT]** `FeedSubviews.swift:25-27` — the header's trailing rule is applied via
`.overlay(alignment: .bottom)` rather than as the last element of the `VStack`, as the plan
described (`plan.md:194`). The overlay draws *over* the bottom 2pt of the header's padding
instead of adding height. Visually near-identical, but it is an undocumented deviation.

**[NIT]** `FeedView.swift:15-19` — `@State private var viewModel: FeedViewModel` for an object
that is owned by `HomeTabViewModel` (`HomeTabViewModel.swift:15`). `@State` signals ownership and
carries the "only the first instance passed wins" lifetime rule; a plain `let viewModel:
FeedViewModel` would still get full Observation-driven updates and would express the actual
ownership. **This is plan-mandated** (`plan.md:213-214`), so it is a plan-level question, not an
implementer error — raising it so the idiom gets settled before three more tabs adopt it.

**[NIT]** `HomeTabBar.swift:81` and `HomeTabView.swift:19-20` — `PlaceholderTabView` applies
`.background(Theme.Palette.background)` to a `ContentUnavailableView` that sizes to its content,
so it does not fill; the effect is achieved anyway by the parent's
`.frame(maxWidth:maxHeight:.infinity).background(...)`. Harmless but redundant.

**[NIT]** `HomeTabBar.swift:62` — `Image(systemName:).font(.system(size: Theme.Size.tabIcon))`
uses a `Theme.Size` (a frame token) as a font size. The plan does define `tabIcon` under `Size`,
so this follows the plan, but a `Theme.Typeface.tabIcon` (or `Theme.IconSize`) would keep the
token namespaces honest for the other three tabs.

## Answers to the specific review questions

**1. Is the `nonisolated` reasoning sound?** Yes — and it is not papering over a design problem.
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` really does make `Offer`/`Restaurant`/`FeedProfile`
MainActor-isolated by default, which would (a) break their `Hashable` witnesses and (b) make them
unusable from the nonisolated-by-default test target. I confirmed the isolation behaviour with a
standalone `swiftc -default-isolation MainActor` typecheck rather than taking it on trust. The
only defect is uniformity: `HomeTab` and `Theme` were left MainActor-isolated (see W2, N4).

**2. CLAUDE.md compliance.** Clean. No `AnyView`, no `ObservableObject`/`@Published`, no `try?`,
both ViewModels are `@MainActor @Observable final class` with `private(set)` state and fully
defaulted inits, protocol-driven constructor injection via `FeedContentProviding`, every `body`
well under 40 lines, and decomposition into private computed subviews throughout. One forward-
looking note: the DI is wired entirely through *default arguments* (`FeedViewModel(provider:
MockFeedContentProvider())` → `HomeTabViewModel(feed: FeedViewModel())` → `HomeTabView`), so
`PideYaApp` never declares what it depends on. Correct and per-plan for a mock-only feature, but
when a real provider arrives, `PideYaApp` must become an explicit composition root rather than
another layer of defaults.

**3. Design-system discipline.** Both prescribed greps pass. The prose requirement does not:
`.white` at `FeedSubviews.swift:94` is an unconfined colour literal. Spacing, sizes, strokes,
fonts and kerning are otherwise 100% tokenised — I found no magic numbers in any view.

**4. DESIGN.md fidelity.** Zero corner radius everywhere (verified by grep). Palette matches
`DESIGN.md:8-13` exactly. Header is genuinely pinned via `.safeAreaInset(edge: .top)`. Uppercase
copy is stored as literals — `rg 'textCase' PideYa/` returns nothing, so the accessibility-value
trap was correctly avoided. Carousel peek computes to 61.3% on both 375pt and 393pt widths
(`(w - 7·12)·0.625 + 4·12`), inside the 55–70% window and matching `DESIGN.md:33`'s "~62%".
Dividers are correctly inset to the text content. Gaps: the `.white` literal and the 2pt row
divider versus "thin".

**5. Is the design system a sound base for Buscar/Pedidos/Cuenta?** Broadly yes — the token
namespaces are well-factored, `PlaceholderTabView` is properly shared, and `HomeTab` is a clean
extension point. Fix before the next tab builds on it: the missing `onAccent` token, `stroke` →
`strokeBorder`, the `SectionHeaderView` optional-pair API, and the `Theme`/`HomeTab` isolation.
These are all cheap now and expensive after three call-site sets exist.

**6. Test quality.** The injection test is real, not tautological (distinct stub data). Two
mutability tests are tautological and should go. Real coverage gaps: mock `profile()`, both
`Offer` formatting properties, and `HomeTab.systemImage`. The NBSP discovery in `changes.md:46-52`
is excellent work — the implementer verified the actual formatter output instead of coding to the
plan's prose, which is exactly right and would otherwise have shipped a permanently-red test.

**7. Retain cycles / memory.** None found. No `Task`, no Combine, no `[weak self]` needed —
`SectionHeaderView`'s stored `action` closure is held by a value-type `View` that no long-lived
object retains, so there is no cycle. View identity across tab switches is handled correctly by
hoisting `FeedViewModel` ownership into `HomeTabViewModel`; the only loss is transient UI state
(W6). One minor SwiftUI note: a stored closure makes `SectionHeaderView` non-equatable, so
SwiftUI cannot skip its body on re-render — negligible at this size, but relevant if the
component is later used in a `List` row.

**Does the missing UI test suite block?** Yes. It leaves five criteria unverified, two of them
(6 and 7) unverifiable by any other means, and the known-wrong NBSP expectation in criterion 5
will produce a confusing failure for whoever writes them later without this context. It is a
single file of roughly four tests and the context is fresh now.

---

## Required changes

### MUST-FIX

1. **`PideYaUITests/` — add the missing UI test suite.** Cover acceptance criteria 2, 3, 4, 6 and
   7 as specified in `plan.md:385-389`. Replace the dead template in
   `PideYaUITests/PideYaUITests.swift:25-33`. Use `\u{00A0}` in any fee assertion.
2. **`PideYa/Home/Feed/FeedSubviews.swift:94`** — replace the hardcoded `.foregroundStyle(.white)`
   with a new `Theme.Palette.onAccent` token, so all colour literals live in `Theme.swift` per
   acceptance criterion 8. Widen the criterion-8 grep so it can actually catch named colours.
3. **`PideYa/Home/HomeTabBar.swift:11`** — mark `nonisolated enum HomeTab`. It declares `Sendable`
   but its `title`/`systemImage` are MainActor-isolated, inconsistent with the `nonisolated`
   treatment correctly applied to the Feed models, and unusable from the nonisolated-by-default
   test target.
4. **`PideYa/Home/HomeTabBar.swift:80-82`** — add `.accessibilityElement(children: .contain)` to
   `PlaceholderTabView` so `placeholder.<tab>` resolves as a single queryable element; acceptance
   criterion 4 depends on it and nothing currently proves it works.
5. **`PideYa/Home/Feed/FeedModels.swift:74-124`** — make the mock seed data static/stably-identified
   instead of minting fresh `UUID()`s per call, so `Identifiable` identity is stable as the plan
   requires.
6. **`PideYaTests/FeedTests.swift`** — add coverage for `MockFeedContentProvider.profile()`,
   `Offer.etaText` / `Offer.subtitleText`, and `HomeTab.systemImage`; drop the two tautological
   mutability round-trips.
7. **`PideYa/DesignSystem/DesignSystemViews.swift:11-26`** — add the plan-specified `.clipped()` to
   `HatchedPlaceholder`, or record the deliberate deviation in `changes.md`.
8. **`PideYa/Home/HomeTabView.swift:26-32`** — document (in `changes.md`) that the `switch` tears
   down `FeedView` on tab change, so scroll position / keyboard focus / future navigation path do
   not survive a tab round-trip; or keep the screens resident.

### NICE-TO-HAVE

9. `PideYa/DesignSystem/DesignSystemViews.swift:74-75, 85` — collapse `SectionHeaderView`'s
   `actionTitle`/`action` optionals into one parameter so invalid states are unrepresentable and
   `?? {}` stops silently producing inert buttons.
10. `PideYa/Home/Feed/FeedSubviews.swift:144-151` — make the chip row wrap (`ViewThatFits` or a
    flow layout) and give the trailing fee `.lineLimit(1)` + `.layoutPriority(1)`; verify at
    `.accessibility1`.
11. `PideYa/Home/Feed/FeedView.swift:82-85` — use `thickness: Theme.Stroke.hairline` for row
    dividers to match `DESIGN.md:46`'s "thin".
12. `PideYa/Home/Feed/FeedModels.swift:44-46, 54-56` — hoist the duplicated `etaText` onto
    `ClosedRange<Int>`.
13. `PideYa/DesignSystem/DesignSystemViews.swift:65`, `PideYa/Home/Feed/FeedSubviews.swift:46, 72,
    88` — switch `Rectangle().stroke` to `.strokeBorder` so borders sit fully inside their bounds.
14. `PideYa/DesignSystem/Theme.swift:14` — mark `nonisolated enum Theme`.
15. `PideYa/DesignSystem/DesignSystemViews.swift:74-75, 95-96` — `let` + explicit `init` instead of
    `var` + synthesized memberwise init.
16. `PideYa/Home/Feed/FeedView.swift:15-19` — reconsider `@State` for a parent-owned ViewModel
    (plan-level decision; settle before the next three tabs copy it).
17. `PideYa/Home/HomeTabBar.swift:62` — move `tabIcon` out of `Theme.Size` (a frame namespace) into
    a font/icon namespace.
18. `plan.md:351` — correct acceptance criterion 5's expected strings to use U+00A0 before `€`.

VERDICT: CHANGES_REQUESTED — 1 critical, 9 warnings

---

# Re-review — fix cycle 1

Reviewer: staff iOS review pass (second look).
Baseline: `git HEAD` = `4b48ed9`, working tree still dirty, nothing committed.
Everything below was **independently verified in this session**, not taken from `changes.md`.

## Verification I ran myself

| Check | Result |
|---|---|
| `xcodebuild build -scheme PideYa -destination 'iPhone 17'` | **BUILD SUCCEEDED**; grep for `warning:` in the full log returns exactly one line, the unrelated `appintentsmetadataprocessor` info message. Zero compiler warnings — claim confirmed. |
| `xcodebuild test -only-testing:PideYaTests` | **TEST SUCCEEDED**. |
| `xcodebuild test -only-testing:PideYaUITests -parallel-testing-enabled NO` | **TEST SUCCEEDED — 11/11**. Breakdown: 6 `HomeFeedUITests`, 1 `testLaunchPerformance`, 4 × `PideYaUITestsLaunchTests.testLaunch` (that class sets `runsForEachTargetApplicationUIConfiguration = true`, which is where the "5 pre-existing" count comes from). No flakes on my run. |
| Criterion-8 widened grep `#[0-9A-Fa-f]{6}\|Color\(red:\|Color\.\w\|\.white\|\.black` outside `Theme.swift` | no matches (exit 1). |
| `rg 'AnyView\|cornerRadius\|RoundedRectangle\|ObservableObject\|@Published'` | one match, still only the `Theme.swift:13` doc comment. |
| `rg 'try\?\|try!'` across `PideYa/`, `PideYaTests/`, `PideYaUITests/` | no matches. Force-unwrap scan clean. |
| `git diff HEAD -- PideYa/PideYaApp.swift PideYa.xcodeproj/project.pbxproj` | **0 lines**. Both untouched. The project uses `fileSystemSynchronizedGroups`, so the six new files are picked up without a pbxproj edit — this is why "no pbxproj diff" and "new files build" are both true. |
| `body` line counts across every view file | max **17** (`FeedView`), all well under 40. |

### Mutation testing of the new UI tests

The brief asked me not to take the new UI tests on faith. I copied the tree to a scratchpad,
injected three deliberate regressions, and re-ran the corresponding tests. All three tests
**failed exactly as they should**, which proves they are load-bearing rather than vacuously true:

| Injected regression | Test | Result |
|---|---|---|
| `Casa Lola.promotion = nil` → `"-10%"` (so it gains a second chip) | `testChipCountsPerRecommendationRow` | **FAILED** — `XCTAssertEqual failed: ("2") is not equal to ("1")` at `:109` |
| `containerRelativeFrame(count: 8, span: 5)` → `count: 1, span: 1` (full-width cards) | `testCarouselPeekRatioAndHorizontalSwipeRevealsSecondCard` | **FAILED** — `XCTAssertLessThanOrEqual failed: ("0.9203980099502488") is greater than ("0.7")` at `:129` |
| `HomeTabView.selectedScreen` switch → `ZStack` keeping `FeedView` resident behind the placeholder | `testTabRoundTripSwapsInicioAndPlaceholderContent` | **FAILED** — `XCTAssertFalse failed` at `:79` |

So, answering the three specific questions: the chip test **does** count chips per row and
distinguishes 1 from 2; the carousel test **does** measure a real ratio (0.92 vs. the passing
0.55–0.70 window); and the round-trip test **does** prove `OFERTAS DE HOY` disappears. The
`0.9204` figure also incidentally confirms the passing ratio is a genuine measurement of the
rendered frame, not a constant. This is real verification, not test theatre.

## Per-item status

### MUST-FIX

1. **UI test suite** — **FIXED.** `PideYaUITests/HomeFeedUITests.swift` covers criteria 2, 3, 4,
   5, 6, 7. Fee assertions use `\u{00A0}` as instructed. Dead `testExample` removed from
   `PideYaUITests/PideYaUITests.swift` (`git diff` shows −11 lines, nothing else). Mutation-proven
   above. The two authoring discoveries logged in `changes.md` (`Ver todas` is a `Button` because
   of `SectionHeaderView`'s trailing action; `LazyVStack` rows below the fold are absent from the
   a11y tree until scrolled) are correct and well documented.
2. **`Theme.Palette.onAccent` + widened grep** — **FIXED.** `FeedSubviews.swift:96` now uses the
   token; `plan.md:363` carries the widened grep; grep re-run clean.
3. **`nonisolated enum HomeTab`** — **FIXED** (`HomeTabBar.swift:11`).
4. **`PlaceholderTabView` container element** — **FIXED** (`HomeTabBar.swift:82`), and empirically
   proven: `app.otherElements["placeholder.buscar"]` resolves in the passing round-trip test.
5. **Stable mock IDs** — **FIXED.** `static let seedOffers` / `seedRecommendations` with
   `stableID(_:)` building `UUID(uuid:)` from a 16-byte tuple. I checked the mechanism: the tuple
   initialiser is non-failable (no force unwrap introduced, as intended), byte values 1, 2 and 11,
   12, 13 are distinct, and `static let` is initialised once, so `provider.offers()` returns
   byte-identical identities on every call. Correct and genuinely stable.
6. **Test coverage** — **FIXED.** `profileMatchesDocumentedValues`, `offerEtaTextHasNoThousandsSeparator`,
   `offerSubtitleTextComposesCuisineAndEta`, `homeTabSystemImagesAreIOS17AvailableSymbols` all
   added; both tautological round-trips removed and the tests renamed honestly
   (`searchTextStartsEmpty`, `selectedTabDefaultsToInicio`).
7. **`HatchedPlaceholder().clipped()`** — **FIXED** (`DesignSystemViews.swift:24`).
8. **Tab-switch teardown documented** — **FIXED.** `changes.md:157-170` is a thorough, honest
   write-up that names exactly what survives (`searchText`, because it lives on
   `HomeTabViewModel.feed`) and what does not (scroll position, keyboard focus), and hands the
   decision to whoever builds Buscar/Pedidos/Cuenta. This is what I asked for.

### NICE-TO-HAVE

9. `SectionAction` — **FIXED.** Invalid "title without handler" state is now unrepresentable;
   `?? {}` is gone; call sites updated.
10. Wrapping chip row + fee protection — **PARTIAL.** The fee's `.lineLimit(1)` +
    `.layoutPriority(1)` is done and correct. `FlowLayout` wraps correctly in the normal case, but
    has proposal edge-case defects (see finding **R1**) and was never verified at `.accessibility1`.
    Structurally better than the old `HStack`; not fully closed.
11. Hairline row dividers — **FIXED** (`FeedView.swift:84`).
12. `etaText` hoisted to `ClosedRange<Int>` — **FIXED** (`FeedModels.swift:35-40`), both call sites
    delegate.
13. `stroke` → `strokeBorder` — **FIXED**, all four sites (`DesignSystemViews.swift:66`,
    `FeedSubviews.swift:46, 72, 88`). No `Rectangle().stroke(` remains.
14. `nonisolated enum Theme` — **FIXED** (`Theme.swift:14`).
15. `let` + explicit `init` on `SectionHeaderView` / `HardRule` — **FIXED**.
16. `@State` vs `let` for a parent-owned ViewModel — **deliberately unchanged, and that is the right
    call.** Standing open question for the user, not a review item. Not blocking, not re-raised.
17. `Theme.IconSize.tab` — **FIXED** (`Theme.swift:46-48`, `HomeTabBar.swift:62`).
18. `plan.md` criterion 5 NBSP — **FIXED**, with an in-place note explaining the correction. The
    criterion-8 widening at `plan.md:361-366` is likewise annotated. Both plan edits are ones I
    asked for and are documented rather than silently applied.

Score: 8/8 MUST-FIX fixed, 8/9 assigned NICE-TO-HAVEs fixed, 1 partial.

## New findings this cycle

### WARNING

**[WARNING] R1** `DesignSystemViews.swift:136-155` — `FlowLayout.sizeThatFits` mishandles two
proposal edge cases. I replicated the algorithm verbatim in a scratchpad script and measured it
with two chips (78×24, 46×24, spacing 8):

| Proposed width | Returned size | Correct? |
|---|---|---|
| `nil` (`.unspecified`) | `132 × 24` | yes |
| `.infinity` | `132 × 24` | yes |
| `400` | `400 × 24` | greedy — claims the whole proposal rather than `min(400, 132)` |
| `0` (`.zero`) | `0 × 56` | wrong — reports a **minimum width of 0** while its subviews are 78pt wide |

Consequences: (a) reporting `0` as the minimum tells the parent the chip row can shrink to
nothing, and because both passes measure subviews with `sizeThatFits(.unspecified)` and place them
with `ProposedViewSize(size)`, a chip is **never** offered a narrower width — so at a container
width below one chip's natural width the chips draw *outside* `bounds` instead of wrapping or
truncating, which is precisely the clipping the wrapping layout was added to prevent, just moved to
a narrower threshold; (b) always returning the full finite proposal makes the layout greedy, which
collapses the `Spacer()` in `RestaurantRowView` — visually identical today (chips are leading
aligned and the fee has `layoutPriority(1)`), but it is not the layout contract the code reads as.
→ Return `CGSize(width: min(maxWidth, totalWidth), height: ...)`, and place with
`ProposedViewSize(width: min(size.width, bounds.width), height: size.height)` so an oversized chip
truncates inside the bounds instead of overflowing. Then verify once at `.accessibility1`
(Simulator → Settings → Accessibility → Display & Text Size, or `-UIPreferredContentSizeCategoryName
UICTContentSizeCategoryAccessibilityL` as a launch argument — no extra tooling needed, which also
closes the "reasoned rather than visually confirmed" caveat in `changes.md:186`).
**Not blocking**: it needs a container narrower than a single chip to manifest, it is not a crash,
a data race, or a regression against `main`, and the common path is now strictly better than the
old non-wrapping `HStack`.

### NIT

**[NIT] R2** `DesignSystemViews.swift:129-172` — `FlowLayout` declares `cache: inout ()` and then
calls `subview.sizeThatFits(.unspecified)` for every subview in **both** passes. The `Cache`
associated type exists exactly to carry measured sizes from `sizeThatFits` into `placeSubviews`.
Negligible for two chips; worth doing before this primitive is reused. It also ignores
`subviews[i].spacing` preferences and top-aligns every item within a line — fine for uniform chips,
surprising for mixed content.

**[NIT] R3** `HomeFeedUITests.swift:102-113` — the chip test scrolls to the **bottom** for
`chips.Casa Lola` and only then asserts on `chips.Taquería Norte`, the **top** row, relying on the
`LazyVStack` retaining off-screen rows in the a11y tree. It passes today (and passed under mutation),
but it is the one ordering in the file that depends on lazy-stack retention. → Assert Taquería Norte
first while it is on screen, then `scrollUntilVisible` for Casa Lola.

**[NIT] R4** `FeedSubviews.swift:90, 156`, `FeedView.swift:63` — accessibility identifiers are keyed
on **mock content** (`offerCard.Taquería Norte`, `chips.Casa Lola`). When a real provider replaces
`MockFeedContentProvider`, every one of these selectors goes stale and the tests fail for a reason
unrelated to the code under test. → Either key on `offer.id` / `restaurant.id` and have the test
resolve by index within `offersCarousel`, or keep names but add a one-line comment tying them to the
mock so the coupling is deliberate.

**[NIT] R5** `PideYaTests/FeedTests.swift` — MUST-FIX 5 (stable IDs) has **no test guarding it**.
The whole point of the `static let` seed arrays is that identity survives repeated calls, and
nothing asserts it, so a future refactor back to `UUID()` per call would go unnoticed. → One line:
`#expect(provider.offers().map(\.id) == provider.offers().map(\.id))`.

**[NIT] R6** `PideYaTests/FeedTests.swift:126-137` — acceptance criterion 5 names the exact strings
`Mexicana · ★ 4,8` / `Italiana · ★ 4,7` / `Casera · ★ 4,9`, but `subtitleTextComposesStarSeparator`
still only asserts `.contains(" · ★ ")`. The `Offer` twin (`:159-168`) asserts the full string.
→ Make the `Restaurant` one assert the full composed string too, for symmetry and criterion fidelity.

**[NIT] R7** `DesignSystemViews.swift:58` — `.clear` in `ChipView.backgroundColor` is still the one
colour literal outside `Theme.swift`, and the widened criterion-8 grep does not cover it either.
Carried over unchanged from the first review, still the lowest-severity form of the issue (absence
of fill, not a palette choice).

## Answers to the specific re-review questions

**2. Are the new UI tests real?** Yes — mutation-proven, see the table above. Three separate
injected regressions each produced exactly one targeted failure. The assertions are neither
trivially true nor weakened. Two further points in their favour: `XCTAssertFalse(...exists)` is used
for the negative half of the round-trip rather than the classic "assert the positive twice" cop-out,
and `scrollUntilVisible` fails loudly (via the following `waitForExistence`) if its swipe budget is
exhausted rather than silently returning. The only soft spot is the ordering in R3.

**3. Are the new accessibility identifiers test-driven pollution?** No — reasonable, with one
caveat worth stating plainly. `.accessibilityIdentifier` itself is inert: it is never spoken by
VoiceOver and exists precisely for UI-test targeting, so `offersCarousel` and `offerCard.<name>` cost
nothing at runtime. `.accessibilityElement(children: .contain)` is **not** inert — it inserts a
container node into the accessibility tree. But `.contain` (as opposed to `.combine` or `.ignore`)
preserves every descendant as an independently navigable element, and grouping an offer card or a
chip row is defensible VoiceOver semantics on its own merits, not just test scaffolding. Criteria 6
and 7 are unverifiable without queryable containers, so this was the minimum viable change rather
than a shortcut. The real cost is R4's coupling to mock content, not the identifiers themselves.

**4. Is the hand-rolled `FlowLayout` safe?** Mostly. The wrap arithmetic, line-height tracking and
`totalWidth` accumulation are correct, `nil`/`.infinity` proposals are handled correctly (verified
numerically), and both passes measure subviews consistently so `placeSubviews` cannot disagree with
`sizeThatFits`. The `.zero` proposal and the never-constrained subview proposal are genuine defects
— see R1. It compiles cleanly under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` without a
`nonisolated` annotation, which is correct: it is view-layer code and belongs on the main actor,
unlike `Theme` / `HomeTab` / the Feed models.

**5. Are the `UUID(uuid:)` IDs correct and stable?** Yes. Non-failable tuple initialiser (no force
unwrap smuggled in), 16 bytes, distinct last bytes, held in `static let` arrays that Swift
initialises exactly once. Stability is real; it is just untested (R5).

**6. Acceptance criteria, re-audited.** 1 PASS (verified myself: build succeeded, zero warnings,
pbxproj clean). 2, 3, 4, 6, 7 now PASS **and are automated**. 5 PASS, with the plan text corrected
to reflect the real U+00A0 output. 8 PASS under the widened grep that can now see named colours.
9 still NOT RUN (`swift-format` genuinely not installed — consistent with CLAUDE.md; manual check
performed). 10 PASS (0-line diff). 11 PASS (max body 17 lines). That is 10 of 11 verified, one
blocked on absent tooling — up from 5 unverified criteria last cycle.

**7. Regressions.** None. `PideYaApp.swift` and `project.pbxproj` byte-identical; no `AnyView`,
`cornerRadius`, `RoundedRectangle`, `ObservableObject`, `@Published`, `try?`, `try!` or force
unwraps anywhere; no retain cycles introduced (`SectionAction` stores a closure in a value-type
`View`, same as before — no long-lived object retains it, so no `[weak self]` is needed); no new
concurrency surface; every `body` still under 40 lines.

## Verdict rationale

Every MUST-FIX is genuinely fixed, and the one that mattered most — the missing UI test suite — was
not merely added but built to a standard that survives mutation testing. Eight of the nine assigned
NICE-TO-HAVEs are closed. The single new risk (`FlowLayout` proposal edge cases) was introduced by a
NICE-TO-HAVE, is not a regression against `main`, degrades gracefully, and needs an extreme layout
to surface. Item 16 remains an open plan-level question for the user, as agreed.

Nothing here justifies spending the second fix cycle. **R1 should be picked up as a follow-up before
`FlowLayout` is reused by another tab**, and R3/R5 are two-line hardening tasks worth folding into
that same follow-up.

VERDICT: APPROVED

