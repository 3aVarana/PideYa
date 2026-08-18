# Feature: Pedidos tab (order history + active order tracking)

Build the third tab of the Home shell — `Pedidos` — replicating
`.claude/workflow/pedidos-tab/DESIGN.md`. A pinned header, one `EN CURSO` active-order card
with a four-stage progress tracker, and an `ANTERIORES` list of past orders. No networking,
no persistence: static mock data behind a protocol, exactly like `Feed`.

`Buscar` and `Cuenta` stay on `PlaceholderTabView`. The `Inicio` tab must not regress: the only
edits to shipped files are two *additive* design-system extensions and the two-line routing
change in `HomeTabView` / `HomeTabViewModel`.

Source spec: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/pedidos-tab/DESIGN.md`

## Existing patterns to follow

- `PideYa/Home/Feed/FeedView.swift:14-37` — a screen owned by `HomeTabViewModel` holds its
  ViewModel as a **plain `let`** (never `@State`) and takes a `bottomInset: CGFloat = 0`.
  `OrdersView` copies this signature verbatim. See `CLAUDE.md` "ViewModel ownership".
- `PideYa/Home/Feed/FeedView.swift:39-58` — `NavigationStack { ScrollView { … } }` with
  `.scrollIndicators(.hidden)`, `.safeAreaInset(edge: .top)` for the pinned header,
  a **second** `.safeAreaInset(edge: .bottom)` carrying `bottomInset`, and
  `.toolbar(.hidden, for: .navigationBar)`. `OrdersView` mirrors this exactly — see
  DESIGN.md §7.2 and acceptance criterion 12.
- `PideYa/Home/Feed/FeedView.swift:101-112` — `LazyVStack(spacing: 0)` + `ForEach` +
  interleaved `HardRule`. **Deliberately diverges here**: the feed indents its rule past the
  thumbnail and omits it after the last row; Pedidos does neither (DESIGN.md §4.4).
- `PideYa/Home/Feed/FeedModels.swift:10` + `:42-68` — `private let esES = Locale(identifier: "es_ES")`
  at file scope, and all display strings as computed properties on the model so they are
  unit-testable without a view. Same file-scope constant is re-declared in `OrdersModels.swift`
  (it is `private`, so it does not leak across files).
- `PideYa/Home/Feed/FeedModels.swift:70-81` — `nonisolated protocol …Providing: Sendable` with
  synchronous methods, plus a `private static func stableID(_:) -> UUID` seed helper that avoids
  force-unwrapping `UUID(uuidString:)` (`NeverForceUnwrap` is on).
- `PideYa/Home/Feed/FeedViewModel.swift:11-23` — `@MainActor @Observable final class`,
  `private(set) var` state, provider injected via a **defaulted** init parameter, assigned
  synchronously in `init` with no `Task`/`load()`/loading state.
- `PideYa/Home/HomeTabView.swift:25-39` — the tab bar's real height is measured with
  `.onGeometryChange` into `tabBarHeight` and passed down; `selectedScreen` is a
  `@ViewBuilder` `switch` returning concrete branches (**no `AnyView`**).
- `PideYa/Home/Feed/FeedSubviews.swift:11-31` — pinned-header shape: `VStack` +
  `.background(Theme.Palette.background)` + `.overlay(alignment: .bottom) { HardRule() }` +
  `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` cap where a fixed-size box is involved.
- `PideYa/Home/Feed/FeedSubviews.swift:121-140` — list-row shape: `HStack(alignment: .top, spacing: md)`
  of `HatchedPlaceholder().frame(...)` + a details `VStack` + trailing price with
  `.lineLimit(1).layoutPriority(1)`, capped at `.accessibility1` because the thumbnail is fixed.
- `PideYa/DesignSystem/DesignSystemViews.swift:18-20` — every `Text` gets `.themeFont(_:)`,
  never `.font(.system(size:))` (DESIGN.md §7.1).
- `PideYa/DesignSystem/DesignSystemViews.swift:81-158` — `ChipView(style: .promo)` and
  `SectionHeaderView(title:action:)` with the bundled `SectionAction`. Both reused as-is.
- `PideYa/DesignSystem/Theme.swift:15` — `nonisolated enum Theme` namespace; **every** colour
  literal lives in `Theme.Palette` and nowhere else.
- `PideYaTests/FeedTests.swift:13-43` — a file-`private` `Stub…ContentProvider` returning
  distinct data, used to prove constructor injection actually flows.
- `PideYaUITests/HomeFeedUITests.swift:21-27` — `scrollUntilVisible(_:in:maxSwipes:)` helper for
  `LazyVStack` rows that do not exist until scrolled into view.
- `.swift-format` + `.githooks/pre-commit` — 4-space indent, 120 cols, no force-unwrap/try, no
  implicitly-unwrapped optionals, `///` doc comments only, **ASCII identifiers only** (Spanish
  accents belong in string literals, never in symbol names — hence `Orders`, not `Pedidos`, as
  the symbol/folder prefix), trailing commas in multi-element collections.
- `PideYa.xcodeproj/project.pbxproj:32-48` — `PBXFileSystemSynchronizedRootGroup` with no
  exception set: new `.swift` files under `PideYa/`, `PideYaTests/`, `PideYaUITests/` join their
  target automatically. **Do not hand-edit the pbxproj.**

### Naming and placement decision

New code lives in `PideYa/Home/Orders/`, mirroring `PideYa/Home/Feed/` (folder-per-feature,
`XModels.swift` / `XViewModel.swift` / `XSubviews.swift` / `XView.swift`). English symbol
names, Spanish string literals — the same split `Feed`/`Restaurant`/`Offer` already uses.

## Tasks

1. [x] Edit `PideYa/DesignSystem/Theme.swift` — add `Palette.outline`, `Palette.surface`, and three `Size` tokens. Purely additive.
2. [x] Edit `PideYa/DesignSystem/DesignSystemViews.swift` — add `StarRatingView` and `OutlinedActionButton`. Purely additive.
3. [x] Add `PideYa/Home/Orders/OrdersModels.swift` — `OrderStage`, `ActiveOrder`, `PastOrder`, es-ES display text, `OrdersContentProviding` + `MockOrdersContentProvider`.
4. [x] Add `PideYa/Home/Orders/OrdersViewModel.swift` — `@MainActor @Observable` VM with a constructor-injected provider and a derived summary string.
5. [x] Add `PideYa/Home/Orders/OrdersSubviews.swift` — `OrdersHeaderView`, `ActiveOrderCardView`, `OrderProgressView`, `PastOrderRowView`.
6. [x] Add `PideYa/Home/Orders/OrdersView.swift` — compose the pinned header + `EN CURSO` + `ANTERIORES` into a scroll view.
7. [x] Edit `PideYa/Home/HomeTabViewModel.swift` + `PideYa/Home/HomeTabView.swift` — own an `OrdersViewModel` and route `case .pedidos`.
8. [x] Add `PideYaTests/OrdersTests.swift` — Swift Testing coverage for formatting, stage logic, mock data, derived counts and injection.
9. [x] Add `PideYaUITests/OrdersUITests.swift` — XCUITest coverage for the acceptance criteria that need a running app.

---

### 1. `PideYa/DesignSystem/Theme.swift` (edit — additive only)

Do not change or re-order any existing token; the Inicio tab depends on all of them.

**`Theme.Palette` — two new colours:**

- `outline` = `#C9C9C9`. Used by (a) the `REPETIR` button's hairline border (DESIGN.md §4.3)
  and (b) the un-reached fourth progress segment (§3.4). It is **not** `placeholder` (`#D9D9D9`):
  `placeholder` means "fill behind a missing image", and a control border and an image stand-in
  must be free to diverge. The mockup measured `#C9C9C9` in both new places, so one token covers
  both. Doc comment must say this.
- `surface` = `#FFFFFF`. The pure-white fill of the square bolt button (§3.5), which reads
  lighter than the card body. Deliberately *not* `onAccent`, which happens to share the same RGB
  but means "foreground on an accent fill"; collapsing them would couple two unrelated roles.
  Doc comment must say this.

**`Theme.Size` — three new tokens:**

- `orderThumbnail: CGFloat = 64` — the square hatched thumbnail used by both the active card
  (§3.3, ≈61×65 pt) and the past-order rows (§4.1, ≈65 pt). One token, both call sites.
- `actionButton: CGFloat = 48` — minimum height of the `Ver seguimiento` button and the exact
  side of the square bolt button (§3.5 says the visual box reads 48–52 pt and 48 is the HIG tap
  minimum). Applied as `minHeight` on the primary button so it can grow with Dynamic Type, and
  as a fixed `width`/`height` on the square one.
- `progressSegment: CGFloat = 5` — thickness of a tracker segment (§3.4, ≈4–5 pt).

**No new `Typeface` tokens.** Every string on this screen maps to an existing token:
`brand` (the `Pedidos` title), `subtitle` (the count line, row line 2), `subtitleBold`
(`Ayuda`, `Ver seguimiento`), `band` (`EN CAMINO` / `LLEGA 20:45`), `cardTitle` (active-order
name + total), `rowTitle` (past-order name + total), `chip` (progress labels, `REPETIR`),
`sectionTitle` (section headers). **Decision on the title size:** reuse `brand` (40/heavy)
rather than adding a ~34 pt token — DESIGN.md §2 offers both and its own header says point
sizes are ±transcription error at 2.29 px/pt; a new near-duplicate token is not worth it.

**No new `IconSize` tokens.** All three new glyphs (`questionmark.circle`, `bolt.fill`,
`star`/`star.fill`) are sized by applying `.themeFont(_:)` to the `Image`, since SF Symbols
size off the ambient font. This is *better* than `HomeTabBar`'s `.font(.system(size: Theme.IconSize.tab))`
because the glyphs then scale with Dynamic Type, and it makes the "no `.font(` in this feature"
grep in acceptance criterion 9 clean. Do not retrofit `HomeTabBar` — out of scope.

### 2. `PideYa/DesignSystem/DesignSystemViews.swift` (edit — additive only)

Two new `struct`s, each with a `#Preview`. `ChipView`, `SectionHeaderView`, `HardRule`,
`HatchedPlaceholder`, `FlowLayout` and `themeFont` are untouched.

```
struct StarRatingView: View {
    let score: Double
    let outOf: Int
    init(score: Double, outOf: Int = 5)
}
```

- `HStack(spacing: 0)` of `ForEach(0..<outOf, id: \.self)`; each element is
  `Image(systemName: index < filledCount ? "star.fill" : "star")`, `.themeFont(Theme.Typeface.chip)`,
  `.foregroundStyle(Theme.Palette.accent)` — filled *and* hollow stars are accent red (§4.2a).
- `private var filledCount: Int { min(outOf, max(0, Int(score.rounded()))) }` — clamped, so no
  crash or force-unwrap for out-of-range input.
- `.accessibilityElement(children: .ignore)` + `.accessibilityLabel("\(filledCount) de \(outOf) estrellas")`,
  so VoiceOver reads one phrase instead of five images.

```
struct OutlinedActionButton: View {
    let title: String
    let action: () -> Void
    init(title: String, action: @escaping () -> Void)
}
```

- A real `Button`. Label: `Text(title)` `.themeFont(Theme.Typeface.chip)`,
  `.foregroundStyle(Theme.Palette.ink)`, `.padding(.horizontal, Theme.Spacing.sm)`,
  `.padding(.vertical, Theme.Spacing.xs)`, then
  `.overlay(Rectangle().strokeBorder(Theme.Palette.outline, lineWidth: Theme.Stroke.hairline))`.
  Transparent fill (no `.background`).
- `.buttonStyle(.plain)` so the label keeps ink and does not pick up the accent tint.
- **Why a new component rather than a `ChipView` style:** `ChipView` is not a `Button` and
  `.outlined` is ink-bordered; DESIGN.md §4.3 forbids collapsing the two. `ChipView` is shipped
  and covered by UI tests, so it is not modified.

### 3. `PideYa/Home/Orders/OrdersModels.swift`

**Data model shape.** All value types → `Sendable` automatically; declared `nonisolated` because
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` would otherwise isolate them to the main actor and
they must be usable from the provider without hopping. `Hashable` for future
`navigationDestination(for:)` use. `Identifiable` via an explicit `let id: UUID` so mock data has
stable identity across re-renders.

```
nonisolated enum OrderStage: String, CaseIterable, Identifiable, Hashable, Sendable {
    case confirmado, enCocina, enCamino, entregado      // declaration order == tracker order
    var id: String { rawValue }
    var label: String        // "CONFIRMADO", "EN COCINA", "EN CAMINO", "ENTREGADO"
    var stepIndex: Int       // 0, 1, 2, 3 — via an explicit switch, NOT
                             // allCases.firstIndex(of:)! (NeverForceUnwrap is on)
}

nonisolated struct ActiveOrder: Identifiable, Hashable, Sendable {
    let id: UUID
    let restaurantName: String   // "Taquería Norte"
    let total: Decimal           // 24.60  — numeric, NOT "24,60 €"
    let itemCount: Int           // 3
    let orderNumber: String      // "4821" — String, so no grouping separator can ever appear
    let stage: OrderStage        // .enCamino
    let etaText: String          // "20:45" — see the Date decision below
}

nonisolated struct PastOrder: Identifiable, Hashable, Sendable {
    let id: UUID
    let restaurantName: String
    let total: Decimal
    let dateText: String         // "12 ago" — see the Date decision below
    let itemCount: Int
    let rating: Double?          // nil == unrated == VALORAR PEDIDO chip (§4.2b)
}
```

**Decision — dates and times are stored pre-formatted `String`s, not `Date`s.** `12 ago` /
`20:45` come from the mockup as literals, and es-ES abbreviated months round-trip differently
across ICU versions (`ago`, `ago.`, `ag.`), so a `Date` + `.formatted(.dateTime…)` would make the
rendering OS-version-dependent and the tests flaky for a screen with no real data source. Money
and rating stay numeric because their formatters *are* stable and their comma/`€` behaviour is
the thing under test. A doc comment in the file must state this and note that a real backend
would carry `Date` and move the formatting into a computed property.

**Display formatting** (computed properties in the same file, unit-testable without a view):

- `private let esES = Locale(identifier: "es_ES")` at file scope.
- `ActiveOrder.totalText` / `PastOrder.totalText` →
  `total.formatted(.currency(code: "EUR").locale(esES))` → `"24,60\u{00A0}€"`. **Emits U+00A0
  before `€`, not a plain space** (DESIGN.md §7.4).
- `ActiveOrder.statusText` → `stage.label` → `"EN CAMINO"`.
- `ActiveOrder.arrivalText` → `"LLEGA \(etaText)"` → `"LLEGA 20:45"` (literal uppercase).
- `ActiveOrder.subtitleText` → `"\(itemCountText) · Pedido #\(orderNumber)"` →
  `"3 artículos · Pedido #4821"`. Middle dot is `·` (U+00B7) with a space either side.
- Shared `itemCountText` → `count == 1 ? "1 artículo" : "\(count) artículos"`. Implemented once
  (a `private func` at file scope or an `Int` extension) and used by both models. The mockup only
  ever shows counts ≥ 2, but `1 artículos` is a one-ternary bug worth pre-empting; tested.
- `PastOrder.subtitleText` → `"\(dateText) · \(itemCountText)"` → `"12 ago · 2 artículos"`.
- `PastOrder.ratingText` → `String?`; `nil` when `rating` is `nil`, else
  `rating.formatted(.number.precision(.fractionLength(1)).locale(esES))` → `"5,0"`, `"4,0"`.
  Use `if let`/`map`, never force-unwrap.
- `PastOrder.isRated` → `rating != nil`.

**Uppercase copy is stored as literal uppercase strings** (`"EN CURSO"`, `"ANTERIORES"`,
`"EN CAMINO"`, `"REPETIR"`, `"VALORAR PEDIDO"`, `"LLEGA …"`). **Never `.textCase(.uppercase)`** —
it leaves the accessibility value lowercase and would break every UI-test assertion below. This
bit the previous feature.

**Dependency injection:**

```
nonisolated protocol OrdersContentProviding: Sendable {
    func activeOrders() -> [ActiveOrder]
    func pastOrders() -> [PastOrder]
}

nonisolated struct MockOrdersContentProvider: OrdersContentProviding {
    private static func stableID(_ lastByte: UInt8) -> UUID   // same helper as MockFeedContentProvider
    private static let seedActive: [ActiveOrder]
    private static let seedPast: [PastOrder]
}
```

`stableID` is duplicated from `MockFeedContentProvider` (3 lines, `private static`) rather than
hoisted, so no shipped file changes. Noted in Risks.

**Seed data.** Active (one), exactly per DESIGN.md §6: `Taquería Norte`, `24.60`, 3 items,
order `"4821"`, `.enCamino`, `"20:45"`.

Past orders — **twelve**, so the derived header reads `1 en curso · 12 anteriores` exactly as
the mockup does (see Open question 1). The first three are pinned by §6; the remaining nine are
invented filler and must be marked as such in a comment:

| # | Restaurant | Total | Date | Items | Rating |
|---|---|---|---|---|---|
| 1 | `Forno Bianco` | 18.90 | `12 ago` | 2 | 5.0 |
| 2 | `Casa Lola` | 31.20 | `9 ago` | 4 | nil |
| 3 | `Sakura Ramen` | 26.50 | `4 ago` | 2 | 4.0 |
| 4 | `Taquería Norte` | 22.40 | `2 ago` | 3 | 5.0 |
| 5 | `Bar Manolo` | 14.75 | `30 jul` | 2 | nil |
| 6 | `Wok Express` | 19.30 | `27 jul` | 3 | 4.0 |
| 7 | `Forno Bianco` | 27.10 | `24 jul` | 3 | 5.0 |
| 8 | `La Parrilla` | 35.80 | `20 jul` | 5 | 4.0 |
| 9 | `Poke Bowl Co` | 16.20 | `16 jul` | 2 | nil |
| 10 | `Casa Lola` | 29.95 | `11 jul` | 4 | 5.0 |
| 11 | `Sakura Ramen` | 23.40 | `7 jul` | 2 | 4.0 |
| 12 | `Bar Manolo` | 12.60 | `2 jul` | 1 | nil |

Row 12 has `itemCount == 1`, which exercises the `1 artículo` singular path on screen.
IDs: active `stableID(1)`; past `stableID(21)` … `stableID(32)`.

### 4. `PideYa/Home/Orders/OrdersViewModel.swift`

```
@MainActor
@Observable
final class OrdersViewModel {
    private(set) var activeOrders: [ActiveOrder]
    private(set) var pastOrders: [PastOrder]

    var summaryText: String            // computed, derived — never stored
    var hasActiveOrders: Bool          // computed: !activeOrders.isEmpty

    init(provider: OrdersContentProviding = MockOrdersContentProvider())
}
```

- `init` reads both provider methods synchronously and assigns. No `Task`, no `load()`, no
  loading/error state — there is no I/O. Provider parameter defaulted so `OrdersViewModel()`
  and `HomeTabViewModel()` stay call-site-free. Do not store the provider.
- `summaryText` is **computed from the arrays**, so it is structurally incapable of
  contradicting what the list renders:
  `"\(activeOrders.count) en curso · \(pastOrders.count) \(pastOrders.count == 1 ? "anterior" : "anteriores")"`.
  (`en curso` is invariant in Spanish for both 1 and N; `anterior/anteriores` is not.)
- No `var` state analogous to `FeedViewModel.searchText`: nothing on this screen is two-way
  bound, so `OrdersView` needs no `Bindable`. Stated here explicitly so the implementer does not
  add one out of pattern-matching.

### 5. `PideYa/Home/Orders/OrdersSubviews.swift`

Four internal `struct`s (internal, not private, because they live in a separate file from
`OrdersView` — the same trade `FeedSubviews.swift` makes to keep bodies under 40 lines). Each
gets a `#Preview`.

**`OrdersHeaderView(title:summaryText:onHelp:)`** — the pinned header (§2).

- `body`: a `VStack(alignment: .leading)` containing `titleRow`, then
  `.padding(.horizontal, Theme.Spacing.lg)`, `.padding(.top, Theme.Spacing.md)`,
  `.padding(.bottom, Theme.Spacing.lg)`, `.background(Theme.Palette.background)`,
  `.overlay(alignment: .bottom) { HardRule() }`, and
  `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` — same cap and reason as
  `FeedHeaderView`, since the 40 pt `brand` title cannot grow without bound beside the Ayuda
  group. `.accessibilityIdentifier("orders.header")`.
- `private var titleRow`: `HStack(alignment: .bottom)` of a leading
  `VStack(alignment: .leading, spacing: Theme.Spacing.xs)` (`Text(title)` `.themeFont(brand)`
  `.kerning(Theme.Kerning.brand)` ink; `Text(summaryText)` `.themeFont(subtitle)` secondary),
  a `Spacer()`, and `helpButton`. `.bottom` alignment is what puts the Ayuda group on the
  subtitle's row rather than the title's (§2).
- `private var helpButton`: a `Button(action: onHelp)` whose label is
  `VStack(alignment: .leading, spacing: Theme.Spacing.xs)` of
  `HStack(spacing: Theme.Spacing.xs) { Image(systemName: "questionmark.circle").themeFont(subtitleBold); Text("Ayuda").themeFont(subtitleBold) }`
  followed by `HardRule(color: Theme.Palette.ink, thickness: Theme.Stroke.rule)`.
  Because the rule is inside the `VStack`, it spans exactly the icon+label group's width and
  nothing more (§2). `.buttonStyle(.plain)`, `.foregroundStyle(Theme.Palette.ink)`,
  `.accessibilityIdentifier("orders.helpButton")`.

**`ActiveOrderCardView(order:onTrack:onQuickAction:)`** (§3.1–§3.5).

- `body`: `VStack(spacing: 0) { statusBand; cardBody }`,
  `.background(Theme.Palette.searchFill)` (the existing near-`#EAEAE8` token, per §3.1 — do not
  add a new colour), `.overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.rule))`
  (2 pt, heavier than the feed's 1 pt cards), `.accessibilityElement(children: .contain)`,
  `.accessibilityIdentifier("orders.activeCard")`. No corner radius, no clip shape.
- `private var statusBand`: `HStack { Text(order.statusText); Spacer(); Text(order.arrivalText) }`,
  both `.themeFont(Theme.Typeface.band)` `.kerning(Theme.Kerning.sectionTitle)`
  `.foregroundStyle(Theme.Palette.onAccent)`; then `.padding(.horizontal, Theme.Spacing.md)`,
  `.padding(.vertical, Theme.Spacing.sm)`, `.frame(maxWidth: .infinity)`,
  `.background(Theme.Palette.accent)`. **Height comes from padding, not a fixed `.frame(height:)`** —
  §3.2's 31 pt is what 13 pt heavy text plus 8 pt padding produces, and pinning it would clip at
  large Dynamic Type.
- `private var cardBody`: `VStack(alignment: .leading, spacing: Theme.Spacing.md) { summaryRow; OrderProgressView(stage: order.stage); actionRow }.padding(Theme.Spacing.md)`.
- `private var summaryRow`: `HStack(alignment: .top, spacing: Theme.Spacing.md)` of
  `HatchedPlaceholder().frame(width: Theme.Size.orderThumbnail, height: Theme.Size.orderThumbnail)`
  and a `VStack(alignment: .leading, spacing: Theme.Spacing.xs)` of
  `HStack { Text(order.restaurantName).themeFont(cardTitle).lineLimit(1); Spacer(); Text(order.totalText).themeFont(cardTitle).lineLimit(1).layoutPriority(1) }`
  (both ink) and `Text(order.subtitleText).themeFont(subtitle)` secondary.
- `private var actionRow`: `HStack(spacing: Theme.Spacing.md) { trackButton; quickActionButton }`.
- `private var trackButton`: `Button(action: onTrack)` labelled
  `Text("Ver seguimiento").themeFont(subtitleBold).foregroundStyle(Theme.Palette.onAccent)`
  then `.padding(.horizontal, Theme.Spacing.md)` then
  `.frame(maxWidth: .infinity, minHeight: Theme.Size.actionButton, alignment: .leading)`
  then `.background(Theme.Palette.accent)` then
  `.overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.rule))`.
  **Modifier order matters**: padding before frame is what produces a left-inset, *not centred*,
  label (§3.5 calls this out as deliberate). `.buttonStyle(.plain)`,
  `.accessibilityIdentifier("orders.trackButton")`.
- `private var quickActionButton`: `Button(action: onQuickAction)` labelled
  `Image(systemName: "bolt.fill").themeFont(Theme.Typeface.rowTitle).foregroundStyle(Theme.Palette.ink)`
  then `.frame(width: Theme.Size.actionButton, height: Theme.Size.actionButton)`,
  `.background(Theme.Palette.surface)`,
  `.overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.rule))`.
  `.buttonStyle(.plain)`, `.accessibilityLabel("Acciones rápidas")` (see Open question 2),
  `.accessibilityIdentifier("orders.quickActionButton")`.

**`OrderProgressView(stage:)`** (§3.4).

- Lives here, not in the design system: the "only the *current* stage is highlighted, completed
  stages are not" rule is order-domain semantics, not a reusable progress-bar behaviour. The two
  genuinely generic new pieces (`StarRatingView`, `OutlinedActionButton`) do go in the design
  system.
- `body`: `VStack(alignment: .leading, spacing: Theme.Spacing.xs) { segments; labels }`,
  `.accessibilityElement(children: .contain)`, `.accessibilityIdentifier("orders.progress")`.
- `private var segments`: `HStack(spacing: Theme.Spacing.xs)` of
  `ForEach(OrderStage.allCases) { s in Rectangle().fill(s.stepIndex <= stage.stepIndex ? Theme.Palette.accent : Theme.Palette.outline).frame(height: Theme.Size.progressSegment).frame(maxWidth: .infinity) }`,
  with `.accessibilityHidden(true)` on the `HStack` (decorative). Equal widths come from
  `maxWidth: .infinity` on each, not `GeometryReader`.
- `private var labels`: `HStack(alignment: .top, spacing: Theme.Spacing.xs)` of
  `ForEach(OrderStage.allCases) { s in Text(s.label).themeFont(Theme.Typeface.chip).foregroundStyle(s == stage ? Theme.Palette.accent : Theme.Palette.secondary).lineLimit(2).minimumScaleFactor(0.8).frame(maxWidth: .infinity, alignment: alignment(for: s)) }`.
- `private func alignment(for stage: OrderStage) -> Alignment` — `.leading` for `stepIndex == 0`,
  `.trailing` for `stepIndex == OrderStage.allCases.count - 1`, `.center` otherwise (§3.4).
- Colour is **not** the sole carrier of "which stage is current": the accent status band above
  spells out `EN CAMINO` in text. Consequence for tests: the string `EN CAMINO` appears **twice**
  on screen (band + label), so UI tests must count or use `.firstMatch`, never assume one match.

**`PastOrderRowView(order:onRepeat:)`** (§4.1–§4.3).

- `body`: `HStack(alignment: .top, spacing: Theme.Spacing.md) { HatchedPlaceholder().frame(width: Theme.Size.orderThumbnail, height: Theme.Size.orderThumbnail); details }`,
  `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` (fixed 64 pt thumbnail — same reason as
  `RestaurantRowView`), `.accessibilityElement(children: .contain)`,
  `.accessibilityIdentifier("orders.past.\(order.id.uuidString)")`.
  **Identifier keyed on `id`, not the name** — restaurant names repeat across the twelve seeded
  rows, so a name-keyed identifier would be ambiguous in XCUITest.
- `private var details`: `VStack(alignment: .leading, spacing: Theme.Spacing.xs) { titleLine; Text(order.subtitleText).themeFont(subtitle).foregroundStyle(secondary); statusLine }`.
- `private var titleLine`: `HStack { Text(order.restaurantName).themeFont(rowTitle).lineLimit(1); Spacer(); Text(order.totalText).themeFont(rowTitle).lineLimit(1).layoutPriority(1) }`, both ink.
- `private var statusLine`: `HStack { ratingOrChip; Spacer(); OutlinedActionButton(title: "REPETIR", action: onRepeat) }`.
- `@ViewBuilder private var ratingOrChip`: `if let rating = order.rating, let ratingText = order.ratingText`
  → `HStack(spacing: Theme.Spacing.xs) { StarRatingView(score: rating); Text(ratingText).themeFont(subtitle).foregroundStyle(Theme.Palette.secondary) }`
  with `.accessibilityIdentifier("orders.rating")`; `else`
  → `ChipView(text: "VALORAR PEDIDO", style: .promo)` (existing component, unmodified).
  `@ViewBuilder` + `if/else` returns concrete branches — **no `AnyView`**.

### 6. `PideYa/Home/Orders/OrdersView.swift`

```
struct OrdersView: View {
    let viewModel: OrdersViewModel          // plain `let` — owned by HomeTabViewModel
    let bottomInset: CGFloat                // the tab bar's measured height

    init(viewModel: OrdersViewModel, bottomInset: CGFloat = 0)

    body:
      NavigationStack {
          ScrollView {
              VStack(spacing: 0) {
                  if viewModel.hasActiveOrders { activeSection; HardRule() }
                  pastSection
              }
          }
          .scrollIndicators(.hidden)
          .background(Theme.Palette.background)
          .safeAreaInset(edge: .top, spacing: 0) { header }
          .safeAreaInset(edge: .bottom, spacing: 0) {
              Theme.Palette.transparent.frame(height: bottomInset)
          }
          .toolbar(.hidden, for: .navigationBar)
      }

    private var header:        OrdersHeaderView(title: "Pedidos", summaryText: viewModel.summaryText, onHelp: {})
    private var activeSection: SectionHeaderView(title: "EN CURSO") + ForEach(activeOrders) { ActiveOrderCardView(…) }
    private var pastSection:   SectionHeaderView(title: "ANTERIORES", action: .init(title: "Filtrar", perform: {})) + pastList
    private var pastList:      LazyVStack(spacing: 0) { ForEach(pastOrders) { row; HardRule(thickness: .hairline) } }
}
```

Concrete requirements:

- **The `NavigationStack` + double `safeAreaInset` is mandatory, not stylistic.** DESIGN.md §7.2:
  `HomeTabView`'s bottom inset does not cross the `NavigationStack` boundary, so without the
  second inset the twelfth past-order row sits behind the tab bar. `bottomInset` is threaded from
  `HomeTabView.tabBarHeight` (already measured, no new measurement code).
- The bar is hidden and there is no `navigationDestination` yet: the stack is the seam so the
  typed-enum destination pattern can be added later without restructuring. **Do not invent an
  `OrdersRoute` enum or detail screens now.**
- `activeSection`: `VStack(alignment: .leading, spacing: Theme.Spacing.md)` with
  `SectionHeaderView(title: "EN CURSO")` — **no trailing action** (§3) — and the card(s), all
  `.padding(.horizontal, Theme.Spacing.lg)`, `.padding(.vertical, Theme.Spacing.lg)`.
- `pastSection`: `SectionHeaderView(title: "ANTERIORES", action: .init(title: "Filtrar", perform: {}))`
  padded `.horizontal, lg`, then `pastList`.
- `pastList` separators (§4.4): a `HardRule(thickness: Theme.Stroke.hairline)` after **every**
  row *including the last*, and the whole `LazyVStack` — rows and rules alike — gets a single
  `.padding(.horizontal, Theme.Spacing.lg)` so the rule spans the full **content** width and
  runs under the thumbnail column. **Do not copy `FeedView`'s
  `.padding(.leading, Theme.Size.rowThumbnail + Theme.Spacing.md)` indent, and do not skip the
  trailing rule the way `FeedView` does.** Both differences are explicit in DESIGN.md §4.4.
- Empty active list: when `viewModel.hasActiveOrders` is false the entire `EN CURSO` section and
  its following `HardRule` are omitted. Unreachable with the mock provider, but this avoids
  inventing empty-state copy the mockup does not specify (see Risks).
- `ForEach(viewModel.activeOrders)` / `ForEach(viewModel.pastOrders)` — both `Identifiable`, so
  no `id:` argument.
- All button actions are `{}` no-ops (Open question 3).
- `#Preview { OrdersView(viewModel: OrdersViewModel()) }`.

### 7. `PideYa/Home/HomeTabViewModel.swift` + `PideYa/Home/HomeTabView.swift` (edits)

The **only** changes to shipped Home files. Both are additive; no existing line is deleted.

```
final class HomeTabViewModel {
    var selectedTab: HomeTab = .inicio
    let feed: FeedViewModel
    let orders: OrdersViewModel                       // NEW

    init(feed: FeedViewModel = FeedViewModel(), orders: OrdersViewModel = OrdersViewModel()) { … }
}
```

Every parameter stays defaulted, so `HomeTabViewModel()` still compiles and
`PideYa/PideYaApp.swift` needs **zero** changes. The orders ViewModel is owned here, not created
inside the `switch`, so scroll position and future filter state survive tab switches
(DESIGN.md §7.3).

```
@ViewBuilder private var selectedScreen: some View {
    switch viewModel.selectedTab {
    case .inicio:  FeedView(viewModel: viewModel.feed,     bottomInset: tabBarHeight)
    case .pedidos: OrdersView(viewModel: viewModel.orders, bottomInset: tabBarHeight)   // NEW
    case let other: PlaceholderTabView(tab: other)
    }
}
```

No `AnyView`. `HomeTabBar`, `HomeTab` and `PlaceholderTabView` are untouched — the Pedidos glyph
stays `doc.text` and Inicio stays `house.fill` (DESIGN.md §5 marks both as observations, not
requirements).

### 8. `PideYaTests/OrdersTests.swift`

Swift Testing only. Includes a file-`private` `StubOrdersContentProvider` returning fixed,
distinct data. See Test plan.

### 9. `PideYaUITests/OrdersUITests.swift`

XCUITest — the one sanctioned XCTest exception. Reuses a local copy of the
`scrollUntilVisible(_:in:maxSwipes:)` helper (the shipped one is private to `HomeFeedUITests`;
do not modify that file). Every test navigates via `app.buttons["tabbar.pedidos"].tap()` first.

---

## Acceptance criteria

1. **Given** a clean checkout, **when**
   `xcodebuild build -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'` runs,
   **then** it succeeds with **zero warnings**, and `git diff --stat` shows
   `PideYa.xcodeproj/project.pbxproj` and `PideYa/PideYaApp.swift` as **unchanged**.
2. **Given** the app is on Inicio, **when** `tabbar.pedidos` is tapped, **then** the static texts
   `Pedidos`, `1 en curso · 12 anteriores`, `EN CURSO`, `ANTERIORES` and the buttons `Ayuda`
   (identifier `orders.helpButton`) and `Filtrar` all exist, and `OFERTAS DE HOY` does not.
   **When** `tabbar.inicio` is tapped again, **then** `OFERTAS DE HOY` exists and `EN CURSO`
   does not. (Proves routing works and does not break Inicio.)
3. **Given** the Pedidos tab, **when** the active card is queried, **then** an element with
   identifier `orders.activeCard` exists containing the texts `Taquería Norte`,
   `3 artículos · Pedido #4821`, `LLEGA 20:45`, and `24,60\u{00A0}€` — the total using a comma
   decimal separator and a **non-breaking space (U+00A0)** before `€`, asserted with the escape,
   not a literal space (DESIGN.md §7.4).
4. **Given** the Pedidos tab, **when** `app.staticTexts` is filtered on the exact label
   `EN CAMINO`, **then** **exactly two** elements match — the status band and the current
   progress label — proving both render and that the stage is conveyed textually, not by colour
   alone. The texts `CONFIRMADO`, `EN COCINA` and `ENTREGADO` each match exactly once.
5. **Given** the `ANTERIORES` list, **when** the first three rows are read, **then** they are
   `Forno Bianco` / `18,90\u{00A0}€` / `12 ago · 2 artículos`, `Casa Lola` / `31,20\u{00A0}€` /
   `9 ago · 4 artículos`, `Sakura Ramen` / `26,50\u{00A0}€` / `4 ago · 2 artículos`, in that
   order.
6. **Given** the `Casa Lola` row (unrated), **then** it contains a static text `VALORAR PEDIDO`
   and **no** element with identifier `orders.rating`; **given** the `Forno Bianco` row (rated),
   **then** it contains an `orders.rating` element whose label is `5 de 5 estrellas` and a static
   text `5,0`, and **no** `VALORAR PEDIDO`.
7. **Given** any past-order row, **then** it contains exactly one button whose label is `REPETIR`,
   and tapping it does not crash, dismiss, push, or change any visible text (no-op action).
   The same holds for `Ayuda`, `Filtrar`, `orders.trackButton` and `orders.quickActionButton`.
8. **Given** the bolt button, **when** its accessibility label is read, **then** it is
   `Acciones rápidas` (it is icon-only and must not be unlabelled).
9. **Given** the sources, **when** they are grepped, **then**:
   - `rg -n '\.cornerRadius\(|RoundedRectangle\(|AnyView\(|ObservableObject|@Published|try\?|\.textCase\(' PideYa/ PideYaTests/ PideYaUITests/`
     returns **no matches** (zero corner radius, no `AnyView`, no unhandled `try?`, no
     `.textCase` — DESIGN.md §0 and §7.5).
     > **Amended after plan review.** The original form of this grep omitted the `(` anchors and
     > so matched the *prose* in `Theme.swift:14` (`/// may apply \`.cornerRadius\` or
     > \`RoundedRectangle\``), making the criterion fail on an untouched checkout. The anchored
     > pattern above is verified empty against the pre-feature tree, so any match it reports is
     > genuinely introduced by this feature.
   - `rg -n '#[0-9A-Fa-f]{6}|Color\(red:|Color\.\w|\.white|\.black|\.gray|\.red' PideYa/ --glob '!PideYa/DesignSystem/Theme.swift'`
     returns **no matches** (every colour literal confined to `Theme.swift`);
   - `rg -n '\.font\(' PideYa/Home/Orders/ PideYa/DesignSystem/DesignSystemViews.swift` returns
     matches **only** inside `ThemeFontModifier`, i.e. no `.font(.system(size:))` anywhere in
     this feature — all sizing goes through `.themeFont(_:)` (DESIGN.md §7.1);
   - `rg -n 'padding\(\.leading, Theme\.Size' PideYa/Home/Orders/` returns **no matches** (the
     `ANTERIORES` separators are full content width, not thumbnail-indented — DESIGN.md §4.4).
10. **Given** `PideYa/Home/Orders/`, **when** each `Text(` occurrence is inspected, **then**
    every one has a `.themeFont(` applied to it or to an enclosing container, and
    **when** the app is launched twice — once normally and once with
    `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityL` — **then** the
    measured `frame.height` of the `ANTERIORES` static text is **strictly greater** in the second
    run. (A ratio of exactly 1.0 was the previous feature's Dynamic Type defect.)
11. **Given** the Pedidos tab at maximum scroll, **when** the twelfth past-order row is located,
    **then** it `isHittable`, its `frame` does **not** intersect `tabbar.pedidos`'s frame, and
    `row.frame.maxY <= tabBar.frame.minY`. (This is the `NavigationStack` bottom-inset
    interaction from DESIGN.md §7.2 — it fails if `OrdersView` omits its own
    `.safeAreaInset(edge: .bottom)`.)
12. **Given** the Pedidos tab, **when** the list is scrolled down, **then** the
    `orders.header` element remains present and its `frame.minY` is unchanged (the header is
    pinned via `.safeAreaInset(edge: .top)` and does not scroll — DESIGN.md §1).
13. **Given** `swift-format lint --configuration .swift-format --recursive PideYa PideYaTests PideYaUITests`
    (invoked via `xcrun --find swift-format`, since `which swift-format` fails), **then** it
    reports **no findings**, and `git commit` succeeds without `--no-verify` (DESIGN.md §7.7).
14. **Given** every `View` added or edited, **when** its `body` is measured, **then** it is under
    40 lines, and every new file has at least one `#Preview` that compiles.
15. **Given** `xcodebuild test -only-testing:PideYaTests` and `-only-testing:PideYaUITests`,
    **then** all pre-existing tests still pass (15 unit + 13 UI from `home-tab-feed-ui`), plus the
    new ones below.

## Test plan

**Unit** (`PideYaTests/OrdersTests.swift`, Swift Testing — `import Testing`, `@Test`, `#expect`):

| Test | Proves |
|---|---|
| `orderStageLabelsAreLiteralUppercase` | `OrderStage.allCases.map(\.label) == ["CONFIRMADO", "EN COCINA", "EN CAMINO", "ENTREGADO"]` — uppercase is baked into the string, not applied by `.textCase`. |
| `orderStageStepIndicesAreSequential` | `allCases.map(\.stepIndex) == [0, 1, 2, 3]` — the tracker's fill logic (`stepIndex <= current`) is anchored. |
| `activeOrderTotalUsesNonBreakingSpaceBeforeEuro` | `24.60` → `"24,60\u{00A0}€"`. Asserted with the explicit escape (DESIGN.md §7.4). |
| `pastOrderTotalsUseNonBreakingSpaceBeforeEuro` | `18.90`/`31.20`/`26.50` → `"18,90\u{00A0}€"` etc.; also `0` → `"0,00\u{00A0}€"`. |
| `activeOrderSubtitleComposesItemsAndOrderNumber` | `"3 artículos · Pedido #4821"` — literal `#`, U+00B7 with spaces, no grouping separator in the order number. |
| `itemCountTextIsSingularForOne` | `1` → `"1 artículo"`, `2` → `"2 artículos"`, `0` → `"0 artículos"`. |
| `activeOrderArrivalTextIsPrefixed` | `"LLEGA 20:45"`. |
| `pastOrderSubtitleComposesDateAndItems` | `"12 ago · 2 artículos"`. |
| `pastOrderRatingTextUsesCommaDecimal` | `5.0` → `"5,0"`, `4.0` → `"4,0"` (trailing zero kept); `nil` rating → `ratingText == nil` and `isRated == false`. |
| `mockProviderSeedsOneActiveOrderPerDesign` | `activeOrders().count == 1`, name `Taquería Norte`, `orderNumber == "4821"`, `stage == .enCamino`, `etaText == "20:45"`, `itemCount == 3`. |
| `mockProviderSeedsTwelvePastOrdersInDocumentedOrder` | `pastOrders().count == 12`; first three names/totals/dates/ratings match DESIGN.md §6; `pastOrders()[1].rating == nil`. |
| `mockProviderIDsAreStableAcrossCalls` | Calling `pastOrders()` twice yields identical `id` arrays — protects `ForEach` diffing. |
| `viewModelSurfacesInjectedProviderData` | **Constructor injection.** `OrdersViewModel(provider: StubOrdersContentProvider())` exposes the *stub's* names (`"Stub Activo"`, `["Stub Anterior"]`), not the mock's — the stub returns 1 active + 1 past so the assertion cannot pass by coincidence. `@MainActor`. |
| `summaryTextIsDerivedFromArrays` | With the stub (1 active, 1 past) → `"1 en curso · 1 anterior"`; with the mock (1, 12) → `"1 en curso · 12 anteriores"`. Proves the header string can never contradict the list, and covers the singular `anterior`. |
| `hasActiveOrdersIsFalseForEmptyProvider` | An empty stub → `hasActiveOrders == false`, `summaryText == "0 en curso · 0 anteriores"` — the `EN CURSO` section-hiding path. |
| `homeTabViewModelOwnsOrdersViewModel` | `HomeTabViewModel()` compiles with no arguments and `viewModel.orders` is non-nil; assigning `selectedTab = .pedidos` sticks. Guards the "PideYaApp unchanged" contract. |

ViewModel tests are marked `@MainActor` (the types are MainActor-isolated). Model/provider
tests are not (the types are `nonisolated`).

**UI** (`PideYaUITests/OrdersUITests.swift`, XCUITest):

| Test | Covers |
|---|---|
| `testPedidosTabShowsHeaderAndSections` | Criterion 2 (both directions of the Inicio↔Pedidos round trip). |
| `testActiveOrderCardContent` | Criterion 3, including the U+00A0 total. |
| `testProgressTrackerLabelsAndCurrentStageDuplication` | Criterion 4 — the exactly-two `EN CAMINO` count. |
| `testFirstThreePastOrdersMatchDesign` | Criterion 5. |
| `testRatedAndUnratedRowsRenderDifferently` | Criterion 6 (`orders.rating` label vs `VALORAR PEDIDO`). |
| `testAllActionsAreNoOps` | Criterion 7 — tap `Ayuda`, `Filtrar`, `orders.trackButton`, `orders.quickActionButton` and one `REPETIR`, then assert `orders.activeCard` still exists and `ANTERIORES` is still on screen. |
| `testQuickActionButtonHasAccessibilityLabel` | Criterion 8. |
| `testLastPastOrderRowIsReachableAboveTabBar` | Criterion 11 — the `NavigationStack` bottom-inset regression. Scrolls well past first existence to reach true maximum scroll, then compares frames (mirrors `HomeFeedUITests.testLastRecommendationRowIsReachableAboveTabBar`, which is how this class of bug was caught last time). |
| `testHeaderStaysPinnedWhileListScrolls` | Criterion 12 — capture `orders.header.frame.minY`, swipe up three times, re-read, assert unchanged. |
| `testOrdersTextScalesWithDynamicType` | Criterion 10 — two launches, `ANTERIORES` height strictly greater at `UICTContentSizeCategoryAccessibilityL`. |

**Edge cases to exercise manually / in previews:**

- iPhone SE (375 pt) at `.accessibility1`: the four progress labels are the tightest constraint
  (`CONFIRMADO` at 13 pt bold in a ~80 pt column). Confirm they wrap to two lines rather than
  clipping, and that the card does not overflow horizontally.
- The `1 artículo` singular row (seed #12, `Bar Manolo`) renders correctly.
- `Ver seguimiento`'s label stays **left**-inset at every Dynamic Type size — the most likely
  visual regression if a `.frame` / `.padding` order gets swapped.
- The `ANTERIORES` separator below the final row is present (the mockup's cue that the list
  continues), and the row above it is fully clear of the tab bar.
- Dark mode: appearance unchanged (fixed sRGB literals) — the accepted behaviour.
- VoiceOver swipe through the active card: band → name → total → subtitle → four stage labels →
  `Ver seguimiento` → `Acciones rápidas`.

**Not runnable yet:** snapshot tests — `SnapshotTesting` is still not an SPM dependency
(`CLAUDE.md` "Tooling Not Yet Installed"). Do not add it in this feature.

## Resolved open questions (DESIGN.md §8)

1. **`12 anteriores` vs 3 rendered rows** → **Derive the count from the provider array *and* seed
   twelve past orders** (first three exactly per §6, nine invented and commented as filler).
   Reason: deriving makes the header structurally unable to lie, while twelve rows reproduces the
   mockup's literal string *and* makes its "list continues past the fold" scroll behaviour real
   instead of implied.
2. **Bolt button meaning** → accessibility label **`Acciones rápidas`**, identifier
   `orders.quickActionButton`, no-op action. Reason: the bolt sits on an *in-progress* order
   where DESIGN.md's alternative suggestion "Pedir de nuevo" would be nonsense (the order has not
   arrived, and `REPETIR` already owns reordering), so a neutral quick-actions label describes the
   affordance without promising behaviour that does not exist.
3. **Are `Filtrar` / `Ayuda` / `Ver seguimiento` / bolt / `REPETIR` functional?** → **No.** All
   five are real `Button`s with `{}` actions, exactly as `Ver todas` shipped in the feed. Reason:
   the accessibility tree, hit targets and layout are then correct, and wiring real destinations
   later is a change of closure body, not a restructure. Acceptance criterion 7 pins the no-op
   behaviour so a future accidental navigation is caught.

## Out of scope

- `Buscar` and `Cuenta` — `PlaceholderTabView` only, unchanged.
- Any behavioural change to the Inicio tab, `HomeTabBar`, `HomeTab` glyphs (`doc.text` /
  `house.fill` stay — DESIGN.md §5), `ChipView`, `SectionHeaderView`, `HardRule`,
  `HatchedPlaceholder`, `FlowLayout`, or the existing `Theme` tokens.
- Order-detail / tracking-map screens, an `OrdersRoute` enum, `navigationDestination`, filtering
  UI behind `Filtrar`, a help screen behind `Ayuda`, reorder flows behind `REPETIR`.
- Rating capture behind `VALORAR PEDIDO` (it is a `ChipView`, not a button — the mockup shows no
  affordance and §4.2 describes it as a status element).
- Networking, persistence, SwiftData, caching, pull-to-refresh, pagination, loading/error states,
  live ETA updates or any animation of the progress tracker.
- Real image assets (`HatchedPlaceholder` remains the stand-in).
- Localization catalogue / `String(localized:)`; date and time localization (see the pre-formatted
  string decision in task 3).
- Dark mode, iPad, landscape, Dynamic Type above `.accessibility1`.
- Snapshot testing, analytics, haptics, animated tab transitions.
- Retrofitting `HomeTabBar`'s `.font(.system(size: Theme.IconSize.tab))` to `themeFont`.

## Risks / open questions

- **Separator width is the one genuinely ambiguous reading.** DESIGN.md §4.4 says "full content
  width … runs underneath the thumbnail column as well". I read that as *inside* the 16 pt page
  margins (aligned with the thumbnail's leading edge), **not** screen-edge-to-edge, since the
  emphasis is on "not indented past the thumbnail". If a visual pass disagrees, the fix is moving
  one `.padding(.horizontal, Theme.Spacing.lg)` from the `LazyVStack` onto the rows only.
- **Progress labels on narrow screens.** Four labels in ~80 pt columns on iPhone SE is the
  tightest layout in the feature. Mitigated with `lineLimit(2)` + `minimumScaleFactor(0.8)`, but
  it needs a real device/simulator check; the mockup itself truncates to `ENTREG.`, which suggests
  the designer hit the same wall. Do **not** solve it by shrinking the `chip` token — that would
  affect the shipped feed.
- **`Ver seguimiento`'s left-aligned label is fragile.** It depends on `.padding(.horizontal)`
  being applied *before* `.frame(maxWidth: .infinity, alignment: .leading)`. A well-meaning
  reorder silently centres it. There is no automated check for this — it is on the visual pass.
- **Nine invented past orders.** Restaurants #5–#12 and all dates after `4 ago` are fabricated
  filler to make the derived `12 anteriores` honest. They must be commented as invented so nobody
  treats them as spec.
- **Pre-formatted `dateText` / `etaText`** trade correctness-under-locale for stability. Documented
  in the file. If a backend lands, both become `Date` and the formatting moves into computed
  properties — a contained change, but it will churn the unit tests that assert on the literals.
- **`stableID(_:)` is duplicated** into `MockOrdersContentProvider` rather than hoisted, to keep
  `FeedModels.swift` byte-identical. Three lines. If a third tab needs it, hoist then.
- **`Theme.Palette.surface` (`#FFFFFF`) duplicates `onAccent`'s RGB.** Intentional — two distinct
  semantic roles that a future theme would want to move independently. Flagging it so a later
  reader does not "clean it up".
- **Palette values are eyeballed** from a 2.29 px/pt render (DESIGN.md's own caveat). `#C9C9C9` for
  `outline` and the decision to reuse `searchFill` for the card body are both approximations;
  expect a polish pass.
- **The string `EN CAMINO` appears twice on screen.** Any future UI test that does
  `app.staticTexts["EN CAMINO"]` without `.firstMatch` or a count will behave unpredictably.
  Criterion 4 turns this from a trap into an assertion.
- **Task count is 9, near the top of the 3–10 range.** Tasks 1–2 (design-system extensions) could
  be split into their own reviewable unit, but I recommend against it for the same reason as last
  time: `StarRatingView` and `OutlinedActionButton` have no call sites until the Pedidos screen
  exists, so reviewing them alone means reviewing an API in a vacuum.
- **Assumed** that `HomeTabViewModel` gaining a second defaulted init parameter is acceptable and
  that no in-flight branch constructs it positionally. `PideYaApp.swift` is unaffected.
