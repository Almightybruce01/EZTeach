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
    /// Optional; if nil, derived from periods
    let schoolStartTime: String?
    let schoolEndTime: String?
    /// Slot size in minutes for grid view (5 or 10)
    let slotMinutes: Int?
    
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
            activeDays: data["activeDays"] as? [Int] ?? [2, 3, 4, 5, 6],
            effectiveStartDate: (data["effectiveStartDate"] as? Timestamp)?.dateValue(),
            effectiveEndDate: (data["effectiveEndDate"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            schoolStartTime: data["schoolStartTime"] as? String,
            schoolEndTime: data["schoolEndTime"] as? String,
            slotMinutes: data["slotMinutes"] as? Int
        )
    }
    
    var effectiveStart: String {
        schoolStartTime ?? periods.map(\.startTime).min() ?? "07:00"
    }
    var effectiveEnd: String {
        schoolEndTime ?? periods.map(\.endTime).max() ?? "15:30"
    }
    var slotSize: Int { slotMinutes ?? 10 }
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
        case intercom = "intercom"      // Intercom / Good Morning
        case dismissal = "dismissal"
        
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
            case .intercom: return "Intercom / Good Morning"
            case .dismissal: return "Dismissal"
            }
        }
    }
    
    /// Grade level for grade-specific events (e.g. "K Lunch", "1st Grade Lunch"). 0 = K.
    let gradeLevel: Int?
    
    init(id: String, name: String, periodNumber: Int?, startTime: String, endTime: String, periodType: PeriodType, gradeLevel: Int? = nil) {
        self.id = id
        self.name = name
        self.periodNumber = periodNumber
        self.startTime = startTime
        self.endTime = endTime
        self.periodType = periodType
        self.gradeLevel = gradeLevel
    }
    
    static func fromDict(_ dict: [String: Any]) -> BellPeriod? {
        return BellPeriod(
            id: dict["id"] as? String ?? UUID().uuidString,
            name: dict["name"] as? String ?? "",
            periodNumber: dict["periodNumber"] as? Int,
            startTime: dict["startTime"] as? String ?? "",
            endTime: dict["endTime"] as? String ?? "",
            periodType: PeriodType(rawValue: dict["periodType"] as? String ?? "class") ?? .classTime,
            gradeLevel: dict["gradeLevel"] as? Int
        )
    }
    
    func toDict() -> [String: Any] {
        var d: [String: Any] = [
            "id": id,
            "name": name,
            "periodNumber": periodNumber as Any,
            "startTime": startTime,
            "endTime": endTime,
            "periodType": periodType.rawValue
        ]
        if let gl = gradeLevel { d["gradeLevel"] = gl }
        return d
    }
    
    var gradeLabel: String {
        guard let g = gradeLevel else { return "" }
        if g == 0 { return "K" }
        return "Grade \(g)"
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
