//
//  Untitled.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import SwiftUI
import Combine

@MainActor
@Observable

class MovieDetailViewModel {
    var movie: Movie?
    var error: String?
    init(id: Int) { movie = DatabaseManager.shared.favourite(id: id)
        load(id: id)
    }   // instant content if favourited

    func load(id: Int) {
        APIManager.shared.request("/movie/\(id)", query: ["append_to_response": "credits,videos"],
                                  as: Movie.self) { [weak self] result, _ in
            switch result {
            case .success(let m): self?.movie = m
            case .failure(let e): if self?.movie == nil { self?.error = e.localizedDescription }
            }
        }
    }
}
