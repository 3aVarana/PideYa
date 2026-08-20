//
//  AccountView.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// The Cuenta tab: a header block, a 2 × 3 settings grid and a `MONEDERO` block, all inside one
/// scrolling `ScrollView`. Unlike `FeedView`/`OrdersView`, nothing is pinned: DESIGN.md §9 Q1
/// requires the whole screen to remain reachable by scrolling at accessibility content sizes.
///
/// Wrapped in a `NavigationStack` with a hidden bar even though nothing pushes yet, so the typed-
/// enum `navigationDestination` pattern can be added later without restructuring.
struct AccountView: View {
    /// Held as a plain `let`, not `@State`: `HomeTabViewModel` creates and retains the
    /// `AccountViewModel` so its state survives tab switches. See `CLAUDE.md` "ViewModel
    /// ownership".
    let viewModel: AccountViewModel
    /// The tab bar's real, measured height, supplied by `HomeTabView`. `HomeTabView`'s own
    /// `.safeAreaInset(edge: .bottom)` does not cross this view's `NavigationStack` boundary, so
    /// a second, independent bottom inset is applied directly on this `ScrollView`.
    let bottomInset: CGFloat

    init(viewModel: AccountViewModel, bottomInset: CGFloat = 0) {
        self.viewModel = viewModel
        self.bottomInset = bottomInset
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    AccountHeaderView(profile: viewModel.profile)
                    HardRule()
                    AccountTileGridView(tiles: viewModel.tiles, onSelect: { _ in })
                    HardRule()
                    AccountWalletView(wallet: viewModel.wallet, onSignOut: {})
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.Palette.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Theme.Palette.transparent.frame(height: bottomInset)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    AccountView(viewModel: AccountViewModel())
}
