//
//  FeedViewModel.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class FeedViewModel {
    private(set) var profile: FeedProfile
    private(set) var offers: [Offer]
    private(set) var recommendations: [Restaurant]
    var searchText: String = ""

    init(provider: FeedContentProviding = MockFeedContentProvider()) {
        profile = provider.profile()
        offers = provider.offers()
        recommendations = provider.recommendations()
    }
}
