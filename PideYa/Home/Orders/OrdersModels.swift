//
//  OrdersModels.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation

// `dateText` and `etaText` below are stored as pre-formatted `String`s, not `Date`s. The
// mockup gives literal values (`"12 ago"`, `"20:45"`) and es-ES abbreviated month names
// round-trip differently across ICU versions (`ago`, `ago.`, `ag.`), so formatting a `Date`
// would make rendering OS-version-dependent and the tests flaky for a screen with no real
// data source. Money and rating stay numeric because their formatters are stable and their
// comma/`€` behaviour is the thing under test. A real backend would carry `Date` and move the
// formatting into a computed property, the same shape these already use.
private nonisolated let esES = Locale(identifier: "es_ES")

nonisolated enum OrderStage: String, CaseIterable, Identifiable, Hashable, Sendable {
    case confirmado
    case enCocina
    case enCamino
    case entregado

    var id: String { rawValue }

    var label: String {
        switch self {
        case .confirmado: "CONFIRMADO"
        case .enCocina: "EN COCINA"
        case .enCamino: "EN CAMINO"
        case .entregado: "ENTREGADO"
        }
    }

    /// Position in the tracker, 0-indexed. An explicit switch rather than
    /// `allCases.firstIndex(of:)!`, since `NeverForceUnwrap` is on.
    var stepIndex: Int {
        switch self {
        case .confirmado: 0
        case .enCocina: 1
        case .enCamino: 2
        case .entregado: 3
        }
    }
}

nonisolated struct ActiveOrder: Identifiable, Hashable, Sendable {
    let id: UUID
    let restaurantName: String
    let total: Decimal
    let itemCount: Int
    let orderNumber: String
    let stage: OrderStage
    let etaText: String
}

nonisolated struct PastOrder: Identifiable, Hashable, Sendable {
    let id: UUID
    let restaurantName: String
    let total: Decimal
    let dateText: String
    let itemCount: Int
    let rating: Double?
}

/// `count == 1 ? "1 artículo" : "\(count) artículos"`, shared by both order types so the
/// singular/plural split is implemented exactly once.
nonisolated private func itemCountText(_ count: Int) -> String {
    count == 1 ? "1 artículo" : "\(count) artículos"
}

nonisolated extension ActiveOrder {
    var totalText: String {
        total.formatted(.currency(code: "EUR").locale(esES))
    }

    var statusText: String {
        stage.label
    }

    var arrivalText: String {
        "LLEGA \(etaText)"
    }

    var subtitleText: String {
        "\(itemCountText(itemCount)) · Pedido #\(orderNumber)"
    }
}

nonisolated extension PastOrder {
    var totalText: String {
        total.formatted(.currency(code: "EUR").locale(esES))
    }

    var subtitleText: String {
        "\(dateText) · \(itemCountText(itemCount))"
    }

    var ratingText: String? {
        rating.map { $0.formatted(.number.precision(.fractionLength(1)).locale(esES)) }
    }

    var isRated: Bool {
        rating != nil
    }
}

nonisolated protocol OrdersContentProviding: Sendable {
    func activeOrders() -> [ActiveOrder]
    func pastOrders() -> [PastOrder]
}

nonisolated struct MockOrdersContentProvider: OrdersContentProviding {
    /// A stable, non-optional `UUID` built from a single byte, so seed data never needs to
    /// force-unwrap `UUID(uuidString:)`. Duplicated from `MockFeedContentProvider` (3 lines)
    /// rather than hoisted, so `FeedModels.swift` stays byte-identical.
    private static func stableID(_ lastByte: UInt8) -> UUID {
        UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, lastByte))
    }

    private static let seedActive: [ActiveOrder] = [
        ActiveOrder(
            id: stableID(1),
            restaurantName: "Taquería Norte",
            total: 24.60,
            itemCount: 3,
            orderNumber: "4821",
            stage: .enCamino,
            etaText: "20:45"
        )
    ]

    // The first three rows are pinned by DESIGN.md §6. Rows 4-12 are invented filler, added so
    // the derived "1 en curso · 12 anteriores" header string matches the mockup honestly.
    private static let seedPast: [PastOrder] = [
        PastOrder(
            id: stableID(21), restaurantName: "Forno Bianco", total: 18.90, dateText: "12 ago", itemCount: 2,
            rating: 5.0
        ),
        PastOrder(
            id: stableID(22), restaurantName: "Casa Lola", total: 31.20, dateText: "9 ago", itemCount: 4,
            rating: nil
        ),
        PastOrder(
            id: stableID(23), restaurantName: "Sakura Ramen", total: 26.50, dateText: "4 ago", itemCount: 2,
            rating: 4.0
        ),
        // Invented filler — not present in DESIGN.md §6.
        PastOrder(
            id: stableID(24), restaurantName: "Taquería Norte", total: 22.40, dateText: "2 ago", itemCount: 3,
            rating: 5.0
        ),
        PastOrder(
            id: stableID(25), restaurantName: "Bar Manolo", total: 14.75, dateText: "30 jul", itemCount: 2,
            rating: nil
        ),
        PastOrder(
            id: stableID(26), restaurantName: "Wok Express", total: 19.30, dateText: "27 jul", itemCount: 3,
            rating: 4.0
        ),
        PastOrder(
            id: stableID(27), restaurantName: "Forno Bianco", total: 27.10, dateText: "24 jul", itemCount: 3,
            rating: 5.0
        ),
        PastOrder(
            id: stableID(28), restaurantName: "La Parrilla", total: 35.80, dateText: "20 jul", itemCount: 5,
            rating: 4.0
        ),
        PastOrder(
            id: stableID(29), restaurantName: "Poke Bowl Co", total: 16.20, dateText: "16 jul", itemCount: 2,
            rating: nil
        ),
        PastOrder(
            id: stableID(30), restaurantName: "Casa Lola", total: 29.95, dateText: "11 jul", itemCount: 4,
            rating: 5.0
        ),
        PastOrder(
            id: stableID(31), restaurantName: "Sakura Ramen", total: 23.40, dateText: "7 jul", itemCount: 2,
            rating: 4.0
        ),
        PastOrder(
            id: stableID(32), restaurantName: "Bar Manolo", total: 12.60, dateText: "2 jul", itemCount: 1,
            rating: nil
        ),
    ]

    func activeOrders() -> [ActiveOrder] {
        Self.seedActive
    }

    func pastOrders() -> [PastOrder] {
        Self.seedPast
    }
}
