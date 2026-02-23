//
//  Constants.swift
//  Kids TV
//

import Foundation

enum Constants {
    static let youtubeBaseUrl = "https://www.googleapis.com/youtube/v3"
    static let searchEndpoint = "/search"
    static let videosEndpoint = "/videos"
    static let categoriesEndpoint = "/videoCategories"
    static let maxSearchResults = 50
    static let defaultTimeLimitMinutes = 60
    static let defaultBreakIntervalMinutes = 30
    static let defaultBreakDurationMinutes = 5

    static let playlistsKey = "playlists"
    static let settingsKey = "settings"
    static let watchHistoryKey = "watch_history"
    static let dailyUsageKey = "daily_usage"
    static let weeklyUsageKey = "weekly_usage"
    static let curatedVideosKey = "curated_videos"
    static let searchHistoryKey = "search_history"
    static let themeModeKey = "theme_mode"

    /// YouTube API keys: read from Info.plist YOUTUBE_API_KEYS array or env
    static var youtubeApiKeys: [String] {
        if let keys = Bundle.main.object(forInfoDictionaryKey: "YOUTUBE_API_KEYS") as? [String], !keys.isEmpty {
            return keys.filter { !$0.isEmpty && $0 != "your_youtube_api_key_here" }
        }
        if let key = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"], !key.isEmpty {
            return [key]
        }
        return []
    }

    static var youtubeApiKey: String { youtubeApiKeys.first ?? "" }
    static var hasValidApiKey: Bool { !youtubeApiKeys.isEmpty }

    struct KidCategory: Identifiable {
        let id: String
        let title: String
        let query: String
        let iconName: String
    }

    static let kidCategories: [KidCategory] = [
        KidCategory(id: "nursery_rhymes", title: "Nursery Rhymes", query: "nursery rhymes for kids", iconName: "music.note"),
        KidCategory(id: "cartoons", title: "Cartoons", query: "cartoons for children safe", iconName: "tv"),
        KidCategory(id: "learning_abc", title: "ABCs & 123s", query: "alphabet and numbers for kids learning", iconName: "textformat.abc"),
        KidCategory(id: "animals", title: "Animals", query: "animals for kids educational", iconName: "pawprint.fill"),
        KidCategory(id: "stories", title: "Stories", query: "bedtime stories for kids", iconName: "book.fill"),
        KidCategory(id: "science", title: "Science Fun", query: "science experiments for kids easy", iconName: "flask.fill"),
        KidCategory(id: "arts_crafts", title: "Arts & Crafts", query: "easy crafts for kids", iconName: "paintpalette.fill"),
        KidCategory(id: "dancing", title: "Dance Along", query: "dance songs for kids", iconName: "figure.run"),
        KidCategory(id: "nature", title: "Nature", query: "nature videos for children", iconName: "leaf.fill"),
        KidCategory(id: "cooking", title: "Kids Cooking", query: "easy cooking for kids recipes", iconName: "frying.pan.fill"),
        KidCategory(id: "superheroes", title: "Superheroes", query: "superhero cartoons for kids", iconName: "bolt.fill"),
        KidCategory(id: "dinosaurs", title: "Dinosaurs", query: "dinosaurs for kids educational", iconName: "lizard.fill"),
        KidCategory(id: "space", title: "Space", query: "space videos for kids planets", iconName: "sparkles"),
        KidCategory(id: "vehicles", title: "Cars & Trucks", query: "vehicles for kids trucks cars trains", iconName: "car.fill"),
        KidCategory(id: "princess", title: "Princess", query: "princess stories for kids", iconName: "crown.fill"),
        KidCategory(id: "funny", title: "Funny Videos", query: "funny videos for kids clean", iconName: "face.smiling.fill")
    ]
}
