//
//  BellSchedule.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct BellSchedule: Identifiable, Codable {
    let id: String
    let schoolId: String
    let name: String
    let scheduleType: ScheduleType
    let isDefault: Bool
    let periods: [BellPeriod]
    let activeDays: [Int]  // 1 = Sunday, 2 = Monday, etc.
    let effectiveStartDate: Date?
    let effectiveEndDate: Date?
    let createdAt: Date
    
    enum ScheduleType: String, Codable, CaseIterable {
        case regular = "regular"
        case earlyRelease = "early_release"
        case lateStart = "late_start"
        case assembly = "assembly"
        case halfDay = "half_day"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .regular: return "Regular Schedule"
            case .earlyRelease: return "Early Release"
            case .lateStart: return "Late Start"
            case .assembly: return "Assembly Schedule"
            case .halfDay: return "Half Day"
            case .custom: return "Custom"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> BellSchedule? {
        guard let data = doc.data() else { return nil }
        
        let periodsData = data["periods"] as? [[String: Any]] ?? []
        let periods = periodsData.compactMap { BellPeriod.fromDict($0) }
        
        return BellSchedule(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            scheduleType: ScheduleType(rawValue: data["scheduleType"] as? String ?? "regular") ?? .regular,
            isDefault: data["isDefault"] as? Bool ?? false,
            periods: periods,
            activeDays: data["activeDays"] as? [Int] ?? [2, 3, 4, 5, 6], // Mon-Fri
            effectiveStartDate: (data["effectiveStartDate"] as? Timestamp)?.dateValue(),
            effectiveEndDate: (data["effectiveEndDate"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

struct BellPeriod: Identifiable, Codable {
    let id: String
    let name: String
    let periodNumber: Int?
    let startTime: String  // "08:00"
    let endTime: String    // "08:50"
    let periodType: PeriodType
    
    enum PeriodType: String, Codable, CaseIterable {
        case classTime = "class"
        case passing = "passing"
        case lunch = "lunch"
        case breakfast = "breakfast"
        case homeroom = "homeroom"
        case assembly = "assembly"
        case recess = "recess"
        case advisory = "advisory"
        
        var displayName: String {
            switch self {
            case .classTime: return "Class"
            case .passing: return "Passing Period"
            case .lunch: return "Lunch"
            case .breakfast: return "Breakfast"
            case .homeroom: return "Homeroom"
            case .assembly: return "Assembly"
            case .recess: return "Recess"
            case .advisory: return "Advisory"
            }
        }
    }
    
    static func fromDict(_ dict: [String: Any]) -> BellPeriod? {
        return BellPeriod(
            id: dict["id"] as? String ?? UUID().uuidString,
            name: dict["name"] as? String ?? "",
            periodNumber: dict["periodNumber"] as? Int,
            startTime: dict["startTime"] as? String ?? "",
            endTime: dict["endTime"] as? String ?? "",
            periodType: PeriodType(rawValue: dict["periodType"] as? String ?? "class") ?? .classTime
        )
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "periodNumber": periodNumber as Any,
            "startTime": startTime,
            "endTime": endTime,
            "periodType": periodType.rawValue
        ]
    }
}

// MARK: - Schedule Override (for specific dates)
struct ScheduleOverride: Identifiable, Codable {
    let id: String
    let schoolId: String
    let date: Date
    let scheduleId: String?  // nil = no school
    let reason: String
    let createdAt: Date
    
    static func fromDocument(_ doc: DocumentSnapshot) -> ScheduleOverride? {
        guard let data = doc.data() else { return nil }
        
        return ScheduleOverride(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            scheduleId: data["scheduleId"] as? String,
            reason: data["reason"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
