//
//  Theme.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

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
    }

    enum IconSize {
        static let tab: CGFloat = 22
    }

    enum Typeface {
        static let brand = Font.system(size: 40, weight: .heavy)
        static let sectionTitle = Font.system(size: 15, weight: .bold)
        static let cardTitle = Font.system(size: 22, weight: .bold)
        static let rowTitle = Font.system(size: 20, weight: .bold)
        static let subtitle = Font.system(size: 15, weight: .regular)
        static let chip = Font.system(size: 13, weight: .bold)
        static let band = Font.system(size: 13, weight: .heavy)
        static let tabLabel = Font.system(size: 11, weight: .bold)
        static let action = Font.system(size: 15, weight: .medium)
    }

    enum Kerning {
        static let brand: CGFloat = 1
        static let sectionTitle: CGFloat = 1.5
    }
}
