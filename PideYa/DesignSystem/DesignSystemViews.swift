//
//  DesignSystemViews.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI
import UIKit

extension View {
    /// Applies a `Theme.Typeface` token with real Dynamic Type scaling.
    ///
    /// `Theme.Typeface` tokens store a fixed *base* point size and weight; a bare
    /// `.font(.system(size:weight:))` never responds to the user's Content Size Category. This
    /// modifier scales the base size with `UIFontMetrics`, keyed to the live `dynamicTypeSize`
    /// environment value, so text set this way genuinely grows and shrinks with Dynamic Type.
    func themeFont(_ style: Theme.Typeface.Style) -> some View {
        modifier(ThemeFontModifier(style: style))
    }
}

private struct ThemeFontModifier: ViewModifier {
    let style: Theme.Typeface.Style
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.font(scaledFont)
    }

    private var scaledFont: Font {
        let metrics = UIFontMetrics(forTextStyle: style.relativeTo)
        let traitCollection = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let scaledSize = metrics.scaledValue(for: style.size, compatibleWith: traitCollection)
        return Font.system(size: scaledSize, weight: style.weight)
    }
}

extension UIContentSizeCategory {
    /// `DynamicTypeSize` (SwiftUI) has no built-in bridge to `UIContentSizeCategory` (UIKit),
    /// so `UIFontMetrics` is mapped explicitly to the same category the environment reports.
    fileprivate init(_ dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .xLarge: self = .extraLarge
        case .xxLarge: self = .extraExtraLarge
        case .xxxLarge: self = .extraExtraExtraLarge
        case .accessibility1: self = .accessibilityMedium
        case .accessibility2: self = .accessibilityLarge
        case .accessibility3: self = .accessibilityExtraLarge
        case .accessibility4: self = .accessibilityExtraExtraLarge
        case .accessibility5: self = .accessibilityExtraExtraExtraLarge
        @unknown default: self = .large
        }
    }
}

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
            .themeFont(Theme.Typeface.chip)
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
                .themeFont(Theme.Typeface.sectionTitle)
                .kerning(Theme.Kerning.sectionTitle)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            if let action {
                Button(action.title, action: action.perform)
                    .themeFont(Theme.Typeface.action)
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
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let largestItemWidth = sizes.map(\.width).max() ?? 0
        let proposedWidth = proposal.width ?? .infinity
        // A single child can never be split across a line, so the wrap threshold must never be
        // narrower than the widest child. Without this floor, a `.zero` proposal makes every
        // child wrap onto its own line while still (incorrectly) reporting a width of 0, telling
        // the parent this layout can shrink to nothing when it cannot.
        let wrapWidth = max(proposedWidth, largestItemWidth)

        var origin = CGPoint.zero
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for size in sizes {
            if origin.x + size.width > wrapWidth, origin.x > 0 {
                origin.x = 0
                origin.y += lineHeight + spacing
                lineHeight = 0
            }
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, origin.x - spacing)
        }

        let height = origin.y + lineHeight
        guard proposedWidth.isFinite else {
            return CGSize(width: totalWidth, height: height)
        }
        // Never claim more than the proposal actually offers (the old greedy behaviour), but
        // never claim less than the widest single child needs (the old `.zero`-reports-0 bug).
        return CGSize(width: max(largestItemWidth, min(proposedWidth, totalWidth)), height: height)
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
            // Constrain the placement proposal to the available bounds so a child wider than
            // its line's remaining space is asked to fit inside `bounds` rather than being
            // placed at its full natural size and overflowing past the container's edge.
            let placementWidth = min(size.width, bounds.width)
            subview.place(at: origin, proposal: ProposedViewSize(width: placementWidth, height: size.height))
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

/// Clamps a raw rating into a valid filled-star count, so an out-of-range `score` (negative, or
/// above `outOf`) can never crash or force-unwrap; it simply saturates at the nearest valid
/// value. A free function rather than a `private` view property so it is directly testable from
/// `PideYaTests`.
nonisolated func filledStars(score: Double, outOf: Int) -> Int {
    min(outOf, max(0, Int(score.rounded())))
}

/// A row of accent-red stars, filled up to `score` and hollow for the remainder.
///
/// User-facing copy is not baked in: the caller supplies `accessibilityLabel`, keeping this
/// component free of any one app's language (every other component in this file follows the
/// same rule, e.g. `ChipView(text:)`).
struct StarRatingView: View {
    let score: Double
    let outOf: Int
    let accessibilityLabel: (Int, Int) -> String

    init(score: Double, outOf: Int = 5, accessibilityLabel: @escaping (Int, Int) -> String) {
        self.score = score
        self.outOf = outOf
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<outOf, id: \.self) { index in
                Image(systemName: index < filledCount ? "star.fill" : "star")
                    .themeFont(Theme.Typeface.chip)
                    .foregroundStyle(Theme.Palette.accent)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(filledCount, outOf))
    }

    private var filledCount: Int {
        filledStars(score: score, outOf: outOf)
    }
}

/// A hairline-bordered text button with a transparent fill. Distinct from `ChipView(style:
/// .outlined)`, which is ink-bordered and is not a `Button` — this component is for controls
/// whose border colour must diverge from ink (e.g. the `REPETIR` button's light-grey border).
struct OutlinedActionButton: View {
    let title: String
    let action: () -> Void

    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .themeFont(Theme.Typeface.chip)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .overlay(Rectangle().strokeBorder(Theme.Palette.outline, lineWidth: Theme.Stroke.hairline))
        }
        .buttonStyle(.plain)
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

#Preview("StarRatingView") {
    VStack(spacing: Theme.Spacing.sm) {
        StarRatingView(score: 5.0) { filled, outOf in "\(filled) de \(outOf) estrellas" }
        StarRatingView(score: 4.0) { filled, outOf in "\(filled) de \(outOf) estrellas" }
    }
    .padding()
}

#Preview("OutlinedActionButton") {
    OutlinedActionButton(title: "REPETIR", action: {})
        .padding()
}
