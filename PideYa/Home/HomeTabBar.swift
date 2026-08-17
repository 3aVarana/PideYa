//
//  HomeTabBar.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// The four tabs of the Home shell.
nonisolated enum HomeTab: String, CaseIterable, Identifiable, Sendable {
    case inicio
    case buscar
    case pedidos
    case cuenta

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inicio: "Inicio"
        case .buscar: "Buscar"
        case .pedidos: "Pedidos"
        case .cuenta: "Cuenta"
        }
    }

    var systemImage: String {
        switch self {
        case .inicio: "house.fill"
        case .buscar: "magnifyingglass"
        case .pedidos: "doc.text"
        case .cuenta: "person"
        }
    }
}

/// A custom bottom tab bar: hard 1pt top rule, bold small labels, red selected state.
struct HomeTabBar: View {
    @Binding var selection: HomeTab

    var body: some View {
        VStack(spacing: 0) {
            HardRule(color: Theme.Palette.ink, thickness: Theme.Stroke.hairline)
            HStack(spacing: 0) {
                ForEach(HomeTab.allCases) { tab in
                    tabButton(for: tab)
                }
            }
            .background(Theme.Palette.background)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func tabButton(for tab: HomeTab) -> some View {
        let isSelected = tab == selection
        return Button {
            selection = tab
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: Theme.IconSize.tab))
                Text(tab.title)
                    .font(Theme.Typeface.tabLabel)
            }
            .foregroundStyle(isSelected ? Theme.Palette.accent : Theme.Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .accessibilityIdentifier("tabbar.\(tab.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A shared placeholder screen for tabs without a real implementation yet.
struct PlaceholderTabView: View {
    let tab: HomeTab

    var body: some View {
        ContentUnavailableView(tab.title, systemImage: tab.systemImage, description: Text("Próximamente."))
            .background(Theme.Palette.background)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("placeholder.\(tab.rawValue)")
    }
}

#Preview("HomeTabBar") {
    HomeTabBar(selection: .constant(.inicio))
}

#Preview("PlaceholderTabView") {
    PlaceholderTabView(tab: .buscar)
}
