# DESIGN.md — Cuenta tab

> **Why this file exists.** The design was supplied as an image. Subagents in this pipeline
> cannot see images, so this is a faithful text transcription of the mockup and is the
> single source of truth for visual intent. Where the mockup is ambiguous it says so
> explicitly rather than inventing a resolution — see **§9 Open questions**.
>
> Source image: `~/Downloads/pideya-cuenta-3b.png`, **1206 × 2622 px = exactly 3.0 px per
> point on a 402 × 874 pt device** (iPhone 17). Unlike the two previous mockups, this one was
> measured **programmatically** (BMP pixel probe), not by eye. Every number below with a `pt`
> unit is a real measurement of the rendered ink, accurate to ±0.3 pt. Derived **font sizes**
> are the exception: they are back-calculated from ink box heights using SF Pro metrics
> (cap ≈ 0.714 em, ascender ≈ 0.73 em) and are only accurate to **±2 pt**. Treat font sizes as
> "which existing `Theme` token is nearest", never as values to hardcode.

---

## 0. Relationship to the existing design system

This is the **third** tab built on the design system from `home-tab-feed-ui`, extended by
`pedidos-tab`. It reuses that language wholesale:

- Same page background, ink, secondary, accent, promo-fill colours.
- **Zero corner radius everywhere.** No `.cornerRadius`, no `RoundedRectangle`. Every box,
  badge and rule in this mockup is a hard-edged rectangle. (Note: the badge and tile corners
  in the mockup are visibly square — this is verified, not assumed.)
- Same uppercase, letter-spaced labels; same es-ES number formatting (comma decimal
  separator, **U+00A0** before `€`).

Prefer reusing `Theme` tokens and `DesignSystemViews` components. Add new tokens only where
the mockup genuinely shows something the previous two tabs did not — §7 lists exactly what
that is.

### 0.1 Two measured deviations that are house style, NOT new design intent

I measured the **already-shipped** `pideya-pedidos-2a.png` to check these. Both appear
identically in that mockup, and the shipped Pedidos code deliberately normalises both. Do the
same here; do **not** "fix" them.

| Mockup measures | Shipped code uses | Verdict |
|---|---|---|
| Screen margin **20.0 pt** (both mockups) | `Theme.Spacing.lg` = **16 pt** | Use **16 pt**. Cross-tab consistency beats 4 pt of fidelity. |
| Two reds: **`#EC3013`** for icons/tab-bar and **`#AE1800`** for red *text* (both mockups) | single `Theme.Palette.accent` = `#E2372A` | Use **`accent`** for both. Splitting it now would be a design-system-wide change touching two shipped screens. |

> The `#AE1800` text-red is plausibly a deliberate contrast choice (≈6.5:1 on the page
> background vs ≈4.0:1 for `accent`). That is worth revisiting **as its own change across all
> tabs**, not silently introduced in this one.

---

## 1. Screen skeleton, top to bottom

```
┌─────────────────────────────────────────────┐
│  CUENTA                                     │  ← grey eyebrow
│  Víctor                                     │  ← 34 pt heavy, TWO LINES
│  Arana                                      │
│  ▓EMAIL VERIFICADO▓  ┌TEL. PENDIENTE┐       │  ← two badges
├═════════════════════════════════════════════┤  ← 2 pt rule, full bleed
│   👤 Perfil          │  🪪 Identidad         │
│   Nombre, foto…      │  Teléfono sin verif. │  ← red subtitle
├──────────────────────┼──────────────────────┤  ← 2 pt hairline-grey
│   🛡 Seguridad        │  🔔 Notificaciones    │
│   2FA desactivada    │  Push y email activos│  ← red subtitle (left)
├──────────────────────┼──────────────────────┤
│   💬 Comunicación     │  💳 Pagos             │
│   Español · sin mkt  │  Visa ···· 4412 · …  │
├═════════════════════════════════════════════┤  ← 2 pt rule, full bleed
│  MONEDERO                                   │  ← grey eyebrow
│  Saldo y cupones                   12,50 €  │
│  ─────────────────────────────────────────  │  ← 2 pt rule, INSET to margins
│  Cerrar sesión                              │  ← accent red, bold
│  PideYa 1.0 · Términos · Privacidad         │  ← grey footer
│                                             │
│              (empty background)             │
├─────────────────────────────────────────────┤
│  Inicio    Buscar    Pedidos    ●Cuenta     │  ← existing HomeTabBar
└─────────────────────────────────────────────┘
```

**The content does not fill the screen.** The footer's last ink is at y ≈ 717 pt and the tab
bar's top rule is at y ≈ 792 pt — about **75 pt of empty background** below the footer. This
screen is *shorter* than the viewport at the default content size, unlike Inicio and Pedidos.

**Scroll behaviour is therefore NOT observable from the mockup.** See §9 Q1.

---

## 2. Vertical map (measured ink positions, y in pt from the top of the screen)

| y (ink top → bottom) | Element |
|---|---|
| 66.3 – 74.0 | `CUENTA` eyebrow |
| 88.3 – 113.3 | `Víctor` (line 1 of the name) |
| 124.3 – 148.3 | `Arana` (line 2 of the name) |
| 166.0 – 192.7 | badge boxes (both) |
| 194 – 199.7 | `PENDIENTE` — the second badge's text **overflowing below its own border** (see §3.3) |
| **209.0 – 211.0** | **rule, 2 pt, full bleed, `#6C6A6A`** |
| 209 – 329 | grid row 1 (`Perfil` / `Identidad`) — tile height **120 pt** |
| **329.0 – 331.0** | **rule, 2 pt, full bleed, `#9F9D9D`** |
| 331 – 449 | grid row 2 (`Seguridad` / `Notificaciones`) |
| **449.0 – 451.0** | **rule, 2 pt, full bleed, `#9F9D9D`** |
| 451 – 569 | grid row 3 (`Comunicación` / `Pagos`) |
| **569.0 – 571.0** | **rule, 2 pt, full bleed, `#6C6A6A`** |
| 588.3 – 597.0 | `MONEDERO` eyebrow |
| 616.3 – 635.7 | `Saldo y cupones` + `12,50 €` row |
| **653.0 – 655.0** | **rule, 2 pt, INSET to x 20.0 – 381.7, `#9F9D9D`** |
| 675.7 – 686.0 | `Cerrar sesión` |
| 708.3 – 717.0 | `PideYa 1.0 · Términos · Privacidad` |
| 792.0 – 794.0 | tab bar top rule, 2 pt, `#201E1D` (ink) |

**Every structural rule in this screen is 2 pt** = `Theme.Stroke.rule`. There are no 1 pt
rules except the second badge's border (§3.3).

### 2.1 The two rule greys

| Where | Measured | Nearest token |
|---|---|---|
| Below the header; below the grid (the two **section boundaries**) | `#6C6A6A` | darker than `secondary` (`#8A8A8A`) — nothing matches exactly |
| Between grid rows; the column divider; the wallet rule; the badge border | `#9F9D9D` | `secondary` (`#8A8A8A`) is the closest |

The design distinguishes **boundary** rules (darker) from **internal** rules (lighter).
`HardRule()` currently defaults to `secondary` at 2 pt, which sits between the two. See §9 Q5.

---

## 3. Header block (y 0 – 209 pt)

Left margin: measured **20.0 pt**; **implement at `Theme.Spacing.lg` (16 pt)** per §0.1.

### 3.1 Eyebrow — `CUENTA`

- Ink box: y 66.3–74.0 (**cap height 8.0 pt**), x 20.3–74.3 (w 54.3 pt).
- Uppercase, bold, **letter-spaced**, colour `#7F7E7D` → **`Theme.Palette.secondary`**.
- Derived size ≈ **11 pt** bold. Nearest tokens: `tabLabel` (11, bold) matches the size but is
  semantically a tab label; `sectionTitle` (15, bold) is the right *role* but measurably too
  big. See §9 Q4.
- ⚠️ **This is grey.** `SectionHeaderView` hardcodes `Theme.Palette.ink`. It cannot be reused
  as-is for this label — see §9 Q4.
- The string is literally uppercase in the source. **Do not use `.textCase(.uppercase)`** —
  it is on the prohibited-pattern list (§8.5).

### 3.2 Name — `Víctor Arana`

- Line 1 `Víctor`: y 88.3–113.3, x 20.3–118.3 (w 98.3 pt).
- Line 2 `Arana`: y 124.3–148.3 (**cap height 24.3 pt**), x 20.0–117.7 (w 98.0 pt).
- Colour `#201E1D` → **`Theme.Palette.ink`**. Weight: heavy.
- Derived size ≈ **34 pt heavy** (cap 24.3 / 0.714). Cross-checked against the measured
  advance width: 98 pt / 5 glyphs = 0.576 em at 34 pt, which matches SF Pro Heavy lowercase.
  **`Theme.Typeface.brand` is 40 pt** — measurably too large. See §9 Q4.
- Baseline-to-baseline: **35 pt** (≈1.03 em — deliberately tight leading).

> ### ⚠️ The two-line break is DELIBERATE, not incidental wrapping.
> `Víctor` is 98 pt wide and `Arana` is 98 pt wide. On one line, with a space, the name would
> be ≈205 pt — it fits *easily* inside the 370 pt content width. The renderer had no reason to
> wrap it. **The design breaks between given name and surname on purpose.**
>
> Implement this by modelling the name as **two fields** (e.g. `givenName` / `familyName`)
> rendered on two lines, **not** by relying on `Text` wrapping and **not** by embedding a
> `\n` in a single display string. A single wrapped `Text` would put the break in a
> width-dependent place and would collapse to one line for a short name, which is not what
> the design shows.

### 3.3 Badge row (y 166.0 – 199.7 pt)

Two badges, left-aligned, with an **8.0 pt gap** between them (x 153.0 – 160.7).

**Badge 1 — `EMAIL VERIFICADO`**
- Solid fill `#FFE0D9` → **`Theme.Palette.promoFill`**; text `#AE1800` → **`accent`** (§0.1).
- Box: x 20.0 – 152.9 (**w 133 pt**), y 166.0 – 192.7 (**h 27 pt**). **No border.**
- This is exactly the existing **`ChipView(text:style: .promo)`**.

**Badge 2 — `TEL. PENDIENTE`**
- Transparent fill, **1 px border** `#9F9D9D`, text `#201E1D` → ink.
- Box: x 161.0 – 279.0 (**w 118 pt**), y 166.0 – 192.7 (**h 27 pt**, same as badge 1).
- Nearest existing component: **`ChipView(text:style: .outlined)`** — but that draws an **ink**
  border, and this measures grey (`#9F9D9D`). See §9 Q5.

> ### ⚠️ The overflow in the mockup is a RENDERING ARTIFACT. Do not reproduce it.
> The word `PENDIENTE` is drawn at y 194 – 199.7 pt, i.e. **below the badge's own bottom
> border** (which ends at 192.7). The mockup's renderer gave the box a fixed 27 pt height and
> the two-line label spilled out of it.
>
> The correct implementation is a chip that **sizes to its content**: one line if it fits, and
> a box that *grows* if it wraps. `ChipView` already behaves this way. Do not add a fixed
> height, and do not clip.

Both badges must sit in a **`FlowLayout`**, not an `HStack` — that component exists precisely
so chip rows wrap instead of overflowing at large Dynamic Type sizes.

---

## 4. The 2 × 3 grid (y 209 – 569 pt)

### 4.1 Structure

- **Three rows, each exactly 120 pt tall**, separated by 2 pt full-bleed rules.
- **Two equal columns.** The vertical divider is at x 200.0 – 201.7 (**2 pt**, `#9F9D9D`) and
  runs the **full height of the grid**, y 209.0 → 570.7 — it butts into both boundary rules
  and is not inset at the top or bottom.
- Column content boxes are therefore x 0–200 and x 202–402.
- Tile content inset from its own column's leading edge: **≈14 pt** (left column ink starts at
  x 14.3–15.0; right column at x 216.0–217.7, i.e. 14.0–15.7 from the 202 pt column origin).
  Nearest token: `Theme.Spacing.lg` (16) — note this is **less** than the header's margin.

### 4.2 Tile internals (offsets from the tile's own top edge)

| Element | Offset | Measured |
|---|---|---|
| Icon glyph top | ≈ **+18 pt** | row 1 +19.7, row 2 +16.7, row 3 +17.7 (varies by symbol) |
| Title ink | ≈ **+50 pt** → baseline **+63 pt** | row 1: 261.0–272.0 |
| Subtitle ink | ≈ **+72 pt** to **+83 pt** | row 1: 282.7–292.7 |
| Bottom padding | ≈ **36 pt** | content ends 84 pt into a 120 pt tile |

Content is **top-aligned**, not vertically centred (19.7 pt above, 36.3 pt below).

⚠️ **120 pt is the measured height at the default content size, not a hard constraint.** Use
it as a `minHeight`. A fixed `.frame(height: 120)` will clip at large Dynamic Type. The two
tiles in a row must render at **equal heights** regardless.

### 4.3 The six tiles

| # | Col | Icon (SF Symbol — best match, see §9 Q3) | Icon colour | Title | Subtitle | Subtitle colour |
|---|---|---|---|---|---|---|
| 1 | L | `person` | ink | `Perfil` | `Nombre, foto, direcciones` | secondary |
| 2 | R | `person.text.rectangle` | **accent** | `Identidad` | `Teléfono sin verificar` | **accent** |
| 3 | L | `checkmark.shield` | **accent** | `Seguridad` | `2FA desactivada` | **accent** |
| 4 | R | `bell` | ink | `Notificaciones` | `Push y email activos` | secondary |
| 5 | L | `bubble.left` | ink | `Comunicación` | `Español · sin marketing` | secondary |
| 6 | R | `creditcard` | ink | `Pagos` | `Visa ···· 4412 · 12,50 €` | secondary |

> **The red is a state, not a per-tile decoration.** Tiles 2 and 3 are the two that need the
> user's attention (`Teléfono sin verificar`, `2FA desactivada`), and in both the **icon and
> the subtitle turn accent red together**. Model this as a single `needsAttention: Bool` on
> the tile, driving both colours — not as two independent colour fields.

Measured colours: icons `#EC3013`/`#201E1D`; titles `#000000` (→ `ink`); normal subtitles
`#747372` (→ `secondary`); attention subtitles `#AE1800` (→ `accent`, §0.1).

### 4.4 Sizes

- **Icon glyph boxes**: 14.7 – 20.7 pt wide, 14.7 – 20.3 pt tall → symbol point size
  ≈ **22 – 24 pt**. `Theme.IconSize.tab` is 22. See §9 Q4.
- **Titles** ≈ **15 – 16 pt bold**. Cross-checked: `Perfil` ascender-to-baseline 11.3 pt;
  `Notificaciones` 14 glyphs in 106.7 pt. Nearest token: `subtitleBold` (15, bold).
  ⚠️ `rowTitle` (20, bold) — used for row titles in Inicio and Pedidos — is measurably **too
  large** here. The two-column layout halves the available width, so this screen legitimately
  runs a smaller type scale than the single-column screens.
- **Subtitles** ≈ **11 pt regular** (attention subtitles the same size, **bold**). Measured
  ink heights 8.7 – 10.3 pt. `subtitle` (15) is too large; `chip` (13) is closer.

### 4.5 `Visa ···· 4412 · 12,50 €`

- The masking glyphs read as **four middle dots**; transcribe as `····` (U+00B7 ×4).
- Separators are ` · ` (U+00B7 with a space either side), matching the rest of the app.
- ⚠️ `12,50 €` here is **the same number** as the `MONEDERO` balance in §5. See §9 Q2.

---

## 5. `MONEDERO` block (y 569 – 717 pt)

| Element | Spec |
|---|---|
| Eyebrow `MONEDERO` | Same treatment as `CUENTA` (§3.1): uppercase, bold, letter-spaced, `#747372` → `secondary`, cap height 9.0 pt. |
| `Saldo y cupones` | Ink `#201E1D`, bold. Ink box y 622.3–634.3, w 105.3 pt → ≈ **13–14 pt bold**. Left-aligned at the content margin. |
| `12,50 €` | Ink, bold, **noticeably larger than the label** — ink box y 616.3–635.7 (h 19.7 pt), x 304.0–381.0 (w 77.3 pt). Derived ≈ **22–26 pt bold**; nearest token **`cardTitle`** (22, bold). Right-aligned to the content margin (right edge 381.0 = 402 − 21). |
| Rule | 2 pt, `#9F9D9D`, y 653.0–655.0, **x 20.0 – 381.7 — inset to the content margins, NOT full bleed.** This is the only inset rule on the screen and the contrast with the full-bleed rules above is deliberate. |
| `Cerrar sesión` | `#AE1800` → **`accent`**, bold, ≈ **13–14 pt**. Ink box y 675.7–686.0, x 20.3–112.7. Left-aligned. Sentence case — **not** uppercase. |
| Footer | `PideYa 1.0 · Términos · Privacidad` — `#898887` → **`secondary`** (an exact match), regular, ≈ **12 pt**. Ink box y 708.3–717.0, x 20.7–205.3. |

`Cerrar sesión` is a destructive action. It is styled as **plain red text with no border and
no fill** — it is not a chip and not a button-looking control.

---

## 6. Tab bar

The existing `HomeTabBar` is reused **unchanged**. In this mockup **Cuenta** is selected: its
icon and label are accent red (`#EC3013`) and the other three are grey. That behaviour already
exists — no change required.

One **observation, not a requirement**: the mockup renders the *unselected* tab items in grey
(`#7F7E7D` ≈ `secondary`), while `HomeTabBar.swift:66` renders them in `Theme.Palette.ink`.
The same mismatch exists in the Pedidos mockup and shipped anyway. **Changing it would alter
two already-tested screens and is out of scope for this feature.**

---

## 7. What is genuinely new here

Everything else on this screen already exists. New surface area is limited to:

1. A **two-column grid with full-bleed inter-cell rules**. `LazyVGrid` cannot draw rules
   between cells; the row count is fixed at 3. Build it from `HStack`/`VStack` with explicit
   `HardRule`s and a divider `Rectangle`, so the rules are real, measurable views.
2. A **tile** component: icon + title + subtitle + `needsAttention` state (§4.3).
3. A **grey eyebrow label** (§3.1) — `SectionHeaderView` is ink-only.
4. Possibly one or two `Typeface` tokens (§9 Q4) and one `Palette` token (§9 Q5).

---

## 8. Carried-over constraints

These are hard-won lessons from the two previous features. Violating them reintroduces bugs
that were already found and fixed.

1. **`Font.system(size:weight:)` does not honour Dynamic Type.** All text must go through
   `View.themeFont(_:)`, which scales via `UIFontMetrics`. A raw `.font(.system(size:))`
   anywhere in this feature is a defect.
2. **`.safeAreaInset(edge: .bottom)` applied in `HomeTabView` does NOT cross a child's
   `NavigationStack` boundary.** If this screen wraps itself in a `NavigationStack` (as both
   `FeedView` and `OrdersView` do), it **must** take the measured `bottomInset` and apply its
   own bottom inset, or its footer will sit behind the tab bar. `HomeTabView` already measures
   the real bar height into `tabBarHeight` — pass it through.
3. **ViewModel ownership**: the owner holds `@State`, a borrowed ViewModel is a plain `let`.
   `HomeTabViewModel` should create and retain the account ViewModel (add it with a
   **defaulted** init parameter so `HomeTabViewModel()` still compiles and `PideYaApp.swift`
   needs no change), and `AccountView` holds it as a plain `let`.
4. **es-ES currency emits U+00A0 (NON-BREAKING SPACE) before `€`**, not a plain space. Any
   test asserting on a formatted price must use `\u{00A0}` or it will fail confusingly.
5. **Prohibited patterns** (a `rg` for these must return no matches):
   `.cornerRadius(`, `RoundedRectangle(`, `AnyView(`, `ObservableObject`, `@Published`,
   `try?`, `.textCase(`. Uppercase copy is written uppercase in the source string.
   Also: no `UserDefaults.standard`, view `body` under 40 lines.
6. New `.swift` files under the synced folders join the target automatically
   (`PBXFileSystemSynchronizedRootGroup`). **Do not edit `project.pbxproj`.**
7. `swift-format` **is** available via `xcrun --find swift-format` even though
   `which swift-format` fails, and the pre-commit hook runs it. Lint before declaring done.
8. **`nonisolated` on a type declaration does NOT propagate into separate `extension`
   blocks** under this project's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Extension
   members silently become `@MainActor`, and a closure literal inside one traps at runtime
   (`EXC_BREAKPOINT` in `swift_task_checkIsolatedSwift`) when called from a nonisolated
   context — this cost a full review cycle in `pedidos-tab`. Write `nonisolated extension X {}`
   explicitly, and `nonisolated let` on any file-scope constant such an extension references.

### 8.1 Dynamic Type is a real risk on this screen

The 2 × 3 grid is the tightest layout in the app: `Notificaciones` already occupies 106.7 pt
of a ~187 pt content column at the default size. At accessibility content sizes the two
columns **will** overflow. The plan must state how this is handled — the usual answer is to
collapse to a single column when
`dynamicTypeSize.isAccessibilitySize`, keeping the same rules between cells.

---

## 9. Open questions (do not silently invent an answer)

1. **Does this screen scroll, and does the header pin?** The mockup cannot show it: the
   content is ~75 pt *shorter* than the viewport. Pedidos pins its header because a long list
   scrolls under it; this screen has no list. **Recommendation:** one `ScrollView` with
   *everything* scrolling (no `.safeAreaInset(edge: .top)` pinned header), because at
   accessibility type sizes this content will exceed the viewport and the user must be able to
   reach `Cerrar sesión`. The bottom inset from §8.2 is still required either way.
2. **`12,50 €` appears twice** — as the `Pagos` tile subtitle and as the `MONEDERO` balance.
   Are they the same value? **Recommendation: yes — model one `walletBalance`, format it once,
   and have both call sites read it**, so the two can never drift. This mirrors how
   `OrdersViewModel.summaryText` is derived from the arrays rather than hardcoded. If the
   planner decides they are unrelated numbers, say so explicitly.
3. **Icon identities are my best match, not ground truth.** `person`, `person.text.rectangle`,
   `checkmark.shield`, `bell`, `bubble.left`, `creditcard` are chosen from the rendered glyph
   shapes (§4.3 lists the measured glyph boxes). Substituting a near neighbour is acceptable;
   inventing a different *concept* is not.
4. **Type scale.** Measured sizes are consistently smaller than the shipped tokens: name 34 pt
   (`brand` is 40), tile title ≈15–16 (`rowTitle` is 20), tile subtitle ≈11 (`subtitle` is 15),
   eyebrow ≈11–12 (`sectionTitle` is 15), icons ≈22–24 (`IconSize.tab` is 22). The planner must
   choose **one** policy and apply it consistently:
   (a) add the handful of tokens needed to match the mockup, or
   (b) round everything to the nearest existing token and accept a slightly larger screen.
   **Recommendation: (a) but minimally** — the name (34 heavy) and the tile subtitle (11) are
   the two that are visibly wrong if rounded; the rest map acceptably onto `subtitleBold`,
   `cardTitle` and `IconSize.tab`.
5. **Rule and border colours.** Three greys are in play: `#6C6A6A` (section boundaries),
   `#9F9D9D` (internal rules + the badge border), and the existing `secondary` `#8A8A8A`
   between them. And `ChipView(style: .outlined)` draws an **ink** border where this mockup
   measures `#9F9D9D`. **Recommendation:** use `HardRule()` (secondary, 2 pt) for every rule
   and accept the small delta, rather than introducing two near-identical grey tokens; but
   the badge border genuinely is not ink, so either add a `ChipView` border-colour option or
   reuse `Theme.Palette.outline` (`#C9C9C9`, already added for the Pedidos `REPETIR` button).
6. **Are the tiles, the badges and `Cerrar sesión` interactive?** No destination screens
   exist. **Recommendation:** the six tiles and `Cerrar sesión` are real `Button`s with
   **no-op actions** (matching `Ver todas`, `Filtrar` and `Ayuda` in the shipped tabs), so the
   layout and accessibility tree are correct and behaviour can be added later without
   restructuring. The badges are **not** interactive — they are status indicators. The footer
   `Términos` / `Privacidad` read as links; treat them as non-interactive text for now unless
   the planner argues otherwise.
7. **Where does the account data come from?** There is no auth, no networking and no
   persistence in this project. **Recommendation:** an `AccountContentProviding` protocol with
   a `MockAccountContentProvider`, mirroring `MockOrdersContentProvider` exactly, injected
   into the ViewModel via a defaulted init parameter.
8. **`Víctor Arana` is the repository owner's own name.** It is used here as mock display
   data. Flagging it only so nobody mistakes it for a hardcoded credential or real PII that
   needs redacting.
