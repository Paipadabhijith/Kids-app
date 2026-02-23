//
//  ParentalSettingsView.swift
//  Kids TV
//

import SwiftUI

struct ParentalSettingsView: View {
    @StateObject private var parental = ParentalControlService.shared
    @State private var settings: SettingsModel = SettingsModel()
    @State private var timeLimit: String = ""
    @State private var passwordEntry: String = ""
    @State private var showPasswordAlert = false

    var body: some View {
        Form {
            Section("Parental controls") {
                Toggle("Enable parental controls", isOn: $settings.parentalControlsEnabled)
                    .onChange(of: settings.parentalControlsEnabled) { _, on in
                        if on {
                            settings.dailyTimeLimitMinutes = settings.dailyTimeLimitMinutes ?? Constants.defaultTimeLimitMinutes
                        }
                        parental.saveSettings(settings)
                    }
                if settings.parentalControlsEnabled {
                    HStack {
                        Text("Daily time limit (minutes)")
                        TextField("60", text: $timeLimit)
                            .keyboardType(.numberPad)
                    }
                    .onChange(of: timeLimit) { _, new in
                        settings.dailyTimeLimitMinutes = Int(new)
                        parental.saveSettings(settings)
                    }
                }
            }
            Section("Parent password") {
                Button("Set password") {
                    showPasswordAlert = true
                }
            }
            Section("Break reminders") {
                Toggle("Break reminders", isOn: $settings.breakRemindersEnabled)
                    .onChange(of: settings.breakRemindersEnabled) { _, _ in
                        parental.saveSettings(settings)
                    }
                if settings.breakRemindersEnabled {
                    HStack {
                        Text("Interval (minutes)")
                        TextField("30", value: $settings.breakIntervalMinutes, format: .number)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Break duration (minutes)")
                        TextField("5", value: $settings.breakDurationMinutes, format: .number)
                            .keyboardType(.numberPad)
                    }
                }
            }
        }
        .navigationTitle("Parental settings")
        .onAppear {
            settings = parental.getSettings()
            timeLimit = settings.dailyTimeLimitMinutes.map { "\($0)" } ?? ""
        }
        .onChange(of: settings.breakIntervalMinutes) { _, _ in parental.saveSettings(settings) }
        .onChange(of: settings.breakDurationMinutes) { _, _ in parental.saveSettings(settings) }
        .alert("Set parent password", isPresented: $showPasswordAlert) {
            SecureField("Password", text: $passwordEntry)
            Button("Cancel", role: .cancel) { passwordEntry = "" }
            Button("Save") {
                if !passwordEntry.isEmpty {
                    parental.setPassword(passwordEntry)
                }
                passwordEntry = ""
            }
        } message: {
            Text("Enter a password to protect parental settings.")
        }
    }
}
