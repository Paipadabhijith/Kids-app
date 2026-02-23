//
//  ChildProfileModel.swift
//  Kids TV
//

import Foundation
import SwiftUI

struct ChildProfileModel: Identifiable, Codable {
    let id: String
    var name: String
    var age: Int
    var avatarUrl: String?
    var dailyTimeLimitMinutes: Int
    var blockedKeywords: [String]
    var preferredTopics: [String]
    var whitelistedChannels: [String]
    var blacklistedChannels: [String]
    var calmModeEnabled: Bool
    var createdAt: Date
    var isActive: Bool

    init(
        id: String,
        name: String,
        age: Int,
        avatarUrl: String? = nil,
        dailyTimeLimitMinutes: Int = 60,
        blockedKeywords: [String] = [],
        preferredTopics: [String] = [],
        whitelistedChannels: [String] = [],
        blacklistedChannels: [String] = [],
        calmModeEnabled: Bool = false,
        createdAt: Date? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarUrl = avatarUrl
        self.dailyTimeLimitMinutes = dailyTimeLimitMinutes
        self.blockedKeywords = blockedKeywords
        self.preferredTopics = preferredTopics
        self.whitelistedChannels = whitelistedChannels
        self.blacklistedChannels = blacklistedChannels
        self.calmModeEnabled = calmModeEnabled
        self.createdAt = createdAt ?? Date()
        self.isActive = isActive
    }

    var ageGroup: String {
        if age < 5 { return "Toddler" }
        if age < 8 { return "Young Child" }
        if age < 13 { return "Pre-Teen" }
        return "Teen"
    }

    var profileColor: Color {
        let colors: [Color] = [
            .green, .blue, .orange, .purple, .pink,
            Color(red: 0, green: 0.74, blue: 0.83)
        ]
        return colors[abs(id.hashValue) % colors.count]
    }
}
