//
//  AppThemeService.swift
//  Kids TV
//

import SwiftUI

enum AppThemeMode: String {
    case light
    case dark
    case system
}

final class AppThemeService: ObservableObject {
    static let shared = AppThemeService()
    @Published var themeMode: AppThemeMode = .system

    private init() {
        if let raw = StorageService.shared.getThemeModePreference() {
            themeMode = AppThemeMode(rawValue: raw) ?? .system
        }
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    func setThemeMode(_ mode: AppThemeMode) {
        themeMode = mode
        StorageService.shared.saveThemeModePreference(mode.rawValue)
    }
}
