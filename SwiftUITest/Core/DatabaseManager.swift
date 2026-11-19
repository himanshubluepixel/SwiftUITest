//
//  DatabaseManager.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import Foundation
import SwiftData
import Observation

/// The ONLY table. Holds both API cache and favourites as raw JSON.
@Model
final class StoredJSON {
    @Attribute(.unique) var key: String
    var kind: String          // "cache" | "favourite"
    var data: Data
    var updatedAt: Date
    init(key: String, kind: String, data: Data) {
        self.key = key; self.kind = kind; self.data = data; self.updatedAt = .now
    }
}

enum StoreKind: String { case cache, favourite }

@MainActor @Observable
final class DatabaseManager {
    static let shared = DatabaseManager()

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private(set) var favouriteIDs: Set<Int> = []   // drives heart icons
    private(set) var changeToken = 0               // makes views refresh on any favourite change

    private init() {
        container = try! ModelContainer(for: StoredJSON.self)
        favouriteIDs = Set(rows(kind: .favourite).compactMap { Int($0.key.dropFirst(4)) })
    }

    // MARK: Raw JSON (used by APIManager)
    func save(_ data: Data, key: String, kind: StoreKind = .cache) {
        if let r = row(key) { r.data = data; r.updatedAt = .now }
        else { context.insert(StoredJSON(key: key, kind: kind.rawValue, data: data)) }
        try? context.save()
    }
    func load(key: String) -> Data? { row(key)?.data }

    func clearCache() {
        rows(kind: .cache).forEach { context.delete($0) }
        try? context.save()
    }

    // MARK: Favourites
    func isFavourite(_ id: Int) -> Bool { favouriteIDs.contains(id) }

    func toggleFavourite(_ movie: Movie) {
        let key = "fav_\(movie.id)"
        if favouriteIDs.contains(movie.id) {
            if let r = row(key) { context.delete(r); try? context.save() }
            favouriteIDs.remove(movie.id)
        } else {
            if let data = try? APIManager.encoder.encode(movie) { save(data, key: key, kind: .favourite) }
            favouriteIDs.insert(movie.id)
        }
        changeToken += 1
    }

    /// Call inside a view body. Reading changeToken registers observation, so the list auto-refreshes
    func favourites() -> [Movie] {
        _ = changeToken
        return rows(kind: .favourite).compactMap { try? APIManager.decoder.decode(Movie.self, from: $0.data) }
    }
    func favourite(id: Int) -> Movie? {
        load(key: "fav_\(id)").flatMap { try? APIManager.decoder.decode(Movie.self, from: $0) }
    }

    // MARK: Private
    private func row(_ key: String) -> StoredJSON? {
        var d = FetchDescriptor<StoredJSON>(predicate: #Predicate { $0.key == key })
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }
    private func rows(kind: StoreKind) -> [StoredJSON] {
        let k = kind.rawValue
        let d = FetchDescriptor<StoredJSON>(predicate: #Predicate { $0.kind == k },
                                            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(d)) ?? []
    }
}
