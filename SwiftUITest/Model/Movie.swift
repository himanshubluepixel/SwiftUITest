//
//  Movie.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import Foundation

// MARK: Models. ONE Movie model serves list, detail and favourites (detail-only fields are optional)
struct Movie: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    // detail only
    let runtime: Int?
    let tagline: String?
    let genres: [Genre]?
    let credits: Credits?
    let videos: VideoList?

    var posterURL: URL? { TMDB.image(posterPath) }
    var backdropURL: URL? { TMDB.image(backdropPath, size: "w780") }
    var year: String { String((releaseDate ?? "").prefix(4)) }
    var rating: String { String(format: "%.1f", voteAverage ?? 0) }
    var trailerKey: String? {
        videos?.results.first { $0.site == "YouTube" && $0.type == "Trailer" }?.key
    }
}

struct Genre: Codable, Hashable { let id: Int; let name: String }
struct Credits: Codable, Hashable { let cast: [Cast] }
struct Cast: Codable, Identifiable, Hashable {
    let id: Int; let name: String; let character: String?; let profilePath: String?
}
struct VideoList: Codable, Hashable { let results: [Video] }
struct Video: Codable, Identifiable, Hashable {
    let id: String; let key: String; let site: String; let type: String; let name: String
}

/// Wrapper for every list endpoint:  Paged<Movie>
struct Paged<T: Codable>: Codable {
    let page: Int
    let results: [T]
    let totalPages: Int
}
