//
//  ApiKeyService.swift
//  Kids TV
//

import Foundation

final class ApiKeyService {
    static let shared = ApiKeyService()
    private let currentKeyIndexKey = "current_api_key_index"
    private let failedKeysKey = "failed_api_keys"
    private var apiKeys: [String] = []
    private var currentIndex: Int = 0
    private var failedKeys: Set<String> = []

    private init() {
        apiKeys = Constants.youtubeApiKeys
        currentIndex = UserDefaults.standard.integer(forKey: currentKeyIndexKey)
        if currentIndex >= apiKeys.count { currentIndex = 0 }
        if let stored = UserDefaults.standard.string(forKey: failedKeysKey) {
            failedKeys = Set(stored.split(separator: ",").map { String($0) })
        }
    }

    func getCurrentKey() -> String {
        guard !apiKeys.isEmpty else { return "" }
        return apiKeys[currentIndex]
    }

    var hasNextKey: Bool { apiKeys.count > 1 }

    func rotateToNextKey() -> Bool {
        guard apiKeys.count > 1 else { return false }
        failedKeys.insert(apiKeys[currentIndex])
        for _ in 0..<apiKeys.count {
            currentIndex = (currentIndex + 1) % apiKeys.count
            if !failedKeys.contains(apiKeys[currentIndex]) {
                UserDefaults.standard.set(currentIndex, forKey: currentKeyIndexKey)
                UserDefaults.standard.set(failedKeys.joined(separator: ","), forKey: failedKeysKey)
                return true
            }
        }
        failedKeys.removeAll()
        currentIndex = 0
        UserDefaults.standard.set(0, forKey: currentKeyIndexKey)
        UserDefaults.standard.set("", forKey: failedKeysKey)
        return true
    }

    func isQuotaError(_ error: Error) -> Bool {
        let s = error.localizedDescription.lowercased()
        return s.contains("quota") || s.contains("403") || s.contains("quotaexceeded")
    }
}
