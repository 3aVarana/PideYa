//
//  PideYaApp.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

@main
struct PideYaApp: App {
    var body: some Scene {
        WindowGroup {
            HomeTabView(viewModel: HomeTabViewModel())
        }
    }
}
