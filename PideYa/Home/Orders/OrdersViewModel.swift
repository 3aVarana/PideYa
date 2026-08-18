//
//  OrdersViewModel.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class OrdersViewModel {
    private(set) var activeOrders: [ActiveOrder]
    private(set) var pastOrders: [PastOrder]

    init(provider: OrdersContentProviding = MockOrdersContentProvider()) {
        activeOrders = provider.activeOrders()
        pastOrders = provider.pastOrders()
    }

    var hasActiveOrders: Bool {
        !activeOrders.isEmpty
    }

    /// Derived from the arrays themselves, so this string can never contradict what the list
    /// renders. "en curso" is invariant in Spanish for both 1 and N; "anterior"/"anteriores" is
    /// not.
    var summaryText: String {
        let pastWord = pastOrders.count == 1 ? "anterior" : "anteriores"
        return "\(activeOrders.count) en curso · \(pastOrders.count) \(pastWord)"
    }
}
