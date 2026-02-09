//
//  Announcement.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import Foundation
import SwiftUI

struct Announcement: Identifiable {
    let id: String
    let schoolId: String
    let title: String
    let body: String
    let attachmentUrl: String?
    /// `false` when taken down; omitted/true = active.
    let isActive: Bool
    /// Role of the author: "school" (principal), "teacher", "staff", etc.
    let authorRole: String
    /// Display name of the author
    let authorName: String
    /// When the announcement was created
    let createdAt: Date?

    // MARK: - Role-Based Colors
    /// Icon color based on the role of the announcement author
    var roleColor: Color {
        switch authorRole {
        case "school":   return Color(red: 0.15, green: 0.22, blue: 0.45)   // Navy (Principal)
        case "teacher":  return Color(red: 0.13, green: 0.59, blue: 0.53)   // Teal
        case "district": return Color(red: 0.55, green: 0.22, blue: 0.67)   // Purple
        default:         return Color(red: 0.45, green: 0.45, blue: 0.50)   // Gray (Janitor / Staff)
        }
    }

    /// Human-readable role label
    var roleLabel: String {
        switch authorRole {
        case "school":   return "Principal"
        case "teacher":  return "Teacher"
        case "district": return "District"
        case "sub":      return "Substitute"
        default:         return "Staff"
        }
    }

    /// SF Symbol for the announcement icon
    var roleIcon: String {
        switch authorRole {
        case "school":   return "megaphone.fill"
        case "teacher":  return "person.fill"
        case "district": return "building.columns.fill"
        default:         return "bell.fill"
        }
    }
}
