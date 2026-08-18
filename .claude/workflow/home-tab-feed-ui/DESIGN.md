# Design Spec — Home Tab + Feed (transcribed from mockup)

Single iPhone screen. Overall aesthetic is **editorial / brutalist**: hard 1px black
borders, **sharp corners everywhere (no corner radius)**, off-white background, one
red accent, gray diagonal-hatch image placeholders. All copy is Spanish.

## Palette (approximate, from the mockup)
- Background: warm off-white `#F2F2F0`
- Ink / borders / primary text: near-black `#111111`
- Secondary text: mid gray `#8A8A8A`
- Accent red: `#E2372A` (band fill, selected tab, "Ver todas", price-less discount text)
- Discount chip fill: pale red/pink `#FBD9D5` with red text
- Image placeholder: light gray `#D9D9D9` with diagonal hatch stripes

## Layout, top to bottom

### 1. Header (fixed, does NOT scroll)
- `PIDEYA` — very large, heavy weight, **uppercase**, slight letter-spacing, black.
- Top-right: **square** outlined box (~52pt), 1px black border, no radius, containing
  initials `VA` in bold black. This is the account/avatar affordance.
- Under the title: red map-pin icon + `Calle Mayor 44` in **bold black** + a small
  chevron-down. This is the address selector (tappable).
- Search field: full-width rectangle, light gray fill, **1px black border, no radius**,
  ~56pt tall, magnifier icon on the left, gray placeholder
  `Buscar restaurantes o platos`. Non-functional in this feature (visual only, or a
  plain binding — no search results screen yet).
- A horizontal rule (~2pt, gray) separates the header block from the scrolling feed.

### 2. `OFERTAS DE HOY` section
- Section header row: `OFERTAS DE HOY` uppercase, bold, letter-spaced, black —
  and on the trailing edge `Ver todas` in **red**, regular/medium weight.
- Below it, a **horizontally scrolling** carousel of offer cards. Cards are peeked
  (second card is partly visible off the right edge). Card width ~ 62% of screen.
- Offer card anatomy (top → bottom), 1px black border around the whole card, no radius:
  1. Image placeholder — hatched gray square, roughly 1:1, fills card width.
  2. **Red band** spanning full card width, white **uppercase bold** text, e.g.
     `-40% · HASTA LAS 23:00`, `2X1 EN PIZZAS`. Text is left-aligned with padding.
  3. White/background area: restaurant name in **large bold black**
     (`Taquería Norte`, `Forno Bianco`), then a gray subtitle line
     `Mexicana · 25-35 min`.
- A horizontal rule separates this section from the next.

### 3. `RECOMENDADOS PARA TI` section
- `RECOMENDADOS PARA TI` uppercase bold letter-spaced black.
- Directly beneath, a gray subtitle: `Según tus últimos pedidos`.
- A **vertical list** of restaurant rows. Rows are separated by a thin gray divider
  (inset to the content, not full-bleed).
- Row anatomy, leading → trailing:
  - Hatched gray **square** thumbnail (~72pt), no radius.
  - Text stack:
    - Name — bold black, ~20pt (`Taquería Norte`, `Forno Bianco`, `Casa Lola`).
    - Subtitle — gray: cuisine `·` filled star glyph `·` rating with a **comma**
      decimal separator (`Mexicana · ★ 4,8`).
    - A chip row:
      - Delivery-time chip: black 1px border, no fill, no radius, bold black text
        (`25-35 min`, `30-40 min`).
      - Optional promo chip: pale red fill, no border, no radius, **red bold** text
        (`-40%`, `2X1`). Absent when the restaurant has no promo (`Casa Lola` has none).
  - Trailing: delivery fee, **bold black**, comma decimal + euro sign
    (`1,90 €`, `2,50 €`, `0,00 €`).
- The list continues under the tab bar (it is scrollable content).

### 4. Tab bar (bottom, fixed)
- A hard 1px black rule along its top edge; background matches the page.
- Four items, evenly distributed, each an icon above a **bold, small** label:
  1. `Inicio` — house icon — **selected**, rendered in accent red (icon + label).
  2. `Buscar` — magnifying glass — unselected, dark gray/black.
  3. `Pedidos` — receipt / document icon — unselected.
  4. `Cuenta` — person icon — unselected.
- Only `Inicio` has a real screen (FeedView). `Buscar`, `Pedidos`, `Cuenta` must exist
  as selectable tabs but their screens are explicitly out of scope for this feature —
  use a simple placeholder for each.

## Sample data visible in the mockup (use as seed/mock data)
Offers carousel:
| Restaurant | Banner | Cuisine | ETA |
|---|---|---|---|
| Taquería Norte | `-40% · HASTA LAS 23:00` | Mexicana | 25-35 min |
| Forno Bianco | `2X1 EN PIZZAS` | Italiana | 30-40 min |

Recommended list:
| Restaurant | Cuisine | Rating | ETA | Promo | Fee |
|---|---|---|---|---|---|
| Taquería Norte | Mexicana | 4,8 | 25-35 min | `-40%` | 1,90 € |
| Forno Bianco | Italiana | 4,7 | 30-40 min | `2X1` | 2,50 € |
| Casa Lola | Casera | 4,9 | (not visible, choose) | none | 0,00 € |

## Notes / constraints
- Numbers use **comma** decimal separators (es-ES). Prefer formatting from a numeric
  model value with an es_ES locale rather than hardcoding strings, so the model stays
  typed.
- Image placeholders: there are no assets. Render the hatched gray placeholder as a
  reusable SwiftUI view (e.g. diagonal stripes via `Canvas` or a repeating overlay) so
  real images can drop in later.
- No networking. Data is static/mock, served from the ViewModel.
