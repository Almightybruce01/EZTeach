//
//  FirestoreService.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

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

        let normalizedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        let result = try await Auth.auth()
            .createUser(withEmail: normalizedEmail, password: password)

        let uid = result.user.uid
        let schoolRef = db.collection("schools").document()
        let grades = Array(gradesFrom...gradesTo)

        let normalizedSchoolCode = schoolCode.trimmingCharacters(in: .whitespaces).uppercased()
        try await schoolRef.setData([
            "name": name,
            "address": address,
            "city": city,
            "state": state,
            "zip": zip,
            "schoolCode": normalizedSchoolCode,
            "grades": grades,
            "ownerUid": uid,
            "subscriptionStatus": "inactive",
            "subscriptionActive": false,
            "subscriptionEndDate": NSNull(),
            "createdAt": Timestamp()
        ])

        try await db.collection("users").document(uid).setData([
            "email": normalizedEmail,
            "role": "school",
            "fullName": name,
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
        address: String,
        city: String,
        state: String,
        zip: String,
        numberOfSchools: Int
    ) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        let result = try await Auth.auth()
            .createUser(withEmail: normalizedEmail, password: password)
        
        let uid = result.user.uid
        let districtRef = db.collection("districts").document()
        
        // Calculate pricing
        let pricing = District.calculatePrice(schoolCount: numberOfSchools)
        
        try await districtRef.setData([
            "name": districtName,
            "ownerUid": uid,
            "adminFirstName": firstName,
            "adminLastName": lastName,
            "adminEmail": normalizedEmail,
            "adminPhone": phone,
            "address": address,
            "city": city,
            "state": state,
            "zip": zip,
            "schoolCount": numberOfSchools,
            "schoolIds": [],
            "subscriptionTier": pricing.tier.rawValue,
            "monthlyPrice": pricing.total,
            "pricePerSchool": pricing.pricePerSchool,
            "subscriptionStatus": "inactive",
            "subscriptionActive": false,
            "subscriptionEndDate": NSNull(),
            "createdAt": Timestamp()
        ])
        
        try await db.collection("users").document(uid).setData([
            "email": normalizedEmail,
            "role": "district",
            "districtId": districtRef.documentID,
            "firstName": firstName,
            "lastName": lastName,
            "fullName": "\(firstName) \(lastName)",
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
        staffType: String? = nil, // "principal" | "assistant_principal" | "assistant_teacher" | "secretary" — no grade required
        firstName: String,
        lastName: String
    ) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        let result = try await Auth.auth()
            .createUser(withEmail: normalizedEmail, password: password)

        let uid = result.user.uid
        let fullName = "\(firstName) \(lastName)"

        var userData: [String: Any] = [
            "email": normalizedEmail,
            "role": role,
            "firstName": firstName,
            "lastName": lastName,
            "fullName": fullName,
            "activeSchoolId": NSNull(),
            "joinedSchools": [],
            "createdAt": Timestamp()
        ]
        if let st = staffType { userData["staffType"] = st }
        try await db.collection("users").document(uid).setData(userData)

        if role == "teacher" {
            let ref = db.collection("teachers").document()
            var teacherData: [String: Any] = [
                "userId": uid,
                "firstName": firstName,
                "lastName": lastName,
                "displayName": fullName,
                "schoolId": NSNull(),
                "grades": [],
                "createdAt": Timestamp()
            ]
            if let st = staffType { teacherData["staffType"] = st }
            try await ref.setData(teacherData)
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
        let normalizedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        let result = try await Auth.auth()
            .createUser(withEmail: normalizedEmail, password: password)
        
        let uid = result.user.uid
        let fullName = "\(firstName) \(lastName)"
        
        try await db.collection("users").document(uid).setData([
            "email": normalizedEmail,
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
            "email": normalizedEmail,
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

        let normalizedCode = code.trimmingCharacters(in: .whitespaces).uppercased()
        let snap = try await db.collection("schools")
            .whereField("schoolCode", isEqualTo: normalizedCode)
            .getDocuments()

        guard let schoolDoc = snap.documents.first else {
            throw NSError(domain: "InvalidSchoolCode", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid school code"])
        }

        let schoolId = schoolDoc.documentID
        let schoolData = schoolDoc.data()
        let schoolName = schoolData["name"] as? String ?? "School"
        let schoolCity = schoolData["city"] as? String ?? ""

        // Block join if school has not activated subscription — teachers/subs/parents cannot access until school subscribes
        let subscriptionActive = schoolData["subscriptionActive"] as? Bool ?? false
        if !subscriptionActive {
            throw NSError(domain: "SchoolNotSubscribed", code: 0, userInfo: [NSLocalizedDescriptionKey: "This school has not activated their account yet. Teachers, subs, and parents cannot join until the school administrator completes setup on our website. Please ask the school to manage their account at ezteach.org."])
        }

        let userRef = db.collection("users").document(uid)
        let userSnap = try await userRef.getDocument()
        let userData = userSnap.data() ?? [:]

        let userRole = userData["role"] as? String ?? ""
        let firstName = userData["firstName"] as? String ?? ""
        let lastName = userData["lastName"] as? String ?? ""
        let fullName = userData["fullName"] as? String ?? "\(firstName) \(lastName)"

        var joinedSchools = userData["joinedSchools"] as? [[String: String]] ?? []

        if !joinedSchools.contains(where: { $0["id"] == schoolId }) {
            joinedSchools.append(["id": schoolId, "name": schoolName, "city": schoolCity])
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

    /// Search schools by name, city, or code. Returns array of { id, name, city, schoolCode }.
    func searchSchools(searchText: String) async throws -> [[String: Any]] {
        let functions = Functions.functions()
        let result = try await functions.httpsCallable("searchSchools").call(["searchText": searchText])
        return (result.data as? [[String: Any]]) ?? []
    }

    /// Create a school for district subscription (full account: Auth + users + schools). Returns (id, code, name).
    func createSchoolForDistrict(
        name: String,
        address: String,
        city: String,
        state: String,
        zip: String,
        schoolCode: String,
        adminEmail: String,
        adminPassword: String,
        adminFirstName: String,
        adminLastName: String
    ) async throws -> (id: String, code: String, name: String) {
        let code = schoolCode
        let existing = try await lookupSchoolByCode(code)
        if existing != nil {
            throw NSError(domain: "CreateSchool", code: 0, userInfo: [NSLocalizedDescriptionKey: "School code \(code) is already in use."])
        }

        let result = try await Auth.auth().createUser(withEmail: adminEmail, password: adminPassword)
        let uid = result.user.uid
        let fullName = "\(adminFirstName) \(adminLastName)"

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
            "ownerUid": uid,
            "subscriptionStatus": "inactive",
            "subscriptionActive": false,
            "subscriptionEndDate": NSNull(),
            "createdAt": Timestamp()
        ])

        try await db.collection("users").document(uid).setData([
            "email": adminEmail,
            "role": "school",
            "firstName": adminFirstName,
            "lastName": adminLastName,
            "fullName": fullName,
            "activeSchoolId": ref.documentID,
            "joinedSchools": [["id": ref.documentID, "name": name, "city": city]],
            "createdAt": Timestamp()
        ])

        return (ref.documentID, code, name)
    }

    // =========================================================
    // MARK: - CREATE STUDENT (via Cloud Function - globally unique studentCode, correct passwordHash)
    // =========================================================
    func createStudent(
        firstName: String,
        middleName: String,
        lastName: String,
        gradeLevel: Int,
        schoolId: String,
        dateOfBirth: Date? = nil,
        notes: String = "",
        email: String? = nil
    ) async throws -> Student {
        var payload: [String: Any] = [
            "schoolId": schoolId,
            "firstName": firstName.trimmingCharacters(in: .whitespaces),
            "middleName": middleName.trimmingCharacters(in: .whitespaces),
            "lastName": lastName.trimmingCharacters(in: .whitespaces),
            "gradeLevel": gradeLevel,
            "notes": notes.trimmingCharacters(in: .whitespaces)
        ]
        if let dob = dateOfBirth {
            payload["dateOfBirth"] = ["_seconds": Int64(dob.timeIntervalSince1970)]
        }
        if let em = email?.trimmingCharacters(in: .whitespaces).lowercased(), !em.isEmpty, em.contains("@") {
            payload["email"] = em
        }
        let result = try await Functions.functions().httpsCallable("createStudent").call(payload)
        guard let data = result.data as? [String: Any] else {
            throw NSError(domain: "CreateStudent", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        let id = data["id"] as? String ?? ""
        let sc = (data["studentCode"] as? String ?? "").uppercased()
        var createdAt = Date()
        if let ts = data["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else if let sec = (data["createdAt"] as? [String: Any])?["_seconds"] as? Int64 {
            createdAt = Date(timeIntervalSince1970: TimeInterval(sec))
        }
        var dob: Date?
        if let ts = data["dateOfBirth"] as? Timestamp {
            dob = ts.dateValue()
        } else if let sec = (data["dateOfBirth"] as? [String: Any])?["_seconds"] as? Int64 {
            dob = Date(timeIntervalSince1970: TimeInterval(sec))
        }
        return Student(
            id: id,
            firstName: data["firstName"] as? String ?? "",
            middleName: data["middleName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            studentCode: sc,
            gradeLevel: data["gradeLevel"] as? Int ?? 0,
            dateOfBirth: dob,
            notes: data["notes"] as? String ?? "",
            parentIds: data["parentIds"] as? [String] ?? [],
            createdAt: createdAt,
            email: data["email"] as? String,
            passwordChangedAt: nil
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
    // MARK: - LEAVE SCHOOL (teachers/subs — reversible)
    // =========================================================
    func leaveSchool(_ schoolId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

        let userRef = db.collection("users").document(uid)
        let userSnap = try await userRef.getDocument()
        guard let userData = userSnap.data() else {
            throw NSError(domain: "UserError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        let role = userData["role"] as? String ?? ""
        guard role == "teacher" || role == "sub" else {
            throw NSError(domain: "RoleError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Only teachers and subs can leave schools"])
        }

        var joinedSchools = userData["joinedSchools"] as? [[String: String]] ?? []
        joinedSchools.removeAll { $0["id"] == schoolId }

        let activeSchoolId = userData["activeSchoolId"] as? String
        let newActiveIdValue: String? = (activeSchoolId == schoolId)
            ? joinedSchools.first?["id"]
            : activeSchoolId
        let newActiveId: Any = newActiveIdValue ?? NSNull()

        var updates: [String: Any] = [
            "joinedSchools": joinedSchools,
            "activeSchoolId": newActiveId
        ]
        if activeSchoolId == schoolId, let first = joinedSchools.first {
            updates["schoolName"] = first["name"] ?? NSNull()
        } else if activeSchoolId == schoolId {
            updates["schoolName"] = NSNull()
        }

        try await userRef.updateData(updates)

        let nextSchoolId: Any = joinedSchools.first?["id"] ?? NSNull()
        if role == "teacher" {
            let tq = try await db.collection("teachers").whereField("userId", isEqualTo: uid).limit(to: 1).getDocuments()
            if let td = tq.documents.first, (td.data()["schoolId"] as? String) == schoolId {
                try await td.reference.updateData(["schoolId": nextSchoolId])
            }
        } else if role == "sub" {
            let sq = try await db.collection("subs").whereField("userId", isEqualTo: uid).limit(to: 1).getDocuments()
            if let sd = sq.documents.first, (sd.data()["schoolId"] as? String) == schoolId {
                try await sd.reference.updateData(["schoolId": nextSchoolId])
            }
        }
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
