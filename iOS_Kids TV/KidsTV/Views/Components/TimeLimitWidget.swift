//
//  TimeLimitWidget.swift
//  Kids TV
//

import SwiftUI

struct TimeLimitWidget: View {
    let remainingMinutes: Int
    let isLimitExceeded: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(isLimitExceeded ? .red : AppTheme.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isLimitExceeded ? "Time's up" : "Screen time left")
                        .font(.subheadline.weight(.semibold))
                    Text(isLimitExceeded ? "Ask a parent to adjust settings" : "\(remainingMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(isLimitExceeded ? Color.red.opacity(0.1) : AppTheme.primary.opacity(0.1))
            .cornerRadius(AppTheme.standardRadius)
        }
        .buttonStyle(.plain)
    }
}
