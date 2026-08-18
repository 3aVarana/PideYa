//
//  OrdersView.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// The Pedidos tab: fixed header, an `EN CURSO` active-order card and an `ANTERIORES` list of
/// past orders.
///
/// Wrapped in a `NavigationStack` with a hidden bar even though nothing pushes yet, so the
/// typed-enum `navigationDestination` pattern can be added later without restructuring.
struct OrdersView: View {
    /// Held as a plain `let`, not `@State`: `HomeTabViewModel` creates and retains the
    /// `OrdersViewModel` so its state survives tab switches. See `CLAUDE.md` "ViewModel
    /// ownership".
    let viewModel: OrdersViewModel
    /// The tab bar's real, measured height, supplied by `HomeTabView`. `HomeTabView`'s own
    /// `.safeAreaInset(edge: .bottom)` does not cross this view's `NavigationStack` boundary, so
    /// a second, independent bottom inset is applied directly on this `ScrollView` — the same
    /// fix `FeedView` applies.
    let bottomInset: CGFloat

    init(viewModel: OrdersViewModel, bottomInset: CGFloat = 0) {
        self.viewModel = viewModel
        self.bottomInset = bottomInset
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.hasActiveOrders {
                        activeSection
                        HardRule()
                    }
                    pastSection
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.Palette.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                header
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Theme.Palette.transparent.frame(height: bottomInset)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        OrdersHeaderView(title: "Pedidos", summaryText: viewModel.summaryText, onHelp: {})
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeaderView(title: "EN CURSO")
            ForEach(viewModel.activeOrders) { order in
                ActiveOrderCardView(order: order, onTrack: {}, onQuickAction: {})
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeaderView(title: "ANTERIORES", action: .init(title: "Filtrar", perform: {}))
                .padding(.horizontal, Theme.Spacing.lg)
            pastList
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var pastList: some View {
        LazyVStack(spacing: 0) {
            // `order.id` stays the `ForEach` identity (stable across re-renders); `index` is
            // threaded separately, purely so `PastOrderRowView` can expose a content-independent
            // `.accessibilityIdentifier`.
            ForEach(Array(viewModel.pastOrders.enumerated()), id: \.element.id) { index, order in
                PastOrderRowView(order: order, index: index, onRepeat: {})
                    .padding(.vertical, Theme.Spacing.md)
                HardRule(thickness: Theme.Stroke.hairline)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

#Preview {
    OrdersView(viewModel: OrdersViewModel())
}
