# DESIGN.md — Pedidos tab

> **Why this file exists.** The design was supplied as an image. Subagents in this pipeline
> cannot see images, so this is a faithful text transcription of the mockup and is the
> single source of truth for visual intent. Where the mockup is ambiguous it says so
> explicitly rather than inventing a resolution — see **Open questions** at the end.
>
> Source image: `~/Downloads/pideya-pedidos-2a.png` (919 px wide render of a ~402 pt-wide
> phone, so **≈2.29 image px per point**). All point sizes below are derived by dividing
> measured pixel values by 2.29 and are therefore **approximate**: treat them as "which
> existing `Theme` token is nearest", not as exact values to hardcode.

---

## 0. Relationship to the existing design system

This screen is the **second** tab built on the design system established by
`home-tab-feed-ui` (see `../home-tab-feed-ui/DESIGN.md`). It reuses that language wholesale:

- Same page background, ink, secondary, accent, promo-fill and placeholder colours.
- **Zero corner radius everywhere.** No `.cornerRadius`, no `RoundedRectangle`. Every box,
  button, chip and badge in this mockup is a hard-edged rectangle.
- Same hatched diagonal-stripe stand-in for missing imagery (`HatchedPlaceholder`).
- Same uppercase, letter-spaced section headers (`SectionHeaderView`).
- Same es-ES number formatting: **comma decimal separator**, space before `€`.

Prefer reusing `Theme` tokens and `DesignSystemViews` components over introducing new ones.
Add new tokens only where the mockup genuinely shows something the feed did not.

---

## 1. Screen skeleton, top to bottom

```
┌─────────────────────────────────────────────┐
│  Pedidos                          (?) Ayuda │  ← fixed header (does NOT scroll)
│  1 en curso · 12 anteriores       ────────  │
├═════════════════════════════════════════════┤  ← hard rule
│  EN CURSO                                   │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  │
│  ┃ EN CAMINO             LLEGA 20:45     ┃  │  ← accent band
│  ┃ ▨▨  Taquería Norte           24,60 €  ┃  │
│  ┃ ▨▨  3 artículos · Pedido #4821        ┃  │
│  ┃ ▬▬▬ ▬▬▬ ▬▬▬ ░░░                       ┃  │  ← 4-segment progress
│  ┃ CONFIRMADO EN COCINA EN CAMINO ENTREG.┃  │
│  ┃ ┌───────────────────────────┐ ┌─────┐ ┃  │
│  ┃ │ Ver seguimiento           │ │  ⚡  │ ┃  │
│  ┃ └───────────────────────────┘ └─────┘ ┃  │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  │
├═════════════════════════════════════════════┤  ← hard rule
│  ANTERIORES                         Filtrar │
│  ▨▨  Forno Bianco             18,90 €       │
│  ▨▨  12 ago · 2 artículos                   │
│  ▨▨  ★★★★★ 5,0            [ REPETIR ]       │
│  ─────────────────────────────────────────  │  ← hairline, FULL width
│  ▨▨  Casa Lola                31,20 €       │
│  ...                                        │
├─────────────────────────────────────────────┤
│  Inicio    Buscar    Pedidos     Cuenta     │  ← existing HomeTabBar
└─────────────────────────────────────────────┘
```

**Scroll behaviour.** The header (title + subtitle + Ayuda) is **pinned** and does not
scroll — same treatment as `FeedView`'s header, i.e. a `.safeAreaInset(edge: .top)` on the
scroll view rather than a member of the scrolled content. Everything from `EN CURSO`
downward scrolls. The mockup shows a separator *below* the last visible row (Sakura Ramen),
which indicates the ANTERIORES list continues past the fold.

---

## 2. Header

| Element | Spec |
|---|---|
| Title | `Pedidos` — very large, heavy weight, ink. Sentence case, **not** uppercase. Nearest token: `Theme.Typeface.brand` (40 pt heavy), possibly one step smaller (~34 pt). |
| Subtitle | `1 en curso · 12 anteriores` — secondary grey, regular. Nearest token: `Theme.Typeface.subtitle`. Middle-dot separator is `·` (U+00B7) with a space either side. |
| Trailing action | A question-mark-in-circle icon (SF Symbol `questionmark.circle`) followed by the bold ink word `Ayuda`. |
| Ayuda underline | A **thick ink rule (~3 px ≈ 1.5 pt, i.e. `Theme.Stroke.rule`) directly beneath the icon+label group**, spanning the group's full width and nothing more. This is a deliberate "hard-underlined link" treatment, not a button border. |

Vertical alignment: the Ayuda group sits on the **subtitle's** baseline row, not the title's —
it is noticeably lower than the `Pedidos` title.

A full-width hard rule closes the header (same weight as the feed's section rules).

---

## 3. `EN CURSO` section

Section header `EN CURSO` — uppercase, bold, letter-spaced, **no trailing action**
(unlike `OFERTAS DE HOY`, which had "Ver todas"). Use `SectionHeaderView(title:)`.

### 3.1 Active order card — outer frame

- A **thick ink border on all four sides**, visibly heavier than the hairline separators
  used elsewhere: ~4 px ≈ **2 pt**, i.e. `Theme.Stroke.rule`.
- **Zero corner radius.**
- Card body fill is **slightly darker than the page background** — measured ≈ `#EAEAE8`
  against the page's `#F2F2F0`. The existing `Theme.Palette.searchFill` (`#E8E8E6`) is the
  nearest token and should be reused rather than adding a near-duplicate colour.

### 3.2 Status band (top strip of the card)

- Full card width, flush to the border, **accent red fill** (`Theme.Palette.accent`).
- Height ≈ 72 px ≈ **31 pt**.
- Left: `EN CAMINO` — white, heavy, uppercase, letter-spaced. Nearest token:
  `Theme.Typeface.band` + `Theme.Kerning.sectionTitle`.
- Right: `LLEGA 20:45` — same treatment, right-aligned.
- Both use `Theme.Palette.onAccent` for the foreground.

### 3.3 Order summary row

- **Thumbnail**: hatched placeholder, ≈ 139 × 148 px ≈ **61 × 65 pt** — read as a square,
  roughly `Theme.Size.rowThumbnail` (72) or slightly smaller (~64).
- **Title** `Taquería Norte` — bold ink, ≈ `Theme.Typeface.cardTitle` (22 pt bold).
- **Price** `24,60 €` — same size and weight as the title, right-aligned on the same line.
  Note the **comma decimal separator** and the space before `€` (see §7 on the exact space
  character — this bit us in the previous feature).
- **Subtitle** `3 artículos · Pedido #4821` — secondary grey, `Theme.Typeface.subtitle`.
  The order number is rendered with a literal `#` prefix.

### 3.4 Progress tracker

- **Four equal-width segments** laid out edge to edge across the card's content width,
  separated by a small gap (≈ 6 px ≈ 3 pt).
- Segment thickness ≈ 10 px ≈ **4–5 pt**.
- Segments **1, 2 and 3 are accent red** (completed + current); segment **4 is light grey**
  (≈ `#C9C9C9`; nearest token `Theme.Palette.placeholder` at `#D9D9D9`).
- Beneath the segments, a row of **four uppercase labels**, one per segment, small and bold
  (≈ `Theme.Typeface.chip` / `band`): `CONFIRMADO`, `EN COCINA`, `EN CAMINO`, `ENTREGADO`.
- Label colours: **`EN CAMINO` (the current stage) is accent red**; the other three,
  *including the two already-completed stages*, are **secondary grey**. Only the current
  stage is highlighted — completed stages are not.
- The first label is left-aligned to the card content edge and the last is right-aligned to
  it; the labels distribute across the four segment columns.

### 3.5 Action row

Two side-by-side controls, equal height (≈ 94 px ≈ **41 pt**, though the visual box with its
border reads closer to 48–52 pt; treat ~48 pt as a sensible minimum tap target):

1. **Primary button** — takes all remaining width.
   - Accent red fill, **ink border** (~4 px ≈ 2 pt), white heavy text `Ver seguimiento`.
   - **The label is LEFT-aligned with inset padding, not centred.** This is unusual and
     deliberate — do not centre it.
2. **Trailing square button** — a square roughly matching the row height.
   - **White fill** (lighter than the card body — this reads as pure `#FFFFFF`), ink border
     of the same weight, and a **lightning-bolt glyph** in ink (SF Symbol `bolt.fill`).
   - No label. It needs an `accessibilityLabel` since it is icon-only; the mockup gives no
     text for it, so a reasonable Spanish label such as "Pedir de nuevo" / "Acción rápida"
     must be chosen and documented.

---

## 4. `ANTERIORES` section

Section header `ANTERIORES` with a **trailing `Filtrar` action in accent red**
(`SectionHeaderView(title:action:)`, exactly like "Ver todas" in the feed).

### 4.1 Past-order row anatomy

Each row is a thumbnail on the left and a three-line stack on the right:

- **Thumbnail**: hatched placeholder square, ≈ 148 px ≈ **65 pt** (same as §3.3).
- **Line 1**: bold ink restaurant name (`Theme.Typeface.rowTitle`, 20 pt bold) on the left,
  bold price on the right, same size/weight as the name.
- **Line 2**: secondary grey `12 ago · 2 artículos` — a short date (day + abbreviated
  Spanish month, **lowercase**, no year) then the item count.
- **Line 3**: a status element on the left and the `REPETIR` button on the right.

### 4.2 Line 3 — two mutually exclusive left-hand states

The mockup shows both, one per row, and they are alternatives for the same slot:

**(a) Rated** — a five-star row plus the numeric score:
   - Stars are **accent red**. Filled stars for the score, **outlined (hollow) stars** for the
     remainder. `5,0` → five filled. `4,0` → four filled + one outlined.
   - The numeric value follows the stars, in secondary grey, formatted es-ES with a **comma**
     decimal separator and one decimal place: `5,0`, `4,0`.

**(b) Unrated** — a promo-fill chip reading `VALORAR PEDIDO`:
   - Pale pink fill (`Theme.Palette.promoFill`), **accent red bold uppercase text**, no
     border. This is exactly the existing `ChipView(style: .promo)`.

### 4.3 `REPETIR` button

- Uppercase, small, bold, **ink** text.
- **Hairline border in a light grey — NOT ink.** Measured ≈ `#C9C9C9`. This is the one place
  in the design system where an outlined control does not use an ink border, and it must not
  be collapsed into `ChipView(style: .outlined)` (which is ink-bordered) without adding a
  variant. Nearest existing token: `Theme.Palette.placeholder`.
- Transparent / page-coloured fill.
- It is a real, tappable `Button`.

### 4.4 Separators

A **hairline rule between consecutive rows, spanning the full content width** — it runs
underneath the thumbnail column as well.

> ⚠️ **This differs from `FeedView`**, where the recommendation separators are *indented*
> past the thumbnail (`.padding(.leading, rowThumbnail + md)`). Do not copy the feed's
> indent here; the mockup clearly shows a full-bleed rule.

A separator is also visible *below* the final row, consistent with more content below the fold.

---

## 5. Tab bar

The existing `HomeTabBar` is reused unchanged in structure. In this mockup the **Pedidos**
tab is the selected one: its icon and label are accent red while the other three are ink.
That behaviour already exists — no change required.

Two cosmetic mismatches, both **observations, not requirements**:

- The mockup's Pedidos glyph is a receipt/document with a bookmark ribbon; the code currently
  uses `doc.text`. Close enough to leave alone.
- The mockup's Inicio glyph is an **outlined** house; the code uses `house.fill`. Changing it
  is out of scope for this feature and would touch a shipped, tested screen.

---

## 6. Seed data (mock content)

The screen must render from a mock provider, mirroring `MockFeedContentProvider`.

**Active order** (one):

| Field | Value |
|---|---|
| Restaurant | `Taquería Norte` |
| Total | `24,60 €` |
| Item count | `3` |
| Order number | `4821` |
| Stage | `EN CAMINO` (3rd of 4) |
| ETA | `20:45` |

**Past orders** (three, in this order):

| Restaurant | Total | Date | Items | Line-3 state |
|---|---|---|---|---|
| `Forno Bianco` | `18,90 €` | `12 ago` | `2` | rated `5,0` |
| `Casa Lola` | `31,20 €` | `9 ago` | `4` | **unrated** → `VALORAR PEDIDO` |
| `Sakura Ramen` | `26,50 €` | `4 ago` | `2` | rated `4,0` |

**Header counts**: `1 en curso · 12 anteriores`.

---

## 7. Carried-over constraints from the previous feature

These are hard-won lessons from `home-tab-feed-ui`. Violating them reintroduces bugs that
were already found and fixed once.

1. **`Font.system(size:weight:)` does not honour Dynamic Type.** All text must go through
   `View.themeFont(_:)`, which scales via `UIFontMetrics`. A `.font(.system(size:))` call
   anywhere in this feature is a defect.
2. **`.safeAreaInset(edge: .bottom)` applied in `HomeTabView` does NOT cross a child's
   `NavigationStack` boundary.** `FeedView` therefore takes a measured `bottomInset` and
   applies its own bottom inset. If this screen also wraps itself in a `NavigationStack`, it
   **must** do the same or its last row will sit behind the tab bar. `HomeTabView` already
   measures the real bar height into `tabBarHeight` — pass it through.
3. **ViewModel ownership**: the owner holds `@State`, a borrowed ViewModel is a plain `let`.
   `HomeTabViewModel` should create and retain the orders ViewModel so state survives tab
   switches, and the Pedidos view holds it as a plain `let`, using
   `Bindable(viewModel).property` for any two-way binding. See `CLAUDE.md`.
4. **es-ES currency emits U+00A0 (NON-BREAKING SPACE) before `€`**, not a plain space. Any
   test asserting on a formatted price must use `\u{00A0}` or it will fail confusingly.
5. **Zero corner radius**, no `AnyView`, no unhandled `try?`, no `UserDefaults.standard`,
   view `body` under 40 lines — per `CLAUDE.md`.
6. New `.swift` files under the synced folders join the target automatically
   (`PBXFileSystemSynchronizedRootGroup`). **Do not edit `project.pbxproj`.**
7. `swift-format` **is** available via `xcrun --find swift-format` even though
   `which swift-format` fails, and the pre-commit hook runs it. Lint before declaring done.

---

## 8. Open questions (do not silently invent an answer)

1. **`12 anteriores` vs 3 rendered rows.** The header claims twelve past orders but the list
   shows three. Either the count is a separate total (with the list paginated/truncated) or
   the mock data should contain twelve. Recommendation: model the count as derived from the
   provider's data and seed enough orders that the header reads honestly, **or** keep three
   rows and derive the string from the actual array count (`1 en curso · 3 anteriores`).
   Deriving is preferable to hardcoding a number the UI contradicts. The planner must pick
   one and state it in the plan.
2. **Bolt button meaning.** No label or tooltip is given. Its accessibility label is a
   judgement call that must be documented.
3. **Are `Filtrar`, `Ayuda`, `Ver seguimiento`, the bolt and `REPETIR` functional?** No
   destination screens exist. Assume they are wired as real `Button`s with **no-op actions**
   (matching how "Ver todas" was handled in the feed), so the layout and accessibility tree
   are correct and behaviour can be added later without restructuring.
