//
//  YouTubeBackendService.swift
//  Kids TV - uses Firebase Functions for caching/rate limiting
//

import Foundation

final class YouTubeBackendService {
    static let shared = YouTubeBackendService()
    private let baseURL = "https://us-central1-kids-attention-app.cloudfunctions.net"
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    private init() {}

    func searchVideos(query: String, maxResults: Int = 25) async throws -> [VideoModel] {
        var comp = URLComponents(string: "\(baseURL)/youtubeSearch")!
        comp.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "\(maxResults)")
        ]
        guard let url = comp.url else { throw NSError(domain: "Backend", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]) }
        let (data, resp) = try await session.data(from: url)
        guard let http = resp as? HTTPURLResponse else { throw NSError(domain: "Backend", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]) }
        if http.statusCode != 200 {
            let err = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] ?? "Unknown error"
            throw NSError(domain: "Backend", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(err)"])
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw NSError(domain: "Backend", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        return items.compactMap { VideoModel.fromYouTubeItem($0) }
    }

    func getVideoDetails(videoId: String) async throws -> VideoModel? {
        var comp = URLComponents(string: "\(baseURL)/youtubeVideo")!
        comp.queryItems = [URLQueryItem(name: "id", value: videoId)]
        guard let url = comp.url else { return nil }
        let (data, resp) = try await session.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]],
              let first = items.first else { return nil }
        return VideoModel.fromYouTubeItem(first)
    }
}
