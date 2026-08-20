//
//  AccountViewModel.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class AccountViewModel {
    private(set) var profile: AccountProfile
    private(set) var tiles: [AccountTile]
    private(set) var wallet: AccountWallet

    /// Reads all three provider methods synchronously and assigns. There is no I/O, so there is
    /// no `Task`, no `load()` and no loading/error state; the provider itself is not stored.
    init(provider: AccountContentProviding = MockAccountContentProvider()) {
        profile = provider.profile()
        tiles = provider.tiles()
        wallet = provider.wallet()
    }
}
