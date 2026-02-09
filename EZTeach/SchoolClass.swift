//
//  SchoolClass.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import Foundation
import FirebaseFirestore

struct SchoolClass: Identifiable, Hashable {
    let id: String
    let name: String
    let grade: Int
    let schoolId: String
    let teacherIds: [String]
    let classType: ClassType
    let subjectType: SubjectType
    let period: Int?  // For specials teachers who see multiple classes
    let scheduleDay: String?  // For rotating schedules (A day, B day, etc)
    
    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SchoolClass, rhs: SchoolClass) -> Bool {
        lhs.id == rhs.id
    }
    
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
    
    enum SubjectType: String, Codable, CaseIterable {
        case homeroom = "homeroom"
        case art = "art"
        case music = "music"
        case pe = "pe"
        case library = "library"
        case technology = "technology"
        case spanish = "spanish"
        case french = "french"
        case band = "band"
        case choir = "choir"
        case drama = "drama"
        case stem = "stem"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .homeroom: return "Homeroom"
            case .art: return "Art"
            case .music: return "Music"
            case .pe: return "P.E."
            case .library: return "Library"
            case .technology: return "Technology"
            case .spanish: return "Spanish"
            case .french: return "French"
            case .band: return "Band"
            case .choir: return "Choir"
            case .drama: return "Drama"
            case .stem: return "STEM"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .homeroom: return "house.fill"
            case .art: return "paintpalette.fill"
            case .music: return "music.note"
            case .pe: return "figure.run"
            case .library: return "books.vertical.fill"
            case .technology: return "desktopcomputer"
            case .spanish, .french: return "globe"
            case .band: return "music.mic"
            case .choir: return "person.wave.2.fill"
            case .drama: return "theatermasks.fill"
            case .stem: return "gearshape.2.fill"
            case .other: return "folder.fill"
            }
        }
        
        var isSpecials: Bool {
            self != .homeroom
        }
    }
    
    init(id: String, name: String, grade: Int, schoolId: String, teacherIds: [String], classType: ClassType = .regular, subjectType: SubjectType = .homeroom, period: Int? = nil, scheduleDay: String? = nil) {
        self.id = id
        self.name = name
        self.grade = grade
        self.schoolId = schoolId
        self.teacherIds = teacherIds
        self.classType = classType
        self.subjectType = subjectType
        self.period = period
        self.scheduleDay = scheduleDay
    }
    
    /// Creates from Firestore document
    static func fromDocument(_ doc: DocumentSnapshot) -> SchoolClass? {
        guard let data = doc.data() else { return nil }
        return SchoolClass(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            grade: data["grade"] as? Int ?? 0,
            schoolId: data["schoolId"] as? String ?? "",
            teacherIds: data["teacherIds"] as? [String] ?? [],
            classType: ClassType(rawValue: data["classType"] as? String ?? "") ?? .regular,
            subjectType: SubjectType(rawValue: data["subjectType"] as? String ?? "") ?? .homeroom,
            period: data["period"] as? Int,
            scheduleDay: data["scheduleDay"] as? String
        )
    }
}
