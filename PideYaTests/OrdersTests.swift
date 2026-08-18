//
//  OrdersTests.swift
//  PideYaTests
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation
import Testing

@testable import PideYa

private struct StubOrdersContentProvider: OrdersContentProviding {
    func activeOrders() -> [ActiveOrder] {
        [
            ActiveOrder(
                id: UUID(),
                restaurantName: "Stub Activo",
                total: 9.99,
                itemCount: 1,
                orderNumber: "0001",
                stage: .confirmado,
                etaText: "12:00"
            )
        ]
    }

    func pastOrders() -> [PastOrder] {
        [
            PastOrder(
                id: UUID(),
                restaurantName: "Stub Anterior",
                total: 5.50,
                dateText: "1 ene",
                itemCount: 1,
                rating: nil
            )
        ]
    }
}

private struct EmptyOrdersContentProvider: OrdersContentProviding {
    func activeOrders() -> [ActiveOrder] {
        []
    }

    func pastOrders() -> [PastOrder] {
        []
    }
}

struct OrderStageTests {
    @Test func orderStageLabelsAreLiteralUppercase() {
        #expect(OrderStage.allCases.map(\.label) == ["CONFIRMADO", "EN COCINA", "EN CAMINO", "ENTREGADO"])
    }

    @Test func orderStageStepIndicesAreSequential() {
        #expect(OrderStage.allCases.map(\.stepIndex) == [0, 1, 2, 3])
    }
}

struct OrdersFormattingTests {
    @Test func activeOrderTotalUsesNonBreakingSpaceBeforeEuro() {
        let order = ActiveOrder(
            id: UUID(),
            restaurantName: "A",
            total: 24.60,
            itemCount: 3,
            orderNumber: "4821",
            stage: .enCamino,
            etaText: "20:45"
        )
        #expect(order.totalText == "24,60\u{00A0}€")
    }

    @Test func pastOrderTotalsUseNonBreakingSpaceBeforeEuro() {
        let totals: [(Decimal, String)] = [
            (18.90, "18,90\u{00A0}€"),
            (31.20, "31,20\u{00A0}€"),
            (26.50, "26,50\u{00A0}€"),
            (0, "0,00\u{00A0}€"),
        ]
        for (total, expected) in totals {
            let order = PastOrder(
                id: UUID(), restaurantName: "A", total: total, dateText: "1 ene", itemCount: 1, rating: nil
            )
            #expect(order.totalText == expected)
        }
    }

    @Test func activeOrderSubtitleComposesItemsAndOrderNumber() {
        let order = ActiveOrder(
            id: UUID(),
            restaurantName: "A",
            total: 24.60,
            itemCount: 3,
            orderNumber: "4821",
            stage: .enCamino,
            etaText: "20:45"
        )
        #expect(order.subtitleText == "3 artículos · Pedido #4821")
    }

    @Test func itemCountTextIsSingularForOne() {
        func subtitle(_ count: Int) -> String {
            let order = PastOrder(
                id: UUID(), restaurantName: "A", total: 0, dateText: "1 ene", itemCount: count, rating: nil
            )
            return order.subtitleText
        }
        #expect(subtitle(1) == "1 ene · 1 artículo")
        #expect(subtitle(2) == "1 ene · 2 artículos")
        #expect(subtitle(0) == "1 ene · 0 artículos")
    }

    @Test func activeOrderArrivalTextIsPrefixed() {
        let order = ActiveOrder(
            id: UUID(),
            restaurantName: "A",
            total: 0,
            itemCount: 1,
            orderNumber: "1",
            stage: .enCamino,
            etaText: "20:45"
        )
        #expect(order.arrivalText == "LLEGA 20:45")
    }

    @Test func pastOrderSubtitleComposesDateAndItems() {
        let order = PastOrder(id: UUID(), restaurantName: "A", total: 0, dateText: "12 ago", itemCount: 2, rating: nil)
        #expect(order.subtitleText == "12 ago · 2 artículos")
    }

    @Test func pastOrderRatingTextUsesCommaDecimal() {
        let rated5 = PastOrder(id: UUID(), restaurantName: "A", total: 0, dateText: "1 ene", itemCount: 1, rating: 5.0)
        #expect(rated5.ratingText == "5,0")
        #expect(rated5.isRated)

        let rated4 = PastOrder(id: UUID(), restaurantName: "A", total: 0, dateText: "1 ene", itemCount: 1, rating: 4.0)
        #expect(rated4.ratingText == "4,0")

        let unrated = PastOrder(id: UUID(), restaurantName: "A", total: 0, dateText: "1 ene", itemCount: 1, rating: nil)
        #expect(unrated.ratingText == nil)
        #expect(!unrated.isRated)
    }
}

struct MockOrdersContentProviderTests {
    @Test func mockProviderSeedsOneActiveOrderPerDesign() {
        let provider = MockOrdersContentProvider()
        let active = provider.activeOrders()
        #expect(active.count == 1)
        #expect(active[0].restaurantName == "Taquería Norte")
        #expect(active[0].orderNumber == "4821")
        #expect(active[0].stage == .enCamino)
        #expect(active[0].etaText == "20:45")
        #expect(active[0].itemCount == 3)
    }

    @Test func mockProviderSeedsTwelvePastOrdersInDocumentedOrder() {
        let provider = MockOrdersContentProvider()
        let past = provider.pastOrders()
        #expect(past.count == 12)
        #expect(past[0].restaurantName == "Forno Bianco")
        #expect(past[0].total == 18.90)
        #expect(past[0].dateText == "12 ago")
        #expect(past[0].rating == 5.0)
        #expect(past[1].restaurantName == "Casa Lola")
        #expect(past[1].total == 31.20)
        #expect(past[1].dateText == "9 ago")
        #expect(past[1].rating == nil)
        #expect(past[2].restaurantName == "Sakura Ramen")
        #expect(past[2].total == 26.50)
        #expect(past[2].dateText == "4 ago")
        #expect(past[2].rating == 4.0)
    }

    @Test func mockProviderIDsAreStableAcrossCalls() {
        let provider = MockOrdersContentProvider()
        #expect(provider.pastOrders().map(\.id) == provider.pastOrders().map(\.id))
        #expect(provider.activeOrders().map(\.id) == provider.activeOrders().map(\.id))
    }
}

@MainActor
struct OrdersViewModelTests {
    @Test func viewModelSurfacesInjectedProviderData() {
        let viewModel = OrdersViewModel(provider: StubOrdersContentProvider())
        #expect(viewModel.activeOrders.map(\.restaurantName) == ["Stub Activo"])
        #expect(viewModel.pastOrders.map(\.restaurantName) == ["Stub Anterior"])
    }

    @Test func summaryTextIsDerivedFromArrays() {
        let stubViewModel = OrdersViewModel(provider: StubOrdersContentProvider())
        #expect(stubViewModel.summaryText == "1 en curso · 1 anterior")

        let mockViewModel = OrdersViewModel()
        #expect(mockViewModel.summaryText == "1 en curso · 12 anteriores")
    }

    @Test func hasActiveOrdersIsFalseForEmptyProvider() {
        let viewModel = OrdersViewModel(provider: EmptyOrdersContentProvider())
        #expect(!viewModel.hasActiveOrders)
        #expect(viewModel.summaryText == "0 en curso · 0 anteriores")
    }
}

@MainActor
struct HomeTabViewModelOrdersTests {
    @Test func homeTabViewModelOwnsOrdersViewModel() {
        let viewModel = HomeTabViewModel()
        #expect(viewModel.orders.activeOrders.count == 1)
        viewModel.selectedTab = .pedidos
        #expect(viewModel.selectedTab == .pedidos)
    }
}
