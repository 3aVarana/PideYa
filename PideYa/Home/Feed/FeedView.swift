//
//  FeedView.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// The Inicio tab: fixed header, offers carousel and recommended restaurants list.
///
/// Wrapped in a `NavigationStack` with a hidden bar even though nothing pushes yet, so the
/// typed-enum `navigationDestination` pattern can be added later without restructuring.
struct FeedView: View {
    /// Held as a plain `let`, not `@State`, because this view does not own it: `HomeTabViewModel`
    /// creates and retains the `FeedViewModel` so feed state survives tab switches. `@State` would
    /// claim ownership and apply its "only the first instance passed in wins" lifetime rule, which
    /// would silently ignore a later swap of the injected view model. Observation still drives
    /// updates through the `@Observable` reference, so nothing is lost by dropping the wrapper.
    let viewModel: FeedViewModel
    /// The tab bar's real, measured height, supplied by `HomeTabView`.
    ///
    /// `HomeTabView` already applies `.safeAreaInset(edge: .bottom)` for the tab bar one level
    /// above this view's `NavigationStack`, but that inset does not reach this screen's
    /// `ScrollView`: `NavigationStack` is backed by a `UINavigationController`/`UIHostingView`
    /// boundary, and SwiftUI's ancestor safe-area reservation does not cross that boundary the
    /// way it does for plain nested SwiftUI containers (this is why the pinned *top* header,
    /// whose inset is applied directly to this same `ScrollView` below, works correctly while
    /// the bottom one silently did not). The fix is to apply a second, independent
    /// `.safeAreaInset(edge: .bottom)` directly on this `ScrollView`, using the tab bar's real
    /// measured height rather than a hardcoded constant.
    let bottomInset: CGFloat

    init(viewModel: FeedViewModel, bottomInset: CGFloat = 0) {
        self.viewModel = viewModel
        self.bottomInset = bottomInset
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    offersSection
                    HardRule()
                    recommendedSection
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
        // `viewModel` is a plain `let`, so there is no `$` projection to bind through.
        // `Bindable` produces the write-back binding the search field needs.
        FeedHeaderView(profile: viewModel.profile, searchText: Bindable(viewModel).searchText)
    }

    private var offersSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeaderView(title: "OFERTAS DE HOY", action: .init(title: "Ver todas", perform: {}))
                .padding(.horizontal, Theme.Spacing.lg)
            offersCarousel
        }
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var offersCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.offers) { offer in
                    OfferCardView(offer: offer)
                        .containerRelativeFrame(.horizontal, count: 8, span: 5, spacing: Theme.Spacing.md)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, Theme.Spacing.lg, for: .scrollContent)
        .accessibilityIdentifier("offersCarousel")
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            SectionHeaderView(title: "RECOMENDADOS PARA TI")
            Text("Según tus últimos pedidos")
                .themeFont(Theme.Typeface.subtitle)
                .foregroundStyle(Theme.Palette.secondary)
            recommendedList
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var recommendedList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.recommendations) { restaurant in
                RestaurantRowView(restaurant: restaurant)
                    .padding(.vertical, Theme.Spacing.md)
                if restaurant.id != viewModel.recommendations.last?.id {
                    HardRule(thickness: Theme.Stroke.hairline)
                        .padding(.leading, Theme.Size.rowThumbnail + Theme.Spacing.md)
                }
            }
        }
    }
}

#Preview {
    FeedView(viewModel: FeedViewModel())
}
