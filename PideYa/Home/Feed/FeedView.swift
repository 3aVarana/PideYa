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
    @State private var viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        _viewModel = State(initialValue: viewModel)
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
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        FeedHeaderView(profile: viewModel.profile, searchText: $viewModel.searchText)
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
                .font(Theme.Typeface.subtitle)
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
