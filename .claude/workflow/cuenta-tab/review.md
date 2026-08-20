# Code review — Cuenta tab

Reviewer: staff iOS review pass. Scope: uncommitted working tree on top of `99df4c3`
(4 modified files, 3 new paths). Build/test/lint/grep results were supplied by the launching
agent and were **not** re-run; everything below is what those results do *not* prove.

Method: 8 scratch-tree mutants (`.../scratchpad/mutants/m0…m7`, each with its own
`-derivedDataPath`), one accessibility-tree probe test, one SIL dump and one `swiftc -typecheck`
isolation probe. The real working tree was never modified — `git status --porcelain` at the end of
the review is byte-identical to the start (same 4 modified + 3 untracked paths).

---

## 1. Verdict on the two documented deviations

### Deviation 1 — removing `.accessibilityElement(children: .ignore)` from the tile `Button`

**Confirmed correct, with one wrong sentence in the write-up.**

Mutant `m1` restores the plan's literal spec (`.accessibilityElement(children: .ignore)` layered on
the `Button`, after `.buttonStyle(.plain)`). A probe test dumped every button, every
`otherElement` and every `staticText`:

```
PROBE-BTN   [5] id=<>                    label=<Perfil, Nombre, foto, direcciones>  frame=(0,222.3,200,120)
PROBE-OTHER [17] id=<account.tile.perfil> label=<Perfil. Nombre, foto, direcciones>
PROBE-COUNT account.tile.perfil any=1 buttons=0 other=1 staticTexts=0   (type=1 → .other)
→ testSixTilesHaveExactLabelsAndUniqueIdentifiers: XCTAssertEqual failed: ("0") is not equal to ("6")
```

So the structural claim in `changes.md` is right: SwiftUI builds **two** elements per tile — the
control's own `.button` node (empty identifier, comma-joined auto label) and an additional
`.other` node that carries the explicit label *and* identifier. `app.buttons` resolves the former,
so the query returns 0.

The sentence *"neither `.accessibilityLabel` nor `.accessibilityIdentifier` was taking effect"* is
**not accurate** — both took effect perfectly, on the wrapper element (`app.otherElements` would
have found it, with the exact `"Perfil. Nombre, foto, direcciones"` label). The precise root cause
is: **`.accessibilityElement(children:)` synthesises a new element for the modified subtree and
that element does not inherit the control's `.button` trait, so the identifier/label move off the
queryable button.** Worth stating that way, because it also means the modifier *duplicates* the
tile in the accessibility tree, which is a VoiceOver defect in its own right — an extra reason to
have removed it.

**The cascade concern is genuinely still handled without the modifier.** Mutant `m0` (pristine)
asserts on counts, not existence, for all six tiles rather than just `perfil`:

```
account.tile.perfil          any=1 buttons=1 other=0 staticTexts=0  type=9 (.button)
account.tile.identidad       any=1 buttons=1 other=0 …
account.tile.seguridad       any=1 …   notificaciones any=1 …   comunicacion any=1 …   pagos any=1 …
account.header any=1  account.grid any=1  account.badges any=1  account.wallet any=1
labels exact, frames 200 × 119.99999999999997
```

One correction to a claim in `plan.md` (risks section) and in the file comments: the tile's inner
`Text`s **do** remain in the query tree — `app.staticTexts["Perfil"]` exists, as do
`"Nombre, foto, direcciones"` and `"Visa ···· 4412 · 12,50 €"`. Crucially, the `m1` and `m0`
static-text dumps are **identical**, i.e. `.ignore` never removed them either. It only ever added
the duplicate `.other` element. Nothing was lost by dropping it.

### Deviation 2 — tile-level `minHeight` + `.contentShape(Rectangle())`

**Claim (b) — `.contentShape` is load-bearing — CONFIRMED.** Mutant `m2` removes only
`.contentShape(Rectangle())`:

```
PROBE-PERFIL frame=(16.0, 240.33, 136.0, 66.00)      ← drawn-content bounds, not the frame box
XCTAssertGreaterThanOrEqual failed: ("66.00001525878906") is less than ("119.9")
```

The reported frame collapses in **both** axes (x 16 not 0, w 136 not 200), which is the signature
of hit-test/accessibility geometry tracking the label's ink rather than the padded frame. The
comment at `AccountSubviews.swift:79-84` describes this accurately. It is also a real hit-target
fix, not just a measurement fix — without it, taps on the empty lower half of a tile miss.

**Claim (a) — "a row-level `.frame(minHeight:)` does not propagate to the row's children" —
DISPROVED.** Mutant `m3` removes the tile-level `minHeight` and keeps the row-level frame
(`AccountSubviews.swift:153`) plus `.contentShape`:

```
PROBE-PERFIL frame=(0.0, 222.33, 200.0, 119.99999999999997)
testGridIsTwoEqualColumnsAtDefaultTextSize … passed
```

Mutant `m6` does the converse (removes the row-level frame, keeps the tile-level one): also 120.0,
both grid tests pass. **Either layer alone produces a 120 pt tile.** The 66 pt measurement the dev
saw was caused *solely* by the missing `.contentShape`; adding the tile-level `minHeight` was not
the fix and the stated SwiftUI layout rule ("a `ScrollView` proposes unbounded height, so
`.frame(minHeight:)` on the row only pads the row's own reported size") is false —
`.frame(minHeight:)` resolves its own height and proposes it down, and the tile's
`maxHeight: .infinity` consumes it.

---

## 2. Findings

### WARNING

- **[WARNING] `PideYa/Home/Account/AccountSubviews.swift:70-78` (with `:153`)** — the 8-line
  comment justifying the tile-level `minHeight` states a SwiftUI layout rule that is
  demonstrably false (mutant `m3`: with that `minHeight` deleted the tile still measures
  200 × 120.0 and both grid tests pass), and the row-level `.frame(minHeight:)` it says is
  inadequate is *still present* on line 153. The screen therefore carries two independent 120 pt
  floors, each documented as if the other did not work — the next person to touch this will delete
  the wrong one on the strength of a comment that is wrong.
  → **Fix:** keep exactly one floor. Recommended: keep the tile-level
  `.frame(maxWidth:.infinity, minHeight:Theme.Size.accountTile, maxHeight:.infinity, alignment:.topLeading)`
  (it is the layer that makes a *single* tile honour the design's 120 pt even outside a row), drop
  `.frame(minHeight: Theme.Size.accountTile)` on line 153, and rewrite the comment to say what is
  actually true: *"`.contentShape(Rectangle())` below is what makes the measured/hit-test frame
  match this box; the `minHeight` is the design's 120 pt floor (DESIGN.md §4.1) and `maxHeight`
  lets siblings equalise."*

- **[WARNING] `.claude/workflow/cuenta-tab/changes.md` (Deviations §2)** — two factual errors in
  the written record. (i) *"`AccountTileGridView.rowView`'s `HStack` now carries no `.frame`
  modifier of its own"* — it does, `AccountSubviews.swift:153`. (ii) The 66 pt failure is
  attributed to two independent causes; only `.contentShape` was causal (mutants `m2`/`m3`/`m6`
  above). This file is the artifact the next feature copies its reasoning from, and the previous
  cycle's cost came from exactly this — a confidently-worded diagnosis that was trusted and wrong.
  → **Fix:** correct both statements; keep the `.contentShape` evidence, drop the
  "row `minHeight` doesn't propagate" claim, and note that the tile-level `minHeight` is a
  deliberate choice of layer rather than a required fix.

### NIT

- **[NIT] `changes.md` (Deviations §1)** — replace *"neither `.accessibilityLabel` nor
  `.accessibilityIdentifier` was taking effect"* with the measured truth: both took effect on a
  synthesised `.other` element that does not carry the `.button` trait, so `app.buttons` missed it
  while `app.otherElements` would have found it. Add the reusable rule this yields:
  **never layer `.accessibilityElement(children:)` on a view that is already a control** — it
  duplicates the element and strips the trait. (`OrdersSubviews.swift:160-171`'s
  `quickActionButton` is the shipped example of the right shape.)

- **[NIT] `PideYa/Home/Account/AccountModels.swift:15-20` and `PideYaTests/AccountTests.swift:143-146`**
  — both say dropping a `nonisolated` annotation *"compiles, but traps at runtime
  (`EXC_BREAKPOINT`…)"*. For **this** file that is wrong in a benign direction: none of the four
  extensions contains a closure literal, so the failure mode is a compile error, proved by
  `swiftc -swift-version 6 -default-isolation MainActor -typecheck` on a copy with `nonisolated`
  stripped from `extension AccountProfile`:
  `error: main actor-isolated property 'badges' can not be referenced from a nonisolated context`.
  → **Fix:** say "the nonisolated test suites below stop compiling" (a stronger guard than a
  runtime trap) and keep the runtime-trap note as the reason the rule exists generally.

- **[NIT] `PideYaUITests/AccountUITests.swift:226-228`** — criterion 10's assertion sits inside
  `if header.exists { … }`, so the test has a silently-vacuous path. It *is* load-bearing today
  (mutant `m7` moved the header into a `.safeAreaInset(edge: .top)`; the test failed with
  `("70.0") is not less than ("70.0") - Header did not move while the screen scrolled`), but the
  guard evaporates the day the header scrolls fully off at some content size.
  → **Fix:** assert the disjunction explicitly, e.g.
  `XCTAssertTrue(!header.exists || header.frame.minY < originalMinY)`, and additionally assert that
  *something* moved (compare `account.grid`'s `minY` before/after) so "nothing scrolled at all"
  cannot pass.

- **[NIT] `PideYaUITests/AccountUITests.swift:206`** — criterion 9's inset guard is real but thin:
  mutant `m4` (bottom `.safeAreaInset` removed) fails by 0.67 pt
  (`("770.33") is greater than ("769.67")`). A future spacing tweak of ~1 pt could hide the
  regression, or manufacture a false failure.
  → **Fix:** assert the footer, not just the sign-out button (the footer is the lowest element and
  clears the bar by a larger margin), or add
  `XCTAssertTrue(footer.frame.maxY <= tabBar.frame.minY - 4)`.

- **[NIT] `PideYaTests/AccountTests.swift:189-194`** — `mockPagosSubtitleIsDerivedFromTheSameWallet`
  uses `hasSuffix(provider.wallet().balanceText)`, which stays green if someone replaces the
  derivation with a hardcoded `"Visa ···· 4412 · 12,50 €"`. It only catches drift *after* the
  balance changes, so criterion 5's "provably not two literals" is proved by
  `paymentSummaryTextReadsTheWalletItIsGiven` (the `balance: 99` case), not by this test.
  → **Fix:** expose `MockAccountContentProvider.paymentMethod()` (it already exists as
  `seedPayment`) and assert
  `pagos?.subtitle == provider.paymentMethod().summaryText(wallet: provider.wallet())`, which no
  literal can satisfy by accident.

- **[NIT] `PideYa/Home/Account/AccountSubviews.swift:211-217`** — `.lineLimit(1)` on `balanceValue`
  applies in both branches, including the accessibility-size `VStack`. Harmless for `12,50 €`;
  a four-digit balance at AX5 would truncate rather than wrap in the one branch that has room.
  → **Fix:** move `.lineLimit(1)`/`.layoutPriority(1)` into the `HStack` branch only (they exist to
  stop the `Spacer` squeezing the value), or add `.minimumScaleFactor(0.8)`.

- **[NIT] `PideYa/Home/Account/AccountSubviews.swift:230`** — the footer hardcodes the app version
  (`"PideYa 1.0 · Términos · Privacidad"`), which will drift from `CFBundleShortVersionString`
  the first time the version bumps. It matches DESIGN.md §5 and the localization pass is out of
  scope, so this is a note, not a change request — but it belongs on the follow-up list next to the
  string-catalogue work.

- **[NIT] `PideYa/Home/Account/AccountSubviews.swift:122-127`** — `rows` is a computed property
  that re-runs `AccountTileRow.rows(from:columns:)`, and `rows.count` inside the `ForEach` body
  re-chunks once per row. Six tiles, so immaterial today.
  → **Fix:** `let rows = rows` at the top of `body` (or `let lastIndex = rows.count - 1`).

- **[NIT] `PideYa/Home/Account/AccountModels.swift:82-90`** — `AccountTile.id` is
  `kind.rawValue`, so a provider returning two tiles of the same kind yields duplicate `ForEach`
  ids (`AccountSubviews.swift:143`) and SwiftUI's duplicate-ID diffing breakage. Unreachable from
  the mock; the test helper `makeTiles` already wraps with `%` and would hit it above 6.
  → **Fix:** either document the uniqueness precondition on `AccountContentProviding.tiles()` or
  make `rows(from:)` de-duplicate defensively. Cheapest is one line of doc comment.

---

## 3. Acceptance criteria audit

| # | Criterion | Status | Evidence beyond "the test passed" |
|---|---|---|---|
| 1 | Build 0 warnings, pbxproj/App untouched | PASS | supplied; `git diff --stat` for both is empty (re-checked) |
| 2 | Routing + no regression in Inicio/Pedidos | PASS | design-system edits are additive only (`.outlined` arms unchanged, three new `Typeface`/`Size` tokens, one new `ChipView` case); the only other shipped-file edits are one `switch` arm and one defaulted init parameter; no positional `HomeTabViewModel(…)` call site exists |
| 3 | Two-line name; badges are not controls | PASS | mutation-proved: single interpolated `Text` (`m5`) → `testNameRendersAsTwoSeparateLines` fails at line 54 |
| 4 | Six tile buttons, exact labels, cascade == 1 | PASS | probe extends the check to **all six** identifiers + 4 containers: every one resolves to exactly 1 element, type 9 (.button), exact label |
| 5 | Balance once as text, once in the Pagos label | PASS (see NIT) | UI half solid; the unit half's single-source claim rests on `paymentSummaryTextReadsTheWalletItIsGiven`, not on the `hasSuffix` test |
| 6 | Tiles/sign-out are no-ops; footer inert | PASS | — |
| 7 | Two equal columns, height ≥ 120 | PASS | measured 200 × 119.99999999999997 independently in `m0`; the `120 - 0.1` tolerance is legitimate, not a weakened check |
| 8 | Collapse to one column at AccessibilityL | PASS | mutation-proved: `columns` pinned to 2 (`m5`) → fails, `("260.67") is not less than ("260.67")` |
| 9 | Sign-out/footer above the tab bar at AX size | PASS (thin) | mutation-proved: bottom `.safeAreaInset` removed (`m4`) → fails by 0.67 pt |
| 10 | Header scrolls, is not pinned | PASS | mutation-proved: header hoisted into `.safeAreaInset(edge:.top)` (`m7`) → fails, `("70.0") is not less than ("70.0")` |
| 11 | Five prohibited-pattern greps | PASS | supplied; the two doc-comment rewordings in `changes.md` §3 are legitimate (they avoid self-matches, they do not weaken the greps) |
| 12 | `MONEDERO` grows at AccessibilityL | PASS | mutation-proved: `EyebrowLabel` switched to `.font(.system(size:11,weight:.bold))` (`m5`) → fails, `13.33 -> 13.33` |
| 13 | `swift-format lint` clean | PASS | supplied |
| 14 | Bodies < 40 lines, previews present | PASS | measured: 19 / 13 / 30 / 12 / 15 lines; 4 previews in `AccountSubviews`, 1 in `AccountView`, 2 added to `DesignSystemViews` |
| 15 | 84 tests green | PASS | supplied |

## 4. Concurrency / Swift 6 (verified empirically, not by reading)

`xcrun swiftc -swift-version 6 -default-isolation MainActor -enable-upcoming-feature
NonisolatedNonsendingByDefault -enable-upcoming-feature InferIsolatedConformances -emit-sil` on
`AccountModels.swift` (3 000+ SIL lines): **0 occurrences of `Isolation: global_actor`** and
**0 `swift_task_isCurrentExecutor` / `_checkExpectedExecutor`**. All four `nonisolated extension`
blocks, `private nonisolated let esES`, and every closure inside `AccountTileRow.rows(from:columns:)`
are genuinely nonisolated. The non-`@MainActor` suites (`AccountTileKindTests`,
`AccountFormattingTests`, `AccountTileRowTests`, `MockAccountContentProviderTests`) do exercise the
extension-declared members and the closure-bearing chunker, and dropping any annotation breaks the
build (proved above). `AccountViewModel` is correctly `@MainActor @Observable` with a synchronous,
provider-injected init and no stored provider; no `Task`, no detached work, no retain cycles (no
escaping closure captures `self`; `action` / `onSelect` / `onSignOut` are plain no-ops passed down).

## 5. What is done well (do not "fix" these)

- The single `needsAttention` flag driving icon colour, subtitle colour **and** subtitle weight
  (`AccountSubviews.swift:65,102-108`) — DESIGN.md §4.3's "the red is a state" made structural.
- `PaymentMethod.summaryText(wallet:)` taking the wallet rather than a number: exactly one `12.50`
  literal in the feature.
- `AccountTileRow.rows(from:columns:)` as a `static func` on the owning type (not a top-level free
  function): clamped `columns`, `min(…, tiles.count)` bound, no force-unwrap, no out-of-range
  slice, and directly reachable from a nonisolated test — this is the `filledStars` NIT correctly
  applied.
- `EyebrowLabel` takes its copy as a parameter, so no Spanish literal lands in `DesignSystem/`.
- `.outlinedSubtle` added by widening existing `switch` arms rather than editing them; `.outlined`
  and `.promo` behaviour is bit-identical for Inicio/Pedidos.
- Badges in a real `FlowLayout`, no fixed chip height, no `.clipped()` — §3.3's overflow artifact
  correctly *not* reproduced.
- ViewModel ownership is right: `@State` in `HomeTabView`, plain `let` in `AccountView`, defaulted
  init parameter so `PideYaApp.swift` needs no change.

## 6. Still uncovered by any automated check (manual pass)

Unchanged from the plan's own list, and still true: SF Symbol identities (a typo renders blank and
no test can see it), the iPhone SE @ `.xxxLarge` two-column worst case, the column divider butting
cleanly into both boundary rules, the inset-vs-full-bleed rule contrast in `MONEDERO`, and dark
mode. Colour fidelity is not testable from XCUITest at all — the `secondary`/`#9F9D9D` and
`accent`/`#AE1800` collapses are plan-sanctioned and were confirmed by reading only.

---

Nothing here is behaviourally broken and no criterion is unproved; the two WARNINGs are a false
mechanism recorded in shipped source next to a redundant modifier, and a written record that
contradicts the file it describes. Both are a few lines to fix and need no test changes.

VERDICT: CHANGES_REQUESTED — 0 critical, 2 warnings
