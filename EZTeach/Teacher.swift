//
//  Teacher.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import Foundation

struct Teacher: Identifiable {
    let id: String          // teacher document ID
    let firstName: String
    let lastName: String
    let displayName: String
    let schoolId: String
    let userId: String
    let grades: [Int]

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// "Last Name, First Name" format for display in lists
    var formattedName: String {
        if lastName.isEmpty && firstName.isEmpty {
            return displayName.isEmpty ? "Unknown" : displayName
        }
        return "\(lastName), \(firstName)"
    }
}
