//
//  Student.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import Foundation
import FirebaseFirestore

struct Student: Identifiable, Codable {
    let id: String
    let firstName: String
    let middleName: String  // Required to help prevent duplicates
    let lastName: String
    let schoolId: String
    let studentCode: String  // Unique 8-digit code for parent linking
    let gradeLevel: Int
    let dateOfBirth: Date?
    let notes: String
    let parentIds: [String]  // User IDs of linked parents
    let createdAt: Date
    
    var name: String {
        if lastName.isEmpty && firstName.isEmpty {
            return "Unknown Student"
        }
        if middleName.isEmpty {
            return "\(lastName), \(firstName)"
        }
        return "\(lastName), \(firstName) \(middleName.prefix(1))."
    }
    
    var fullName: String {
        if middleName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        return "\(firstName) \(middleName) \(lastName)"
    }
    
    var fullNameFormatted: String {
        if middleName.isEmpty {
            return "\(lastName), \(firstName)"
        }
        return "\(lastName), \(firstName) \(middleName)"
    }
    
    // Unique key for duplicate detection: lowercase first+middle+last+dob
    var duplicateKey: String {
        let dobString: String
        if let dob = dateOfBirth {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            dobString = formatter.string(from: dob)
        } else {
            dobString = "nodob"
        }
        return "\(firstName.lowercased())_\(middleName.lowercased())_\(lastName.lowercased())_\(dobString)"
    }
    
    // Generate a unique 8-digit student code
    static func generateStudentCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in letters.randomElement()! })
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> Student? {
        guard let data = doc.data() else { return nil }
        
        return Student(
            id: doc.documentID,
            firstName: data["firstName"] as? String ?? "",
            middleName: data["middleName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            studentCode: data["studentCode"] as? String ?? "",
            gradeLevel: data["gradeLevel"] as? Int ?? 0,
            dateOfBirth: (data["dateOfBirth"] as? Timestamp)?.dateValue(),
            notes: data["notes"] as? String ?? "",
            parentIds: data["parentIds"] as? [String] ?? [],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "firstName": firstName,
            "middleName": middleName,
            "lastName": lastName,
            "schoolId": schoolId,
            "studentCode": studentCode,
            "gradeLevel": gradeLevel,
            "notes": notes,
            "parentIds": parentIds,
            "createdAt": Timestamp(date: createdAt),
            "duplicateKey": duplicateKey  // Store for efficient querying
        ]
        
        if let dob = dateOfBirth {
            dict["dateOfBirth"] = Timestamp(date: dob)
        }
        
        return dict
    }
}
