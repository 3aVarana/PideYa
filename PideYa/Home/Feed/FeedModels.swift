//
//  FeedModels.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation

private let esES = Locale(identifier: "es_ES")

nonisolated struct Offer: Identifiable, Hashable, Sendable {
    let id: UUID
    let restaurantName: String
    let bannerText: String
    let cuisine: String
    let etaMinutes: ClosedRange<Int>
}

nonisolated struct Restaurant: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let cuisine: String
    let rating: Double
    let etaMinutes: ClosedRange<Int>
    let promotion: String?
    let deliveryFee: Decimal
}

nonisolated struct FeedProfile: Hashable, Sendable {
    let initials: String
    let addressLine: String
}

nonisolated extension ClosedRange where Bound == Int {
    /// e.g. `25...35` → `"25-35 min"`. Plain interpolation on purpose: no grouping separators wanted.
    var etaText: String {
        "\(lowerBound)-\(upperBound) min"
    }
}

extension Restaurant {
    var ratingText: String {
        rating.formatted(.number.precision(.fractionLength(1)).locale(esES))
    }

    var deliveryFeeText: String {
        deliveryFee.formatted(.currency(code: "EUR").locale(esES))
    }

    var etaText: String {
        etaMinutes.etaText
    }

    var subtitleText: String {
        "\(cuisine) · ★ \(ratingText)"
    }
}

extension Offer {
    var etaText: String {
        etaMinutes.etaText
    }

    var subtitleText: String {
        "\(cuisine) · \(etaText)"
    }
}

nonisolated protocol FeedContentProviding: Sendable {
    func profile() -> FeedProfile
    func offers() -> [Offer]
    func recommendations() -> [Restaurant]
}

nonisolated struct MockFeedContentProvider: FeedContentProviding {
    /// A stable, non-optional `UUID` built from a single byte, so seed data never needs to
    /// force-unwrap `UUID(uuidString:)`.
    private static func stableID(_ lastByte: UInt8) -> UUID {
        UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, lastByte))
    }

    // Stable IDs (rather than `UUID()` minted per call) so `Identifiable` identity stays
    // constant across repeated calls, keeping `ForEach` diffing correct if a future refresh
    // calls the provider more than once.
    private static let seedOffers: [Offer] = [
        Offer(
            id: stableID(1),
            restaurantName: "Taquería Norte",
            bannerText: "-40% · HASTA LAS 23:00",
            cuisine: "Mexicana",
            etaMinutes: 25...35
        ),
        Offer(
            id: stableID(2),
            restaurantName: "Forno Bianco",
            bannerText: "2X1 EN PIZZAS",
            cuisine: "Italiana",
            etaMinutes: 30...40
        ),
    ]

    private static let seedRecommendations: [Restaurant] = [
        Restaurant(
            id: stableID(11),
            name: "Taquería Norte",
            cuisine: "Mexicana",
            rating: 4.8,
            etaMinutes: 25...35,
            promotion: "-40%",
            deliveryFee: 1.90
        ),
        Restaurant(
            id: stableID(12),
            name: "Forno Bianco",
            cuisine: "Italiana",
            rating: 4.7,
            etaMinutes: 30...40,
            promotion: "2X1",
            deliveryFee: 2.50
        ),
        // Casa Lola's ETA is not visible in the mockup; 20...30 is a chosen placeholder.
        Restaurant(
            id: stableID(13),
            name: "Casa Lola",
            cuisine: "Casera",
            rating: 4.9,
            etaMinutes: 20...30,
            promotion: nil,
            deliveryFee: 0
        ),
    ]

    func profile() -> FeedProfile {
        FeedProfile(initials: "VA", addressLine: "Calle Mayor 44")
    }

    func offers() -> [Offer] {
        Self.seedOffers
    }

    func recommendations() -> [Restaurant] {
        Self.seedRecommendations
    }
}
