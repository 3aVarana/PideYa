//
//  Theme.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI
import UIKit

/// Design tokens shared by every tab in the Home shell.
///
/// Corner radius is always 0 in this design system: no view in this feature
/// may apply `.cornerRadius` or `RoundedRectangle`.
nonisolated enum Theme {
    enum Palette {
        static let background = Color(red: 242 / 255, green: 242 / 255, blue: 240 / 255)
        static let ink = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
        static let secondary = Color(red: 138 / 255, green: 138 / 255, blue: 138 / 255)
        static let accent = Color(red: 226 / 255, green: 55 / 255, blue: 42 / 255)
        static let promoFill = Color(red: 251 / 255, green: 217 / 255, blue: 213 / 255)
        static let placeholder = Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255)
        static let searchFill = Color(red: 232 / 255, green: 232 / 255, blue: 230 / 255)
        /// Foreground colour for text/icons drawn directly on `accent` fills (e.g. the offer banner band).
        static let onAccent = Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255)
        /// Invisible spacer colour, used where a view needs a `Color` only to occupy layout
        /// space (e.g. the tab-bar-height bottom inset in `FeedView`), never as a visible fill.
        static let transparent = Color.clear
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Stroke {
        static let hairline: CGFloat = 1
        static let rule: CGFloat = 2
    }

    enum Size {
        static let avatarBox: CGFloat = 52
        static let searchField: CGFloat = 56
        static let rowThumbnail: CGFloat = 72
        /// Estimate of `HomeTabBar`'s rendered height, used only as the initial value of
        /// `HomeTabView`'s `@State` before the bar's real height is measured with
        /// `onGeometryChange`. The real, measured height is always the source of truth for the
        /// bottom content inset that keeps the last recommendation row above the bar; this token
        /// only avoids a flash of unpadded content on the very first layout pass.
        static let tabBarFallbackHeight: CGFloat = 56
    }

    enum IconSize {
        static let tab: CGFloat = 22
    }

    /// Font tokens. **Not** `Font` values directly: a bare `Font.system(size:weight:)` is a
    /// fixed-point-size font that never responds to the user's Content Size Category, so it
    /// does not honour Dynamic Type despite superficially looking like it might. Each token
    /// below pairs the design's base point size (as specified at the default/"Large" content
    /// size category) with the `UIFontMetrics` text style used to scale it. Apply a token with
    /// `View.themeFont(_:)` (see `DesignSystemViews.swift`), not `.font(_:)` directly, so the
    /// scaling actually happens.
    enum Typeface {
        struct Style {
            let size: CGFloat
            let weight: Font.Weight
            let relativeTo: UIFont.TextStyle
        }

        static let brand = Style(size: 40, weight: .heavy, relativeTo: .largeTitle)
        static let sectionTitle = Style(size: 15, weight: .bold, relativeTo: .subheadline)
        static let cardTitle = Style(size: 22, weight: .bold, relativeTo: .title2)
        static let rowTitle = Style(size: 20, weight: .bold, relativeTo: .title3)
        static let subtitle = Style(size: 15, weight: .regular, relativeTo: .subheadline)
        static let subtitleBold = Style(size: 15, weight: .bold, relativeTo: .subheadline)
        static let chip = Style(size: 13, weight: .bold, relativeTo: .caption1)
        static let band = Style(size: 13, weight: .heavy, relativeTo: .caption1)
        static let tabLabel = Style(size: 11, weight: .bold, relativeTo: .caption2)
        static let action = Style(size: 15, weight: .medium, relativeTo: .subheadline)
    }

    enum Kerning {
        static let brand: CGFloat = 1
        static let sectionTitle: CGFloat = 1.5
    }
}
