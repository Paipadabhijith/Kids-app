//
//  SettingsModel.swift
//  Kids TV
//

import Foundation

struct SettingsModel: Codable {
    var parentalControlsEnabled: Bool
    var dailyTimeLimitMinutes: Int?
    var blockedKeywords: [String]
    var blockedCategories: [String]
    var parentPasswordHash: String?
    var requirePasswordForSettings: Bool
    var lastResetDate: Date?
    var breakRemindersEnabled: Bool
    var breakIntervalMinutes: Int?
    var breakDurationMinutes: Int?
    var calmModeEnabled: Bool
    var calmModeContrast: Double
    var calmModeSaturation: Double
    var calmModeBrightness: Double
    var calmModeWarmth: Double
    var calmModePreset: String?
    var binauralBeatsEnabled: Bool
    var windDownModeEnabled: Bool
    var calmFocusModeEnabled: Bool
    var binauralBeatsVolume: Double
    var whitelistedChannels: [String]
    var blacklistedChannels: [String]

    init(
        parentalControlsEnabled: Bool = false,
        dailyTimeLimitMinutes: Int? = nil,
        blockedKeywords: [String] = [],
        blockedCategories: [String] = [],
        parentPasswordHash: String? = nil,
        requirePasswordForSettings: Bool = true,
        lastResetDate: Date? = nil,
        breakRemindersEnabled: Bool = false,
        breakIntervalMinutes: Int? = nil,
        breakDurationMinutes: Int? = nil,
        calmModeEnabled: Bool = false,
        calmModeContrast: Double = 0.75,
        calmModeSaturation: Double = 0.7,
        calmModeBrightness: Double = -0.1,
        calmModeWarmth: Double = 0.15,
        calmModePreset: String? = nil,
        binauralBeatsEnabled: Bool = true,
        windDownModeEnabled: Bool = false,
        calmFocusModeEnabled: Bool = false,
        binauralBeatsVolume: Double = 0.12,
        whitelistedChannels: [String] = [],
        blacklistedChannels: [String] = []
    ) {
        self.parentalControlsEnabled = parentalControlsEnabled
        self.dailyTimeLimitMinutes = dailyTimeLimitMinutes
        self.blockedKeywords = blockedKeywords
        self.blockedCategories = blockedCategories
        self.parentPasswordHash = parentPasswordHash
        self.requirePasswordForSettings = requirePasswordForSettings
        self.lastResetDate = lastResetDate
        self.breakRemindersEnabled = breakRemindersEnabled
        self.breakIntervalMinutes = breakIntervalMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.calmModeEnabled = calmModeEnabled
        self.calmModeContrast = calmModeContrast
        self.calmModeSaturation = calmModeSaturation
        self.calmModeBrightness = calmModeBrightness
        self.calmModeWarmth = calmModeWarmth
        self.calmModePreset = calmModePreset
        self.binauralBeatsEnabled = binauralBeatsEnabled
        self.windDownModeEnabled = windDownModeEnabled
        self.calmFocusModeEnabled = calmFocusModeEnabled
        self.binauralBeatsVolume = binauralBeatsVolume
        self.whitelistedChannels = whitelistedChannels
        self.blacklistedChannels = blacklistedChannels
    }
}
