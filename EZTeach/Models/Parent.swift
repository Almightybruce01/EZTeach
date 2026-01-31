//
//  Parent.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct Parent: Identifiable, Codable {
    let id: String
    let userId: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let childrenIds: [String]  // Student IDs
    let schoolIds: [String]    // Schools their children attend
    let notificationsEnabled: Bool
    let emailNotifications: Bool
    let pushNotifications: Bool
    let createdAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var formattedName: String {
        "\(lastName), \(firstName)"
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> Parent? {
        guard let data = doc.data() else { return nil }
        
        return Parent(
            id: doc.documentID,
            userId: data["userId"] as? String ?? "",
            firstName: data["firstName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            email: data["email"] as? String ?? "",
            phone: data["phone"] as? String,
            childrenIds: data["childrenIds"] as? [String] ?? [],
            schoolIds: data["schoolIds"] as? [String] ?? [],
            notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true,
            emailNotifications: data["emailNotifications"] as? Bool ?? true,
            pushNotifications: data["pushNotifications"] as? Bool ?? true,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Parent-Student Link
struct ParentStudentLink: Identifiable, Codable {
    let id: String
    let parentId: String
    let parentUserId: String
    let studentId: String
    let relationship: Relationship
    let isPrimaryContact: Bool
    let canPickup: Bool
    let emergencyContact: Bool
    let createdAt: Date
    
    enum Relationship: String, Codable, CaseIterable {
        case mother = "mother"
        case father = "father"
        case guardian = "guardian"
        case grandparent = "grandparent"
        case other = "other"
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> ParentStudentLink? {
        guard let data = doc.data() else { return nil }
        
        return ParentStudentLink(
            id: doc.documentID,
            parentId: data["parentId"] as? String ?? "",
            parentUserId: data["parentUserId"] as? String ?? "",
            studentId: data["studentId"] as? String ?? "",
            relationship: Relationship(rawValue: data["relationship"] as? String ?? "guardian") ?? .guardian,
            isPrimaryContact: data["isPrimaryContact"] as? Bool ?? false,
            canPickup: data["canPickup"] as? Bool ?? true,
            emergencyContact: data["emergencyContact"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
