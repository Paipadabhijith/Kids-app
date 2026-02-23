//
//  StorageService.swift
//  Kids TV
//

import Foundation
import Combine

final class StorageService: ObservableObject {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard
    private let apiCachePrefix = "api_cache_"

    private init() {}

    // MARK: - Playlists
    func getPlaylists() -> [PlaylistModel] {
        guard let data = defaults.data(forKey: Constants.playlistsKey),
              let decoded = try? JSONDecoder().decode([PlaylistModel].self, from: data) else { return [] }
        return decoded
    }

    func savePlaylists(_ playlists: [PlaylistModel]) {
        if let data = try? JSONEncoder().encode(playlists) {
            defaults.set(data, forKey: Constants.playlistsKey)
        }
    }

    // MARK: - Settings
    func getSettings() -> SettingsModel {
        guard let data = defaults.data(forKey: Constants.settingsKey),
              let decoded = try? JSONDecoder().decode(SettingsModel.self, from: data) else { return SettingsModel() }
        return decoded
    }

    func saveSettings(_ settings: SettingsModel) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Constants.settingsKey)
        }
    }

    // MARK: - Theme
    func getThemeModePreference() -> String? {
        defaults.string(forKey: Constants.themeModeKey)
    }

    func saveThemeModePreference(_ value: String) {
        defaults.set(value, forKey: Constants.themeModeKey)
    }

    // MARK: - Watch history (profile-scoped)
    private func watchHistoryKey(profileId: String?) -> String {
        guard let id = profileId, !id.isEmpty else { return Constants.watchHistoryKey }
        return "\(Constants.watchHistoryKey)_\(id)"
    }

    func getWatchHistory(profileId: String? = nil) -> [VideoModel] {
        let key = watchHistoryKey(profileId: profileId)
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([VideoModel].self, from: data) else { return [] }
        return decoded
    }

    func addToWatchHistory(_ video: VideoModel, profileId: String? = nil) {
        var history = getWatchHistory(profileId: profileId)
        history.removeAll { $0.id == video.id }
        history.insert(video, at: 0)
        if history.count > 100 { history = Array(history.prefix(100)) }
        let key = watchHistoryKey(profileId: profileId)
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: key)
        }
    }

    func clearWatchHistory(profileId: String? = nil) {
        defaults.removeObject(forKey: watchHistoryKey(profileId: profileId))
    }

    // MARK: - Daily usage
    struct DailyUsage {
        var date: String
        var minutesUsed: Int
    }

    func getDailyUsage() -> DailyUsage {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        guard let data = defaults.data(forKey: Constants.dailyUsageKey),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return DailyUsage(date: today, minutesUsed: 0)
        }
        let date = raw["date"] as? String ?? today
        let minutes = raw["minutesUsed"] as? Int ?? 0
        return DailyUsage(date: date, minutesUsed: minutes)
    }

    func updateDailyUsage(minutesUsed: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        var usage = getDailyUsage()
        if usage.date != today { usage.date = today; usage.minutesUsed = 0 }
        usage.minutesUsed = minutesUsed
        let payload: [String: Any] = ["date": usage.date, "minutesUsed": usage.minutesUsed]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            defaults.set(data, forKey: Constants.dailyUsageKey)
        }
    }

    func resetDailyUsage() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let payload: [String: Any] = ["date": formatter.string(from: Date()), "minutesUsed": 0]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            defaults.set(data, forKey: Constants.dailyUsageKey)
        }
    }

    func getTodayUsage() -> Int { getDailyUsage().minutesUsed }

    // MARK: - Curated videos
    func getCuratedVideos() -> [VideoModel] {
        guard let data = defaults.data(forKey: Constants.curatedVideosKey),
              let decoded = try? JSONDecoder().decode([VideoModel].self, from: data) else { return [] }
        return decoded
    }

    func saveCuratedVideos(_ videos: [VideoModel]) {
        if let data = try? JSONEncoder().encode(videos) {
            defaults.set(data, forKey: Constants.curatedVideosKey)
        }
    }

    func addCuratedVideo(_ video: VideoModel) {
        var list = getCuratedVideos()
        if !list.contains(where: { $0.id == video.id }) {
            list.append(video)
            saveCuratedVideos(list)
        }
    }

    func removeCuratedVideo(id: String) {
        var list = getCuratedVideos()
        list.removeAll { $0.id == id }
        saveCuratedVideos(list)
    }

    // MARK: - Child profiles
    func getChildProfiles() -> [ChildProfileModel] {
        guard let data = defaults.data(forKey: "child_profiles"),
              let decoded = try? JSONDecoder().decode([ChildProfileModel].self, from: data) else { return [] }
        return decoded
    }

    func saveChildProfiles(_ profiles: [ChildProfileModel]) {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: "child_profiles")
        }
    }

    func getActiveProfile() -> ChildProfileModel? {
        getChildProfiles().first { $0.isActive }
    }

    // MARK: - API cache (TTL)
    func getCachedApiData(key: String, maxAge: TimeInterval) -> [String: Any]? {
        let fullKey = "\(apiCachePrefix)\(key)"
        guard let data = defaults.data(forKey: fullKey),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ts = json["timestampMs"] as? Int,
              Date().timeIntervalSince1970 * 1000 - Double(ts) <= maxAge * 1000,
              let payload = json["data"] as? [String: Any] else { return nil }
        return payload
    }

    func setCachedApiData(key: String, data: [String: Any]) {
        let fullKey = "\(apiCachePrefix)\(key)"
        let payload: [String: Any] = [
            "timestampMs": Int(Date().timeIntervalSince1970 * 1000),
            "data": data
        ]
        if let encoded = try? JSONSerialization.data(withJSONObject: payload) {
            defaults.set(encoded, forKey: fullKey)
        }
    }
}

