//
//  Attendance.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct AttendanceRecord: Identifiable, Codable {
    let id: String
    let schoolId: String
    let classId: String
    let studentId: String
    let studentName: String
    let date: Date
    let status: AttendanceStatus
    let timeIn: Date?
    let timeOut: Date?
    let notes: String?
    let markedByUserId: String
    let markedByRole: String
    let createdAt: Date
    let updatedAt: Date
    
    enum AttendanceStatus: String, Codable, CaseIterable {
        case present = "present"
        case absent = "absent"
        case tardy = "tardy"
        case excused = "excused"
        case earlyDismissal = "early_dismissal"
        
        var displayName: String {
            switch self {
            case .present: return "Present"
            case .absent: return "Absent"
            case .tardy: return "Tardy"
            case .excused: return "Excused"
            case .earlyDismissal: return "Early Dismissal"
            }
        }
        
        var iconName: String {
            switch self {
            case .present: return "checkmark.circle.fill"
            case .absent: return "xmark.circle.fill"
            case .tardy: return "clock.fill"
            case .excused: return "doc.text.fill"
            case .earlyDismissal: return "arrow.right.circle.fill"
            }
        }
        
        var colorName: String {
            switch self {
            case .present: return "green"
            case .absent: return "red"
            case .tardy: return "orange"
            case .excused: return "blue"
            case .earlyDismissal: return "purple"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> AttendanceRecord? {
        guard let data = doc.data() else { return nil }
        
        return AttendanceRecord(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            classId: data["classId"] as? String ?? "",
            studentId: data["studentId"] as? String ?? "",
            studentName: data["studentName"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            status: AttendanceStatus(rawValue: data["status"] as? String ?? "present") ?? .present,
            timeIn: (data["timeIn"] as? Timestamp)?.dateValue(),
            timeOut: (data["timeOut"] as? Timestamp)?.dateValue(),
            notes: data["notes"] as? String,
            markedByUserId: data["markedByUserId"] as? String ?? "",
            markedByRole: data["markedByRole"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Daily Attendance Summary
struct DailyAttendanceSummary: Identifiable {
    let id: String
    let date: Date
    let totalStudents: Int
    let presentCount: Int
    let absentCount: Int
    let tardyCount: Int
    let excusedCount: Int
    
    var attendanceRate: Double {
        guard totalStudents > 0 else { return 0 }
        return Double(presentCount + tardyCount) / Double(totalStudents) * 100
    }
}
