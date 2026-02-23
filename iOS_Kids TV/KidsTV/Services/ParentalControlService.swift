//
//  ParentalControlService.swift
//  Kids TV
//

import Foundation
import CryptoKit

final class ParentalControlService {
    static let shared = ParentalControlService()
    private let storage = StorageService.shared

    private static let defaultInappropriateKeywords = [
        "violence", "fight", "war", "gun", "weapon", "kill", "death", "murder", "blood", "gore",
        "adult", "mature", "explicit", "nsfw", "sexy", "nude", "naked", "porn", "xxx",
        "curse", "swear", "bad words", "profanity", "damn", "hell",
        "horror", "scary", "frightening", "terrifying", "ghost", "zombie", "demon", "monster",
        "drugs", "alcohol", "smoking", "gambling", "casino", "beer", "wine", "cigarette",
        "18+", "adults only", "not for kids", "parental guidance", "rated r", "mature content",
        "suicide", "self harm", "hate", "racism"
    ]

    private init() {}

    func getSettings() -> SettingsModel { storage.getSettings() }
    func saveSettings(_ settings: SettingsModel) { storage.saveSettings(settings) }

    func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    func verifyPassword(_ password: String, storedHash: String?) -> Bool {
        guard let stored = storedHash else { return false }
        return hashPassword(password) == stored
    }

    func checkPassword(_ password: String) -> Bool {
        let settings = getSettings()
        guard let hash = settings.parentPasswordHash else { return true }
        return verifyPassword(password, storedHash: hash)
    }

    func setPassword(_ password: String) {
        var settings = getSettings()
        settings.parentPasswordHash = hashPassword(password)
        saveSettings(settings)
    }

    func isTimeLimitExceeded() -> Bool {
        let settings = getSettings()
        guard settings.parentalControlsEnabled, let limit = settings.dailyTimeLimitMinutes else { return false }
        let usage = storage.getDailyUsage()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if usage.date != today {
            storage.resetDailyUsage()
            return false
        }
        return usage.minutesUsed >= limit
    }

    func getRemainingTimeMinutes() -> Int {
        let settings = getSettings()
        guard settings.parentalControlsEnabled, let limit = settings.dailyTimeLimitMinutes else { return -1 }
        let usage = storage.getDailyUsage()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if usage.date != today {
            storage.resetDailyUsage()
            return limit
        }
        return max(0, limit - usage.minutesUsed)
    }

    func recordVideoWatch(minutesWatched: Int) {
        let settings = getSettings()
        guard settings.parentalControlsEnabled else { return }
        let usage = storage.getDailyUsage()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        var minutes = usage.minutesUsed
        if usage.date != today { minutes = 0 }
        storage.updateDailyUsage(minutesUsed: minutes + minutesWatched)
    }

    private func containsBlockedKeyword(_ text: String, keyword: String) -> Bool {
        let lower = text.lowercased()
        let kw = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        if kw.isEmpty { return false }
        if kw.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
            let pattern = kw.split(separator: " ").map { NSRegularExpression.escapedPattern(for: String($0)) }.joined(separator: "\\s+")
            let regex = try? NSRegularExpression(pattern: "\\b\(pattern)\\b")
            let range = NSRange(lower.startIndex..., in: lower)
            return regex?.firstMatch(in: lower, range: range) != nil
        }
        return lower.contains(kw)
    }

    func isVideoAllowed(_ video: VideoModel) -> Bool {
        let settings = getSettings()
        let combined = "\(video.title) \(video.description) \(video.channelTitle)".lowercased()
        let channelLower = video.channelTitle.lowercased()

        for kw in ParentalControlService.defaultInappropriateKeywords {
            if containsBlockedKeyword(combined, keyword: kw) { return false }
        }
        if settings.parentalControlsEnabled {
            for kw in settings.blockedKeywords where containsBlockedKeyword(combined, keyword: kw) { return false }
            for ch in settings.blacklistedChannels where channelLower.contains(ch.lowercased()) { return false }
            if !settings.whitelistedChannels.isEmpty {
                let allowed = settings.whitelistedChannels.contains { channelLower.contains($0.lowercased()) }
                if !allowed { return false }
            }
        }
        return true
    }

    func shouldShowBreakReminder(minutesWatched: Int) -> Bool {
        let settings = getSettings()
        guard settings.breakRemindersEnabled, let interval = settings.breakIntervalMinutes else { return false }
        return minutesWatched > 0 && minutesWatched % interval == 0
    }

    func getBreakDurationMinutes() -> Int {
        getSettings().breakDurationMinutes ?? Constants.defaultBreakDurationMinutes
    }
}
