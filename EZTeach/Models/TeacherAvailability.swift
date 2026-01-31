//
//  TeacherAvailability.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct TeacherAvailability: Identifiable, Codable {
    let id: String
    let teacherId: String
    let teacherUserId: String
    let schoolId: String
    let date: Date
    let status: AvailabilityStatus
    let reason: String?
    let createdAt: Date
    
    enum AvailabilityStatus: String, Codable, CaseIterable {
        case available = "available"
        case unavailable = "unavailable"
        case partialDay = "partial_day"
        case pendingLeave = "pending_leave"
        case approvedLeave = "approved_leave"
        
        var displayName: String {
            switch self {
            case .available: return "Available"
            case .unavailable: return "Unavailable"
            case .partialDay: return "Partial Day"
            case .pendingLeave: return "Pending Leave"
            case .approvedLeave: return "Approved Leave"
            }
        }
        
        var color: String {
            switch self {
            case .available: return "green"
            case .unavailable: return "red"
            case .partialDay: return "orange"
            case .pendingLeave: return "yellow"
            case .approvedLeave: return "blue"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> TeacherAvailability? {
        guard let data = doc.data() else { return nil }
        
        return TeacherAvailability(
            id: doc.documentID,
            teacherId: data["teacherId"] as? String ?? "",
            teacherUserId: data["teacherUserId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            status: AvailabilityStatus(rawValue: data["status"] as? String ?? "available") ?? .available,
            reason: data["reason"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
