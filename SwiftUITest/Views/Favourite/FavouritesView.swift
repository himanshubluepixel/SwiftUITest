//
//  FavouritesView.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI

struct FavouritesView: View {
    var body: some View {
        let movies = DatabaseManager.shared.favourites()
        Group {
            if movies.isEmpty {
               emptyState
            } else {
                MovieGrid(movies: movies)
            }
        }
        .padding(.md)
        .bgColor(.bg)
        .navigationTitle("Favourites")
        .navigationBarTitleDisplayMode(.large)
    }
}


#Preview {
    FavouritesView()
}

extension FavouritesView {
    private var emptyState: some View {
        ContentUnavailableView("No favourites yet", image: "heart", description:  Text("Tap the heart on any movie to save it for offline viewing."))
    }
}

