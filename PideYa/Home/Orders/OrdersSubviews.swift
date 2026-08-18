//
//  OrdersSubviews.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// The fixed header block: brand title, summary line and the "Ayuda" trailing action.
struct OrdersHeaderView: View {
    let title: String
    let summaryText: String
    let onHelp: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            titleRow
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
        .background(Theme.Palette.background)
        .overlay(alignment: .bottom) {
            HardRule()
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        // `.accessibilityElement(children: .contain)` is required here, not just cosmetic: an
        // `.accessibilityIdentifier` applied to a container that is *not* itself an
        // accessibility element cascades down and overwrites every descendant's own identifier
        // (e.g. it would silently replace `helpButton`'s "orders.helpButton" with
        // "orders.header"). `.contain` makes this VStack a real container element so its
        // identifier applies to it alone.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("orders.header")
    }

    private var titleRow: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .themeFont(Theme.Typeface.brand)
                    .kerning(Theme.Kerning.brand)
                    .foregroundStyle(Theme.Palette.ink)
                Text(summaryText)
                    .themeFont(Theme.Typeface.subtitle)
                    .foregroundStyle(Theme.Palette.secondary)
            }
            Spacer()
            helpButton
        }
    }

    private var helpButton: some View {
        Button(action: onHelp) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "questionmark.circle")
                        .themeFont(Theme.Typeface.subtitleBold)
                    Text("Ayuda")
                        .themeFont(Theme.Typeface.subtitleBold)
                }
                HardRule(color: Theme.Palette.ink, thickness: Theme.Stroke.rule)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.Palette.ink)
        .accessibilityIdentifier("orders.helpButton")
    }
}

/// The `EN CURSO` card: accent status band, thumbnail/name/total summary, progress tracker and
/// a two-control action row.
struct ActiveOrderCardView: View {
    let order: ActiveOrder
    let onTrack: () -> Void
    let onQuickAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            statusBand
            cardBody
        }
        .background(Theme.Palette.searchFill)
        .overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.rule))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("orders.activeCard")
    }

    private var statusBand: some View {
        HStack {
            Text(order.statusText)
                .themeFont(Theme.Typeface.band)
                .kerning(Theme.Kerning.sectionTitle)
            Spacer()
            Text(order.arrivalText)
                .themeFont(Theme.Typeface.band)
                .kerning(Theme.Kerning.sectionTitle)
        }
        .foregroundStyle(Theme.Palette.onAccent)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.accent)
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            summaryRow
            OrderProgressView(stage: order.stage)
            actionRow
        }
        .padding(Theme.Spacing.md)
    }

    private var summaryRow: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            HatchedPlaceholder()
                .frame(width: Theme.Size.orderThumbnail, height: Theme.Size.orderThumbnail)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(order.restaurantName)
                        .themeFont(Theme.Typeface.cardTitle)
                        .lineLimit(1)
                    Spacer()
                    Text(order.totalText)
                        .themeFont(Theme.Typeface.cardTitle)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                .foregroundStyle(Theme.Palette.ink)
                Text(order.subtitleText)
                    .themeFont(Theme.Typeface.subtitle)
                    .foregroundStyle(Theme.Palette.secondary)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            trackButton
            quickActionButton
        }
    }

    private var trackButton: some View {
        Button(action: onTrack) {
            Text("Ver seguimiento")
                .themeFont(Theme.Typeface.subtitleBold)
                .foregroundStyle(Theme.Palette.onAccent)
                .padding(.horizontal, Theme.Spacing.md)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.actionButton, alignment: .leading)
                .background(Theme.Palette.accent)
                .overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.rule))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("orders.trackButton")
    }

    private var quickActionButton: some View {
        Button(action: onQuickAction) {
            Image(systemName: "bolt.fill")
                .themeFont(Theme.Typeface.rowTitle)
                .foregroundStyle(Theme.Palette.ink)
                .frame(width: Theme.Size.actionButton, height: Theme.Size.actionButton)
                .background(Theme.Palette.surface)
                .overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.rule))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Acciones rápidas")
        .accessibilityIdentifier("orders.quickActionButton")
    }
}

/// The four-stage progress tracker: equal-width segments plus a row of stage labels, where only
/// the current stage's label is accent-coloured (completed stages read secondary grey).
struct OrderProgressView: View {
    let stage: OrderStage

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            segments
            labels
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("orders.progress")
    }

    private var segments: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(OrderStage.allCases) { orderStage in
                Rectangle()
                    .fill(orderStage.stepIndex <= stage.stepIndex ? Theme.Palette.accent : Theme.Palette.outline)
                    .frame(height: Theme.Size.progressSegment)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var labels: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            ForEach(OrderStage.allCases) { orderStage in
                Text(orderStage.label)
                    .themeFont(Theme.Typeface.chip)
                    .foregroundStyle(orderStage == stage ? Theme.Palette.accent : Theme.Palette.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: alignment(for: orderStage))
            }
        }
    }

    private func alignment(for orderStage: OrderStage) -> Alignment {
        if orderStage.stepIndex == 0 {
            return .leading
        }
        if orderStage.stepIndex == OrderStage.allCases.count - 1 {
            return .trailing
        }
        return .center
    }
}

/// A single row in the `ANTERIORES` list: thumbnail, name/total, date/items and a rating-or-chip
/// line paired with the `REPETIR` button.
struct PastOrderRowView: View {
    let order: PastOrder
    /// The row's position in `ANTERIORES`, used only for `.accessibilityIdentifier`.
    /// Content-independent (unlike a name- or id-keyed identifier) so UI-test selectors survive
    /// a data-source swap; `order.id` remains the `ForEach` identity.
    let index: Int
    let onRepeat: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            HatchedPlaceholder()
                .frame(width: Theme.Size.orderThumbnail, height: Theme.Size.orderThumbnail)
            details
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("orders.past.row.\(index)")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            titleLine
            Text(order.subtitleText)
                .themeFont(Theme.Typeface.subtitle)
                .foregroundStyle(Theme.Palette.secondary)
            statusLine
        }
    }

    private var titleLine: some View {
        HStack {
            Text(order.restaurantName)
                .themeFont(Theme.Typeface.rowTitle)
                .lineLimit(1)
            Spacer()
            Text(order.totalText)
                .themeFont(Theme.Typeface.rowTitle)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .foregroundStyle(Theme.Palette.ink)
    }

    private var statusLine: some View {
        HStack {
            ratingOrChip
            Spacer()
            OutlinedActionButton(title: "REPETIR", action: onRepeat)
        }
    }

    @ViewBuilder
    private var ratingOrChip: some View {
        if let rating = order.rating, let ratingText = order.ratingText {
            HStack(spacing: Theme.Spacing.xs) {
                // The identifier goes on `StarRatingView`, not the enclosing `HStack`: the
                // `HStack` is not itself an accessibility element, so an identifier on it would
                // cascade down and land on both descendants (`StarRatingView` *and* the `Text`)
                // instead of naming a single container. `StarRatingView` already collapses to
                // exactly one element via `.accessibilityElement(children: .ignore)`.
                StarRatingView(score: rating) { filled, outOf in "\(filled) de \(outOf) estrellas" }
                    .accessibilityIdentifier("orders.rating")
                Text(ratingText)
                    .themeFont(Theme.Typeface.subtitle)
                    .foregroundStyle(Theme.Palette.secondary)
            }
        } else {
            ChipView(text: "VALORAR PEDIDO", style: .promo)
        }
    }
}

#Preview("OrdersHeaderView") {
    OrdersHeaderView(title: "Pedidos", summaryText: "1 en curso · 12 anteriores", onHelp: {})
}

#Preview("ActiveOrderCardView") {
    ActiveOrderCardView(
        order: ActiveOrder(
            id: UUID(),
            restaurantName: "Taquería Norte",
            total: 24.60,
            itemCount: 3,
            orderNumber: "4821",
            stage: .enCamino,
            etaText: "20:45"
        ),
        onTrack: {},
        onQuickAction: {}
    )
    .padding()
}

#Preview("OrderProgressView") {
    OrderProgressView(stage: .enCamino)
        .padding()
}

#Preview("PastOrderRowView") {
    VStack {
        PastOrderRowView(
            order: PastOrder(
                id: UUID(), restaurantName: "Forno Bianco", total: 18.90, dateText: "12 ago", itemCount: 2,
                rating: 5.0
            ),
            index: 0,
            onRepeat: {}
        )
        PastOrderRowView(
            order: PastOrder(
                id: UUID(), restaurantName: "Casa Lola", total: 31.20, dateText: "9 ago", itemCount: 4,
                rating: nil
            ),
            index: 1,
            onRepeat: {}
        )
    }
    .padding()
}
