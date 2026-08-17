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

    init(feed: FeedViewModel = FeedViewModel()) {
        self.feed = feed
    }
}
