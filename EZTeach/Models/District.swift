//
//  District.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct District: Identifiable, Codable {
    let id: String
    let name: String
    let ownerUid: String
    let schoolIds: [String]
    let subscriptionActive: Bool
    let maxSchools: Int
    let subscriptionStartDate: Date?
    let subscriptionEndDate: Date?
    let paymentMethod: String?
    let createdAt: Date

    // MARK: - District Pricing
    // Districts simply pick a school tier (S/M1/M2/L/XL/ENT) for each school.
    // The district total = sum of all school tier prices.
    // Same tiers as individual schools — no separate per-student pricing.

    /// Calculate total monthly/yearly price for a district given an array of tier keys
    static func calculateTotal(tiers: [String]) -> (monthlyTotal: Double, yearlyTotal: Double) {
        var monthly = 0.0
        var yearly  = 0.0
        for key in tiers {
            if let tier = FirestoreService.schoolTiers.first(where: { $0.tier == key }) {
                monthly += Double(tier.price)
                yearly  += Double(tier.price) * 10 // yearly = 10 months (save ~17%)
            }
        }
        return (monthly, yearly)
    }

    static func fromDocument(_ doc: DocumentSnapshot) -> District? {
        guard let data = doc.data() else { return nil }

        return District(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            ownerUid: data["ownerUid"] as? String ?? "",
            schoolIds: data["schoolIds"] as? [String] ?? [],
            subscriptionActive: data["subscriptionActive"] as? Bool ?? false,
            maxSchools: data["maxSchools"] as? Int ?? 0,
            subscriptionStartDate: (data["subscriptionStartDate"] as? Timestamp)?.dateValue(),
            subscriptionEndDate: (data["subscriptionEndDate"] as? Timestamp)?.dateValue(),
            paymentMethod: data["paymentMethod"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Subscription Status Check
extension District {
    var isActive: Bool {
        guard subscriptionActive else { return false }
        guard let endDate = subscriptionEndDate else { return false }
        return endDate > Date()
    }

    var daysUntilRenewal: Int? {
        guard let endDate = subscriptionEndDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }
}
