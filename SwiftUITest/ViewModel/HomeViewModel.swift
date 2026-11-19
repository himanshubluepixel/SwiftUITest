//
//  HomeViewModel.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//
import SwiftUI
import Combine

@MainActor
@Observable
class HomeViewModel {
    var sections: [MovieSection: [Movie]] = [:]
    var isOffline = false
    var error: String?

    init()
    {
        load()
    }
    func load() {
        isOffline = false
        error = nil
        for s in MovieSection.allCases {
            APIManager.shared.request(s.path, as: Paged<Movie>.self) { [weak self] result, fromCache in
                switch result {

                case .success(let page):

                    self?.sections[s] = page.results

                    print("Loaded \(page.results.count) movies")

                    if fromCache { self?.isOffline = true }

                case .failure(let e):
                    self?.error = e.localizedDescription
                }
            }
        }
    }
}


