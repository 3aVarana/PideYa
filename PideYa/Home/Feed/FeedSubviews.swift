//
//  FeedSubviews.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

/// The fixed header block: brand mark, avatar, address selector and search field.
struct FeedHeaderView: View {
    let profile: FeedProfile
    @Binding var searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            brandRow
            addressRow
            searchField
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
        .background(Theme.Palette.background)
        .overlay(alignment: .bottom) {
            HardRule()
        }
        // The 52pt avatar box and the brand word's single-line layout cannot grow indefinitely;
        // cap growth the same way `HomeTabBar` already does.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var brandRow: some View {
        HStack {
            Text("PIDEYA")
                .themeFont(Theme.Typeface.brand)
                .kerning(Theme.Kerning.brand)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            avatarBox
        }
    }

    private var avatarBox: some View {
        Text(profile.initials)
            .themeFont(Theme.Typeface.rowTitle)
            .foregroundStyle(Theme.Palette.ink)
            .frame(width: Theme.Size.avatarBox, height: Theme.Size.avatarBox)
            .overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.hairline))
    }

    private var addressRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "mappin")
                .foregroundStyle(Theme.Palette.accent)
            Text(profile.addressLine)
                .themeFont(Theme.Typeface.subtitleBold)
                .foregroundStyle(Theme.Palette.ink)
            Image(systemName: "chevron.down")
                .foregroundStyle(Theme.Palette.ink)
        }
    }

    private var searchField: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Palette.secondary)
            TextField("Buscar restaurantes o platos", text: $searchText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: Theme.Size.searchField)
        .background(Theme.Palette.searchFill)
        .overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.hairline))
    }
}

/// A single card in the "Ofertas de hoy" carousel.
struct OfferCardView: View {
    let offer: Offer

    var body: some View {
        VStack(spacing: 0) {
            HatchedPlaceholder()
                .aspectRatio(1, contentMode: .fit)
            bannerBand
            details
        }
        .background(Theme.Palette.background)
        .overlay(Rectangle().strokeBorder(Theme.Palette.ink, lineWidth: Theme.Stroke.hairline))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("offerCard.\(offer.restaurantName)")
    }

    private var bannerBand: some View {
        Text(offer.bannerText)
            .themeFont(Theme.Typeface.band)
            .foregroundStyle(Theme.Palette.onAccent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Palette.accent)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(offer.restaurantName)
                .themeFont(Theme.Typeface.cardTitle)
                .foregroundStyle(Theme.Palette.ink)
            Text(offer.subtitleText)
                .themeFont(Theme.Typeface.subtitle)
                .foregroundStyle(Theme.Palette.secondary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A single row in the "Recomendados para ti" list.
struct RestaurantRowView: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            HatchedPlaceholder()
                .frame(width: Theme.Size.rowThumbnail, height: Theme.Size.rowThumbnail)
            details
            Spacer()
            Text(restaurant.deliveryFeeText)
                .themeFont(Theme.Typeface.subtitleBold)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .layoutPriority(1)
        }
        // The 72pt thumbnail is fixed size; cap growth the same way `HomeTabBar` already does
        // so the row's chips (now wrapped by `FlowLayout`) and fee text stay legible rather than
        // pushing the row to an unbounded height.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(restaurant.name)
                .themeFont(Theme.Typeface.rowTitle)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
            Text(restaurant.subtitleText)
                .themeFont(Theme.Typeface.subtitle)
                .foregroundStyle(Theme.Palette.secondary)
            chips
        }
    }

    private var chips: some View {
        FlowLayout(spacing: Theme.Spacing.sm) {
            ChipView(text: restaurant.etaText, style: .outlined)
            if let promotion = restaurant.promotion {
                ChipView(text: promotion, style: .promo)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chips.\(restaurant.name)")
    }
}

#Preview("FeedHeaderView") {
    FeedHeaderView(
        profile: FeedProfile(initials: "VA", addressLine: "Calle Mayor 44"),
        searchText: .constant("")
    )
}

#Preview("OfferCardView") {
    OfferCardView(
        offer: Offer(
            id: UUID(),
            restaurantName: "Taquería Norte",
            bannerText: "-40% · HASTA LAS 23:00",
            cuisine: "Mexicana",
            etaMinutes: 25...35
        )
    )
    .frame(width: 240)
}

#Preview("RestaurantRowView") {
    RestaurantRowView(
        restaurant: Restaurant(
            id: UUID(),
            name: "Taquería Norte",
            cuisine: "Mexicana",
            rating: 4.8,
            etaMinutes: 25...35,
            promotion: "-40%",
            deliveryFee: 1.90
        )
    )
    .padding()
}
