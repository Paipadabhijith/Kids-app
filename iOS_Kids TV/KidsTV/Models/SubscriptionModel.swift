//
//  SubscriptionModel.swift
//  Kids TV
//

import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
    case brightKids
    case zenKids
}

struct SubscriptionModel: Codable {
    var tier: SubscriptionTier
    var expiryDate: Date?
    var isActive: Bool
    var cancelAtPeriodEnd: Bool

    init(
        tier: SubscriptionTier = .brightKids,
        expiryDate: Date? = nil,
        isActive: Bool = true,
        cancelAtPeriodEnd: Bool = false
    ) {
        self.tier = tier
        self.expiryDate = expiryDate
        self.isActive = isActive
        self.cancelAtPeriodEnd = cancelAtPeriodEnd
    }

    var isPremium: Bool {
        let notExpired = expiryDate == nil || (expiryDate ?? .distantPast) > Date()
        return tier == .zenKids && isActive && notExpired
    }

    var isFree: Bool { !isPremium }
    var tierName: String { tier == .zenKids ? "Zen Kids" : "Bright Kids" }
    var tierBadge: String { tier == .zenKids ? "ZK" : "BK" }
}
