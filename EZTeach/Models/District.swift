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
    
    // MARK: - Per-Student/Year Pricing (district annual)
    enum SubscriptionTier: String, Codable, CaseIterable {
        case none       = "none"
        case tier3k     = "tier3k"       // 3,000–7,500 students: $12/student/yr
        case tier7k     = "tier7k"       // 7,501–15,000: $11/student/yr
        case tier15k    = "tier15k"      // 15,001–30,000: $10/student/yr
        case tier30k    = "tier30k"      // 30,001–60,000: $9/student/yr
        case tier60k    = "tier60k"      // 60,000+: $8/student/yr
        case perSchool  = "perSchool"    // $2,750/school/yr (up to 750 students/school)

        var pricePerStudentYear: Double {
            switch self {
            case .none:      return 12.0
            case .tier3k:    return 12.0
            case .tier7k:    return 11.0
            case .tier15k:   return 10.0
            case .tier30k:   return 9.0
            case .tier60k:   return 8.0
            case .perSchool: return 0   // uses flat per-school
            }
        }

        var label: String {
            switch self {
            case .none:      return "No plan"
            case .tier3k:    return "3,000–7,500 students"
            case .tier7k:    return "7,501–15,000 students"
            case .tier15k:   return "15,001–30,000 students"
            case .tier30k:   return "30,001–60,000 students"
            case .tier60k:   return "60,000+ students"
            case .perSchool: return "$2,750/school/year"
            }
        }

        var schoolRange: String { label }

        /// Legacy compatibility — returns approximate per-school equivalent
        var pricePerSchool: Double {
            switch self {
            case .perSchool: return 2750.0 / 12.0  // monthly equivalent
            default: return pricePerStudentYear * 750 / 12  // estimate for 750 students
            }
        }

        static func tierFor(studentCount: Int) -> SubscriptionTier {
            switch studentCount {
            case 0:            return .none
            case 1...7500:     return .tier3k
            case 7501...15000: return .tier7k
            case 15001...30000: return .tier15k
            case 30001...60000: return .tier30k
            default:           return .tier60k
            }
        }

        /// Legacy: tier by school count (uses perSchool flat rate)
        static func tierFor(schoolCount: Int) -> SubscriptionTier {
            if schoolCount == 0 { return .none }
            return .perSchool
        }
    }

    /// Per-student annual pricing: returns (tier, pricePerStudent, annualTotal)
    static func calculateStudentPrice(totalStudents: Int) -> (tier: SubscriptionTier, pricePerStudent: Double, annualTotal: Double) {
        let tier = SubscriptionTier.tierFor(studentCount: totalStudents)
        let price = tier.pricePerStudentYear
        let total = price * Double(totalStudents)
        return (tier, price, total)
    }

    /// Per-school annual pricing: $2,750/school/year (up to 750 students each)
    static func calculatePerSchoolPrice(schoolCount: Int) -> (pricePerSchool: Double, annualTotal: Double) {
        return (2750.0, 2750.0 * Double(schoolCount))
    }

    /// Legacy compatibility
    static func calculatePrice(schoolCount: Int) -> (tier: SubscriptionTier, pricePerSchool: Double, total: Double) {
        let result = calculatePerSchoolPrice(schoolCount: schoolCount)
        return (.perSchool, result.pricePerSchool / 12.0, result.annualTotal / 12.0)
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
