//
//  SubRequest.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct SubRequest: Identifiable, Codable {
    let id: String
    let schoolId: String
    let teacherId: String
    let teacherUserId: String
    let teacherName: String
    let date: Date
    let startTime: String?
    let endTime: String?
    let isFullDay: Bool
    let reason: String
    let classIds: [String]
    let classNames: [String]
    let grade: Int?
    let status: RequestStatus
    let assignedSubId: String?
    let assignedSubUserId: String?
    let assignedSubName: String?
    let notes: String?
    let subPlanId: String?
    let approvedByUserId: String?
    let approvedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum RequestStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case approved = "approved"
        case assigned = "assigned"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
        case rejected = "rejected"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending Approval"
            case .approved: return "Approved - Needs Sub"
            case .assigned: return "Sub Assigned"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            case .rejected: return "Rejected"
            }
        }
        
        var iconName: String {
            switch self {
            case .pending: return "clock"
            case .approved: return "checkmark.circle"
            case .assigned: return "person.fill.checkmark"
            case .inProgress: return "play.circle.fill"
            case .completed: return "checkmark.seal.fill"
            case .cancelled: return "xmark.circle"
            case .rejected: return "xmark.octagon"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> SubRequest? {
        guard let data = doc.data() else { return nil }
        
        return SubRequest(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            teacherId: data["teacherId"] as? String ?? "",
            teacherUserId: data["teacherUserId"] as? String ?? "",
            teacherName: data["teacherName"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            startTime: data["startTime"] as? String,
            endTime: data["endTime"] as? String,
            isFullDay: data["isFullDay"] as? Bool ?? true,
            reason: data["reason"] as? String ?? "",
            classIds: data["classIds"] as? [String] ?? [],
            classNames: data["classNames"] as? [String] ?? [],
            grade: data["grade"] as? Int,
            status: RequestStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
            assignedSubId: data["assignedSubId"] as? String,
            assignedSubUserId: data["assignedSubUserId"] as? String,
            assignedSubName: data["assignedSubName"] as? String,
            notes: data["notes"] as? String,
            subPlanId: data["subPlanId"] as? String,
            approvedByUserId: data["approvedByUserId"] as? String,
            approvedAt: (data["approvedAt"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
