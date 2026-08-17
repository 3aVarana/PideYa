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
    private(set) var title: String

    init(title: String = "PideYa") {
        self.title = title
    }
}
