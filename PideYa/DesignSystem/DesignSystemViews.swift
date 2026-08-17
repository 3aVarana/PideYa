//
//  DesignSystemViews.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// Diagonal-hatch stand-in for a missing image asset. Sized entirely by the caller.
struct HatchedPlaceholder: View {
    var body: some View {
        Canvas { context, size in
            var stripes = Path()
            var x = -size.height
            while x < size.width {
                stripes.move(to: CGPoint(x: x, y: size.height))
                stripes.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += Theme.Spacing.sm
            }
            context.stroke(stripes, with: .color(Theme.Palette.secondary), lineWidth: Theme.Stroke.hairline)
        }
        .background(Theme.Palette.placeholder)
        .clipped()
        .accessibilityHidden(true)
    }
}

/// A small pill of text used for delivery-time and promotion badges.
struct ChipView: View {
    enum Style {
        case outlined
        case promo
    }

    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(Theme.Typeface.chip)
            .foregroundStyle(textColor)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(backgroundColor)
            .overlay(border)
    }

    private var textColor: Color {
        switch style {
        case .outlined: Theme.Palette.ink
        case .promo: Theme.Palette.accent
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .outlined: .clear
        case .promo: Theme.Palette.promoFill
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .outlined: Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.hairline)
        case .promo: EmptyView()
        }
    }
}

/// An uppercase section title with an optional trailing action.
struct SectionHeaderView: View {
    /// A trailing button's title and handler, bundled so one cannot exist without the other.
    struct SectionAction {
        let title: String
        let perform: () -> Void

        init(title: String, perform: @escaping () -> Void) {
            self.title = title
            self.perform = perform
        }
    }

    let title: String
    let action: SectionAction?

    init(title: String, action: SectionAction? = nil) {
        self.title = title
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Typeface.sectionTitle)
                .kerning(Theme.Kerning.sectionTitle)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            if let action {
                Button(action.title, action: action.perform)
                    .font(Theme.Typeface.action)
                    .foregroundStyle(Theme.Palette.accent)
            }
        }
    }
}

/// A hard horizontal divider rule.
struct HardRule: View {
    let color: Color
    let thickness: CGFloat

    init(color: Color = Theme.Palette.secondary, thickness: CGFloat = Theme.Stroke.rule) {
        self.color = color
        self.thickness = thickness
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: thickness)
            .accessibilityHidden(true)
    }
}

/// A left-to-right, top-to-bottom wrapping layout for chip-style content that must not clip
/// or overflow its container at large Dynamic Type sizes.
struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = Theme.Spacing.sm) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var origin = CGPoint.zero
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > maxWidth, origin.x > 0 {
                origin.x = 0
                origin.y += lineHeight + spacing
                lineHeight = 0
            }
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, origin.x - spacing)
        }

        return CGSize(width: maxWidth.isFinite ? maxWidth : totalWidth, height: origin.y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview("HatchedPlaceholder") {
    HatchedPlaceholder()
        .frame(width: 120, height: 120)
}

#Preview("ChipView") {
    HStack {
        ChipView(text: "25-35 min", style: .outlined)
        ChipView(text: "-40%", style: .promo)
    }
    .padding()
}

#Preview("SectionHeaderView") {
    SectionHeaderView(title: "OFERTAS DE HOY", action: .init(title: "Ver todas", perform: {}))
        .padding()
}

#Preview("HardRule") {
    HardRule()
}

#Preview("FlowLayout") {
    FlowLayout(spacing: Theme.Spacing.sm) {
        ChipView(text: "25-35 min", style: .outlined)
        ChipView(text: "-40%", style: .promo)
        ChipView(text: "Envío gratis", style: .promo)
    }
    .frame(width: 160)
    .padding()
}
