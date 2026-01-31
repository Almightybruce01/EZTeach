//
//  FirestoreService.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import FirebaseFirestore
import FirebaseAuth

final class FirestoreService {

    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // =========================================================
    // MARK: - CREATE SCHOOL ACCOUNT
    // =========================================================
    func createSchoolAccount(
        email: String,
        password: String,
        name: String,
        address: String,
        city: String,
        state: String,
        zip: String,
        gradesFrom: Int,
        gradesTo: Int,
        schoolCode: String
    ) async throws {

        let result = try await Auth.auth()
            .createUser(withEmail: email, password: password)

        let uid = result.user.uid
        let schoolRef = db.collection("schools").document()
        let grades = Array(gradesFrom...gradesTo)

        try await schoolRef.setData([
            "name": name,
            "address": address,
            "city": city,
            "state": state,
            "zip": zip,
            "schoolCode": schoolCode,
            "grades": grades,
            "ownerUid": uid,
            "subscriptionStatus": "trial",
            "subscriptionEndDate": NSNull(),
            "createdAt": Timestamp()
        ])

        try await db.collection("users").document(uid).setData([
            "email": email,
            "role": "school",
            "activeSchoolId": schoolRef.documentID,
            "joinedSchools": [
                ["id": schoolRef.documentID, "name": name]
            ],
            "createdAt": Timestamp()
        ])
    }

    // =========================================================
    // MARK: - CREATE DISTRICT ACCOUNT
    // =========================================================
    func createDistrictAccount(
        email: String,
        password: String,
        districtName: String,
        firstName: String,
        lastName: String,
        phone: String,
        numberOfSchools: Int
    ) async throws {
        
        let result = try await Auth.auth()
            .createUser(withEmail: email, password: password)
        
        let uid = result.user.uid
        let districtRef = db.collection("districts").document()
        
        // Calculate pricing
        let pricing = District.calculatePrice(schoolCount: numberOfSchools)
        
        try await districtRef.setData([
            "name": districtName,
            "ownerUid": uid,
            "adminFirstName": firstName,
            "adminLastName": lastName,
            "adminEmail": email,
            "adminPhone": phone,
            "schoolCount": numberOfSchools,
            "schoolIds": [],
            "subscriptionTier": pricing.tier.rawValue,
            "monthlyPrice": pricing.total,
            "pricePerSchool": pricing.pricePerSchool,
            "subscriptionStatus": "trial",
            "subscriptionEndDate": NSNull(),
            "createdAt": Timestamp()
        ])
        
        try await db.collection("users").document(uid).setData([
            "email": email,
            "role": "district",
            "districtId": districtRef.documentID,
            "firstName": firstName,
            "lastName": lastName,
            "phone": phone,
            "createdAt": Timestamp()
        ])
    }
    
    // =========================================================
    // MARK: - CREATE TEACHER/SUB ACCOUNT
    // =========================================================
    func createStaffAccount(
        email: String,
        password: String,
        role: String, // "teacher" | "sub"
        firstName: String,
        lastName: String
    ) async throws {

        let result = try await Auth.auth()
            .createUser(withEmail: email, password: password)

        let uid = result.user.uid
        let fullName = "\(firstName) \(lastName)"

        try await db.collection("users").document(uid).setData([
            "email": email,
            "role": role,
            "firstName": firstName,
            "lastName": lastName,
            "fullName": fullName,
            "activeSchoolId": NSNull(),
            "joinedSchools": [],
            "createdAt": Timestamp()
        ])

        if role == "teacher" {
            let ref = db.collection("teachers").document()
            try await ref.setData([
                "userId": uid,
                "firstName": firstName,
                "lastName": lastName,
                "displayName": fullName,
                "schoolId": NSNull(),
                "grades": [],
                "createdAt": Timestamp()
            ])
        } else if role == "sub" {
            let ref = db.collection("subs").document()
            try await ref.setData([
                "userId": uid,
                "firstName": firstName,
                "lastName": lastName,
                "schoolId": NSNull(),
                "createdAt": Timestamp()
            ])
        } else {
            throw NSError(domain: "InvalidRole", code: 0)
        }
    }

    // =========================================================
    // MARK: - CREATE PARENT ACCOUNT
    // =========================================================
    func createParentAccount(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String
    ) async throws {
        
        let result = try await Auth.auth()
            .createUser(withEmail: email, password: password)
        
        let uid = result.user.uid
        let fullName = "\(firstName) \(lastName)"
        
        try await db.collection("users").document(uid).setData([
            "email": email,
            "role": "parent",
            "firstName": firstName,
            "lastName": lastName,
            "fullName": fullName,
            "phone": phone,
            "activeSchoolId": NSNull(),
            "joinedSchools": [],
            "createdAt": Timestamp()
        ])
        
        let ref = db.collection("parents").document()
        try await ref.setData([
            "userId": uid,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": phone,
            "childrenIds": [],
            "schoolIds": [],
            "notificationsEnabled": true,
            "emailNotifications": true,
            "pushNotifications": true,
            "createdAt": Timestamp()
        ])
    }

    // =========================================================
    // MARK: - JOIN SCHOOL BY CODE
    // =========================================================
    func joinSchoolByCode(_ code: String) async throws {

        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

        let snap = try await db.collection("schools")
            .whereField("schoolCode", isEqualTo: code)
            .getDocuments()

        guard let schoolDoc = snap.documents.first else {
            throw NSError(domain: "InvalidSchoolCode", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid school code"])
        }

        let schoolId = schoolDoc.documentID
        let schoolName = schoolDoc.data()["name"] as? String ?? "School"

        let userRef = db.collection("users").document(uid)
        let userSnap = try await userRef.getDocument()
        let userData = userSnap.data() ?? [:]

        let userRole = userData["role"] as? String ?? ""
        let firstName = userData["firstName"] as? String ?? ""
        let lastName = userData["lastName"] as? String ?? ""
        let fullName = userData["fullName"] as? String ?? "\(firstName) \(lastName)"

        var joinedSchools = userData["joinedSchools"] as? [[String: String]] ?? []

        if !joinedSchools.contains(where: { $0["id"] == schoolId }) {
            joinedSchools.append(["id": schoolId, "name": schoolName])
        }

        try await userRef.setData([
            "joinedSchools": joinedSchools,
            "activeSchoolId": schoolId
        ], merge: true)

        if userRole == "teacher" {
            try await upsertTeacherProfile(userId: uid, schoolId: schoolId, firstName: firstName, lastName: lastName, fullName: fullName)
        } else if userRole == "sub" {
            try await upsertSubProfile(userId: uid, schoolId: schoolId, firstName: firstName, lastName: lastName)
        }
    }

    // =========================================================
    // MARK: - DISTRICT SCHOOL LOOKUP / CREATE
    // =========================================================

    /// Look up school by 6‑digit code. Returns (id, name, districtId) or nil.
    func lookupSchoolByCode(_ code: String) async throws -> (id: String, name: String, districtId: String?)? {
        let snap = try await db.collection("schools")
            .whereField("schoolCode", isEqualTo: code)
            .getDocuments()
        guard let doc = snap.documents.first else { return nil }
        let d = doc.data()
        return (
            doc.documentID,
            d["name"] as? String ?? "School",
            d["districtId"] as? String
        )
    }

    /// Create a school for district subscription (no user account). Returns (id, code, name).
    func createSchoolForDistrict(name: String, address: String, city: String, state: String, zip: String) async throws -> (id: String, code: String, name: String) {
        var code: String
        var existing: (id: String, name: String, districtId: String?)?
        repeat {
            code = String(format: "%06d", Int.random(in: 100_000...999_999))
            existing = try await lookupSchoolByCode(code)
        } while existing != nil

        let ref = db.collection("schools").document()
        let grades = Array(1...12)
        try await ref.setData([
            "name": name,
            "address": address,
            "city": city,
            "state": state,
            "zip": zip,
            "schoolCode": code,
            "grades": grades,
            "subscriptionStatus": "trial",
            "subscriptionEndDate": NSNull(),
            "createdAt": Timestamp()
        ])
        return (ref.documentID, code, name)
    }

    // =========================================================
    // MARK: - CREATE STUDENT
    // =========================================================
    func createStudent(
        firstName: String,
        middleName: String,
        lastName: String,
        gradeLevel: Int,
        schoolId: String,
        dateOfBirth: Date? = nil,
        notes: String = ""
    ) async throws -> Student {
        
        let studentCode = Student.generateStudentCode()
        
        let ref = db.collection("students").document()
        
        // Create duplicate key for checking
        let dobString: String
        if let dob = dateOfBirth {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            dobString = formatter.string(from: dob)
        } else {
            dobString = "nodob"
        }
        let duplicateKey = "\(firstName.lowercased())_\(middleName.lowercased())_\(lastName.lowercased())_\(dobString)"
        
        var data: [String: Any] = [
            "firstName": firstName,
            "middleName": middleName,
            "lastName": lastName,
            "schoolId": schoolId,
            "studentCode": studentCode,
            "gradeLevel": gradeLevel,
            "notes": notes,
            "parentIds": [],
            "duplicateKey": duplicateKey,
            "createdAt": Timestamp()
        ]
        
        if let dob = dateOfBirth {
            data["dateOfBirth"] = Timestamp(date: dob)
        }
        
        try await ref.setData(data)
        
        return Student(
            id: ref.documentID,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            schoolId: schoolId,
            studentCode: studentCode,
            gradeLevel: gradeLevel,
            dateOfBirth: dateOfBirth,
            notes: notes,
            parentIds: [],
            createdAt: Date()
        )
    }

    // =========================================================
    // MARK: - LINK PARENT TO STUDENT
    // =========================================================
    func linkParentToStudent(
        parentUserId: String,
        studentId: String,
        schoolId: String,
        relationship: String,
        isPrimaryContact: Bool,
        canPickup: Bool,
        emergencyContact: Bool
    ) async throws {
        
        let batch = db.batch()
        
        // 1. Add parent to student's parentIds
        let studentRef = db.collection("students").document(studentId)
        batch.updateData([
            "parentIds": FieldValue.arrayUnion([parentUserId])
        ], forDocument: studentRef)
        
        // 2. Create parent-student link
        let linkRef = db.collection("parentStudentLinks").document()
        batch.setData([
            "parentUserId": parentUserId,
            "studentId": studentId,
            "schoolId": schoolId,
            "relationship": relationship,
            "isPrimaryContact": isPrimaryContact,
            "canPickup": canPickup,
            "emergencyContact": emergencyContact,
            "createdAt": Timestamp()
        ], forDocument: linkRef)
        
        // 3. Update parent's profile
        let parentQuery = try await db.collection("parents")
            .whereField("userId", isEqualTo: parentUserId)
            .limit(to: 1)
            .getDocuments()
        
        if let parentDoc = parentQuery.documents.first {
            batch.updateData([
                "childrenIds": FieldValue.arrayUnion([studentId]),
                "schoolIds": FieldValue.arrayUnion([schoolId])
            ], forDocument: parentDoc.reference)
        }
        
        // 4. Update user's activeSchoolId
        let userRef = db.collection("users").document(parentUserId)
        batch.updateData([
            "activeSchoolId": schoolId
        ], forDocument: userRef)
        
        try await batch.commit()
    }

    // =========================================================
    // MARK: - GET PARENT'S CHILDREN
    // =========================================================
    func getParentChildren(parentUserId: String) async throws -> [Student] {
        let snap = try await db.collection("students")
            .whereField("parentIds", arrayContains: parentUserId)
            .getDocuments()
        
        return snap.documents.compactMap { Student.fromDocument($0) }
    }

    // =========================================================
    // MARK: - GET STUDENT BY CODE
    // =========================================================
    func getStudentByCode(_ code: String) async throws -> Student? {
        let snap = try await db.collection("students")
            .whereField("studentCode", isEqualTo: code.uppercased())
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snap.documents.first else { return nil }
        return Student.fromDocument(doc)
    }

    // =========================================================
    // MARK: - SAVE STUDENT GRADE
    // =========================================================
    func saveStudentGrade(
        assignmentId: String,
        studentId: String,
        classId: String,
        pointsEarned: Double?,
        pointsPossible: Double,
        isExcused: Bool,
        isMissing: Bool,
        isLate: Bool,
        comment: String?
    ) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0)
        }
        
        let docId = "\(classId)_\(studentId)_\(assignmentId)"
        
        var data: [String: Any] = [
            "assignmentId": assignmentId,
            "studentId": studentId,
            "classId": classId,
            "pointsPossible": pointsPossible,
            "isExcused": isExcused,
            "isMissing": isMissing,
            "isLate": isLate,
            "gradedByUserId": uid,
            "gradedAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        if let points = pointsEarned {
            data["pointsEarned"] = points
        }
        
        if let comment = comment {
            data["comment"] = comment
        }
        
        try await db.collection("studentGrades").document(docId).setData(data, merge: true)
    }

    // =========================================================
    // MARK: - CREATE ASSIGNMENT
    // =========================================================
    func createAssignment(
        classId: String,
        schoolId: String,
        name: String,
        categoryId: String,
        pointsPossible: Double,
        dueDate: Date?,
        description: String?
    ) async throws -> GradeAssignment {
        
        let ref = db.collection("gradeAssignments").document()
        
        var data: [String: Any] = [
            "classId": classId,
            "schoolId": schoolId,
            "name": name,
            "categoryId": categoryId,
            "pointsPossible": pointsPossible,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        if let dueDate = dueDate {
            data["dueDate"] = Timestamp(date: dueDate)
        }
        
        if let description = description {
            data["description"] = description
        }
        
        try await ref.setData(data)
        
        return GradeAssignment(
            id: ref.documentID,
            classId: classId,
            schoolId: schoolId,
            name: name,
            categoryId: categoryId,
            pointsPossible: pointsPossible,
            dueDate: dueDate,
            description: description,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // =========================================================
    // MARK: - SET GRADE OVERRIDE
    // =========================================================
    func setGradeOverride(
        classId: String,
        studentId: String,
        overridePercentage: Double?,
        overrideLetterGrade: String?,
        reason: String
    ) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0)
        }
        
        let userSnap = try await db.collection("users").document(uid).getDocument()
        let role = userSnap.data()?["role"] as? String ?? ""
        
        let docId = "\(classId)_\(studentId)"
        
        var data: [String: Any] = [
            "classId": classId,
            "studentId": studentId,
            "reason": reason,
            "overriddenByUserId": uid,
            "overriddenByRole": role,
            "updatedAt": Timestamp()
        ]
        
        if let pct = overridePercentage {
            data["overridePercentage"] = pct
        }
        
        if let letter = overrideLetterGrade {
            data["overrideLetterGrade"] = letter.uppercased()
        }
        
        try await db.collection("gradeOverrides").document(docId).setData(data, merge: true)
    }

    // =========================================================
    // MARK: - PRIVATE HELPERS
    // =========================================================
    private func upsertTeacherProfile(
        userId: String,
        schoolId: String,
        firstName: String,
        lastName: String,
        fullName: String
    ) async throws {

        let q = try await db.collection("teachers")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()

        if let doc = q.documents.first {
            try await doc.reference.setData([
                "schoolId": schoolId
            ], merge: true)
        } else {
            let ref = db.collection("teachers").document()
            try await ref.setData([
                "userId": userId,
                "firstName": firstName,
                "lastName": lastName,
                "displayName": fullName,
                "schoolId": schoolId,
                "grades": [],
                "createdAt": Timestamp()
            ])
        }
    }

    private func upsertSubProfile(
        userId: String,
        schoolId: String,
        firstName: String,
        lastName: String
    ) async throws {

        let q = try await db.collection("subs")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()

        if let doc = q.documents.first {
            try await doc.reference.setData([
                "schoolId": schoolId
            ], merge: true)
        } else {
            let ref = db.collection("subs").document()
            try await ref.setData([
                "userId": userId,
                "firstName": firstName,
                "lastName": lastName,
                "schoolId": schoolId,
                "createdAt": Timestamp()
            ])
        }
    }

    // =========================================================
    // MARK: - SYNC
    // =========================================================
    @MainActor
    func syncDerivedCollectionsForCurrentUser() async {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            let data = snap.data() ?? [:]

            let userRole = data["role"] as? String ?? ""
            guard let schoolId = data["activeSchoolId"] as? String else { return }

            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""
            let fullName = data["fullName"] as? String ?? "\(firstName) \(lastName)"

            if userRole == "teacher" {
                try await upsertTeacherProfile(userId: uid, schoolId: schoolId, firstName: firstName, lastName: lastName, fullName: fullName)
            } else if userRole == "sub" {
                try await upsertSubProfile(userId: uid, schoolId: schoolId, firstName: firstName, lastName: lastName)
            }

        } catch {
            print("❌ Sync failed:", error.localizedDescription)
        }
    }
}
