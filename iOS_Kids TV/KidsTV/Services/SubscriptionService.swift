//
//  SubscriptionService.swift
//  Kids TV
//

import Foundation

final class SubscriptionService {
    static let shared = SubscriptionService()
    private let key = "user_subscription"
    private let storage = StorageService.shared

    private init() {}

    func getSubscription() -> SubscriptionModel {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(SubscriptionModel.self, from: data) else {
            return SubscriptionModel()
        }
        return decoded
    }

    func saveSubscription(_ subscription: SubscriptionModel) {
        if let data = try? JSONEncoder().encode(subscription) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func upgradeToPremium() {
        var sub = SubscriptionModel()
        sub.tier = .zenKids
        sub.isActive = true
        sub.expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        sub.cancelAtPeriodEnd = false
        saveSubscription(sub)
    }

    func downgradeToFree() {
        var sub = SubscriptionModel()
        sub.tier = .brightKids
        sub.isActive = true
        saveSubscription(sub)
    }

    func isPremium() -> Bool { getSubscription().isPremium }
}
