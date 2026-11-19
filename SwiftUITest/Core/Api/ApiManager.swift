//
//  ApiManager.swift
//  SwiftUITest
//
//  Created by Himanshu Fulwani on 19/11/26.
//

import Foundation
import Combine

enum APIError: LocalizedError {
    case invalidURL, noData, server(Int), decoding(String), network(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL."
        case .noData: "No response from server."
        case .server(let c): "Server error (\(c))."
        case .decoding(let m): "Could not read data: \(m)"
        case .network(let m): m
        }
    }
}

final class APIManager {
    static let shared = APIManager()
    private init() {}

    static let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d
    }()
    static let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.keyEncodingStrategy = .convertToSnakeCase; return e
    }()

    private let queue = DispatchQueue(label: "api.background", qos: .userInitiated)
    private var bag: [UUID: AnyCancellable] = [:]     // all cancellables live here
    private var tagged: [String: UUID] = [:]          // lets you cancel/replace by tag

    /// Call from main thread (view models). `completion` is always called on main.
    /// - path: "/movie/popular" (base URL added) or a full "https://..." URL
    /// - cache: save JSON on success and fall back to it on failure
    /// - tag: a new request with the same tag cancels the old one (use for search/pagination)
    func request<T: Decodable>(
        _ path: String,
        query: [String: String] = [:],
        as type: T.Type,
        cache: Bool = true,
        tag: String? = nil,
        completion: @escaping (_ result: Result<T, APIError>, _ fromCache: Bool) -> Void
    ) {
        guard let url = makeURL(path, query) else { completion(.failure(.invalidURL), false); return }
        let key = url.absoluteString        // cache key = full URL (token is in header, not URL)

        var req = URLRequest(url: url)
        req.timeoutInterval = 15
        req.setValue("Bearer \(TMDB.token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "accept")

        if let tag { cancel(tag: tag) }
        let id = UUID()

        let cancellable = URLSession.shared.dataTaskPublisher(for: req)
            .receive(on: queue)                                   // validate + decode OFF the main thread
            .tryMap { out -> (T, Data) in
                guard let http = out.response as? HTTPURLResponse else { throw APIError.noData }
                guard (200..<300).contains(http.statusCode) else { throw APIError.server(http.statusCode) }
                do { return (try APIManager.decoder.decode(T.self, from: out.data), out.data) }
                catch { throw APIError.decoding(error.localizedDescription) }
            }
            .mapError { ($0 as? APIError) ?? .network($0.localizedDescription) }
            .receive(on: DispatchQueue.main)                      // result delivered ON main
            .sink(receiveCompletion: { [weak self] done in
                if case .failure(let err) = done {
                    // network failed -> try offline copy
                    let cached = cache ? MainActor.assumeIsolated { DatabaseManager.shared.load(key: key) } : nil
                    if let cached, let value = try? APIManager.decoder.decode(T.self, from: cached) {
                        completion(.success(value), true)
                    } else {
                        completion(.failure(err), false)
                    }
                }
                self?.finish(id, tag)
            }, receiveValue: { value, raw in
                if cache { MainActor.assumeIsolated { DatabaseManager.shared.save(raw, key: key) } }
                completion(.success(value), false)
            })

        bag[id] = cancellable
        if let tag { tagged[tag] = id }
    }

    func cancel(tag: String) {
        guard let id = tagged.removeValue(forKey: tag) else { return }
        bag[id]?.cancel(); bag[id] = nil
    }
    func cancelAll() { bag.values.forEach { $0.cancel() }; bag.removeAll(); tagged.removeAll() }

    private func finish(_ id: UUID, _ tag: String?) {
        bag[id] = nil
        if let tag, tagged[tag] == id { tagged[tag] = nil }
    }

    private func makeURL(_ path: String, _ query: [String: String]) -> URL? {
        var comps = URLComponents(string: path.hasPrefix("http") ? path : TMDB.baseURL + path)
        let q = ["language": "en-US"].merging(query) { _, new in new }
        comps?.queryItems = q.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return comps?.url
    }
}
