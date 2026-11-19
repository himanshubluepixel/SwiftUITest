//
//  MovieListView.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI

struct MovieListView: View {
    @State private var viewModel: MovieListViewModel

    init(section: MovieSection) {
        _viewModel = State(initialValue: MovieListViewModel(section: section))
    }

    var body: some View {
        MovieGrid(movies: viewModel.movies, isLoading: viewModel.isLoading) { viewModel.loadMore()
        }
        .padding(.md)
        .bgColor(.bg)
        .navigationTitle(viewModel.section.title)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear { viewModel.loadMore() }
    }
}

#Preview {
    MovieListView(section: .trending).environment(Router())
}

