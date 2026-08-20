//
//  HomeTabView.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

struct HomeTabView: View {
    @State private var viewModel: HomeTabViewModel
    /// The tab bar's real rendered height, measured below. Seeded with a rough estimate so the
    /// very first layout pass (before the first measurement lands) still reserves roughly the
    /// right amount of scroll-content padding; the measured value is always what's actually used.
    @State private var tabBarHeight: CGFloat = Theme.Size.tabBarFallbackHeight

    init(viewModel: HomeTabViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        selectedScreen
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HomeTabBar(selection: $viewModel.selectedTab)
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                        tabBarHeight = height
                    }
            }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch viewModel.selectedTab {
        case .inicio: FeedView(viewModel: viewModel.feed, bottomInset: tabBarHeight)
        case .pedidos: OrdersView(viewModel: viewModel.orders, bottomInset: tabBarHeight)
        case .cuenta: AccountView(viewModel: viewModel.account, bottomInset: tabBarHeight)
        case let other: PlaceholderTabView(tab: other)
        }
    }
}

#Preview {
    HomeTabView(viewModel: HomeTabViewModel())
}
