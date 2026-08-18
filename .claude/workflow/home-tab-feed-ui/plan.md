# Feature: Home Tab shell + Feed screen (mockup replication)

Replicate `DESIGN.md` across the tab-bar shell (`HomeTabView`) and the first tab's screen
(`FeedView`). `Buscar` / `Pedidos` / `Cuenta` exist and are selectable but render a shared
placeholder. No networking, no persistence, no image assets — static mock data from the
ViewModel and a procedurally-drawn hatched placeholder.

Source spec: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/home-tab-feed-ui/DESIGN.md`

## Existing patterns to follow

- `PideYa/Home/HomeTabViewModel.swift:11-19` — `@MainActor` + `@Observable` + `final class`,
  `private(set) var` state, defaulted `init`. Every new ViewModel mirrors this exactly.
  Do not use `ObservableObject` / `@Published`.
- `PideYa/Home/HomeTabView.swift:11-15` — the ViewModel-injection idiom:
  `@State private var viewModel` + `init(viewModel:)` + `_viewModel = State(initialValue:)`.
  `FeedView` currently has no ViewModel and must adopt this same idiom.
- `PideYa/Home/HomeTabView.swift:24-30` — `body` delegates to a `private var content: some View`.
  Mirror this decomposition style; CLAUDE.md caps `body` at 40 lines.
- `PideYa/PideYaApp.swift:12-16` — entry point is `HomeTabView(viewModel: HomeTabViewModel())`.
  See "Entry point" below; this file should end up **unchanged**.
- `PideYa/Home/` and `PideYa/Home/Feed/` — folder-per-feature, `XView.swift` + `XViewModel.swift`
  naming. New folders follow the same shape.
- `PideYaTests/PideYaTests.swift:8-18` — Swift Testing (`import Testing`, `struct`, `@Test`,
  `#expect`). No XCTest for unit tests.
- `PideYa.xcodeproj/project.pbxproj:32-48` — three `PBXFileSystemSynchronizedRootGroup`s
  (`PideYa`, `PideYaTests`, `PideYaUITests`) with **no** `PBXFileSystemSynchronizedBuildFileExceptionSet`.
  Consequence: **any new `.swift` file placed under those folders is added to its target
  automatically. Do not hand-edit the pbxproj.**
- `.swift-format:1-88` + `.githooks/pre-commit` — a pre-commit hook rejects unformatted staged
  Swift. Binding rules for this feature: 4-space indent, 120-col lines, no force-unwrap
  (`NeverForceUnwrap`), no force-try, no implicitly-unwrapped optionals, no block comments
  (`///` only for docs), ASCII identifiers only (Spanish accents are fine inside string
  literals, never in symbol names), `[]` for empty-collection init, trailing commas in
  multi-element collections.

### Entry point — explicit decision

CLAUDE.md claims `PideYaApp` → `HomeView(viewModel:)`. **There is no `HomeView` in this repo**
(`PideYa/PideYaApp.swift:14` actually constructs `HomeTabView`). Do **not** create a `HomeView`.

- The entry point **stays** `HomeTabView(viewModel: HomeTabViewModel())`.
- `HomeTabViewModel.init` must keep every parameter defaulted so `HomeTabViewModel()` still
  compiles and `PideYaApp.swift` needs **zero** changes.
- Follow-up (not part of this feature): correct the "View entry point" line in `CLAUDE.md`.

## Tasks

1. [x] Add `PideYa/DesignSystem/Theme.swift` — palette, spacing, border-width and font tokens shared by all four tabs.
2. [x] Add `PideYa/DesignSystem/DesignSystemViews.swift` — `HatchedPlaceholder`, `ChipView`, `SectionHeaderView`, `HardRule`.
3. [x] Add `PideYa/Home/Feed/FeedModels.swift` — `Sendable` models, es-ES display formatting, `FeedContentProviding` + mock impl.
4. [x] Rewrite `PideYa/Home/Feed/FeedViewModel.swift` — `@MainActor @Observable` VM with constructor-injected provider.
5. [x] Add `PideYa/Home/Feed/FeedSubviews.swift` — `FeedHeaderView`, `OfferCardView`, `RestaurantRowView`.
6. [x] Rewrite `PideYa/Home/Feed/FeedView.swift` — compose header + the two sections into a scroll view.
7. [x] Add `PideYa/Home/HomeTabBar.swift` — `HomeTab` enum, custom `HomeTabBar`, shared `PlaceholderTabView`.
8. [x] Rewrite `PideYa/Home/HomeTabView.swift` + `PideYa/Home/HomeTabViewModel.swift` — tab selection state and shell layout.
9. [x] Add `PideYaTests/FeedTests.swift` — Swift Testing coverage for formatting, mock data and tab selection.

---

### 1. `PideYa/DesignSystem/Theme.swift`

A `enum Theme` namespace (uninhabited, no cases) with nested uninhabited enums. Everything
`static let`. **All literals live here — no hex, no magic spacing numbers in any view.**

- `Theme.Palette`: `background` `#F2F2F0`, `ink` `#111111`, `secondary` `#8A8A8A`,
  `accent` `#E2372A`, `promoFill` `#FBD9D5`, `placeholder` `#D9D9D9`,
  `searchFill` (light gray, `#E8E8E6`).
  Define via `Color(red:green:blue:)` sRGB literals, **not** asset-catalog colorsets — the
  design is light-only and fixed literals must not invert under dark mode.
- `Theme.Spacing`: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`.
- `Theme.Stroke`: `hairline: CGFloat = 1`, `rule: CGFloat = 2`.
- `Theme.Size`: `avatarBox 52`, `searchField 56`, `rowThumbnail 72`, `tabIcon 22`.
- `Theme.Typeface` — **corrected during the fix-cycle-2 pass: the original claim below was
  false.** A bare `Font.system(size:weight:)` is a fixed-point-size font and does **not**
  respond to Dynamic Type; QA measured a 1.0 height ratio between a normal launch and
  `.accessibility1` and caught this. Each token is now a `Theme.Typeface.Style(size:weight:
  relativeTo:)` value (base point size + `UIFont.TextStyle`) applied via a new
  `View.themeFont(_:)` modifier (`DesignSystemViews.swift`) that scales the base size with
  `UIFontMetrics(forTextStyle:).scaledValue(for:)` against the live `dynamicTypeSize`
  environment value: `brand` 40/.heavy, `sectionTitle` 15/.bold, `cardTitle` 22/.bold,
  `rowTitle` 20/.bold, `subtitle` 15/.regular, `subtitleBold` 15/.bold (new — replaces the old
  `Theme.Typeface.subtitle.bold()` call sites, since `Style` values aren't `Font`s and can't be
  chained with `.bold()`), `chip` 13/.bold, `band` 13/.heavy, `tabLabel` 11/.bold,
  `action` 15/.medium. Growth is capped at `.accessibility1` on `FeedHeaderView` and
  `RestaurantRowView` (in addition to `HomeTabBar`, already capped) because their 52pt avatar
  box and 72pt thumbnail are fixed-size and cannot grow with the text; `OfferCardView` is left
  uncapped since its card height is not fixed. Icon sizes (`Theme.IconSize`) are deliberately
  left fixed/unscaled — out of scope for this defect fix, which is about text only.
- `Theme.Kerning`: `brand 1`, `sectionTitle 1.5`.
- Doc comment at the top of the file: **corner radius is always 0 in this design system.**
  No view in this feature may apply `.cornerRadius` / `RoundedRectangle`.

### 2. `PideYa/DesignSystem/DesignSystemViews.swift`

Four `struct`s, all internal (used from `Home/`), all with `#Preview`.

- `HatchedPlaceholder` — the image stand-in. `Canvas` drawing 45° stripes (build a `Path` in a
  `while`/`stride` loop from `x = -size.height` to `size.width`, step `Theme.Spacing.sm`,
  `context.stroke(path, with: .color(...), lineWidth: Theme.Stroke.hairline)`) over a
  `Theme.Palette.placeholder` background. Must be `.accessibilityHidden(true)` and must not
  clip its parent (`.clipped()`). Sized entirely by the caller — no intrinsic size.
- `ChipView` — `init(text: String, style: Style)` where
  `enum Style { case outlined, promo }`.
  `.outlined`: clear fill, 1pt `ink` border, `ink` bold text. `.promo`: `promoFill` background,
  no border, `accent` bold text. Both: `Theme.Typeface.chip`, horizontal padding `sm`,
  vertical padding `xs`, zero radius.
- `SectionHeaderView` — `init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil)`.
  `HStack` of the kerned uppercase title and, when `actionTitle != nil`, a trailing `Button`
  in `accent`. Renders no button when `actionTitle` is nil.
- `HardRule` — `init(color: Color = Theme.Palette.secondary, thickness: CGFloat = Theme.Stroke.rule)`.
  A `Rectangle().frame(height:)`, `.accessibilityHidden(true)`.

### 3. `PideYa/Home/Feed/FeedModels.swift`

**Data model shape.** All types `Sendable` (value types → automatic). `Hashable` for future
`navigationDestination` use. `Identifiable` via an explicit `let id: UUID` so mock data is
stable across re-renders.

```
struct Offer: Identifiable, Hashable, Sendable
    id: UUID
    restaurantName: String     // "Taquería Norte"
    bannerText: String         // "-40% · HASTA LAS 23:00"  (already uppercase, see note)
    cuisine: String            // "Mexicana"
    etaMinutes: ClosedRange<Int>   // 25...35

struct Restaurant: Identifiable, Hashable, Sendable
    id: UUID
    name: String
    cuisine: String
    rating: Double             // 4.8  — numeric, NOT "4,8"
    etaMinutes: ClosedRange<Int>
    promotion: String?         // "-40%", "2X1", nil for Casa Lola
    deliveryFee: Decimal       // 1.90 / 2.50 / 0  — numeric, NOT "1,90 €"

struct FeedProfile: Hashable, Sendable
    initials: String           // "VA"
    addressLine: String        // "Calle Mayor 44"
```

**Display formatting** (extensions in the same file, so unit-testable without a view):

- `private let esES = Locale(identifier: "es_ES")` at file scope.
- `Restaurant.ratingText` → `rating.formatted(.number.precision(.fractionLength(1)).locale(esES))` → `"4,8"`.
- `Restaurant.deliveryFeeText` → `deliveryFee.formatted(.currency(code: "EUR").locale(esES))` → `"1,90 €"`, `"0,00 €"`.
- `Restaurant.etaText` / `Offer.etaText` → `"\(etaMinutes.lowerBound)-\(etaMinutes.upperBound) min"` → `"25-35 min"`.
  Plain interpolation on purpose: no grouping separators wanted.
- `Restaurant.subtitleText` → `"\(cuisine) · ★ \(ratingText)"`.
- `Offer.subtitleText` → `"\(cuisine) · \(etaText)"`.

**Uppercase copy must be stored as literal uppercase strings** (`"OFERTAS DE HOY"`,
`"PIDEYA"`, `"-40% · HASTA LAS 23:00"`). Do **not** use the `.textCase(.uppercase)` modifier —
it leaves the accessibility value lowercase and would break the UI-test assertions below.

**Dependency injection** (protocol-driven, per CLAUDE.md):

```
protocol FeedContentProviding: Sendable {
    func profile() -> FeedProfile
    func offers() -> [Offer]
    func recommendations() -> [Restaurant]
}
struct MockFeedContentProvider: FeedContentProviding { ... }   // synchronous, no async
```

Seed data exactly per `DESIGN.md:74-86`. `Casa Lola`'s ETA is not in the mockup — use `20...30`
and note it in the source. Offers order: Taquería Norte, Forno Bianco. Recommendations order:
Taquería Norte, Forno Bianco, Casa Lola.

### 4. `PideYa/Home/Feed/FeedViewModel.swift`

**ViewModel API.**

```
@MainActor
@Observable
final class FeedViewModel {
    private(set) var profile: FeedProfile
    private(set) var offers: [Offer]
    private(set) var recommendations: [Restaurant]
    var searchText: String = ""            // var: bound to the TextField, non-functional

    init(provider: FeedContentProviding = MockFeedContentProvider())
}
```

`init` reads all three provider methods synchronously and assigns — no `Task`, no `load()`,
no loading/error state (there is no I/O). Keep the provider parameter defaulted so previews
and `HomeTabViewModel()` stay call-site-free. Do not store the provider unless a later
refresh needs it.

### 5. `PideYa/Home/Feed/FeedSubviews.swift`

Three internal `struct`s (internal, not private, because they live in a separate file from
`FeedView` — this is the deliberate trade to keep `FeedView.body` under 40 lines). Each gets a
`#Preview`.

- `FeedHeaderView(profile: FeedProfile, searchText: Binding<String>)` — the fixed header.
  Private computed subviews inside it: `brandRow` (`"PIDEYA"` in `Theme.Typeface.brand` +
  `.kerning`, plus the 52pt square `ink`-bordered box holding `profile.initials`),
  `addressRow` (`Image(systemName: "mappin")` tinted `accent`, `profile.addressLine` bold ink,
  `Image(systemName: "chevron.down")`), `searchField` (`HStack` of `magnifyingglass` +
  `TextField("Buscar restaurantes o platos", text: searchText)`, 56pt tall, `searchFill`
  background, 1pt `ink` border via `.overlay(Rectangle().stroke(...))`, `.autocorrectionDisabled()`,
  `.textInputAutocapitalization(.never)`), then a trailing `HardRule`.
- `OfferCardView(offer: Offer)` — `VStack(spacing: 0)`, whole card wrapped in a 1pt `ink`
  `Rectangle().stroke` overlay:
  1. `HatchedPlaceholder().aspectRatio(1, contentMode: .fit)`
  2. red band: `Text(offer.bannerText)` white `Theme.Typeface.band`, `.frame(maxWidth: .infinity, alignment: .leading)`, padding, `.background(Theme.Palette.accent)`
  3. `Text(offer.restaurantName)` `cardTitle` ink, `Text(offer.subtitleText)` `subtitle` secondary, on `background`.
- `RestaurantRowView(restaurant: Restaurant)` — `HStack(alignment: .top)`:
  `HatchedPlaceholder().frame(width: 72, height: 72)`; a `VStack(alignment: .leading)` of
  name (`rowTitle` ink), `restaurant.subtitleText` (`subtitle` secondary), and a chip
  `HStack` — always `ChipView(text: restaurant.etaText, style: .outlined)`, plus
  `ChipView(text: promo, style: .promo)` only when `restaurant.promotion` unwraps (`if let`,
  never force-unwrap); `Spacer()`; `Text(restaurant.deliveryFeeText)` bold ink.

### 6. `PideYa/Home/Feed/FeedView.swift`

**View decomposition.** `body` stays under 40 lines by delegating to private computed properties.

```
struct FeedView: View {
    @State private var viewModel: FeedViewModel
    init(viewModel: FeedViewModel) { _viewModel = State(initialValue: viewModel) }

    body:
      NavigationStack {
          ScrollView {
              VStack(spacing: 0) { offersSection; HardRule(); recommendedSection }
          }
          .scrollIndicators(.hidden)
          .background(Theme.Palette.background)
          .safeAreaInset(edge: .top, spacing: 0) { header }
          .toolbar(.hidden, for: .navigationBar)
      }

    private var header: FeedHeaderView(profile:searchText: $viewModel.searchText)
    private var offersSection: SectionHeaderView("OFERTAS DE HOY", actionTitle: "Ver todas") + carousel
    private var offersCarousel: ScrollView(.horizontal) { LazyHStack(spacing: md) { OfferCardView … } }
    private var recommendedSection: SectionHeaderView("RECOMENDADOS PARA TI")
                                    + Text("Según tus últimos pedidos") + recommendedList
    private var recommendedList: LazyVStack(spacing: 0) { row + inset HardRule between rows }
}
```

Concrete requirements:

- Header is placed with `.safeAreaInset(edge: .top)` so it is pinned and does **not** scroll
  (`DESIGN.md:17`).
- Carousel peek: each card gets
  `.containerRelativeFrame(.horizontal, count: 8, span: 5, spacing: Theme.Spacing.md)`
  (= 62.5% of the scroll container, iOS 17 API) so card 2 peeks off the right edge.
  Add `.scrollIndicators(.hidden)` and `.contentMargins(.horizontal, Theme.Spacing.lg, for: .scrollContent)`.
  Do **not** add `.scrollTargetBehavior(.viewAligned)` — the mockup shows free scrolling, not snapping.
- Divider between recommendation rows is **inset to the text content, not full-bleed**
  (`DESIGN.md:46`): leading padding = thumbnail width + gap = `72 + Theme.Spacing.md`.
  No divider after the last row.
- `ForEach(viewModel.offers)` / `ForEach(viewModel.recommendations)` — `Identifiable`, so no `id:`.
- `#Preview { FeedView(viewModel: FeedViewModel()) }`.

Why a `NavigationStack` with a hidden bar and no `navigationDestination`: this feature has no
push targets (the mockup defines no detail screen, and "Ver todas" / search have nowhere to go).
The stack is the seam so the typed-enum destination pattern from CLAUDE.md can be added later
without restructuring. **Do not invent a `FeedRoute` enum or detail screens now** — see
Out of scope.

### 7. `PideYa/Home/HomeTabBar.swift`

- `enum HomeTab: String, CaseIterable, Identifiable, Sendable { case inicio, buscar, pedidos, cuenta }`
  with `var id: String { rawValue }`, `var title: String` (`"Inicio"`, `"Buscar"`, `"Pedidos"`,
  `"Cuenta"`), and `var systemImage: String`. Use symbols that exist on iOS 17.6:
  `"house.fill"`, `"magnifyingglass"`, `"doc.text"`, `"person"`. **Verify each renders in the
  simulator before finishing** — do not use `text.document` or `receipt` (iOS 18 / SF Symbols 5).
- `HomeTabBar(selection: Binding<HomeTab>)` — `VStack(spacing: 0)` of a 1pt `ink` `HardRule`
  then an `HStack` of `ForEach(HomeTab.allCases)` buttons, each `.frame(maxWidth: .infinity)`
  (even distribution), icon over `Theme.Typeface.tabLabel` title, tinted `accent` when selected
  and `ink` otherwise. `.background(Theme.Palette.background)`.
  Each button: `.accessibilityIdentifier("tabbar.\(tab.rawValue)")`,
  `.accessibilityAddTraits(isSelected ? .isSelected : [])`.
  Cap growth with `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` so labels cannot
  collide at the largest sizes.
- `PlaceholderTabView(tab: HomeTab)` — one view reused by the three out-of-scope tabs.
  A `ContentUnavailableView(tab.title, systemImage: tab.systemImage, description: Text("Próximamente."))`
  on `Theme.Palette.background`, with `.accessibilityIdentifier("placeholder.\(tab.rawValue)")`.

### 8. `PideYa/Home/HomeTabViewModel.swift` + `PideYa/Home/HomeTabView.swift`

ViewModel:

```
@MainActor
@Observable
final class HomeTabViewModel {
    var selectedTab: HomeTab = .inicio
    let feed: FeedViewModel

    init(feed: FeedViewModel = FeedViewModel()) { self.feed = feed }
}
```

Remove `title` — the nav bar is hidden and the brand word lives in `FeedHeaderView`.
The `feed` child ViewModel is **owned here, not created inside the tab switch**, so the feed's
identity and `searchText` survive tab switching.

View:

```
struct HomeTabView: View {
    @State private var viewModel: HomeTabViewModel      // keep existing init idiom

    body:
      selectedScreen
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Theme.Palette.background)
          .safeAreaInset(edge: .bottom, spacing: 0) {
              HomeTabBar(selection: $viewModel.selectedTab)
          }

    @ViewBuilder private var selectedScreen: some View {
        switch viewModel.selectedTab {
        case .inicio: FeedView(viewModel: viewModel.feed)
        case let other: PlaceholderTabView(tab: other)
        }
    }
}
```

- A **custom** tab bar, not `TabView`: the design needs a hard 1pt black top rule, bold small
  labels and a red selected state that the native bar cannot express, and the value-based
  `Tab { }` builder is iOS 18+ while this target is 17.6.
- No `NavigationStack` at this level — each tab screen owns its own (only `FeedView` has one).
- `.safeAreaInset(edge: .bottom)` (not `overlay`) so the last recommendation row is reachable
  rather than permanently hidden behind the bar.
- `@ViewBuilder` + `switch` returns concrete branches — **no `AnyView`**.
- Keep `#Preview { HomeTabView(viewModel: HomeTabViewModel()) }`.

### 9. `PideYaTests/FeedTests.swift`

Swift Testing only. Include a `private struct StubFeedContentProvider: FeedContentProviding`
returning fixed, distinct data to prove injection actually flows through. See Test plan.

---

## Acceptance criteria

1. **Given** a clean checkout, **when** `xcodebuild build -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'`
   runs, **then** it succeeds with **zero warnings** and no manual `project.pbxproj` edit appears
   in `git diff` (`PideYa.xcodeproj/project.pbxproj` is untouched).
2. **Given** the app launches, **when** the first frame renders, **then** static texts `PIDEYA`,
   `VA`, `Calle Mayor 44`, `OFERTAS DE HOY`, `Ver todas`, `RECOMENDADOS PARA TI` and
   `Según tus últimos pedidos` all exist, and a text field with placeholder
   `Buscar restaurantes o platos` exists.
3. **Given** the app launches, **when** the tab bar is queried, **then** elements with
   identifiers `tabbar.inicio`, `tabbar.buscar`, `tabbar.pedidos`, `tabbar.cuenta` all exist
   and are hittable, and `tabbar.inicio` carries the `selected` trait.
4. **Given** the Inicio tab, **when** `tabbar.buscar` is tapped, **then** `placeholder.buscar`
   exists and `OFERTAS DE HOY` no longer exists; **when** `tabbar.inicio` is tapped again,
   **then** `OFERTAS DE HOY` exists again.
5. **Given** the feed, **when** the recommendations are read, **then** exactly the texts
   `Mexicana · ★ 4,8`, `Italiana · ★ 4,7`, `Casera · ★ 4,9` and the fee texts `1,90\u{00A0}€`,
   `2,50\u{00A0}€`, `0,00\u{00A0}€` exist — comma decimal separators, euro sign after a
   **non-breaking space (U+00A0)**, not a regular space. (Corrected during the review-fix pass:
   the es-ES `Decimal.formatted(.currency(...))` formatter emits U+00A0, verified via a
   standalone script and asserted this way in both `PideYaTests` and `PideYaUITests`.)
6. **Given** the `Casa Lola` row, **when** its chips are counted, **then** there is exactly one
   chip (`20-30 min`); **given** the `Taquería Norte` row, **then** there are exactly two
   (`25-35 min` and `-40%`).
7. **Given** the offers carousel, **when** it is scrolled horizontally, **then** the second card
   (`Forno Bianco`, banner `2X1 EN PIZZAS`) becomes fully visible; before scrolling, the first
   card's width is between 55% and 70% of the screen width.
8. **Given** any view in this feature, **when** the sources are grepped, **then**
   `rg 'AnyView|cornerRadius|RoundedRectangle|ObservableObject|@Published|try\?' PideYa/` returns
   no matches, and `rg -n '#[0-9A-Fa-f]{6}|Color\(red:|Color\.\w|\.white|\.black' PideYa/ --glob '!PideYa/DesignSystem/Theme.swift'`
   returns no matches (all colour literals confined to `Theme.swift`). (Widened during the
   review-fix pass: the original hex/`Color(red:` grep passed vacuously against a bare
   `.foregroundStyle(.white)`, a named-colour literal it cannot see.)
9. **Given** the sources, **when** `swift-format lint --configuration .swift-format --recursive PideYa PideYaTests`
   runs, **then** it reports no findings (the pre-commit hook must pass without `--no-verify`).
10. **Given** `PideYa/PideYaApp.swift`, **when** the feature is complete, **then** the file is
    byte-identical to `main` and still constructs `HomeTabView(viewModel: HomeTabViewModel())`.
11. **Given** every `View` added or changed, **when** its `body` is measured, **then** it is
    under 40 lines, and every file has at least one `#Preview` that compiles.

## Test plan

**Unit** (`PideYaTests/FeedTests.swift`, Swift Testing):
- `Restaurant.ratingText` → `4.8` yields `"4,8"`; `4.0` yields `"4,0"` (trailing zero kept).
- `Restaurant.deliveryFeeText` → `1.90` → `"1,90 €"`, `2.50` → `"2,50 €"`, `0` → `"0,00 €"`.
- `etaText` → `25...35` → `"25-35 min"`; `5...5` → `"5-5 min"`; no thousands separator for `100...120`.
- `subtitleText` composition contains `" · ★ "`.
- `MockFeedContentProvider`: `offers().count == 2`, `recommendations().count == 3`, names in the
  documented order, `Casa Lola.promotion == nil`, the other two non-nil.
- `FeedViewModel(provider: StubFeedContentProvider())` surfaces the **stub's** data, not the
  mock's — proves constructor injection is wired.
- `FeedViewModel().searchText` starts `""` and is mutable.
- `HomeTabViewModel().selectedTab == .inicio`; assigning `.cuenta` sticks;
  `HomeTab.allCases.count == 4` with titles `["Inicio", "Buscar", "Pedidos", "Cuenta"]`.
- Mark ViewModel tests `@MainActor` (the types are MainActor-isolated).

**UI** (`PideYaUITests`, XCTest — XCUITest has no Swift Testing equivalent; this is the one
sanctioned XCTest exception):
- Launch → assert acceptance criteria 2, 3, 5, 6.
- Tab round-trip → acceptance criterion 4.
- Horizontal swipe on the carousel → acceptance criterion 7.

**Edge cases to exercise manually / in previews:**
- `Casa Lola` (no promo chip) renders without a gap where the second chip would be.
- Dynamic Type at `.accessibility1`: chips wrap rather than clip, tab labels do not overlap
  (the tab bar is capped at `.accessibility1`).
- Longest name (`Taquería Norte` at XXL) truncates with `.lineLimit(1)` rather than pushing the
  fee off-screen.
- Smallest supported device (iPhone SE, 375pt): carousel card ≈234pt, header still fits.
- Scrolling to the bottom of the recommendations: the last row is fully visible above the tab bar.
- Dark mode: appearance is unchanged (fixed sRGB literals), which is the accepted behaviour.

**Not runnable yet:** snapshot tests — `SnapshotTesting` is not an SPM dependency
(CLAUDE.md "Tooling Not Yet Installed"). Do not add it as part of this feature.

## Out of scope

- `Buscar`, `Pedidos`, `Cuenta` screens — `PlaceholderTabView` only.
- Search behaviour: the field binds to `FeedViewModel.searchText` and does nothing else. No
  filtering, no results screen, no keyboard dismissal handling beyond defaults.
- `Ver todas`, offer cards, restaurant rows, the address selector and the `VA` avatar are
  **non-tappable / no-op**. No detail screens, no `FeedRoute` enum, no `navigationDestination`.
- Networking, persistence, SwiftData, caching, refresh, loading and error states.
- Real image assets (`HatchedPlaceholder` is the permanent stand-in for this feature).
- Localization catalogue / `String(localized:)` — Spanish string literals inline.
- Dark mode, iPad, landscape, Dynamic Type above `.accessibility1`.
- Snapshot testing, analytics, haptics, animated tab transitions.
- Editing `CLAUDE.md` (the stale `HomeView` line is a follow-up).

## Risks / open questions

- **pbxproj — risk resolved, verify anyway.** `project.pbxproj:32-48` declares
  `PBXFileSystemSynchronizedRootGroup` for `PideYa`, `PideYaTests`, `PideYaUITests` with no
  exception sets, so the 5 new app files and 1 new test file are picked up automatically. The
  implementer must (a) create files **inside** those root folders, (b) never hand-edit the
  pbxproj, and (c) confirm with a clean `xcodebuild build` that the new symbols resolve. If
  Xcode is open during file creation, a reopen may be needed for the navigator to refresh —
  that is cosmetic, not a build issue.
- **`HomeView` does not exist.** CLAUDE.md's entry-point line is stale. Assumed: keep
  `HomeTabView` as the root. Confirm this is the intent before starting.
- **`HomeTabViewModel.title` is deleted.** Nothing else references it, but confirm no in-flight
  branch depends on it. `PideYaApp.swift` is unaffected because `init` stays fully defaulted.
- **Locale is hardcoded to `es_ES`.** The app has no localization setup, and `DESIGN.md:89-91`
  demands comma separators regardless of device locale. Assumed correct; it means a device set
  to `en_US` still shows `1,90 €`. If the app should follow device locale later, this is a
  one-line change in `FeedModels.swift`.
- **Palette values are eyeballed from the mockup** (`DESIGN.md:7` says "approximate"). The
  search-field fill and the map-pin/chevron sizes are not specified at all — `#E8E8E6` and SF
  Symbol defaults are my assumption. Expect a visual-polish pass.
- **SF Symbol availability on iOS 17.6.** `house.fill` / `magnifyingglass` / `doc.text` /
  `person` are all long-standing symbols, but `doc.text` is a weak match for "receipt". If a
  better iOS 17-available symbol exists, swap it; do not reach for iOS 18 symbols.
- **`Casa Lola` ETA is invented** (`20...30`) — `DESIGN.md:86` says "not visible, choose".
- **`containerRelativeFrame` peek ratio** (count 8 / span 5 = 62.5%) is derived from
  `DESIGN.md:33` "~62%". Verify visually on iPhone SE and iPhone 17 Pro Max; adjust the
  count/span pair rather than switching to `GeometryReader`.
- **Task count is 9, at the top of the 3–10 range.** If tasks 1–2 (design system) are wanted as
  a separately reviewable unit — reasonable, since the other three tabs will build on them —
  split into "Design system foundation" (tasks 1–2 + a preview-only harness) and "Home + Feed"
  (tasks 3–9). I recommend keeping them together: the tokens have no consumer until the feed
  exists, and splitting would mean reviewing an API with no call sites.

PLAN: /Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/home-tab-feed-ui/plan.md
