//
//  StandardsService.swift
//  EZTeach
//
//  Manages education standards with national → state → district → school resolution.
//

import Foundation
import Combine
import FirebaseFirestore

class StandardsService: ObservableObject {
    static let shared = StandardsService()

    @Published var resolvedStandards: [ResolvedStandard] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()

    // =========================================================
    // MARK: - RESOLUTION LOGIC
    // School Override → District → State → National
    // =========================================================
    func resolveStandards(
        stateCode: String,
        subject: String,
        grade: Int,
        districtId: String? = nil,
        schoolId: String? = nil
    ) async -> [ResolvedStandard] {

        // 1. Start with national base standards for this subject + grade
        var standards = baseStandards(subject: subject, grade: grade, stateCode: "DEFAULT")

        // 2. Layer state standards (overrides matching national ones)
        let stateStds = baseStandards(subject: subject, grade: grade, stateCode: stateCode)
        for stateStd in stateStds {
            if let idx = standards.firstIndex(where: { $0.standardId == stateStd.standardId }) {
                standards[idx] = stateStd
            } else {
                standards.append(stateStd)
            }
        }

        // 3. Layer state overrides from Firestore
        let stateOverrides = await fetchStateOverrides(stateCode: stateCode, subject: subject, grade: grade)
        for override in stateOverrides {
            if let idx = standards.firstIndex(where: { $0.standardId == override.replacesStandardId }) {
                standards[idx] = ResolvedStandard(
                    id: override.newStandardId,
                    standardId: override.newStandardId,
                    framework: stateCode,
                    subject: subject,
                    grade: grade,
                    description: override.description,
                    source: "State Override (\(stateCode))",
                    resolvedFrom: "state",
                    isOverridden: true
                )
            }
        }

        // 4. Layer district custom standards
        if let districtId {
            let districtStds = await fetchDistrictStandards(districtId: districtId, subject: subject, grade: grade)
            for ds in districtStds {
                standards.append(ResolvedStandard(
                    id: ds.id,
                    standardId: ds.id,
                    framework: "District",
                    subject: ds.subject,
                    grade: ds.grade,
                    description: ds.description,
                    source: "District Custom",
                    resolvedFrom: "district",
                    isOverridden: false
                ))
            }
        }

        // 5. Layer school overrides
        if let schoolId {
            let schoolOverrides = await fetchSchoolOverrides(schoolId: schoolId)
            for override in schoolOverrides {
                if let idx = standards.firstIndex(where: { $0.standardId == override.overridesStandardId }) {
                    let base = standards[idx]
                    standards[idx] = ResolvedStandard(
                        id: base.id,
                        standardId: base.standardId,
                        framework: base.framework,
                        subject: base.subject,
                        grade: base.grade,
                        description: override.customDescription,
                        source: "School Override",
                        resolvedFrom: "school",
                        isOverridden: true
                    )
                }
            }
        }

        return standards
    }

    // =========================================================
    // MARK: - BASE STANDARDS (Shipped with app)
    // =========================================================
    func baseStandards(subject: String, grade: Int, stateCode: String) -> [ResolvedStandard] {
        let mapping = StateStandardMapping.mapping(for: stateCode)
        let framework = mapping.subjectMappings[subject] ?? .ccss

        switch subject {
        case "Math":
            return mathStandards(grade: grade, framework: framework)
        case "ELA", "Reading", "Writing":
            return elaStandards(grade: grade, framework: framework)
        case "Science":
            return scienceStandards(grade: grade, framework: framework)
        case "Social Studies":
            return socialStudiesStandards(grade: grade, framework: framework)
        case "PE":
            return peStandards(grade: grade)
        case "Health":
            return healthStandards(grade: grade)
        case "Computer Science":
            return csStandards(grade: grade)
        default:
            return generalStandards(subject: subject, grade: grade, framework: framework)
        }
    }

    // MARK: Math Standards
    private func mathStandards(grade: Int, framework: StandardFramework) -> [ResolvedStandard] {
        let prefix = framework.rawValue
        let g = grade
        return [
            ResolvedStandard(id: "\(prefix).MATH.\(g).OA.1", standardId: "\(prefix).MATH.\(g).OA.1", framework: prefix, subject: "Math", grade: g, description: "Operations & Algebraic Thinking — Represent and solve problems involving addition, subtraction, multiplication, and division.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).MATH.\(g).NBT.1", standardId: "\(prefix).MATH.\(g).NBT.1", framework: prefix, subject: "Math", grade: g, description: "Number & Operations in Base Ten — Understand place value system and perform multi-digit arithmetic.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).MATH.\(g).NF.1", standardId: "\(prefix).MATH.\(g).NF.1", framework: prefix, subject: "Math", grade: g, description: "Number & Operations — Fractions: Develop understanding of fractions as numbers and equivalent fractions.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).MATH.\(g).MD.1", standardId: "\(prefix).MATH.\(g).MD.1", framework: prefix, subject: "Math", grade: g, description: "Measurement & Data — Solve problems involving measurement, data representation, and geometric measurement.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).MATH.\(g).G.1", standardId: "\(prefix).MATH.\(g).G.1", framework: prefix, subject: "Math", grade: g, description: "Geometry — Reason with shapes and their attributes; classify two-dimensional figures.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).MATH.PRACTICE.MP1", standardId: "\(prefix).MATH.PRACTICE.MP1", framework: prefix, subject: "Math", grade: g, description: "Make sense of problems and persevere in solving them.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).MATH.PRACTICE.MP4", standardId: "\(prefix).MATH.PRACTICE.MP4", framework: prefix, subject: "Math", grade: g, description: "Model with mathematics.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).MATH.PRACTICE.MP6", standardId: "\(prefix).MATH.PRACTICE.MP6", framework: prefix, subject: "Math", grade: g, description: "Attend to precision.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
        ]
    }

    // MARK: ELA Standards
    private func elaStandards(grade: Int, framework: StandardFramework) -> [ResolvedStandard] {
        let prefix = framework.rawValue
        let g = grade
        return [
            ResolvedStandard(id: "\(prefix).ELA.RL.\(g).1", standardId: "\(prefix).ELA.RL.\(g).1", framework: prefix, subject: "ELA", grade: g, description: "Read closely and cite textual evidence to support analysis of what the text says explicitly and by inference.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).ELA.RL.\(g).2", standardId: "\(prefix).ELA.RL.\(g).2", framework: prefix, subject: "ELA", grade: g, description: "Determine central ideas or themes of a text and analyze their development; summarize key details.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).ELA.RL.\(g).4", standardId: "\(prefix).ELA.RL.\(g).4", framework: prefix, subject: "ELA", grade: g, description: "Interpret words and phrases as they are used in a text, including figurative and connotative meanings.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).ELA.W.\(g).1", standardId: "\(prefix).ELA.W.\(g).1", framework: prefix, subject: "ELA", grade: g, description: "Write arguments / opinion pieces to support claims with clear reasons and relevant evidence.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).ELA.W.\(g).4", standardId: "\(prefix).ELA.W.\(g).4", framework: prefix, subject: "ELA", grade: g, description: "Produce clear and coherent writing appropriate to task, purpose, and audience.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).ELA.SL.\(g).1", standardId: "\(prefix).ELA.SL.\(g).1", framework: prefix, subject: "ELA", grade: g, description: "Prepare for and participate effectively in collaborative discussions.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
        ]
    }

    // MARK: Science Standards
    private func scienceStandards(grade: Int, framework: StandardFramework) -> [ResolvedStandard] {
        let prefix = framework.rawValue
        let g = grade
        return [
            ResolvedStandard(id: "\(prefix).SCI.\(g).PS.1", standardId: "\(prefix).SCI.\(g).PS.1", framework: prefix, subject: "Science", grade: g, description: "Physical Science — Matter and Its Interactions: Develop models to describe the atomic composition of simple molecules.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).SCI.\(g).LS.1", standardId: "\(prefix).SCI.\(g).LS.1", framework: prefix, subject: "Science", grade: g, description: "Life Science — From Molecules to Organisms: Use evidence to support explanations of how organisms grow, develop, and reproduce.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).SCI.\(g).ESS.1", standardId: "\(prefix).SCI.\(g).ESS.1", framework: prefix, subject: "Science", grade: g, description: "Earth & Space Science — Earth's Place in the Universe: Develop and use models of the Earth-sun-moon system.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "\(prefix).SCI.\(g).ETS.1", standardId: "\(prefix).SCI.\(g).ETS.1", framework: prefix, subject: "Science", grade: g, description: "Engineering & Technology — Define criteria and constraints of a design problem and evaluate competing solutions.", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
        ]
    }

    // MARK: Social Studies Standards
    private func socialStudiesStandards(grade: Int, framework: StandardFramework) -> [ResolvedStandard] {
        let g = grade
        return [
            ResolvedStandard(id: "C3.D2.His.\(g).1", standardId: "C3.D2.His.\(g).1", framework: "C3-Framework", subject: "Social Studies", grade: g, description: "History — Evaluate sources and use evidence to construct historical arguments.", source: "C3 Social Studies Framework", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "C3.D2.Geo.\(g).1", standardId: "C3.D2.Geo.\(g).1", framework: "C3-Framework", subject: "Social Studies", grade: g, description: "Geography — Create and use geographic representations to analyze spatial patterns.", source: "C3 Social Studies Framework", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "C3.D2.Civ.\(g).1", standardId: "C3.D2.Civ.\(g).1", framework: "C3-Framework", subject: "Social Studies", grade: g, description: "Civics — Analyze the origins, purposes, and impact of constitutions, laws, and key documents.", source: "C3 Social Studies Framework", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "C3.D4.\(g).1", standardId: "C3.D4.\(g).1", framework: "C3-Framework", subject: "Social Studies", grade: g, description: "Communicating Conclusions — Construct arguments using claims and evidence from multiple sources.", source: "C3 Social Studies Framework", resolvedFrom: "national", isOverridden: false),
        ]
    }

    // MARK: PE Standards
    private func peStandards(grade: Int) -> [ResolvedStandard] {
        let g = grade
        return [
            ResolvedStandard(id: "SHAPE.\(g).S1", standardId: "SHAPE.\(g).S1", framework: "SHAPE-America", subject: "PE", grade: g, description: "Motor Competence — Demonstrate competency in a variety of motor skills and movement patterns.", source: "SHAPE America", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "SHAPE.\(g).S3", standardId: "SHAPE.\(g).S3", framework: "SHAPE-America", subject: "PE", grade: g, description: "Physical Activity — Demonstrate the knowledge and skills to achieve and maintain a health-enhancing level of physical activity.", source: "SHAPE America", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "SHAPE.\(g).S5", standardId: "SHAPE.\(g).S5", framework: "SHAPE-America", subject: "PE", grade: g, description: "Value of Physical Activity — Recognize the value of physical activity for health, enjoyment, challenge, and social interaction.", source: "SHAPE America", resolvedFrom: "national", isOverridden: false),
        ]
    }

    // MARK: Health Standards
    private func healthStandards(grade: Int) -> [ResolvedStandard] {
        let g = grade
        return [
            ResolvedStandard(id: "NHES.\(g).1", standardId: "NHES.\(g).1", framework: "Health-Ed", subject: "Health", grade: g, description: "Comprehend concepts related to health promotion and disease prevention to enhance health.", source: "National Health Education Standards", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "NHES.\(g).5", standardId: "NHES.\(g).5", framework: "Health-Ed", subject: "Health", grade: g, description: "Demonstrate the ability to use decision-making skills to enhance health.", source: "National Health Education Standards", resolvedFrom: "national", isOverridden: false),
        ]
    }

    // MARK: Computer Science Standards
    private func csStandards(grade: Int) -> [ResolvedStandard] {
        let g = grade
        return [
            ResolvedStandard(id: "CSTA.\(g).AP.1", standardId: "CSTA.\(g).AP.1", framework: "CSTA", subject: "Computer Science", grade: g, description: "Algorithms & Programming — Design and iteratively develop programs that combine control structures.", source: "CSTA Computer Science", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "CSTA.\(g).DA.1", standardId: "CSTA.\(g).DA.1", framework: "CSTA", subject: "Computer Science", grade: g, description: "Data & Analysis — Collect, create, and transform data to identify patterns and make predictions.", source: "CSTA Computer Science", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "ISTE.\(g).CC.1", standardId: "ISTE.\(g).CC.1", framework: "ISTE", subject: "Digital Citizenship", grade: g, description: "Digital Citizenship — Cultivate and manage digital identity and reputation with an awareness of permanence.", source: "ISTE Standards", resolvedFrom: "national", isOverridden: false),
        ]
    }

    // MARK: General Standards
    private func generalStandards(subject: String, grade: Int, framework: StandardFramework) -> [ResolvedStandard] {
        let g = grade
        return [
            ResolvedStandard(id: "GEN.\(subject).\(g).1", standardId: "GEN.\(subject).\(g).1", framework: framework.rawValue, subject: subject, grade: g, description: "Aligned to \(subject) Grade \(GradeUtils.label(g)) State Standards", source: framework.displayName, resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "21C.\(g).CT", standardId: "21C.\(g).CT", framework: "21st-Century", subject: subject, grade: g, description: "21st Century Skills — Critical Thinking and Collaboration", source: "21st Century Learning", resolvedFrom: "national", isOverridden: false),
            ResolvedStandard(id: "SEL.\(g).SM", standardId: "SEL.\(g).SM", framework: "SEL", subject: subject, grade: g, description: "SEL Competency — Self-Management and Responsible Decision-Making", source: "Social-Emotional Learning", resolvedFrom: "national", isOverridden: false),
        ]
    }

    // =========================================================
    // MARK: - FIRESTORE QUERIES
    // =========================================================
    private func fetchStateOverrides(stateCode: String, subject: String, grade: Int) async -> [StateStandardOverride] {
        guard stateCode != "DEFAULT" else { return [] }
        do {
            let snap = try await db.collection("standardOverrides")
                .whereField("state", isEqualTo: stateCode)
                .whereField("subject", isEqualTo: subject)
                .getDocuments()
            return snap.documents.compactMap { doc -> StateStandardOverride? in
                let d = doc.data()
                return StateStandardOverride(
                    state: d["state"] as? String ?? "",
                    replacesStandardId: d["replacesStandardId"] as? String ?? "",
                    newStandardId: d["newStandardId"] as? String ?? "",
                    description: d["description"] as? String ?? "",
                    editable: false
                )
            }
        } catch { return [] }
    }

    private func fetchDistrictStandards(districtId: String, subject: String, grade: Int) async -> [DistrictStandard] {
        do {
            let snap = try await db.collection("districtStandards")
                .whereField("districtId", isEqualTo: districtId)
                .whereField("subject", isEqualTo: subject)
                .whereField("grade", isEqualTo: grade)
                .getDocuments()
            return snap.documents.compactMap { doc -> DistrictStandard? in
                let d = doc.data()
                return DistrictStandard(
                    id: doc.documentID,
                    districtId: d["districtId"] as? String ?? "",
                    subject: d["subject"] as? String ?? "",
                    grade: d["grade"] as? Int ?? 0,
                    description: d["description"] as? String ?? "",
                    editable: true,
                    createdAt: (d["createdAt"] as? Timestamp)?.dateValue()
                )
            }
        } catch { return [] }
    }

    private func fetchSchoolOverrides(schoolId: String) async -> [SchoolStandardOverride] {
        do {
            let snap = try await db.collection("schoolStandardOverrides")
                .whereField("schoolId", isEqualTo: schoolId)
                .getDocuments()
            return snap.documents.compactMap { doc -> SchoolStandardOverride? in
                let d = doc.data()
                return SchoolStandardOverride(
                    id: doc.documentID,
                    schoolId: d["schoolId"] as? String ?? "",
                    overridesStandardId: d["overridesStandardId"] as? String ?? "",
                    customDescription: d["customDescription"] as? String ?? "",
                    editable: true,
                    createdAt: (d["createdAt"] as? Timestamp)?.dateValue()
                )
            }
        } catch { return [] }
    }

    // =========================================================
    // MARK: - WRITE OPERATIONS (Permission-based)
    // =========================================================
    func addDistrictStandard(districtId: String, subject: String, grade: Int, description: String) async throws {
        try await db.collection("districtStandards").addDocument(data: [
            "districtId": districtId,
            "subject": subject,
            "grade": grade,
            "description": description,
            "editable": true,
            "createdAt": Timestamp()
        ])
    }

    func addSchoolOverride(schoolId: String, standardId: String, customDescription: String) async throws {
        try await db.collection("schoolStandardOverrides").addDocument(data: [
            "schoolId": schoolId,
            "overridesStandardId": standardId,
            "customDescription": customDescription,
            "editable": true,
            "createdAt": Timestamp()
        ])
    }

    func deleteDistrictStandard(id: String) async throws {
        try await db.collection("districtStandards").document(id).delete()
    }

    func deleteSchoolOverride(id: String) async throws {
        try await db.collection("schoolStandardOverrides").document(id).delete()
    }

    // =========================================================
    // MARK: - CONVENIENCE: Standards for AI Lesson Plans
    // =========================================================
    func standardsForLesson(subject: String, grade: Int, stateCode: String, districtId: String?, schoolId: String?) async -> [String] {
        let resolved = await resolveStandards(stateCode: stateCode, subject: subject, grade: grade, districtId: districtId, schoolId: schoolId)
        return resolved.map { "\($0.standardId) — \($0.description)" }
    }

    /// All subjects that have standards
    static let supportedSubjects = [
        "Math", "ELA", "Reading", "Writing", "Science",
        "Social Studies", "PE", "Health", "Computer Science",
        "Art", "Music"
    ]
}
