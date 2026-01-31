//
//  Grade.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-27.
//

import Foundation
import FirebaseFirestore

// MARK: - Assignment Category (for weighted grades)
struct AssignmentCategory: Identifiable, Codable {
    let id: String
    var name: String
    var weight: Double  // 0.0 to 1.0 (e.g., 0.30 = 30%)
    var dropLowest: Int // Number of lowest grades to drop
    
    static let defaultCategories: [AssignmentCategory] = [
        AssignmentCategory(id: "homework", name: "Homework", weight: 0.20, dropLowest: 0),
        AssignmentCategory(id: "quizzes", name: "Quizzes", weight: 0.20, dropLowest: 1),
        AssignmentCategory(id: "tests", name: "Tests", weight: 0.40, dropLowest: 0),
        AssignmentCategory(id: "participation", name: "Participation", weight: 0.10, dropLowest: 0),
        AssignmentCategory(id: "projects", name: "Projects", weight: 0.10, dropLowest: 0)
    ]
}

// MARK: - Assignment
struct GradeAssignment: Identifiable, Codable {
    let id: String
    let classId: String
    let schoolId: String
    var name: String
    var categoryId: String
    var pointsPossible: Double
    var dueDate: Date?
    var description: String?
    var createdAt: Date
    var updatedAt: Date
    
    static func fromDocument(_ doc: DocumentSnapshot) -> GradeAssignment? {
        guard let data = doc.data() else { return nil }
        
        return GradeAssignment(
            id: doc.documentID,
            classId: data["classId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            categoryId: data["categoryId"] as? String ?? "homework",
            pointsPossible: data["pointsPossible"] as? Double ?? 100,
            dueDate: (data["dueDate"] as? Timestamp)?.dateValue(),
            description: data["description"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "classId": classId,
            "schoolId": schoolId,
            "name": name,
            "categoryId": categoryId,
            "pointsPossible": pointsPossible,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        if let dueDate = dueDate {
            dict["dueDate"] = Timestamp(date: dueDate)
        }
        if let description = description {
            dict["description"] = description
        }
        return dict
    }
}

// MARK: - Student Grade (individual score on an assignment)
struct StudentGrade: Identifiable, Codable {
    let id: String
    let assignmentId: String
    let studentId: String
    let classId: String
    var pointsEarned: Double?  // nil = not graded yet
    var pointsPossible: Double
    var isExcused: Bool
    var isMissing: Bool
    var isLate: Bool
    var comment: String?
    var gradedByUserId: String?
    var gradedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    var percentage: Double? {
        guard let earned = pointsEarned, !isExcused else { return nil }
        guard pointsPossible > 0 else { return nil }
        return (earned / pointsPossible) * 100
    }
    
    var displayScore: String {
        if isExcused { return "EX" }
        if isMissing { return "M" }
        guard let earned = pointsEarned else { return "-" }
        return "\(formatNumber(earned))/\(formatNumber(pointsPossible))"
    }
    
    var displayPercentage: String {
        guard let pct = percentage else { return "-" }
        return String(format: "%.1f%%", pct)
    }
    
    private func formatNumber(_ num: Double) -> String {
        if num == floor(num) {
            return String(format: "%.0f", num)
        }
        return String(format: "%.1f", num)
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> StudentGrade? {
        guard let data = doc.data() else { return nil }
        
        return StudentGrade(
            id: doc.documentID,
            assignmentId: data["assignmentId"] as? String ?? "",
            studentId: data["studentId"] as? String ?? "",
            classId: data["classId"] as? String ?? "",
            pointsEarned: data["pointsEarned"] as? Double,
            pointsPossible: data["pointsPossible"] as? Double ?? 100,
            isExcused: data["isExcused"] as? Bool ?? false,
            isMissing: data["isMissing"] as? Bool ?? false,
            isLate: data["isLate"] as? Bool ?? false,
            comment: data["comment"] as? String,
            gradedByUserId: data["gradedByUserId"] as? String,
            gradedAt: (data["gradedAt"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "assignmentId": assignmentId,
            "studentId": studentId,
            "classId": classId,
            "pointsPossible": pointsPossible,
            "isExcused": isExcused,
            "isMissing": isMissing,
            "isLate": isLate,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        if let pointsEarned = pointsEarned {
            dict["pointsEarned"] = pointsEarned
        }
        if let comment = comment {
            dict["comment"] = comment
        }
        if let gradedByUserId = gradedByUserId {
            dict["gradedByUserId"] = gradedByUserId
        }
        if let gradedAt = gradedAt {
            dict["gradedAt"] = Timestamp(date: gradedAt)
        }
        return dict
    }
}

// MARK: - Student Overall Grade
struct StudentOverallGrade: Identifiable {
    let id: String  // studentId
    let studentName: String
    var categoryGrades: [String: CategoryGrade]  // categoryId -> grade info
    var overallPercentage: Double
    var letterGrade: String
    var overridePercentage: Double?
    var overrideLetterGrade: String?
    
    var displayPercentage: Double {
        overridePercentage ?? overallPercentage
    }
    
    var displayLetterGrade: String {
        overrideLetterGrade ?? letterGrade
    }
    
    var isOverridden: Bool {
        overridePercentage != nil || overrideLetterGrade != nil
    }
    
    struct CategoryGrade {
        var categoryName: String
        var weight: Double
        var earnedPoints: Double
        var possiblePoints: Double
        var percentage: Double
        var assignmentCount: Int
    }
    
    static func calculateLetterGrade(from percentage: Double) -> String {
        switch percentage {
        case 97...Double.infinity: return "A+"
        case 93..<97: return "A"
        case 90..<93: return "A-"
        case 87..<90: return "B+"
        case 83..<87: return "B"
        case 80..<83: return "B-"
        case 77..<80: return "C+"
        case 73..<77: return "C"
        case 70..<73: return "C-"
        case 67..<70: return "D+"
        case 63..<67: return "D"
        case 60..<63: return "D-"
        default: return "F"
        }
    }
}

// MARK: - Grade Override
struct GradeOverride: Identifiable, Codable {
    let id: String
    let classId: String
    let studentId: String
    var overridePercentage: Double?
    var overrideLetterGrade: String?
    var reason: String?
    var overriddenByUserId: String
    var overriddenByRole: String
    var createdAt: Date
    var updatedAt: Date
    
    static func fromDocument(_ doc: DocumentSnapshot) -> GradeOverride? {
        guard let data = doc.data() else { return nil }
        
        return GradeOverride(
            id: doc.documentID,
            classId: data["classId"] as? String ?? "",
            studentId: data["studentId"] as? String ?? "",
            overridePercentage: data["overridePercentage"] as? Double,
            overrideLetterGrade: data["overrideLetterGrade"] as? String,
            reason: data["reason"] as? String,
            overriddenByUserId: data["overriddenByUserId"] as? String ?? "",
            overriddenByRole: data["overriddenByRole"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Class Grading Settings
struct ClassGradingSettings: Codable {
    var categories: [AssignmentCategory]
    var useWeightedGrades: Bool
    var showLetterGrades: Bool
    var showPercentages: Bool
    var roundingMethod: RoundingMethod
    
    enum RoundingMethod: String, Codable, CaseIterable {
        case none = "No Rounding"
        case nearestWhole = "Nearest Whole"
        case nearestTenth = "Nearest 0.1"
        case nearestHalf = "Nearest 0.5"
    }
    
    static var `default`: ClassGradingSettings {
        ClassGradingSettings(
            categories: AssignmentCategory.defaultCategories,
            useWeightedGrades: true,
            showLetterGrades: true,
            showPercentages: true,
            roundingMethod: .nearestTenth
        )
    }
}
