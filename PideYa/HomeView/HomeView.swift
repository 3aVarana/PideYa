//
//  HomeView.swift
//  PideYa
//
//  Created by Victor Arana on 16/8/26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(viewModel.title)
        }
    }

    private var content: some View {
        ContentUnavailableView(
            "Nothing here yet",
            systemImage: "storefront",
            description: Text("Listings will show up here.")
        )
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
