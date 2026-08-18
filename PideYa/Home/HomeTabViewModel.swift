//
//  HomeTabViewModel.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeTabViewModel {
    var selectedTab: HomeTab = .inicio
    let feed: FeedViewModel
    let orders: OrdersViewModel

    init(feed: FeedViewModel = FeedViewModel(), orders: OrdersViewModel = OrdersViewModel()) {
        self.feed = feed
        self.orders = orders
    }
}
