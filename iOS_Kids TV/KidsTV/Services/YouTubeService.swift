//
//  YouTubeService.swift
//  Kids TV
//

import Foundation

final class YouTubeService {
    static let shared = YouTubeService()
    private let keyService = ApiKeyService.shared
    private let storage = StorageService.shared
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        return URLSession(configuration: c)
    }()

    private init() {}

    static func sanitizeSearchQuery(_ query: String) -> String {
        let bad = ["violence", "adult", "explicit", "nsfw", "horror", "scary", "drugs", "alcohol", "18+", "mature", "curse", "swear", "gun", "weapon", "kill", "death", "blood", "gore"]
        var s = query.lowercased()
        for term in bad { s = s.replacingOccurrences(of: term, with: "") }
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        if s.isEmpty { s = "kids videos" }
        if !s.contains("kids") && !s.contains("children") && !s.contains("child") {
            s = "\(s) for kids"
        }
        return s
    }

    func searchVideos(query: String, maxResults: Int = 25) async throws -> [VideoModel] {
        let key = keyService.getCurrentKey()
        guard !key.isEmpty else { throw NSError(domain: "YouTube", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API key"]) }
        let q = YouTubeService.sanitizeSearchQuery(query)
        var comp = URLComponents(string: "\(Constants.youtubeBaseUrl)/search")!
        comp.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "videoEmbeddable", value: "true"),
            URLQueryItem(name: "safeSearch", value: "strict"),
            URLQueryItem(name: "maxResults", value: "\(min(maxResults, 50))"),
            URLQueryItem(name: "key", value: key)
        ]
        guard let url = comp.url else { throw NSError(domain: "YouTube", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]) }
        let (data, resp) = try await session.data(from: url)
        if let http = resp as? HTTPURLResponse, http.statusCode == 403 {
            if keyService.isQuotaError(NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "quota"])) {
                if keyService.hasNextKey && keyService.rotateToNextKey() {
                    return try await searchVideos(query: query, maxResults: maxResults)
                }
            }
            throw NSError(domain: "YouTube", code: 403, userInfo: [NSLocalizedDescriptionKey: "API quota exceeded"])
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw NSError(domain: "YouTube", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        var videos: [VideoModel] = []
        for item in items {
            if let video = VideoModel.fromYouTubeSearchItem(item) {
                videos.append(video)
            }
        }
        return videos
    }

    func getTrendingKidsShows(maxResults: Int = 25) async throws -> [VideoModel] {
        let queries = ["kids shows for children", "educational videos for kids", "kids cartoons", "nursery rhymes for kids", "kids songs"]
        var all: [VideoModel] = []
        for q in queries {
            if let list = try? await searchVideos(query: q, maxResults: (maxResults / queries.count) + 2) {
                all.append(contentsOf: list)
            }
        }
        var seen: Set<String> = []
        return all.filter { seen.insert($0.id).inserted }
            .sorted { ($1.viewCount ?? 0) > ($0.viewCount ?? 0) }
            .prefix(maxResults)
            .map { $0 }
    }

    func getVideoDetails(videoId: String) async throws -> VideoModel? {
        let key = keyService.getCurrentKey()
        guard !key.isEmpty else { return nil }
        var comp = URLComponents(string: "\(Constants.youtubeBaseUrl)/videos")!
        comp.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "id", value: videoId),
            URLQueryItem(name: "key", value: key)
        ]
        guard let url = comp.url else { return nil }
        let (data, _) = try await session.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]],
              let first = items.first else { return nil }
        return VideoModel.fromYouTubeItem(first)
    }
}
