//
//  ContentView.swift
//  Kids TV
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppThemeService.shared)
        .environmentObject(StorageService.shared)
}
