//
//  KidsTVApp.swift
//  Kids TV - Native iOS
//

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct KidsTVApp: App {
    @StateObject private var themeService = AppThemeService.shared
    @StateObject private var storage = StorageService.shared

    init() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeService)
                .environmentObject(storage)
                .preferredColorScheme(themeService.colorScheme)
        }
    }
}
