//
//  Student.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import Foundation
import Security
import FirebaseFirestore

struct Student: Identifiable, Codable {
    let id: String
    let firstName: String
    let middleName: String  // Required to help prevent duplicates
    let lastName: String
    let schoolId: String
    let studentCode: String  // Unique 8-digit code - used as Student ID for login
    let gradeLevel: Int
    let dateOfBirth: Date?
    let notes: String
    let parentIds: [String]  // User IDs of linked parents
    let createdAt: Date
    let email: String?
    let passwordChangedAt: Date?  // If nil, still using default (studentCode + "!")
    
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
    /// Default password is studentCode + "!" until changed by school/teacher
    var usesDefaultPassword: Bool { passwordChangedAt == nil }
    
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
    
    /// Generate 8-char code (A-Z, 0-9). Creation uses Cloud Function for global uniqueness.
    static func generateStudentCode() -> String {
        var bytes = [UInt8](repeating: 0, count: 8)
        _ = SecRandomCopyBytes(kSecRandomDefault, 8, &bytes)
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String(bytes.map { chars[chars.index(chars.startIndex, offsetBy: Int($0) % 36)] })
    }
    
    /// Parse Cloud Function getMyStudentProfile response
    static func fromCallableResponse(_ data: [String: Any]) -> Student? {
        guard let id = data["id"] as? String else { return nil }
        let createdAt = Self.parseDate(from: data["createdAt"])
        let dob = Self.parseDate(from: data["dateOfBirth"])
        let pwdChanged = Self.parseDate(from: data["passwordChangedAt"])
        return Student(
            id: id,
            firstName: data["firstName"] as? String ?? "",
            middleName: data["middleName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            studentCode: ((data["studentCode"] as? String) ?? "").uppercased(),
            gradeLevel: data["gradeLevel"] as? Int ?? 0,
            dateOfBirth: dob,
            notes: data["notes"] as? String ?? "",
            parentIds: data["parentIds"] as? [String] ?? [],
            createdAt: createdAt ?? Date(),
            email: data["email"] as? String,
            passwordChangedAt: pwdChanged
        )
    }

    private static func parseDate(from value: Any?) -> Date? {
        guard let v = value else { return nil }
        if let ts = v as? Timestamp { return ts.dateValue() }
        if let dict = v as? [String: Any] {
            let sec = (dict["_seconds"] as? Int64) ?? (dict["_seconds"] as? Int).map { Int64($0) }
            if let s = sec { return Date(timeIntervalSince1970: TimeInterval(s)) }
        }
        return nil
    }

    static func fromDocument(_ doc: DocumentSnapshot) -> Student? {
        guard let data = doc.data() else { return nil }
        
        return Student(
            id: doc.documentID,
            firstName: data["firstName"] as? String ?? "",
            middleName: data["middleName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            studentCode: ((data["studentCode"] as? String) ?? "").uppercased(),
            gradeLevel: data["gradeLevel"] as? Int ?? 0,
            dateOfBirth: (data["dateOfBirth"] as? Timestamp)?.dateValue(),
            notes: data["notes"] as? String ?? "",
            parentIds: data["parentIds"] as? [String] ?? [],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            email: data["email"] as? String,
            passwordChangedAt: (data["passwordChangedAt"] as? Timestamp)?.dateValue()
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
