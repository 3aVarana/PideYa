# Feature: Cuenta tab (account settings grid + wallet)

Build the fourth and last tab of the Home shell — `Cuenta` — replicating
`.claude/workflow/cuenta-tab/DESIGN.md`. A header block (grey eyebrow, two-line name, two status
badges), a 2 × 3 settings grid with full-bleed rules between every cell, and a `MONEDERO` block
(balance row, inset rule, `Cerrar sesión`, footer). No networking, no persistence: static mock
data behind a protocol, exactly like `Feed` and `Orders`.

`Buscar` stays on `PlaceholderTabView`. `Inicio` and `Pedidos` must not regress: the only edits to
shipped files are two *additive* design-system extensions and the two-line routing change in
`HomeTabView` / `HomeTabViewModel`.

Source spec: `/Users/vicchorarana/Desktop/projects/PideYa/.claude/workflow/cuenta-tab/DESIGN.md`

## Existing patterns to follow

- `PideYa/Home/Orders/OrdersView.swift:19-29` — a screen owned by `HomeTabViewModel` holds its
  ViewModel as a **plain `let`** (never `@State`) and takes a `bottomInset: CGFloat = 0`.
  `AccountView` copies this signature verbatim. See `CLAUDE.md` "ViewModel ownership".
- `PideYa/Home/Orders/OrdersView.swift:31-52` — `NavigationStack { ScrollView { … } }` with
  `.scrollIndicators(.hidden)`, `.background`, `.safeAreaInset(edge: .bottom)` carrying
  `bottomInset`, and `.toolbar(.hidden, for: .navigationBar)`. `AccountView` mirrors this
  **except** for `.safeAreaInset(edge: .top)`: Cuenta has no pinned header (Q1 below).
- `PideYa/Home/Orders/OrdersModels.swift:17` and `:73`/`:91` — `private nonisolated let esES` at
  file scope and **`nonisolated extension`** on every display-formatting extension. This is
  DESIGN.md §8.8 and it is not optional; see task 3.
- `PideYa/Home/Feed/FeedModels.swift:10`, `:42`, `:60` — the **counter-example**. `esES` is not
  `nonisolated` and the two `extension` blocks are plain, so that file's formatting layer is
  silently `@MainActor`. It is out of scope (do not touch it), but do not copy its shape either.
- `PideYa/Home/Orders/OrdersViewModel.swift:11-20` — `@MainActor @Observable final class`,
  `private(set) var` state, provider injected via a **defaulted** init parameter, assigned
  synchronously in `init`; the provider is not stored; no `Task`, no `load()`, no loading state.
- `PideYa/Home/Orders/OrdersSubviews.swift:28-35` — the identifier-cascade lesson:
  `.accessibilityIdentifier` on a container that is not itself an accessibility element cascades
  onto **every descendant**. Containers get `.accessibilityElement(children: .contain)`.
- `PideYa/Home/Orders/OrdersSubviews.swift:282-288` — the other half of that lesson: an identifier
  on a *leaf group* belongs on a view that is already exactly one element
  (`.accessibilityElement(children: .ignore)` + an explicit label).
- `PideYa/Home/HomeTabView.swift:33-40` — `selectedScreen` is a `@ViewBuilder` `switch` returning
  concrete branches (**no `AnyView`**); the tab bar's real height is measured with
  `.onGeometryChange` into `tabBarHeight` and passed down.
- `PideYa/Home/HomeTabViewModel.swift:15-21` — every init parameter is defaulted, so
  `HomeTabViewModel()` still compiles and `PideYa/PideYaApp.swift` needs zero changes.
- `PideYa/DesignSystem/DesignSystemViews.swift:18-20` — every `Text` and every SF Symbol gets
  `.themeFont(_:)`, never `.font(.system(size:))` (DESIGN.md §8.1).
- `PideYa/DesignSystem/DesignSystemViews.swift:81-121` — `ChipView`, a three-`switch` component;
  extended additively in task 2. `:161-176` `HardRule` (default `secondary`, 2 pt) — reused for
  every rule on this screen. `:180-241` `FlowLayout` — required for the badge row (DESIGN.md §3.3).
- `PideYa/DesignSystem/DesignSystemViews.swift:247-249` — `filledStars(score:outOf:)`: the
  precedent that **any real logic added for a view must be a plain function a non-`@MainActor`
  test can call**. Its review NIT (a bare top-level name polluting the module namespace) is why
  this feature's equivalent is `AccountTileRow.rows(from:columns:)`, a `static func`.
- `PideYa/DesignSystem/Theme.swift:86-103` — `Typeface.Style(size:weight:relativeTo:)`; every new
  token must name the `UIFont.TextStyle` it scales against.
- `PideYaTests/OrdersTests.swift:13-50` — file-`private` stub providers returning data the mock
  cannot produce, so injection tests cannot pass by coincidence. `:62` and `:148` — model and
  provider suites are deliberately **not** `@MainActor`.
- `PideYaUITests/OrdersUITests.swift:81-83` — content-independent accessibility identifiers, and
  `:146-150` — asserting on the **count** of elements matching an identifier as the cascade
  regression guard. Both are requirements here, not options.
- `.swift-format:39-52` — `NeverForceUnwrap`, `NeverUseForceTry`, **`IdentifiersMustBeASCII`**
  (so the tile case is `comunicacion`, not `comunicación`; Spanish accents live in string literals
  only), `UseSynthesizedInitializer`, `OneCasePerLine`, 4-space indent, 120 columns.
- `PideYa.xcodeproj/project.pbxproj:32-48` — `PBXFileSystemSynchronizedRootGroup` with no
  exception set: new `.swift` files under `PideYa/`, `PideYaTests/`, `PideYaUITests/` join their
  target automatically. **`project.pbxproj` is never edited by this feature.**

### Naming and placement decision

New code lives in `PideYa/Home/Account/`, mirroring `PideYa/Home/Feed/` and `PideYa/Home/Orders/`
(`XModels.swift` / `XViewModel.swift` / `XSubviews.swift` / `XView.swift`). English symbol names,
Spanish string literals.

Design-system vs. feature folder, per the established rule (generic visuals → design system,
domain semantics → feature folder):

- `EyebrowLabel` and the new `ChipView` style → **design system**. Both are pure visual primitives
  that take their copy as a parameter.
- `AccountTileView`, `AccountTileGridView`, `AccountHeaderView`, `AccountWalletView` → **feature
  folder**. They encode account semantics (`needsAttention`, the badge pair, the balance row).

**No `stableID(_:)` duplication in this feature.** `AccountTile`'s identity is its
`AccountTileKind` raw value (a `String`), and the badges' is their kind — no `UUID` seeding is
needed anywhere, so the three-line helper duplicated into `MockOrdersContentProvider` is not
duplicated a third time.

## Tasks

1. [x] Edit `PideYa/DesignSystem/Theme.swift` — add three `Typeface` tokens and one `Size` token. Purely additive.
2. [x] Edit `PideYa/DesignSystem/DesignSystemViews.swift` — add `EyebrowLabel` and a third `ChipView.Style` case. Purely additive.
3. [x] Add `PideYa/Home/Account/AccountModels.swift` — profile, badges, the six tiles, row chunking, wallet, payment method, `AccountContentProviding` + `MockAccountContentProvider`.
4. [x] Add `PideYa/Home/Account/AccountViewModel.swift` — `@MainActor @Observable` VM with a constructor-injected provider.
5. [x] Add `PideYa/Home/Account/AccountSubviews.swift` — `AccountHeaderView`, `AccountTileView`, `AccountTileGridView`, `AccountWalletView`.
6. [x] Add `PideYa/Home/Account/AccountView.swift` — compose header + grid + wallet into one scroll view.
7. [x] Edit `PideYa/Home/HomeTabViewModel.swift` + `PideYa/Home/HomeTabView.swift` — own an `AccountViewModel` and route `case .cuenta`.
8. [x] Add `PideYaTests/AccountTests.swift` — Swift Testing coverage for formatting, derivation, chunking, mock data and injection.
9. [x] Add `PideYaUITests/AccountUITests.swift` — XCUITest coverage for the criteria that need a running app.

---

### 1. `PideYa/DesignSystem/Theme.swift` (edit — additive only)

Do not change, re-order or re-value any existing token; Inicio and Pedidos depend on all of them.

**`Theme.Typeface` — three new tokens.** This implements Q4 policy (a), *minimally* (see
"Resolved open questions"). A token is added only where rounding to an existing one is outside
DESIGN.md's own stated ±2 pt error bar on derived font sizes.

- `displayName = Style(size: 34, weight: .heavy, relativeTo: .largeTitle)` — the `Víctor` /
  `Arana` lines. Measured cap height 24.3 pt ÷ 0.714 = **34 pt**, cross-checked against the
  measured 98 pt advance width for 5 glyphs (§3.2). `brand` is 40 pt — 6 pt out, three times the
  error bar, and visibly wrong on a two-line name.
- `caption = Style(size: 11, weight: .regular, relativeTo: .caption2)` — tile subtitles (§4.4,
  measured ≈11 pt regular, ink heights 8.7–10.3 pt) and the footer (§5, ≈12 pt regular). The
  nearest existing tokens are `chip` (13, **bold**) and `subtitle` (15) — wrong weight and 4 pt
  out respectively.
- `captionBold = Style(size: 11, weight: .bold, relativeTo: .caption2)` — the two grey eyebrows
  (`CUENTA`, `MONEDERO`; §3.1 derived ≈11 pt bold) and the `needsAttention` tile subtitles (§4.4:
  "attention subtitles the same size, **bold**"). Mirrors the existing `subtitle`/`subtitleBold`
  pairing. Deliberately used **instead of** `tabLabel` (also 11/bold): §3.1 notes `tabLabel` is
  semantically a tab label, and this avoids a fourth token while keeping the eyebrow's role honest.

**No further `Typeface` tokens.** Everything else rounds inside the ±2 pt error bar:
`subtitleBold` (15) for tile titles (§4.4 measured 15–16), `Saldo y cupones` (§5 measured 13–14)
and `Cerrar sesión` (§5 measured 13–14); `cardTitle` (22) for the balance (§5 measured 22–26,
and §5 itself names `cardTitle` as nearest).

**No new `IconSize` token.** Tile glyphs (§4.4 measured 22–24 pt) are sized by applying
`.themeFont(Theme.Typeface.cardTitle)` (22 pt) to the `Image`, since SF Symbols size off the
ambient font. This is the `OrdersSubviews` precedent and is strictly better than
`HomeTabBar.swift:62`'s `.font(.system(size: Theme.IconSize.tab))`, because the glyphs then scale
with Dynamic Type. **Do not retrofit `HomeTabBar` — out of scope.**

**No new `Kerning` token.** The eyebrows reuse `Theme.Kerning.sectionTitle` (1.5). Checked against
the measurement: `CUENTA` is 54.3 pt wide for 6 glyphs at 11 pt = 0.82 em/glyph; SF Pro Bold
uppercase averages ≈0.65 em plus 1.5/11 = 0.136 em of tracking → 0.79 em. Within tolerance.

**No new `Palette` token** — see Q5 below.

**`Theme.Size` — one new token:**

- `accountTile: CGFloat = 120` — §4.1's measured grid row height. Applied as a **`minHeight`**,
  never a fixed `.frame(height:)`; §4.2 is explicit that 120 pt is the measured height at the
  default content size, not a constraint, and a fixed frame clips at large Dynamic Type.

### 2. `PideYa/DesignSystem/DesignSystemViews.swift` (edit — additive only)

Two additive changes, each with a `#Preview`. `SectionHeaderView`, `HardRule`,
`HatchedPlaceholder`, `FlowLayout`, `StarRatingView`, `OutlinedActionButton`, `filledStars` and
`themeFont` are untouched.

**(a) A third `ChipView.Style` case:**

```
enum Style {
    case outlined          // existing — ink hairline border
    case outlinedSubtle    // NEW — Theme.Palette.secondary hairline border, ink text, no fill
    case promo             // existing
}
```

Add one arm to each of the three existing `switch`es (`textColor` → `ink`, `backgroundColor` →
`.clear`, `border` → `Rectangle().strokeBorder(Theme.Palette.secondary, lineWidth: Theme.Stroke.hairline)`).
Existing call sites and their shipped UI tests are unaffected — this is a purely additive enum
case, not a change of behaviour.

*Why extend `ChipView` rather than add a component:* the second badge differs from `.outlined`
in exactly one property (border colour, §3.3). `OutlinedActionButton` earned its own type because
it is a `Button` and `ChipView` is not; a `StatusBadgeView` here would be a 90 % copy of
`ChipView` with one colour changed. §9 Q5 explicitly offers "add a `ChipView` border-colour
option" as one of the two sanctioned resolutions.

**(b) `EyebrowLabel`:**

```
struct EyebrowLabel: View {
    let text: String
}
```

`Text(text)` + `.themeFont(Theme.Typeface.captionBold)` + `.kerning(Theme.Kerning.sectionTitle)`
+ `.foregroundStyle(Theme.Palette.secondary)`. Copy-free (`text:` parameter), matching every other
component in this file — the round-1 review finding on `StarRatingView`'s baked-in Spanish.
Callers pass literal uppercase strings; **no `.textCase(.uppercase)`** (§8.5).

*Why not extend `SectionHeaderView`:* it hardcodes `Theme.Palette.ink` and 15 pt `sectionTitle`
and is used on two shipped screens (§3.1 states it "cannot be reused as-is"). Adding a style
parameter would change a shipped, UI-tested component's API for a role it does not have; a 6-line
sibling component is the smaller change.

### 3. `PideYa/Home/Account/AccountModels.swift`

**Isolation is a hard requirement here, not a stylistic one.** Under
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `nonisolated` on a type declaration does **not**
propagate into a separate `extension` block (DESIGN.md §8.8; this cost a full review cycle in
`pedidos-tab`). Therefore, in this file:

- `private nonisolated let esES = Locale(identifier: "es_ES")` at file scope — `nonisolated` on
  the constant is required, not decorative: without it the build fails with
  `Main actor-isolated let 'esES' can not be referenced from a nonisolated context` the moment the
  extensions are correctly annotated.
- **Every** extension block is written `nonisolated extension X { … }`.
- Any file-scope helper `func` is `nonisolated private func`.
- Verification is not by eye: task 8 includes a non-`@MainActor` test suite that calls the
  closure-bearing members from a nonisolated context. If an annotation is dropped, that suite
  crashes the test host (`EXC_BREAKPOINT` in `swift_task_checkIsolatedSwift`) rather than passing.

All value types → `Sendable` automatically; `Hashable` for future `navigationDestination(for:)`
use; `Identifiable` via a `String` id derived from the kind (no `UUID`s in this feature).

**Data model.**

```
nonisolated enum VerificationState: String, Hashable, Sendable {
    case verified
    case pending
}

nonisolated enum AccountBadgeKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case email
    case phone
    var id: String { rawValue }
}

nonisolated struct AccountBadge: Identifiable, Hashable, Sendable {
    let kind: AccountBadgeKind
    let state: VerificationState
    var id: String { kind.rawValue }
}

nonisolated struct AccountProfile: Hashable, Sendable {
    let givenName: String        // "Víctor"
    let familyName: String       // "Arana"
    let emailState: VerificationState
    let phoneState: VerificationState
}

nonisolated enum AccountTileKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case perfil
    case identidad
    case seguridad
    case notificaciones
    case comunicacion            // ASCII only — .swift-format IdentifiersMustBeASCII
    case pagos
    var id: String { rawValue }
    var title: String            // "Perfil", "Identidad", … "Comunicación", "Pagos"
    var systemImage: String      // "person", "person.text.rectangle", …
}

nonisolated struct AccountTile: Identifiable, Hashable, Sendable {
    let kind: AccountTileKind
    let subtitle: String
    let needsAttention: Bool     // ONE flag driving BOTH the icon and subtitle colour (§4.3)
    var id: String { kind.rawValue }
}

nonisolated struct AccountTileRow: Identifiable, Hashable, Sendable {
    let id: Int
    let tiles: [AccountTile]
    static func rows(from tiles: [AccountTile], columns: Int) -> [AccountTileRow]
}

nonisolated struct AccountWallet: Hashable, Sendable {
    let balance: Decimal         // 12.50 — numeric, NOT "12,50 €"
}

nonisolated struct PaymentMethod: Hashable, Sendable {
    let brand: String            // "Visa"
    let last4: String            // "4412" — String, so no grouping separator can appear
}
```

**`AccountTileKind.title` / `.systemImage` are on the kind, not the tile**, because they are
invariant design facts. Only `subtitle` and `needsAttention` are per-instance state. This is what
makes §4.3's "the red is a state, not a per-tile decoration" structural rather than conventional.

**`AccountTileRow.rows(from:columns:)`** is the only real logic in the feature, so it is a
`static func` a non-`@MainActor` test can call directly (the `filledStars` precedent, namespaced
per its review NIT). Behaviour: `columns` is clamped to `max(1, columns)`; chunks in order via
`stride(from:to:by:)`; row `id` is the 0-based row index; a ragged final row is returned short
(the view pads it — see task 5). Never force-unwraps, never slices out of range.

**Display formatting** (all in `nonisolated extension` blocks, unit-testable without a view):

- `AccountBadge.text` → literal uppercase, from `kind` × `state`:
  `email`+`verified` → `"EMAIL VERIFICADO"`, `email`+`pending` → `"EMAIL PENDIENTE"`,
  `phone`+`verified` → `"TEL. VERIFICADO"`, `phone`+`pending` → `"TEL. PENDIENTE"`.
  All four combinations are implemented and tested even though the mock uses two; the two unused
  strings are the trivial symmetric forms and are marked as such in a comment.
- `AccountBadge.isVerified` → `state == .verified`. The view maps this to `ChipView` style; the
  model does not import the design system.
- `AccountProfile.badges` → `[AccountBadge]`, always exactly two, **email then phone**, built from
  `emailState` / `phoneState`. Derived, so a badge can never contradict the profile it came from
  (the `OrdersViewModel.summaryText` pattern).
- `AccountWallet.balanceText` → `balance.formatted(.currency(code: "EUR").locale(esES))` →
  `"12,50\u{00A0}€"`. **U+00A0 before `€`, not a plain space** (§8.4).
- `PaymentMethod.maskedText` → `"\(brand) ···· \(last4)"` → `"Visa ···· 4412"`. The masking glyphs
  are **four U+00B7 middle dots** (§4.5), written as `\u{00B7}` in tests.
- `PaymentMethod.summaryText(wallet:)` → `"\(maskedText) · \(wallet.balanceText)"` →
  `"Visa ···· 4412 · 12,50\u{00A0}€"`. Separators are ` · ` (U+00B7, space either side).
  **This method is the resolution of Q2**: it takes the wallet rather than a number, so the Pagos
  tile subtitle is structurally incapable of showing a different balance from `MONEDERO`.

**Dependency injection:**

```
nonisolated protocol AccountContentProviding: Sendable {
    func profile() -> AccountProfile
    func tiles() -> [AccountTile]
    func wallet() -> AccountWallet
}

nonisolated struct MockAccountContentProvider: AccountContentProviding {
    private static let seedWallet: AccountWallet
    private static let seedPayment: PaymentMethod
    private static let seedProfile: AccountProfile
    private static let seedTiles: [AccountTile]
}
```

`paymentMethod()` is deliberately **not** on the protocol: no view needs it. It exists only so the
mock can build the Pagos subtitle from the same wallet it returns —
`AccountTile(kind: .pagos, subtitle: seedPayment.summaryText(wallet: seedWallet), needsAttention: false)`.
There is exactly one `Decimal` `12.50` in the whole feature.

**Seed data** (all six rows are pinned by DESIGN.md §4.3 — nothing invented, unlike `pedidos-tab`):

| kind | subtitle | needsAttention |
|---|---|---|
| `perfil` | `Nombre, foto, direcciones` | false |
| `identidad` | `Teléfono sin verificar` | **true** |
| `seguridad` | `2FA desactivada` | **true** |
| `notificaciones` | `Push y email activos` | false |
| `comunicacion` | `Español · sin marketing` | false |
| `pagos` | *derived* → `Visa ···· 4412 · 12,50 €` | false |

Profile: `givenName: "Víctor"`, `familyName: "Arana"`, `emailState: .verified`,
`phoneState: .pending`. Wallet: `12.50`. Payment: `Visa` / `4412`.

A file comment must record that this is **mock display data** (Q8): the name is the repository
owner's, used as sample content, not a credential and not PII requiring redaction. Nothing here
touches `UserDefaults` or any store.

### 4. `PideYa/Home/Account/AccountViewModel.swift`

```
@MainActor
@Observable
final class AccountViewModel {
    private(set) var profile: AccountProfile
    private(set) var tiles: [AccountTile]
    private(set) var wallet: AccountWallet

    init(provider: AccountContentProviding = MockAccountContentProvider())
}
```

- `init` reads all three provider methods synchronously and assigns. No `Task`, no `load()`, no
  loading/error state — there is no I/O. The provider is not stored.
- **No derived members.** `badges` is already derived on `AccountProfile` (the view reads
  `viewModel.profile.badges`), and row chunking is a *layout* decision that depends on the live
  `dynamicTypeSize`, so it belongs in the view, which calls
  `AccountTileRow.rows(from:columns:)` directly. Stated here explicitly so the implementer does
  not add a `tileRows` property or a `Bindable`/`var` out of pattern-matching: nothing on this
  screen is two-way bound.

### 5. `PideYa/Home/Account/AccountSubviews.swift`

Four internal `struct`s (internal, not private, because they live in a separate file from
`AccountView` — the trade `FeedSubviews`/`OrdersSubviews` already make to keep bodies short). Each
gets a `#Preview`. Every `body` under 40 lines; every `Text` and `Image` gets `.themeFont(_:)`;
no `AnyView`, no `.cornerRadius`, no `RoundedRectangle`, no `.textCase`.

**`AccountHeaderView(profile:)`** (§3, y 0–209).

- `body`: `VStack(alignment: .leading, spacing: Theme.Spacing.sm) { EyebrowLabel(text: "CUENTA"); nameBlock; badgeRow }`
  then `.padding(.horizontal, Theme.Spacing.lg)`, `.padding(.top, Theme.Spacing.sm)`,
  `.padding(.bottom, Theme.Spacing.lg)`, `.frame(maxWidth: .infinity, alignment: .leading)`,
  `.accessibilityElement(children: .contain)`, `.accessibilityIdentifier("account.header")`.
  - `.top, sm` (8): the eyebrow's measured ink top is y 66.3 and the iPhone 17 top safe area is
    59 pt → ≈7 pt of padding above the safe area.
  - `.bottom, lg` (16): badge box bottom 192.7 → boundary rule at 209.0 = 16.3 pt.
  - Horizontal margin is `lg` (16), **not** the measured 20 — house style, §0.1.
  - **No `.dynamicTypeSize(...)` cap.** Unlike `FeedHeaderView`/`OrdersHeaderView` there is no
    fixed-size box in this header (no avatar, no search field), and Q1's resolution requires the
    whole screen to remain reachable by scrolling at accessibility sizes.
- `private var nameBlock`: `VStack(alignment: .leading, spacing: 0)` of **two separate `Text`s** —
  `Text(profile.givenName)` and `Text(profile.familyName)`, both `.themeFont(Theme.Typeface.displayName)`,
  `.foregroundStyle(Theme.Palette.ink)`. §3.2 is emphatic: the break is deliberate, so it must
  come from two fields, **not** from `Text` wrapping and **not** from a `\n` in one string.
  Deliberately **not** `.accessibilityElement(children: .combine)` — combining would erase the two
  separate static texts that acceptance criterion 3 uses to prove the two-field model. VoiceOver
  reads two elements; that matches what is on screen.
- `private var badgeRow`: `FlowLayout(spacing: Theme.Spacing.sm)` (measured 8.0 pt gap, §3.3) over
  `ForEach(profile.badges)` producing
  `ChipView(text: badge.text, style: badge.isVerified ? .promo : .outlinedSubtle)`.
  `.accessibilityElement(children: .contain)` + `.accessibilityIdentifier("account.badges")`.
  Badges are **not** `Button`s (Q6). No fixed height and no `.clipped()`: §3.3's overflow in the
  mockup is a renderer artifact and must not be reproduced.

**`AccountTileView(tile:action:)`** (§4.2–§4.4).

- A real `Button(action: action)` with `.buttonStyle(.plain)` (Q6 — no-op action).
- Label: `VStack(alignment: .leading, spacing: Theme.Spacing.sm)` of
  `Image(systemName: tile.kind.systemImage).themeFont(Theme.Typeface.cardTitle)` and an inner
  `VStack(alignment: .leading, spacing: Theme.Spacing.xs)` of
  `Text(tile.kind.title).themeFont(Theme.Typeface.subtitleBold).foregroundStyle(Theme.Palette.ink)`
  and `Text(tile.subtitle).themeFont(subtitleFont).foregroundStyle(subtitleColor)`.
  - Spacings derived from §4.2: icon ink top +18, title ink top ≈+50 (≈12 pt ink gap → `sm` once
    line-box slack is accounted for); title ink bottom +63 → subtitle ink top +72 (≈10 pt → `xs`).
- `private var subtitleColor: Color` → `tile.needsAttention ? Theme.Palette.accent : Theme.Palette.secondary`;
  `private var subtitleFont` → `tile.needsAttention ? Theme.Typeface.captionBold : Theme.Typeface.caption`.
  The icon's `.foregroundStyle` uses the same `needsAttention` ternary (ink vs accent). All three
  read the single flag — §4.3's requirement.
- `.padding(.horizontal, Theme.Spacing.lg)` (§4.1: content inset ≈14–15.7 pt from the column
  origin), `.padding(.vertical, Theme.Spacing.lg)`, then
  `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)` — `topLeading` gives
  §4.2's top-aligned (not vertically centred) content, and `maxHeight: .infinity` is what makes
  the two tiles in a row render at equal heights.
- Accessibility: `.accessibilityElement(children: .ignore)` +
  `.accessibilityLabel("\(tile.kind.title). \(tile.subtitle)")` +
  `.accessibilityIdentifier("account.tile.\(tile.kind.rawValue)")`. The `.ignore` is the leaf-group
  half of the cascade rule: it stops the icon and the two `Text`s from becoming separately
  identified elements, and the explicit label makes assertions exact instead of depending on
  SwiftUI's child-concatenation order. The identifier is content-independent (the enum raw value),
  so it survives a data-source swap.
  - Note the consequence for tests: tile copy is asserted through `button.label`, **not** through
    `tile.staticTexts["Perfil"]`. This differs from `PastOrderRowView`, which is not a control and
    so uses `.contain`.
  - Colour is not the only carrier of the attention state: the subtitles themselves say
    `Teléfono sin verificar` and `2FA desactivada`, and those strings are in the a11y label.

**`AccountTileGridView(tiles:onSelect:)`** (§4.1, §7.1, §8.1).

- `@Environment(\.dynamicTypeSize) private var dynamicTypeSize`.
- `private var columns: Int { dynamicTypeSize.isAccessibilitySize ? 1 : 2 }` — §8.1's required
  handling. `Notificaciones` already occupies 106.7 pt of a ~187 pt column at the default size, so
  two columns cannot survive accessibility sizes.
- `private var rows: [AccountTileRow] { AccountTileRow.rows(from: tiles, columns: columns) }`.
- `body`: `VStack(spacing: 0)` over `ForEach(Array(rows.enumerated()), id: \.element.id)` emitting
  `row(row)` and, for every row **except the last**, a `HardRule()`. The boundary rules above and
  below the grid are emitted by `AccountView`, not here, so this view owns only the *internal*
  rules. `.accessibilityElement(children: .contain)` + `.accessibilityIdentifier("account.grid")`.
- `private func row(_ row: AccountTileRow) -> some View`: `HStack(spacing: 0)` interleaving
  `AccountTileView(tile:action:)` with a `columnDivider` between adjacent tiles, plus
  `Theme.Palette.transparent.frame(maxWidth: .infinity)` if `row.tiles.count < columns` so a
  ragged final row keeps its tile at column width instead of stretching. Then
  `.frame(minHeight: Theme.Size.accountTile)` and `.fixedSize(horizontal: false, vertical: true)`
  is **not** applied (the row must be free to grow).
- `private var columnDivider`: `Rectangle().fill(Theme.Palette.secondary).frame(width: Theme.Stroke.rule).frame(maxHeight: .infinity).accessibilityHidden(true)`.
  §4.1: 2 pt, runs the full grid height and butts into both boundary rules — that falls out of
  drawing it per row with `maxHeight: .infinity` and zero `HStack` spacing. `HardRule` is
  horizontal-only, so this is a local `Rectangle` (DESIGN.md §7.1 anticipates exactly this).
- The grid and its rules take **no horizontal padding** — they are full-bleed (§2, §4.1).

**`AccountWalletView(wallet:onSignOut:)`** (§5).

- `@Environment(\.dynamicTypeSize) private var dynamicTypeSize`.
- `body`: `VStack(alignment: .leading, spacing: Theme.Spacing.lg)` of
  `EyebrowLabel(text: "MONEDERO")`, `balanceRow`, `HardRule()`, `signOutButton`, `footer`, then
  `.padding(.horizontal, Theme.Spacing.lg)`, `.padding(.top, Theme.Spacing.lg)`,
  `.padding(.bottom, Theme.Spacing.xl)`, `.frame(maxWidth: .infinity, alignment: .leading)`,
  `.accessibilityElement(children: .contain)`, `.accessibilityIdentifier("account.wallet")`.
  Measured gaps in §2 are 17.3 / 17.3 / 20.7 / 22.3 pt — `lg` (16) throughout, plus line-box slack.
  **The rule inside this block is inset to the content margins** because it is inside the padded
  `VStack`; every other rule on the screen is full-bleed. §5 calls that contrast deliberate.
- `@ViewBuilder private var balanceRow`: at non-accessibility sizes an
  `HStack(alignment: .firstTextBaseline)` of `Text("Saldo y cupones").themeFont(subtitleBold).foregroundStyle(ink)`,
  `Spacer()`, `Text(wallet.balanceText).themeFont(cardTitle).foregroundStyle(ink).lineLimit(1).layoutPriority(1)`;
  at accessibility sizes the same two `Text`s in a `VStack(alignment: .leading, spacing: xs)`.
  `.firstTextBaseline` is measured, not guessed: the label's ink bottom is 634.3 and the balance's
  is 635.7 — they share a baseline despite the 13 vs 22 pt sizes. The `if/else` returns two
  concrete branches — **no `AnyView`**.
- `private var signOutButton`: `Button(action: onSignOut)` labelled
  `Text("Cerrar sesión").themeFont(Theme.Typeface.subtitleBold).foregroundStyle(Theme.Palette.accent)`,
  `.buttonStyle(.plain)`, `.accessibilityIdentifier("account.signOutButton")`. Plain red text — no
  border, no fill, sentence case (§5). **No `role: .destructive`**: the role exists for
  menu/alert presentation and would fight the explicit `.foregroundStyle`; the copy carries the
  meaning.
- `private var footer`: one `Text("PideYa 1.0 · Términos · Privacidad")` `.themeFont(caption)`
  `.foregroundStyle(secondary)` `.accessibilityIdentifier("account.footer")` — a single leaf, no
  cascade risk. Non-interactive (Q6).

### 6. `PideYa/Home/Account/AccountView.swift`

```
struct AccountView: View {
    let viewModel: AccountViewModel        // plain `let` — owned by HomeTabViewModel
    let bottomInset: CGFloat               // the tab bar's measured height

    init(viewModel: AccountViewModel, bottomInset: CGFloat = 0)

    body:
      NavigationStack {
          ScrollView {
              VStack(spacing: 0) {
                  AccountHeaderView(profile: viewModel.profile)
                  HardRule()                                     // section boundary
                  AccountTileGridView(tiles: viewModel.tiles, onSelect: { _ in })
                  HardRule()                                     // section boundary
                  AccountWalletView(wallet: viewModel.wallet, onSignOut: {})
              }
          }
          .scrollIndicators(.hidden)
          .background(Theme.Palette.background)
          .safeAreaInset(edge: .bottom, spacing: 0) {
              Theme.Palette.transparent.frame(height: bottomInset)
          }
          .toolbar(.hidden, for: .navigationBar)
      }
}
```

Concrete requirements:

- **No `.safeAreaInset(edge: .top)`** — the header scrolls with everything else (Q1).
- **The `.safeAreaInset(edge: .bottom)` is mandatory, not stylistic.** §8.2: `HomeTabView`'s bottom
  inset does not cross the `NavigationStack` boundary. `bottomInset` is threaded from
  `HomeTabView.tabBarHeight` (already measured; no new measurement code). At the default content
  size this screen is ~75 pt *shorter* than the viewport, so omitting the inset is invisible —
  which is exactly why acceptance criterion 9 runs at an accessibility content size.
- The two `HardRule()`s between blocks are the §2 "section boundary" rules and are **full bleed**:
  the `VStack` takes no horizontal padding; each child block applies its own.
- The bar is hidden and there is no `navigationDestination` yet: the stack is the seam so the
  typed-enum destination pattern can be added later without restructuring. **Do not invent an
  `AccountRoute` enum or detail screens now.**
- All actions are `{}` no-ops (Q6). `onSelect` takes the `AccountTileKind` so a future router has
  a signature to fill in; the closure body stays empty.
- `#Preview { AccountView(viewModel: AccountViewModel()) }`.

### 7. `PideYa/Home/HomeTabViewModel.swift` + `PideYa/Home/HomeTabView.swift` (edits)

The **only** changes to shipped Home files. Both additive; no existing line is deleted.

```
final class HomeTabViewModel {
    var selectedTab: HomeTab = .inicio
    let feed: FeedViewModel
    let orders: OrdersViewModel
    let account: AccountViewModel                     // NEW

    init(
        feed: FeedViewModel = FeedViewModel(),
        orders: OrdersViewModel = OrdersViewModel(),
        account: AccountViewModel = AccountViewModel()    // NEW, defaulted
    )
}
```

```
@ViewBuilder private var selectedScreen: some View {
    switch viewModel.selectedTab {
    case .inicio:  FeedView(viewModel: viewModel.feed,       bottomInset: tabBarHeight)
    case .pedidos: OrdersView(viewModel: viewModel.orders,   bottomInset: tabBarHeight)
    case .cuenta:  AccountView(viewModel: viewModel.account, bottomInset: tabBarHeight)  // NEW
    case let other: PlaceholderTabView(tab: other)
    }
}
```

Every parameter stays defaulted, so `HomeTabViewModel()` still compiles and
`PideYa/PideYaApp.swift` needs **zero** changes. `case let other:` now matches only `.buscar` and
must remain (removing it makes the switch non-exhaustive if a tab is added). No `AnyView`.
`HomeTabBar`, `HomeTab` and `PlaceholderTabView` are untouched — the `cuenta` glyph stays
`person` and the unselected-item colour mismatch stays as-is (§6 marks both as observations, not
requirements).

### 8. `PideYaTests/AccountTests.swift`

Swift Testing only (`import Testing`, `@Test`, `#expect`). Includes a file-`private`
`StubAccountContentProvider` returning fixed data the mock cannot produce. **Model, chunking and
provider suites must not be annotated `@MainActor`** — that is what makes them a real guard on the
§8.8 isolation contract. See Test plan.

### 9. `PideYaUITests/AccountUITests.swift`

XCUITest — the one sanctioned XCTest exception. Every test navigates via
`app.buttons["tabbar.cuenta"].tap()` first. Two tests relaunch with
`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityL`.

---

## Acceptance criteria

1. **Given** a clean checkout, **when**
   `xcodebuild build -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'` runs,
   **then** it succeeds with **zero compiler warnings**, and
   `git diff --stat -- PideYa.xcodeproj/project.pbxproj PideYa/PideYaApp.swift` is **empty**.
2. **Given** the app is on Inicio, **when** `tabbar.cuenta` is tapped, **then**
   `app.otherElements["placeholder.cuenta"]` does **not** exist, and the static texts `CUENTA`,
   `MONEDERO`, `Saldo y cupones` all exist. **When** `tabbar.inicio` is tapped, **then**
   `OFERTAS DE HOY` exists and `MONEDERO` does not; **when** `tabbar.pedidos` is tapped, **then**
   `EN CURSO` exists. (Routing works and neither shipped tab regressed.)
3. **Given** the Cuenta tab, **then** `app.staticTexts["Víctor"]` and `app.staticTexts["Arana"]`
   both exist, and
   `app.staticTexts.matching(NSPredicate(format: "label == %@", "Víctor Arana")).count == 0`.
   (Proves the two-field, two-line name model of §3.2 rather than a wrapped single `Text`.)
   Additionally `app.staticTexts["EMAIL VERIFICADO"]` and `app.staticTexts["TEL. PENDIENTE"]`
   exist, and `app.buttons["EMAIL VERIFICADO"].exists == false` (badges are status, not controls).
4. **Given** the Cuenta tab, **then**
   `app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "account.tile.")).count == 6`,
   and each of the six buttons' `label` equals exactly:
   `Perfil. Nombre, foto, direcciones` / `Identidad. Teléfono sin verificar` /
   `Seguridad. 2FA desactivada` / `Notificaciones. Push y email activos` /
   `Comunicación. Español · sin marketing` / `Pagos. Visa ···· 4412 · 12,50\u{00A0}€`
   (middle dots asserted as `\u{00B7}`, the euro space as `\u{00A0}`).
   **Identifier-cascade guards** (the defect shipped by the previous feature):
   `app.descendants(matching: .any).matching(identifier: "account.tile.perfil").count == 1`,
   and the same `== 1` for `account.header`, `account.grid`, `account.badges`, `account.wallet`.
5. **Given** the Cuenta tab, **then** `app.otherElements["account.wallet"]` contains the static
   texts `MONEDERO`, `Saldo y cupones` and `12,50\u{00A0}€`, and app-wide
   `app.staticTexts.matching(NSPredicate(format: "label == %@", "12,50\u{00A0}€")).count == 1`
   (the second occurrence is inside the Pagos tile's *button label*, asserted in criterion 4).
   **Unit-level:** `MockAccountContentProvider().tiles()` — the `.pagos` tile's `subtitle`
   `hasSuffix(MockAccountContentProvider().wallet().balanceText)`, and
   `PaymentMethod(brand: "Visa", last4: "4412").summaryText(wallet: AccountWallet(balance: 99))`
   ends in `"99,00\u{00A0}€"`. (Q2: one balance, two call sites, provably not two literals.)
6. **Given** the Cuenta tab, **then** `app.buttons["account.signOutButton"].label == "Cerrar sesión"`;
   **when** it and all six tiles are tapped in turn, **then** nothing pushes, dismisses or changes:
   `app.otherElements["account.grid"]` and `app.staticTexts["MONEDERO"]` still exist and
   `tabbar.cuenta` is still selected. **And** `app.staticTexts["PideYa 1.0 · Términos · Privacidad"]`
   exists while `app.buttons["Términos"].exists == false` (Q6: footer is not interactive).
7. **Given** the Cuenta tab at the **default** content size, **then** for
   `perfil = app.buttons["account.tile.perfil"]` and `identidad = app.buttons["account.tile.identidad"]`:
   `abs(perfil.frame.minY - identidad.frame.minY) < 1` (same row),
   `perfil.frame.minX < identidad.frame.minX` (two columns),
   `abs(perfil.frame.height - identidad.frame.height) < 1` (§4.2 equal heights), and
   `perfil.frame.height >= 120` (§4.1 measured row height, applied as `minHeight`).
8. **Given** a launch with
   `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityL`, **then**
   `perfil.frame.minY < identidad.frame.minY` and `abs(perfil.frame.minX - identidad.frame.minX) < 1`
   (the grid collapsed to one column, §8.1), and for every one of the six tiles
   `tile.frame.maxX <= app.windows.firstMatch.frame.maxX + 1` (no horizontal overflow).
9. **Given** the same accessibility-size launch, **when** the view is scrolled to the bottom,
   **then** `app.buttons["account.signOutButton"].isHittable` is true,
   `signOut.frame.maxY <= app.buttons["tabbar.cuenta"].frame.minY`, and the same holds for
   `app.staticTexts["account.footer"]`. **This criterion must be run at an accessibility content
   size**: at the default size the content is ~75 pt shorter than the viewport (§1), so a missing
   `.safeAreaInset(edge: .bottom)` would pass unnoticed. Verify the criterion is load-bearing by
   removing that inset in a scratch copy and observing this test fail.
10. **Given** the same accessibility-size launch, **when** the screen is swiped up three times,
    **then** `app.staticTexts["CUENTA"]`'s `frame.minY` has **decreased** (or the element no longer
    exists). Proves Q1's resolution: the header scrolls, it is not pinned.
11. **Given** the sources, **when** they are grepped, **then**:
    - `rg -n '\.cornerRadius\(|RoundedRectangle\(|AnyView\(|ObservableObject|@Published|try\?|\.textCase\(' PideYa/ PideYaTests/ PideYaUITests/`
      returns **no matches**.
      > The `(` anchors are load-bearing and this exact pattern was **verified empty against the
      > pre-feature tree while writing this plan**. Without them the pattern matches the prose in
      > `PideYa/DesignSystem/Theme.swift:14` (``/// may apply `.cornerRadius` or `RoundedRectangle`.``)
      > and the criterion fails on an untouched checkout — which is what happened in `pedidos-tab`.
    - `rg -n '#[0-9A-Fa-f]{6}|Color\(red:|Color\.\w|\.white|\.black|\.gray|\.red' PideYa/ --glob '!PideYa/DesignSystem/Theme.swift'`
      returns **no matches** (verified empty against the pre-feature tree: every current hit is in
      `Theme.swift`, which the glob excludes).
    - `rg -n '\.font\(' PideYa/Home/Account/` returns **no matches** — all sizing goes through
      `.themeFont(_:)`, including the SF Symbols (§8.1).
    - `rg -n 'frame\(height: Theme\.Size\.accountTile|frame\(width: 120|height: 120' PideYa/Home/Account/`
      returns **no matches** — the 120 pt tile height is a `minHeight`, never a fixed frame (§4.2).
    - `rg -n 'nonisolated extension' PideYa/Home/Account/AccountModels.swift` returns **one match
      per extension block in that file**, and `rg -n '^extension ' PideYa/Home/Account/` returns
      **no matches** (§8.8).
12. **Given** two launches — one default, one with `UICTContentSizeCategoryAccessibilityL` —
    **then** the measured `frame.height` of the `MONEDERO` static text is **strictly greater** in
    the second run. (A ratio of exactly 1.0 is the `Font.system(size:)` defect from §8.1.)
13. **Given** `swift-format lint --configuration .swift-format --recursive PideYa PideYaTests PideYaUITests`
    (invoked via `xcrun --find swift-format`, since `which swift-format` fails), **then** it
    reports **no findings**, and `git commit` succeeds without `--no-verify` (§8.7).
14. **Given** every `View` added or edited, **when** its `body` is measured, **then** it is under
    40 lines, and every new **view** file (`AccountSubviews.swift`, `AccountView.swift`) has at
    least one `#Preview` that compiles. (`AccountModels.swift` and `AccountViewModel.swift` are
    not views and are exempt — the equivalent criterion was mis-worded last time.)
15. **Given** `xcodebuild test -scheme PideYa -destination 'platform=iOS Simulator,name=iPhone 17'`,
    **then** all 55 pre-existing tests still pass, plus the new ones below, with 0 failures.

## Test plan

**Unit** (`PideYaTests/AccountTests.swift`, Swift Testing). Suites `AccountTileKindTests`,
`AccountFormattingTests`, `AccountTileRowTests` and `MockAccountContentProviderTests` are
**not** `@MainActor`; only `AccountViewModelTests` and `HomeTabViewModelAccountTests` are.

| Test | Proves |
|---|---|
| `tileKindsAreTheSixDesignedTilesInOrder` | `AccountTileKind.allCases.map(\.rawValue) == ["perfil","identidad","seguridad","notificaciones","comunicacion","pagos"]`, titles `["Perfil","Identidad","Seguridad","Notificaciones","Comunicación","Pagos"]`, symbols `["person","person.text.rectangle","checkmark.shield","bell","bubble.left","creditcard"]` (§4.3, Q3). Declaration order **is** grid order. |
| `badgeTextCoversEveryKindAndStateCombination` | All four combinations produce literal uppercase strings; `EMAIL VERIFICADO` / `TEL. PENDIENTE` are exact. Guards against `.textCase` creeping in (which would leave the a11y value lowercase). |
| `profileBadgesAreEmailThenPhoneAndDerivedFromState` | `profile.badges.count == 2`, order email→phone, texts follow `emailState`/`phoneState`; flipping `phoneState` to `.verified` changes the second badge's text. Derived, so it cannot contradict the profile. |
| `walletBalanceTextUsesNonBreakingSpaceBeforeEuro` | `12.50` → `"12,50\u{00A0}€"` (asserted with the escape, §8.4); `0` → `"0,00\u{00A0}€"`. |
| `paymentMaskedTextUsesFourMiddleDots` | `"Visa ···· 4412"` with `\u{00B7}` ×4 written explicitly (§4.5). |
| `paymentSummaryTextReadsTheWalletItIsGiven` | `summaryText(wallet:)` == `"Visa ···· 4412 · 12,50\u{00A0}€"`; with `AccountWallet(balance: 99)` it ends `"99,00\u{00A0}€"` — the balance is genuinely read, not a literal (**Q2**). |
| `tileRowsChunkSixTilesIntoThreePairs` | `columns: 2` → 3 rows of 2, ids `0,1,2`, tile order preserved. |
| `tileRowsCollapseToOnePerRowForOneColumn` | `columns: 1` → 6 rows of 1 — the accessibility-size layout (§8.1). |
| `tileRowsHandleRaggedAndDegenerateInput` | 5 tiles / 2 cols → `[2,2,1]`; `[]` → `[]`; `columns: 0` and `columns: -3` clamp to 1 (no crash, no force-unwrap, no out-of-range slice). |
| `modelFormattingRunsFromANonisolatedContext` | **The §8.8 guard.** A non-`@MainActor` `@Test` that calls `AccountTileRow.rows(from:columns:)`, `profile.badges` and `payment.summaryText(wallet:)` — all closure-bearing or extension-declared. Dropping a `nonisolated` annotation makes this crash the test host or fail to compile. Do **not** annotate this suite `@MainActor` to "fix" a failure. |
| `mockProviderSeedsTheSixDesignedTiles` | Six tiles in kind order; subtitles exactly per §4.3; `map(\.needsAttention) == [false, true, true, false, false, false]`. |
| `mockIdentityTileAttentionMatchesPhoneState` | `tiles()[.identidad].needsAttention == (profile().phoneState == .pending)` — cross-consistency between the two places the phone's status is expressed. |
| `mockProfileStoresGivenAndFamilyNameSeparately` | `givenName == "Víctor"`, `familyName == "Arana"`, `emailState == .verified`, `phoneState == .pending` (§3.2, Q8). |
| `mockPagosSubtitleIsDerivedFromTheSameWallet` | `tiles()[.pagos].subtitle.hasSuffix(wallet().balanceText)` and `wallet().balance == 12.50`. Criterion 5's unit half. |
| `viewModelSurfacesInjectedProviderData` | **Constructor injection.** `AccountViewModel(provider: StubAccountContentProvider())` exposes the stub's `givenName` (`"Estela"`), its 2 tiles and its `3.05` balance — values the mock cannot produce, so it cannot pass by coincidence. `@MainActor`. |
| `viewModelWithEmptyProviderHasNoTiles` | An empty stub → `tiles.isEmpty`; `AccountTileRow.rows(from: [], columns: 2) == []` so the grid renders nothing rather than crashing. |
| `homeTabViewModelOwnsAccountViewModel` | `HomeTabViewModel()` compiles with no arguments, `viewModel.account.tiles.count == 6`, and `selectedTab = .cuenta` sticks. Guards the "`PideYaApp.swift` unchanged" contract. |

**UI** (`PideYaUITests/AccountUITests.swift`, XCUITest):

| Test | Covers |
|---|---|
| `testCuentaTabReplacesPlaceholderAndDoesNotBreakOtherTabs` | Criterion 2 (three-way round trip). |
| `testNameRendersAsTwoSeparateLines` | Criterion 3 — the two static texts and the absence of a combined `Víctor Arana`. |
| `testBadgesAreStatusNotControls` | Criterion 3 — both badge strings exist; neither is a button. |
| `testSixTilesHaveExactLabelsAndUniqueIdentifiers` | Criterion 4 — the `count == 6`, the six exact labels, and the five `descendants(...).count == 1` cascade guards. |
| `testWalletShowsBalanceOnceAsTextAndOnceInThePagosTile` | Criterion 5 — the `== 1` static-text count plus the Pagos button label. |
| `testTilesAndSignOutAreNoOps` | Criterion 6 — tap all seven controls, assert nothing navigated. |
| `testFooterIsNotInteractive` | Criterion 6 — footer text exists, `Términos` is not a button. |
| `testGridIsTwoEqualColumnsAtDefaultTextSize` | Criterion 7 — same `minY`, ascending `minX`, equal heights, `height >= 120`. |
| `testGridCollapsesToOneColumnAtAccessibilitySize` | Criterion 8 — stacked `minY`, shared `minX`, no tile past the window's right edge. |
| `testSignOutIsReachableAboveTabBarAtAccessibilitySize` | Criterion 9 — the `NavigationStack` bottom-inset regression, exercised at the only content size where it is observable. |
| `testHeaderScrollsAndIsNotPinned` | Criterion 10 — Q1's resolution. |
| `testAccountTextScalesWithDynamicType` | Criterion 12 — `MONEDERO` height strictly greater at `AccessibilityL`. |

**Edge cases to exercise manually / in previews:**

- **iPhone SE (375 pt) at `.xxxLarge`** — the worst case, because `isAccessibilitySize` is still
  `false` there so the grid is *still two columns* at ~171 pt per column while `Notificaciones`
  and `Comunicación` are at their largest non-accessibility size. Confirm titles wrap rather than
  truncate and the tiles keep equal heights. This is the one gap the automated criteria do not
  close (criterion 8 tests `AccessibilityL`, criterion 7 tests the default).
- The vertical column divider butts cleanly into both boundary rules with no gap at the top or
  bottom of the grid, at both content sizes (§4.1).
- The `MONEDERO` rule is visibly **inset** to the 16 pt margins while every other rule is
  full-bleed (§5) — the single most likely thing to get uniformly padded by accident.
- `Cerrar sesión` is plain red text: no border, no fill, no chip (§5).
- Icon identities render as real glyphs, not the SF Symbols "missing" placeholder — a mistyped
  symbol name is silent at compile time and invisible to every automated criterion here (Q3).
- Dark mode: appearance unchanged (fixed sRGB literals) — the accepted behaviour.
- VoiceOver swipe order: `CUENTA` → `Víctor` → `Arana` → two badges → six tile buttons →
  `MONEDERO` → `Saldo y cupones` → balance → `Cerrar sesión` → footer.

**Not runnable yet:** snapshot tests — `SnapshotTesting` is still not an SPM dependency
(`CLAUDE.md` "Tooling Not Yet Installed"). Do not add it in this feature.

## Resolved open questions (DESIGN.md §9)

Each of the eight is answered explicitly; none is answered by silence.

1. **Does this screen scroll, and does the header pin?** → **One `ScrollView`, everything scrolls,
   nothing pinned.** No `.safeAreaInset(edge: .top)`. Reason: Pedidos pins because a 12-row list
   scrolls *under* the header; here there is no list, and at accessibility content sizes the
   single-column grid plus the wallet block will exceed the viewport, so `Cerrar sesión` must be
   reachable by scrolling. A pinned header would also permanently consume ~145 pt of a screen that
   is already tight at large type. The `.safeAreaInset(edge: .bottom)` from §8.2 is still applied.
   Criterion 10 pins the decision; criterion 9 pins the inset.
2. **Is `12,50 €` the same value in the Pagos tile and in `MONEDERO`?** → **Yes.** One
   `AccountWallet.balance: Decimal`, formatted once by `balanceText`; the Pagos subtitle is built
   by `PaymentMethod.summaryText(wallet:)`, which takes the wallet as a parameter. There is
   exactly one `12.50` literal in the feature (in `MockAccountContentProvider.seedWallet`). Reason:
   a card's stored balance and a wallet balance being the same number is the only reading that
   makes the mockup self-consistent, and deriving makes drift impossible — the
   `OrdersViewModel.summaryText` precedent. Criterion 5 (UI + unit) proves the derivation is real.
3. **Icon identities.** → **Accept all six as transcribed**: `person`, `person.text.rectangle`,
   `checkmark.shield`, `bell`, `bubble.left`, `creditcard`. All exist on iOS 17.6 (none is an
   iOS 18+ addition; `bubble.left` is deprecated-but-present in later SDKs). Reason: DESIGN.md
   permits substituting a near neighbour but not changing the concept, and none of the six has a
   better-matching neighbour for its concept. Pinned by
   `tileKindsAreTheSixDesignedTilesInOrder`, so a later swap is a deliberate, visible edit.
   *Caveat:* a mistyped symbol name compiles and renders a blank — it is on the manual visual pass.
4. **Type scale.** → **Policy (a), minimally: three new `Typeface` tokens** — `displayName` (34
   heavy), `caption` (11 regular), `captionBold` (11 bold). Everything else rounds onto
   `subtitleBold` (15), `cardTitle` (22) and `.themeFont(cardTitle)`-sized icons. Reason: DESIGN.md
   states derived font sizes are accurate only to ±2 pt, so 13–14 → 15 and 22–26 → 22 are *inside*
   the error bar and a new token would be unjustifiable precision; 34 → 40 and 11 → 15 are 3× and
   2× the error bar and are the two §9 Q4 itself names as visibly wrong. `captionBold` doubles as
   the eyebrow token, which avoids both a fourth token and the semantic mismatch of reusing
   `tabLabel`. No new `IconSize` and no new `Kerning`.
5. **Rule and border colours.** → **`HardRule()` (`secondary`, 2 pt) for every rule**, boundary and
   internal alike, and the column divider drawn in `secondary` too. The badge border also uses
   **`secondary`**, via the new `ChipView.Style.outlinedSubtle`. Reason: `secondary` (`#8A8A8A`) is
   21 steps from the internal grey `#9F9D9D` while `outline` (`#C9C9C9`) is 42 — `secondary` is the
   better match, and `outline` means "control border / unreached state" in this codebase, not
   "hairline grey". Two near-identical grey tokens for a 20-step difference would be
   design-system-wide churn for an invisible gain. The boundary/internal distinction (`#6C6A6A` vs
   `#9F9D9D`) is deliberately **collapsed**; it is worth revisiting as its own cross-tab change,
   like the two-reds question in §0.1. **No new `Palette` token is added by this feature.**
6. **Are tiles, badges and `Cerrar sesión` interactive?** → **Tiles: yes, six real `Button`s with
   `{}` actions. `Cerrar sesión`: yes, a real `Button` with a `{}` action. Badges: no. Footer: no.**
   Reason: making the controls real now gets hit targets, the accessibility tree and layout right,
   and later wiring is a change of closure body rather than a restructure (the `Ver todas` /
   `Filtrar` / `Ayuda` precedent). The badges are status indicators with no affordance in the
   mockup. `Términos` / `Privacidad` stay inside one non-interactive `Text`: splitting them into
   buttons would create ~50 × 12 pt tap targets (well under the 44 pt HIG minimum) and promise
   navigation that does not exist. Criterion 6 pins all four decisions.
7. **Where does the account data come from?** → **`AccountContentProviding` +
   `MockAccountContentProvider`, injected through a defaulted init parameter**, mirroring
   `MockOrdersContentProvider`. Three methods (`profile()`, `tiles()`, `wallet()`), synchronous,
   `Sendable`, `nonisolated`. No networking, no auth, no persistence, no `UserDefaults`.
8. **`Víctor Arana` is the repository owner's own name.** → **Keep it, as mock display data.** It
   lives in exactly one place (`MockAccountContentProvider.seedProfile`), is not a credential, is
   not stored anywhere, and is the same class of sample content as `Taquería Norte`. It is also the
   git author's name, so it is self-referential test data rather than third-party PII. Reason to
   flag it anyway: acceptance criteria 3 couples the UI tests to those two strings, so swapping to
   a neutral name later is a two-line change in the mock **plus** three assertions in
   `AccountUITests` — recorded here so that coupling is a known cost, not a surprise.

## Out of scope

- `Buscar` — `PlaceholderTabView` only, unchanged.
- Any behavioural change to `Inicio` or `Pedidos`, to `HomeTabBar` / `HomeTab` glyphs, to
  `SectionHeaderView`, `HardRule`, `HatchedPlaceholder`, `FlowLayout`, `StarRatingView`,
  `OutlinedActionButton`, or to any existing `Theme` token or `ChipView` style.
- **Fixing `PideYa/Home/Feed/FeedModels.swift`'s latent `nonisolated extension` bug** (`:10`,
  `:42`, `:60`). It is real and it is the same defect §8.8 describes, but it belongs to a shipped
  feature and touching it here would mix a bug fix into a feature diff. Do not copy its shape and
  do not edit it. Worth its own follow-up.
- Splitting `Theme.Palette.accent` into an icon-red and a text-red, and the boundary-vs-internal
  rule greys (§0.1, §9 Q5) — both are cross-tab design-system changes.
- Retrofitting `HomeTabBar.swift:62`'s `.font(.system(size: Theme.IconSize.tab))` to `themeFont`,
  and the unselected tab-item colour (§6).
- Detail screens behind any tile, an `AccountRoute` enum, `navigationDestination`, real sign-out,
  a `Términos`/`Privacidad` web view, edit flows, 2FA enrolment, payment-method management.
- Networking, auth, persistence, SwiftData, caching, pull-to-refresh, loading/error states.
- Real image assets, avatars, localization catalogue / `String(localized:)`.
- Dark mode, iPad, landscape, and Dynamic Type behaviour beyond the two-columns → one-column
  collapse specified in §8.1.
- Snapshot testing, analytics, haptics, animated tab transitions.

## Risks / open questions

- **The 35 pt name leading (1.03 em) is not reproducible without a hack.** §3.2 measures
  baseline-to-baseline 35 pt at 34 pt heavy; a `VStack(spacing: 0)` of two `Text`s gives SwiftUI's
  default line box, ≈40–41 pt. Negative `VStack` spacing would hit it at the default size and
  break at every other Dynamic Type size. **Decision: accept the ≈6 pt delta**, same class of
  trade as the 20 → 16 pt margin in §0.1. Flagged so a visual pass does not read it as a bug.
- **`ChipView` is a shipped, UI-tested component and this feature edits it.** The change is a
  purely additive enum case plus three `switch` arms, but it is the one place a regression could
  reach Inicio or Pedidos. Criterion 15 (the full pre-existing suite) is the guard. If a reviewer
  objects to touching it at all, the fallback is a `StatusBadgeView` in `PideYa/Home/Account/` —
  ~15 duplicated lines, and §9 Q5 sanctions either.
- **The tile a11y model differs from `PastOrderRowView`'s.** Tiles are `Button`s and use
  `.accessibilityElement(children: .ignore)` + an explicit label; past-order rows are not controls
  and use `.contain`. Consequence: tile copy is asserted through `button.label`, and
  `app.staticTexts["Perfil"]` will **not** exist. This is correct (a tappable tile is one control)
  but it will surprise anyone pattern-matching on `OrdersUITests`. Called out in the file's comments.
- **`12,50 €` appears twice on screen but only once as a `staticText`** — the other occurrence is
  inside a button's label. Any future test doing `app.staticTexts["12,50\u{00A0}€"]` expecting two
  hits will be confused. Criterion 5 turns this into an assertion rather than a trap.
- **The grid-collapse threshold is `dynamicTypeSize.isAccessibilitySize`**, so `.xxxLarge` still
  renders two columns. That is the largest non-accessibility size and, on a 375 pt device, the
  tightest layout in the app. It is not covered by any automated criterion (criterion 7 tests the
  default size, criterion 8 tests `AccessibilityL`) and is the first item on the manual pass. If
  it proves unusable, the fix is one comparison (`>= .xxLarge`), not a restructure — do **not**
  fix it by shrinking the `caption` token, which the tiles share with the footer.
- **Boundary and internal rule greys are deliberately collapsed to one colour** (Q5). If a visual
  pass disagrees, the fix is a `HardRule(color:)` argument at four call sites — the parameter
  already exists — plus one new `Palette` token.
- **Icon identities are DESIGN.md's best match, not ground truth** (Q3), and a wrong SF Symbol
  name is invisible to every automated check in this plan. Manual pass only.
- **The `.pagos` subtitle derivation lives in the mock provider**, not in a real backend. A future
  provider must call `summaryText(wallet:)` rather than composing its own string; the model method
  exists precisely to make that the path of least resistance, and
  `mockPagosSubtitleIsDerivedFromTheSameWallet` catches the mock drifting, but nothing can force a
  future provider's hand.
- **Task count is 9**, at the top of the 3–10 range. Tasks 1–2 (design-system extensions) could be
  split out, but I recommend against it for the same reason as `pedidos-tab`: `EyebrowLabel` and
  `.outlinedSubtle` have no call sites until this screen exists, so reviewing them alone means
  reviewing an API in a vacuum.
- **Assumed** that `HomeTabViewModel` gaining a third defaulted init parameter is acceptable and
  that no in-flight branch constructs it positionally. `PideYaApp.swift` is unaffected.
- **Assumed** the iPhone 17 top safe area is 59 pt when deriving the header's 8 pt top padding
  from the measured y 66.3 ink position. If the simulator reports otherwise the padding is off by
  a few points; it is a one-token change and is on the visual pass.
