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
    let subscriptionTier: SubscriptionTier
    let maxSchools: Int
    let pricePerSchool: Double
    let totalMonthlyPrice: Double
    let subscriptionStartDate: Date?
    let subscriptionEndDate: Date?
    let paymentMethod: String?
    let createdAt: Date
    
    enum SubscriptionTier: String, Codable, CaseIterable {
        case none = "none"
        case small = "small"      // 1-5 schools: $72/school
        case medium = "medium"    // 6-15 schools: $68/school
        case large = "large"      // 16-30 schools: $64/school
        case enterprise = "enterprise" // 31+ schools: $60/school
        
        var pricePerSchool: Double {
            switch self {
            case .none: return 75.0
            case .small: return 72.0
            case .medium: return 68.0
            case .large: return 64.0
            case .enterprise: return 60.0
            }
        }
        
        var schoolRange: String {
            switch self {
            case .none: return "0"
            case .small: return "1-5"
            case .medium: return "6-15"
            case .large: return "16-30"
            case .enterprise: return "31+"
            }
        }
        
        static func tierFor(schoolCount: Int) -> SubscriptionTier {
            switch schoolCount {
            case 0: return .none
            case 1...5: return .small
            case 6...15: return .medium
            case 16...30: return .large
            default: return .enterprise
            }
        }
    }
    
    static func calculatePrice(schoolCount: Int) -> (tier: SubscriptionTier, pricePerSchool: Double, total: Double) {
        let tier = SubscriptionTier.tierFor(schoolCount: schoolCount)
        let price = tier.pricePerSchool
        let total = price * Double(schoolCount)
        return (tier, price, total)
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> District? {
        guard let data = doc.data() else { return nil }
        
        return District(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            ownerUid: data["ownerUid"] as? String ?? "",
            schoolIds: data["schoolIds"] as? [String] ?? [],
            subscriptionActive: data["subscriptionActive"] as? Bool ?? false,
            subscriptionTier: SubscriptionTier(rawValue: data["subscriptionTier"] as? String ?? "none") ?? .none,
            maxSchools: data["maxSchools"] as? Int ?? 0,
            pricePerSchool: data["pricePerSchool"] as? Double ?? 75.0,
            totalMonthlyPrice: data["totalMonthlyPrice"] as? Double ?? 0,
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
