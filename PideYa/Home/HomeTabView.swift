//
//  HomeTabView.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

struct HomeTabView: View {
    @State private var viewModel: HomeTabViewModel

    init(viewModel: HomeTabViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        selectedScreen
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HomeTabBar(selection: $viewModel.selectedTab)
            }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch viewModel.selectedTab {
        case .inicio: FeedView(viewModel: viewModel.feed)
        case let other: PlaceholderTabView(tab: other)
        }
    }
}

#Preview {
    HomeTabView(viewModel: HomeTabViewModel())
}
