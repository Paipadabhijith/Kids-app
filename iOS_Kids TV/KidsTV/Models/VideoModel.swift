//
//  VideoModel.swift
//  Kids TV
//

import Foundation

struct VideoModel: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var description: String
    var thumbnailUrl: String
    var channelTitle: String
    var duration: String?
    var publishedAt: Date?
    var viewCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description, thumbnailUrl, channelTitle, duration, publishedAt, viewCount
    }

    init(
        id: String,
        title: String,
        description: String,
        thumbnailUrl: String,
        channelTitle: String,
        duration: String? = nil,
        publishedAt: Date? = nil,
        viewCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.thumbnailUrl = thumbnailUrl
        self.channelTitle = channelTitle
        self.duration = duration
        self.publishedAt = publishedAt
        self.viewCount = viewCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        thumbnailUrl = try c.decode(String.self, forKey: .thumbnailUrl)
        channelTitle = try c.decode(String.self, forKey: .channelTitle)
        duration = try c.decodeIfPresent(String.self, forKey: .duration)
        if let dateStr = try c.decodeIfPresent(String.self, forKey: .publishedAt) {
            publishedAt = ISO8601DateFormatter().date(from: dateStr)
        } else {
            publishedAt = nil
        }
        viewCount = try c.decodeIfPresent(Int.self, forKey: .viewCount)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(thumbnailUrl, forKey: .thumbnailUrl)
        try c.encode(channelTitle, forKey: .channelTitle)
        try c.encodeIfPresent(duration, forKey: .duration)
        try c.encodeIfPresent(publishedAt.flatMap { ISO8601DateFormatter().string(from: $0) }, forKey: .publishedAt)
        try c.encodeIfPresent(viewCount, forKey: .viewCount)
    }

    /// Create from YouTube search API item (id may be object with videoId)
    static func fromYouTubeSearchItem(_ item: [String: Any]) -> VideoModel? {
        let snippet = item["snippet"] as? [String: Any] ?? [:]
        let thumbnails = snippet["thumbnails"] as? [String: Any] ?? [:]
        let high = thumbnails["high"] as? [String: Any]
        let def = thumbnails["default"] as? [String: Any]
        let thumbUrl = (high?["url"] ?? def?["url"]) as? String ?? ""
        var videoId = ""
        if let idStr = item["id"] as? String { videoId = idStr }
        else if let idObj = item["id"] as? [String: Any], let vId = idObj["videoId"] as? String { videoId = vId }
        else { return nil }
        var publishedAt: Date?
        if let dateStr = snippet["publishedAt"] as? String {
            publishedAt = ISO8601DateFormatter().date(from: dateStr)
        }
        return VideoModel(
            id: videoId,
            title: snippet["title"] as? String ?? "",
            description: snippet["description"] as? String ?? "",
            thumbnailUrl: thumbUrl,
            channelTitle: snippet["channelTitle"] as? String ?? "",
            duration: nil,
            publishedAt: publishedAt,
            viewCount: nil
        )
    }

    /// Create from YouTube videos API response (snippet + contentDetails)
    static func fromYouTubeItem(_ item: [String: Any]) -> VideoModel? {
        let snippet = item["snippet"] as? [String: Any] ?? [:]
        let contentDetails = item["contentDetails"] as? [String: Any] ?? [:]
        let thumbnails = snippet["thumbnails"] as? [String: Any] ?? [:]
        let high = thumbnails["high"] as? [String: Any]
        let def = thumbnails["default"] as? [String: Any]
        let thumbUrl = (high?["url"] ?? def?["url"]) as? String ?? ""

        let videoId: String
        if let idStr = item["id"] as? String {
            videoId = idStr
        } else if let idObj = item["id"] as? [String: Any], let vId = idObj["videoId"] as? String {
            videoId = vId
        } else {
            return nil
        }

        var publishedAt: Date?
        if let dateStr = snippet["publishedAt"] as? String {
            publishedAt = ISO8601DateFormatter().date(from: dateStr)
        }

        return VideoModel(
            id: videoId,
            title: snippet["title"] as? String ?? "",
            description: snippet["description"] as? String ?? "",
            thumbnailUrl: thumbUrl,
            channelTitle: snippet["channelTitle"] as? String ?? "",
            duration: contentDetails["duration"] as? String,
            publishedAt: publishedAt,
            viewCount: nil
        )
    }

    /// Parse ISO 8601 duration (e.g. PT1M30S) to seconds
    private static func parseDuration(_ duration: String) -> Int {
        let regex = try? NSRegularExpression(pattern: "PT(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)S)?")
        let range = NSRange(duration.startIndex..., in: duration)
        guard let match = regex?.firstMatch(in: duration, range: range) else { return 0 }
        func group(_ i: Int) -> Int {
            guard let r = Range(match.range(at: i), in: duration) else { return 0 }
            return Int(duration[r]) ?? 0
        }
        return group(1) * 3600 + group(2) * 60 + group(3)
    }

    /// Shorts are ≤60 seconds
    var isShort: Bool {
        if let d = duration {
            let sec = VideoModel.parseDuration(d)
            return sec > 0 && sec <= 60
        }
        let lower = title.lowercased()
        return lower.contains("#shorts") || lower.contains("#short")
    }

    var aspectRatio: CGFloat { isShort ? 9/16 : 16/9 }
}
