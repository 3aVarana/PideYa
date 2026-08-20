//
//  AccountSubviews.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// The header block: grey eyebrow, two-line name and the badge row (DESIGN.md §3, y 0–209).
struct AccountHeaderView: View {
    let profile: AccountProfile

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            EyebrowLabel(text: "CUENTA")
            nameBlock
            badgeRow
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("account.header")
    }

    /// Two separate `Text`s, not one `Text` relying on wrapping and not a `\n` in one string:
    /// DESIGN.md §3.2 is emphatic that the given-name/family-name break is deliberate. Deliberately
    /// not `.accessibilityElement(children: .combine)` — combining would erase the two-field model
    /// that acceptance criterion 3 asserts on.
    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(profile.givenName)
                .themeFont(Theme.Typeface.displayName)
                .foregroundStyle(Theme.Palette.ink)
            Text(profile.familyName)
                .themeFont(Theme.Typeface.displayName)
                .foregroundStyle(Theme.Palette.ink)
        }
    }

    private var badgeRow: some View {
        FlowLayout(spacing: Theme.Spacing.sm) {
            ForEach(profile.badges) { badge in
                ChipView(text: badge.text, style: badge.isVerified ? .promo : .outlinedSubtle)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("account.badges")
    }
}

/// A single tile in the 2 × 3 grid: icon, title and a `needsAttention`-coloured subtitle
/// (DESIGN.md §4.2–§4.4). A real `Button` with a no-op action (DESIGN.md §9 Q6).
struct AccountTileView: View {
    let tile: AccountTile
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Image(systemName: tile.kind.systemImage)
                    .themeFont(Theme.Typeface.cardTitle)
                    .foregroundStyle(tile.needsAttention ? Theme.Palette.accent : Theme.Palette.ink)
                textBlock
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            // `minHeight` is the design's 120 pt floor (DESIGN.md §4.1), applied at the tile
            // layer so a single tile honours it even outside a row; `maxHeight: .infinity` lets
            // the row `HStack`'s own cross-axis equalization still grow both siblings past 120
            // at large Dynamic Type. This is the tile's only floor — deliberately not duplicated
            // on the row's `HStack` in `AccountTileGridView.rowView`.
            .frame(maxWidth: .infinity, minHeight: Theme.Size.accountTile, maxHeight: .infinity, alignment: .topLeading)
            // `.contentShape(Rectangle())` below is what makes the measured/hit-test frame match
            // the box above: without it, the accessibility/hit-test frame SwiftUI reports for
            // this element reflects the drawn content's own bounds, not the enclosing `.frame`,
            // so the measured height (and the tappable region) stay at the label's natural size
            // even though the frame is taller.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tile.kind.title). \(tile.subtitle)")
        .accessibilityIdentifier("account.tile.\(tile.kind.rawValue)")
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(tile.kind.title)
                .themeFont(Theme.Typeface.subtitleBold)
                .foregroundStyle(Theme.Palette.ink)
            Text(tile.subtitle)
                .themeFont(subtitleFont)
                .foregroundStyle(subtitleColor)
        }
    }

    private var subtitleColor: Color {
        tile.needsAttention ? Theme.Palette.accent : Theme.Palette.secondary
    }

    private var subtitleFont: Theme.Typeface.Style {
        tile.needsAttention ? Theme.Typeface.captionBold : Theme.Typeface.caption
    }
}

/// The 2 × 3 grid of `AccountTile`s, full-bleed with internal rules between rows and a column
/// divider (DESIGN.md §4.1). Collapses to a single column at accessibility content sizes
/// (DESIGN.md §8.1).
struct AccountTileGridView: View {
    let tiles: [AccountTile]
    let onSelect: (AccountTileKind) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let rows = rows
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                rowView(row)
                if index < rows.count - 1 {
                    HardRule()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("account.grid")
    }

    private var columns: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : 2
    }

    private var rows: [AccountTileRow] {
        AccountTileRow.rows(from: tiles, columns: columns)
    }

    private func rowView(_ row: AccountTileRow) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(row.tiles.enumerated()), id: \.element.id) { index, tile in
                if index > 0 {
                    columnDivider
                }
                AccountTileView(tile: tile, action: { onSelect(tile.kind) })
            }
            if row.tiles.count < columns {
                Theme.Palette.transparent.frame(maxWidth: .infinity)
            }
        }
    }

    private var columnDivider: some View {
        Rectangle()
            .fill(Theme.Palette.secondary)
            .frame(width: Theme.Stroke.rule)
            .frame(maxHeight: .infinity)
            .accessibilityHidden(true)
    }
}

/// The `MONEDERO` block: balance row, an inset rule, `Cerrar sesión` and the footer
/// (DESIGN.md §5).
struct AccountWalletView: View {
    let wallet: AccountWallet
    let onSignOut: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            EyebrowLabel(text: "MONEDERO")
            balanceRow
            HardRule()
            signOutButton
            footer
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("account.wallet")
    }

    @ViewBuilder
    private var balanceRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                balanceLabel
                balanceValue
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                balanceLabel
                Spacer()
                // `.lineLimit`/`.layoutPriority` only apply here, where the `Spacer` would
                // otherwise squeeze the value; the accessibility-size `VStack` above has its own
                // full-width row and should wrap a large balance rather than truncate it.
                balanceValue
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
    }

    private var balanceLabel: some View {
        Text("Saldo y cupones")
            .themeFont(Theme.Typeface.subtitleBold)
            .foregroundStyle(Theme.Palette.ink)
    }

    private var balanceValue: some View {
        Text(wallet.balanceText)
            .themeFont(Theme.Typeface.cardTitle)
            .foregroundStyle(Theme.Palette.ink)
    }

    private var signOutButton: some View {
        Button(action: onSignOut) {
            Text("Cerrar sesión")
                .themeFont(Theme.Typeface.subtitleBold)
                .foregroundStyle(Theme.Palette.accent)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("account.signOutButton")
    }

    private var footer: some View {
        Text("PideYa 1.0 · Términos · Privacidad")
            .themeFont(Theme.Typeface.caption)
            .foregroundStyle(Theme.Palette.secondary)
            .accessibilityIdentifier("account.footer")
    }
}

#Preview("AccountHeaderView") {
    AccountHeaderView(
        profile: AccountProfile(
            givenName: "Víctor", familyName: "Arana", emailState: .verified, phoneState: .pending
        )
    )
}

#Preview("AccountTileView") {
    HStack(spacing: 0) {
        AccountTileView(
            tile: AccountTile(kind: .perfil, subtitle: "Nombre, foto, direcciones", needsAttention: false),
            action: {}
        )
        AccountTileView(
            tile: AccountTile(kind: .identidad, subtitle: "Teléfono sin verificar", needsAttention: true),
            action: {}
        )
    }
}

#Preview("AccountTileGridView") {
    AccountTileGridView(tiles: MockAccountContentProvider().tiles(), onSelect: { _ in })
}

#Preview("AccountWalletView") {
    AccountWalletView(wallet: AccountWallet(balance: 12.50), onSignOut: {})
}
