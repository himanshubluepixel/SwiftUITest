//
//  ApiKeys.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//
import Foundation

enum TMDB {
    static let baseURL = "https://api.themoviedb.org/3"
    static let token = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJiZTg0YmE3MGIwNzJmMjRhZTA0YmM0MDJhYmUxMmFjZiIsIm5iZiI6MTc5NTA3NDAxNy41NjksInN1YiI6IjZhZmVhN2UxNTA4ZDVmMDhmOTgyYTIxZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.wweTQnWI7MEwBWClHrJ5_IOMfruOukZlebw-6nv3eO0"

    static func image(_ path: String?, size: String = "w500") -> URL? {
        guard let path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }
}

enum MovieSection: String, CaseIterable, Hashable {
    case trending, nowPlaying, popular, topRated, upcoming

    var title: String {
        switch self {
        case .trending: "Trending"
        case .nowPlaying: "Now Playing"
        case .popular: "Popular"
        case .topRated: "Top Rated"
        case .upcoming: "Upcoming"
        }
    }
    var path: String {
        switch self {
        case .trending: "/trending/movie/day"
        case .nowPlaying: "/movie/now_playing"
        case .popular: "/movie/popular"
        case .topRated: "/movie/top_rated"
        case .upcoming: "/movie/upcoming"
        }
    }
}
