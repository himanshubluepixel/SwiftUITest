//
//  MovieListViewModel.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI
import Combine

@MainActor
@Observable

class MovieListViewModel {
    let section: MovieSection
    var movies: [Movie] = []
    var isLoading = false
    private var page = 1
    private var totalPages = 1
    init(section: MovieSection) { self.section = section }

    func loadMore(current: Movie? = nil) {
        guard !isLoading, page <= totalPages else { return }
        if let current, current.id != movies.last?.id { return }   // call from row .onAppear
        isLoading = true
        APIManager.shared.request(section.path, query: ["page": "\(page)"],
                                  as: Paged<Movie>.self, tag: section.rawValue) { [weak self] result, _ in
            guard let self else { return }
            isLoading = false
            if case .success(let p) = result { movies += p.results.filter { r in !self.movies.contains { $0.id == r.id } }; totalPages = p.totalPages; page += 1 }
        }
    }
}
