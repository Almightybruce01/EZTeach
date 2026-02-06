//
//  SchoolClass.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import Foundation

struct SchoolClass: Identifiable {
    let id: String
    let name: String
    let grade: Int
    let schoolId: String
    let teacherIds: [String]
    let classType: ClassType
    
    enum ClassType: String, Codable, CaseIterable {
        case regular = "regular"
        case dlp = "dlp"           // Dual Language Program
        case crossCat = "cross_cat" // Cross-categorical
        case mixed = "mixed"       // Mixed / combined class
        case inclusion = "inclusion"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .regular: return "Regular"
            case .dlp: return "DLP (Dual Language)"
            case .crossCat: return "Cross-Categorical"
            case .mixed: return "Mixed / Special"
            case .inclusion: return "Inclusion"
            case .other: return "Other"
            }
        }
    }
    
    init(id: String, name: String, grade: Int, schoolId: String, teacherIds: [String], classType: ClassType = .regular) {
        self.id = id
        self.name = name
        self.grade = grade
        self.schoolId = schoolId
        self.teacherIds = teacherIds
        self.classType = classType
    }
}
