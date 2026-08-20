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
    let account: AccountViewModel

    init(
        feed: FeedViewModel = FeedViewModel(),
        orders: OrdersViewModel = OrdersViewModel(),
        account: AccountViewModel = AccountViewModel()
    ) {
        self.feed = feed
        self.orders = orders
        self.account = account
    }
}
