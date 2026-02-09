//
//  EducationStandard.swift
//  EZTeach
//
//  Dynamic education standards system with national, state, district,
//  and school-level control.
//

import Foundation

// MARK: - Base Standard (read-only)
struct EducationStandard: Identifiable, Hashable, Codable {
    let id: String               // e.g. "CCSS.MATH.5.NBT.1"
    let framework: String        // "CCSS", "NGSS", "TEKS", etc.
    let subject: String          // "Math", "ELA", "Science", etc.
    let grade: Int               // 0-14 matching GradeUtils
    let state: String            // "DEFAULT" for national, "TX" for Texas, etc.
    let description: String
    let source: String           // "Common Core", "Next Generation Science", etc.
    let editable: Bool           // false for base standards

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: EducationStandard, rhs: EducationStandard) -> Bool { lhs.id == rhs.id }
}

// MARK: - State Override
struct StateStandardOverride: Identifiable, Codable {
    var id: String { "\(state)-\(newStandardId)" }
    let state: String
    let replacesStandardId: String
    let newStandardId: String
    let description: String
    let editable: Bool // false for state-defined
}

// MARK: - District Custom Standard
struct DistrictStandard: Identifiable, Codable {
    let id: String               // auto-generated
    let districtId: String
    let subject: String
    let grade: Int
    let description: String
    let editable: Bool           // true
    let createdAt: Date?
}

// MARK: - School Override
struct SchoolStandardOverride: Identifiable, Codable {
    let id: String               // auto-generated
    let schoolId: String
    let overridesStandardId: String
    let customDescription: String
    let editable: Bool           // true
    let createdAt: Date?
}

// MARK: - Resolved Standard (what AI & views use)
struct ResolvedStandard: Identifiable, Hashable {
    let id: String
    let standardId: String
    let framework: String
    let subject: String
    let grade: Int
    let description: String
    let source: String           // "National", "State", "District", "School"
    let resolvedFrom: String     // which level it came from
    let isOverridden: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ResolvedStandard, rhs: ResolvedStandard) -> Bool { lhs.id == rhs.id }
}

// MARK: - Supported Frameworks
enum StandardFramework: String, CaseIterable, Codable {
    case ccss = "CCSS"
    case ngss = "NGSS"
    case teks = "TEKS"
    case best = "B.E.S.T."
    case caCCSS = "CA-CCSS"
    case nyNextGen = "NY-NextGen"
    case ilStandards = "IL-Standards"
    case vaSOL = "VA-SOL"
    case gaExcellence = "GA-Excellence"
    case shapeAmerica = "SHAPE-America"
    case healthEd = "Health-Ed"
    case csta = "CSTA"
    case iste = "ISTE"
    case idea = "IDEA"
    case c3Framework = "C3-Framework"

    var displayName: String {
        switch self {
        case .ccss: return "Common Core (CCSS)"
        case .ngss: return "Next Generation Science (NGSS)"
        case .teks: return "Texas TEKS"
        case .best: return "Florida B.E.S.T."
        case .caCCSS: return "California CCSS"
        case .nyNextGen: return "New York Next Gen"
        case .ilStandards: return "Illinois Standards"
        case .vaSOL: return "Virginia SOL"
        case .gaExcellence: return "Georgia Standards of Excellence"
        case .shapeAmerica: return "SHAPE America (PE)"
        case .healthEd: return "National Health Education"
        case .csta: return "CSTA Computer Science"
        case .iste: return "ISTE Digital Citizenship"
        case .idea: return "IDEA Special Education"
        case .c3Framework: return "C3 Social Studies Framework"
        }
    }

    var icon: String {
        switch self {
        case .ccss: return "book.fill"
        case .ngss: return "atom"
        case .teks: return "star.fill"
        case .best: return "sun.max.fill"
        case .caCCSS: return "leaf.fill"
        case .nyNextGen: return "building.fill"
        case .ilStandards: return "flag.fill"
        case .vaSOL: return "mountain.2.fill"
        case .gaExcellence: return "peach"
        case .shapeAmerica: return "figure.run"
        case .healthEd: return "heart.fill"
        case .csta: return "desktopcomputer"
        case .iste: return "globe"
        case .idea: return "person.fill.checkmark"
        case .c3Framework: return "map.fill"
        }
    }
}

// MARK: - State Mapping
struct StateStandardMapping {
    let stateCode: String
    let stateName: String
    let defaultFrameworks: [StandardFramework]
    let subjectMappings: [String: StandardFramework]

    static let allStates: [StateStandardMapping] = [
        StateStandardMapping(stateCode: "DEFAULT", stateName: "National Default",
                             defaultFrameworks: [.ccss, .ngss, .c3Framework, .shapeAmerica, .healthEd, .csta, .iste, .idea],
                             subjectMappings: ["Math": .ccss, "ELA": .ccss, "Science": .ngss, "Social Studies": .c3Framework, "PE": .shapeAmerica, "Health": .healthEd, "Computer Science": .csta, "Digital Citizenship": .iste]),
        StateStandardMapping(stateCode: "TX", stateName: "Texas",
                             defaultFrameworks: [.teks],
                             subjectMappings: ["Math": .teks, "ELA": .teks, "Science": .teks, "Social Studies": .teks]),
        StateStandardMapping(stateCode: "FL", stateName: "Florida",
                             defaultFrameworks: [.best],
                             subjectMappings: ["Math": .best, "ELA": .best, "Science": .ngss]),
        StateStandardMapping(stateCode: "CA", stateName: "California",
                             defaultFrameworks: [.caCCSS, .ngss],
                             subjectMappings: ["Math": .caCCSS, "ELA": .caCCSS, "Science": .ngss]),
        StateStandardMapping(stateCode: "NY", stateName: "New York",
                             defaultFrameworks: [.nyNextGen, .ngss],
                             subjectMappings: ["Math": .nyNextGen, "ELA": .nyNextGen, "Science": .ngss]),
        StateStandardMapping(stateCode: "IL", stateName: "Illinois",
                             defaultFrameworks: [.ilStandards, .ngss],
                             subjectMappings: ["Math": .ilStandards, "ELA": .ilStandards, "Science": .ngss]),
        StateStandardMapping(stateCode: "VA", stateName: "Virginia",
                             defaultFrameworks: [.vaSOL],
                             subjectMappings: ["Math": .vaSOL, "ELA": .vaSOL, "Science": .vaSOL]),
        StateStandardMapping(stateCode: "GA", stateName: "Georgia",
                             defaultFrameworks: [.gaExcellence, .ngss],
                             subjectMappings: ["Math": .gaExcellence, "ELA": .gaExcellence, "Science": .ngss]),
    ]

    static func mapping(for stateCode: String) -> StateStandardMapping {
        allStates.first(where: { $0.stateCode == stateCode }) ?? allStates[0]
    }
}
