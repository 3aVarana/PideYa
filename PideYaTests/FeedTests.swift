//
//  FeedTests.swift
//  PideYaTests
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation
import Testing

@testable import PideYa

private struct StubFeedContentProvider: FeedContentProviding {
    func profile() -> FeedProfile {
        FeedProfile(initials: "ZZ", addressLine: "Calle Stub 1")
    }

    func offers() -> [Offer] {
        [
            Offer(
                id: UUID(),
                restaurantName: "Stub Restaurant",
                bannerText: "STUB BANNER",
                cuisine: "Stub",
                etaMinutes: 1...2
            )
        ]
    }

    func recommendations() -> [Restaurant] {
        [
            Restaurant(
                id: UUID(),
                name: "Stub Recommendation",
                cuisine: "Stub",
                rating: 5.0,
                etaMinutes: 1...2,
                promotion: "STUB",
                deliveryFee: 9.99
            )
        ]
    }
}

struct FeedFormattingTests {
    @Test func ratingTextUsesCommaDecimalSeparator() {
        let highRating = Restaurant(
            id: UUID(),
            name: "A",
            cuisine: "A",
            rating: 4.8,
            etaMinutes: 1...2,
            promotion: nil,
            deliveryFee: 0
        )
        #expect(highRating.ratingText == "4,8")

        let roundRating = Restaurant(
            id: UUID(),
            name: "A",
            cuisine: "A",
            rating: 4.0,
            etaMinutes: 1...2,
            promotion: nil,
            deliveryFee: 0
        )
        #expect(roundRating.ratingText == "4,0")
    }

    @Test func deliveryFeeTextFormatsAsEuroWithComma() {
        // The es-ES currency formatter uses a non-breaking space (U+00A0) before the symbol.
        let fees: [(Decimal, String)] = [
            (1.90, "1,90\u{00A0}€"),
            (2.50, "2,50\u{00A0}€"),
            (0, "0,00\u{00A0}€"),
        ]
        for (fee, expected) in fees {
            let restaurant = Restaurant(
                id: UUID(),
                name: "A",
                cuisine: "A",
                rating: 4.0,
                etaMinutes: 1...2,
                promotion: nil,
                deliveryFee: fee
            )
            #expect(restaurant.deliveryFeeText == expected)
        }
    }

    @Test func etaTextHasNoThousandsSeparator() {
        let restaurant = Restaurant(
            id: UUID(),
            name: "A",
            cuisine: "A",
            rating: 4.0,
            etaMinutes: 25...35,
            promotion: nil,
            deliveryFee: 0
        )
        #expect(restaurant.etaText == "25-35 min")

        let single = Restaurant(
            id: UUID(),
            name: "A",
            cuisine: "A",
            rating: 4.0,
            etaMinutes: 5...5,
            promotion: nil,
            deliveryFee: 0
        )
        #expect(single.etaText == "5-5 min")

        let large = Restaurant(
            id: UUID(),
            name: "A",
            cuisine: "A",
            rating: 4.0,
            etaMinutes: 100...120,
            promotion: nil,
            deliveryFee: 0
        )
        #expect(large.etaText == "100-120 min")
    }

    @Test func subtitleTextComposesStarSeparator() {
        let restaurant = Restaurant(
            id: UUID(),
            name: "A",
            cuisine: "Mexicana",
            rating: 4.8,
            etaMinutes: 1...2,
            promotion: nil,
            deliveryFee: 0
        )
        #expect(restaurant.subtitleText.contains(" · ★ "))
    }

    @Test func offerEtaTextHasNoThousandsSeparator() {
        let offer = Offer(
            id: UUID(),
            restaurantName: "A",
            bannerText: "A",
            cuisine: "A",
            etaMinutes: 25...35
        )
        #expect(offer.etaText == "25-35 min")

        let large = Offer(
            id: UUID(),
            restaurantName: "A",
            bannerText: "A",
            cuisine: "A",
            etaMinutes: 100...120
        )
        #expect(large.etaText == "100-120 min")
    }

    @Test func offerSubtitleTextComposesCuisineAndEta() {
        let offer = Offer(
            id: UUID(),
            restaurantName: "A",
            bannerText: "A",
            cuisine: "Mexicana",
            etaMinutes: 25...35
        )
        #expect(offer.subtitleText == "Mexicana · 25-35 min")
    }
}

struct MockFeedContentProviderTests {
    @Test func profileMatchesDocumentedValues() {
        let provider = MockFeedContentProvider()
        let profile = provider.profile()
        #expect(profile.initials == "VA")
        #expect(profile.addressLine == "Calle Mayor 44")
    }

    @Test func offersMatchDocumentedOrder() {
        let provider = MockFeedContentProvider()
        let offers = provider.offers()
        #expect(offers.count == 2)
        #expect(offers[0].restaurantName == "Taquería Norte")
        #expect(offers[1].restaurantName == "Forno Bianco")
    }

    @Test func recommendationsMatchDocumentedOrderAndPromotions() {
        let provider = MockFeedContentProvider()
        let recommendations = provider.recommendations()
        #expect(recommendations.count == 3)
        #expect(recommendations[0].name == "Taquería Norte")
        #expect(recommendations[1].name == "Forno Bianco")
        #expect(recommendations[2].name == "Casa Lola")
        #expect(recommendations[0].promotion != nil)
        #expect(recommendations[1].promotion != nil)
        #expect(recommendations[2].promotion == nil)
    }
}

@MainActor
struct FeedViewModelTests {
    @Test func initSurfacesInjectedProviderData() {
        let viewModel = FeedViewModel(provider: StubFeedContentProvider())
        #expect(viewModel.profile.initials == "ZZ")
        #expect(viewModel.offers.map(\.restaurantName) == ["Stub Restaurant"])
        #expect(viewModel.recommendations.map(\.name) == ["Stub Recommendation"])
    }

    @Test func searchTextStartsEmpty() {
        let viewModel = FeedViewModel()
        #expect(viewModel.searchText == "")
    }
}

@MainActor
struct HomeTabViewModelTests {
    @Test func selectedTabDefaultsToInicio() {
        let viewModel = HomeTabViewModel()
        #expect(viewModel.selectedTab == .inicio)
    }

    @Test func homeTabAllCasesMatchDocumentedTitles() {
        #expect(HomeTab.allCases.count == 4)
        #expect(HomeTab.allCases.map(\.title) == ["Inicio", "Buscar", "Pedidos", "Cuenta"])
    }

    @Test func homeTabSystemImagesAreIOS17AvailableSymbols() {
        // These four symbols are long-standing (pre-iOS 17) SF Symbols; guards against a
        // typo'd or iOS 18-only name regressing to a blank glyph (plan.md risk).
        #expect(HomeTab.allCases.map(\.systemImage) == ["house.fill", "magnifyingglass", "doc.text", "person"])
    }
}
