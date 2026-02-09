//
//  StudentsListView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct StudentsListView: View {

    enum StudentTab: String, CaseIterable {
        case myStudents = "My Students"
        case allStudents = "All Students"
    }

    @State private var allStudents: [Student] = []
    @State private var myStudentIds: Set<String> = []
    @State private var hasSchool = true
    @State private var schoolId = ""
    @State private var showAddStudent = false
    @State private var userRole = ""
    @State private var searchText = ""
    @State private var isDistrict = false
    @State private var schoolIds: [String] = []
    @State private var selectedSchoolId = ""
    @State private var schoolNames: [String: String] = [:]
    @State private var selectedTab: StudentTab = .myStudents
    @State private var selectedGradeFilter: Int = -99  // -99 means "All Grades"
    @State private var isLoading = true
    @State private var myClassNames: [String: String] = [:]   // studentId -> class name

    private let db = Firestore.firestore()

    private var effectiveSchoolId: String {
        !selectedSchoolId.isEmpty ? selectedSchoolId : schoolId
    }

    private var isTeacher: Bool { userRole == "teacher" }

    // Base students for current tab
    private var baseStudents: [Student] {
        if isTeacher && selectedTab == .myStudents {
            return allStudents.filter { myStudentIds.contains($0.id) }
        }
        return allStudents
    }

    // Grade-filtered students
    private var gradeFilteredStudents: [Student] {
        if selectedGradeFilter == -99 { return baseStudents }
        return baseStudents.filter { $0.gradeLevel == selectedGradeFilter }
    }

    // Search-filtered students
    private var filteredStudents: [Student] {
        if searchText.isEmpty { return gradeFilteredStudents }
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return gradeFilteredStudents.filter {
            $0.fullName.localizedCaseInsensitiveContains(q) ||
            $0.firstName.localizedCaseInsensitiveContains(q) ||
            $0.middleName.localizedCaseInsensitiveContains(q) ||
            $0.lastName.localizedCaseInsensitiveContains(q) ||
            $0.studentCode.localizedCaseInsensitiveContains(q)
        }
    }

    // Unique grades in the current base list
    private var availableGrades: [Int] {
        Array(Set(baseStudents.map { $0.gradeLevel })).sorted()
    }

    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // District school picker
                if isDistrict && schoolIds.count > 1 {
                    Picker("School", selection: $selectedSchoolId) {
                        ForEach(schoolIds, id: \.self) { sid in
                            Text(schoolNames[sid] ?? "School").tag(sid)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Teacher segment control
                if isTeacher {
                    Picker("View", selection: $selectedTab) {
                        ForEach(StudentTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Grade filter
                if availableGrades.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            gradeChip(label: "All Grades", value: -99)
                            ForEach(availableGrades, id: \.self) { grade in
                                gradeChip(label: GradeUtils.label(grade), value: grade)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                // Student count
                if !isLoading {
                    HStack {
                        Text("\(filteredStudents.count) student\(filteredStudents.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }

                if isLoading {
                    Spacer()
                    ProgressView("Loading students...")
                    Spacer()
                } else if filteredStudents.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredStudents) { student in
                            NavigationLink {
                                StudentProfileView(student: student)
                            } label: {
                                studentRow(student)
                            }
                        }
                        .onDelete(perform: deleteStudents)
                    }
                    .searchable(text: $searchText, prompt: "Search by name or Student ID")
                }
            }
        }
        .navigationTitle("Students")
        .toolbar {
            if userRole == "school" || userRole == "teacher" {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddStudent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddStudent) {
            AddStudentView(schoolId: effectiveSchoolId) {
                loadStudents()
                if isTeacher { loadMyStudents() }
            }
        }
        .onAppear(perform: loadInitialData)
        .onChange(of: selectedSchoolId) { _, _ in
            loadStudents()
            if isTeacher { loadMyStudents() }
        }
    }

    // MARK: - Grade Chip
    private func gradeChip(label: String, value: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                selectedGradeFilter = value
            }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        selectedGradeFilter == value
                            ? AnyShapeStyle(EZTeachColors.accentGradient)
                            : AnyShapeStyle(EZTeachColors.secondaryBackground)
                    )
                )
                .foregroundColor(selectedGradeFilter == value ? .white : .primary)
        }
    }

    // MARK: - Student Row
    private func studentRow(_ student: Student) -> some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(EZTeachColors.accent.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(student.firstName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(EZTeachColors.accent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    Text(GradeUtils.label(student.gradeLevel))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("Student ID: \(student.studentCode)")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }

                // Show class name for teacher's "My Students"
                if isTeacher && selectedTab == .myStudents,
                   let className = myClassNames[student.id] {
                    Text(className)
                        .font(.caption2)
                        .foregroundColor(EZTeachColors.accent)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // My Student indicator
                if isTeacher && selectedTab == .allStudents && myStudentIds.contains(student.id) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }

                // Parent indicator
                if !student.parentIds.isEmpty {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.success)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: isTeacher && selectedTab == .myStudents ? "person.badge.plus" : "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            if isTeacher && selectedTab == .myStudents {
                Text("No Students in Your Classes")
                    .font(.headline)
                Text("Add students to your class roster to see them here, or switch to \"All Students\" to browse the school roster.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No Students")
                    .font(.headline)
                Text("Add students to track grades and communicate with parents.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if userRole == "school" || userRole == "teacher" {
                Button {
                    showAddStudent = true
                } label: {
                    Label("Add Student", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(EZTeachColors.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding(40)
    }

    // MARK: - Actions
    private func deleteStudents(at offsets: IndexSet) {
        for index in offsets {
            let student = filteredStudents[index]
            db.collection("students").document(student.id).delete()
            if !student.schoolId.isEmpty {
                Task {
                    try? await FirestoreService.shared.adjustStudentCount(schoolId: student.schoolId, delta: -1)
                }
            }
        }
        loadStudents()
    }

    private func loadInitialData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            let role = data["role"] as? String ?? ""
            let district = (role == "district")

            DispatchQueue.main.async {
                userRole = role
                isDistrict = district
            }

            if district, let districtId = data["districtId"] as? String {
                db.collection("districts").document(districtId).getDocument { dSnap, _ in
                    let ids = dSnap?.data()?["schoolIds"] as? [String] ?? []
                    let firstId = ids.first ?? ""
                    var names: [String: String] = [:]
                    let group = DispatchGroup()
                    for sid in ids {
                        group.enter()
                        db.collection("schools").document(sid).getDocument { sSnap, _ in
                            names[sid] = sSnap?.data()?["name"] as? String ?? "School"
                            group.leave()
                        }
                    }
                    group.notify(queue: .main) {
                        schoolIds = ids
                        selectedSchoolId = firstId
                        schoolNames = names
                        schoolId = firstId
                        hasSchool = !ids.isEmpty
                        loadStudents()
                    }
                }
            } else if let school = data["activeSchoolId"] as? String {
                DispatchQueue.main.async {
                    schoolId = school
                    schoolIds = [school]
                    selectedSchoolId = school
                    hasSchool = true
                    loadStudents()
                    if role == "teacher" { loadMyStudents() }
                }
            } else {
                DispatchQueue.main.async {
                    hasSchool = false
                    isLoading = false
                }
            }
        }
    }

    private func loadStudents() {
        let sid = effectiveSchoolId
        guard !sid.isEmpty else { return }

        db.collection("students")
            .whereField("schoolId", isEqualTo: sid)
            .order(by: "lastName")
            .getDocuments { snapshot, _ in
                allStudents = snapshot?.documents.compactMap { Student.fromDocument($0) } ?? []
                isLoading = false
            }
    }

    /// For teachers: fetch studentIds from their class rosters
    private func loadMyStudents() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let sid = effectiveSchoolId
        guard !sid.isEmpty else { return }

        // 1) Find classes this teacher owns
        db.collection("classes")
            .whereField("schoolId", isEqualTo: sid)
            .whereField("teacherIds", arrayContains: uid)
            .getDocuments { snap, _ in
                guard let docs = snap?.documents, !docs.isEmpty else {
                    DispatchQueue.main.async {
                        myStudentIds = []
                        myClassNames = [:]
                    }
                    return
                }

                var classIdToName: [String: String] = [:]
                for doc in docs {
                    classIdToName[doc.documentID] = doc["name"] as? String ?? "Class"
                }

                let classIds = Array(classIdToName.keys)

                // 2) Get roster entries for these classes
                // Firestore "in" queries max 30 items; batch if needed
                let batches = stride(from: 0, to: classIds.count, by: 30).map {
                    Array(classIds[$0..<min($0 + 30, classIds.count)])
                }

                var allStudentIdToClass: [String: String] = [:]
                let group = DispatchGroup()

                for batch in batches {
                    group.enter()
                    db.collection("class_rosters")
                        .whereField("classId", in: batch)
                        .getDocuments { rosterSnap, _ in
                            for doc in rosterSnap?.documents ?? [] {
                                if let studentId = doc["studentId"] as? String,
                                   let classId = doc["classId"] as? String {
                                    allStudentIdToClass[studentId] = classIdToName[classId] ?? "Class"
                                }
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    myStudentIds = Set(allStudentIdToClass.keys)
                    myClassNames = allStudentIdToClass
                }
            }
    }
}

// MARK: - Add Student View
struct AddStudentView: View {
    
    let schoolId: String
    let onSuccess: () -> Void
    
    @State private var firstName = ""
    @State private var middleName = ""
    @State private var lastName = ""
    @State private var gradeLevel = 0
    @State private var dateOfBirth = Date()
    @State private var hasDOB = false
    @State private var notes = ""
    @State private var email = ""
    
    @State private var isSaving = false
    @State private var createdStudent: Student?
    @State private var showSuccess = false
    @State private var saveError: String?

    // Cap enforcement
    @State private var showCapReached = false
    @State private var currentCount = 0
    @State private var currentCap   = 200
    
    @Environment(\.dismiss) private var dismiss

    private var isFormValid: Bool {
        !firstName.isEmpty && !middleName.isEmpty && !lastName.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Middle Name (Required)", text: $middleName)
                    TextField("Last Name", text: $lastName)
                    
                    Picker("Grade Level", selection: $gradeLevel) {
                        ForEach(GradeUtils.allGrades, id: \.self) { g in
                            Text(GradeUtils.label(g)).tag(g)
                        }
                    }
                }
                
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(EZTeachColors.accent)
                        Text("Middle name is required to help prevent duplicate student records.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Date of Birth") {
                    Toggle("Include Date of Birth", isOn: $hasDOB)
                    
                    if hasDOB {
                        DatePicker("Birthday", selection: $dateOfBirth, displayedComponents: .date)
                    }
                }
                
                Section("Email (Optional)") {
                    TextField("student@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Text("Teachers, schools, and districts can add a student's email to their profile.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
                
                Section {
                    Button {
                        saveStudent()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            }
                            Text(isSaving ? "Creating..." : "Add Student")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Student Created!", isPresented: $showSuccess) {
                Button("Done") {
                    onSuccess()
                    dismiss()
                }
            } message: {
                if let student = createdStudent {
                    Text("Student ID: \(student.studentCode)\n\nDefault password: \(student.studentCode)!\n\nStudents sign in with Student Login using these credentials. Share the Student ID with parents so they can link their account.")
                }
            }
            .alert("Error", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            // Cap-reached modal
            .sheet(isPresented: $showCapReached) {
                StudentCapReachedSheet(
                    currentCount: currentCount,
                    cap: currentCap,
                    schoolId: schoolId,
                    onUpgraded: { newCap in
                        currentCap = newCap
                    }
                )
            }
        }
    }
    
    private func saveStudent() {
        guard isFormValid else { return }
        isSaving = true
        Task {
            do {
                // Check student cap before creating
                let capCheck = try await FirestoreService.shared.checkStudentCap(schoolId: schoolId)
                if !capCheck.allowed {
                    await MainActor.run {
                        currentCount = capCheck.count
                        currentCap   = capCheck.cap
                        showCapReached = true
                        isSaving = false
                    }
                    return
                }

                let student = try await FirestoreService.shared.createStudent(
                    firstName: firstName,
                    middleName: middleName,
                    lastName: lastName,
                    gradeLevel: gradeLevel,
                    schoolId: schoolId,
                    dateOfBirth: hasDOB ? dateOfBirth : nil,
                    notes: notes,
                    email: email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email
                )
                // Increment the counter (Cloud Function also does this, belt + suspenders)
                try? await FirestoreService.shared.adjustStudentCount(schoolId: schoolId, delta: 1)

                await MainActor.run {
                    createdStudent = student
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    saveError = (error as NSError).localizedDescription
                }
            }
            await MainActor.run { isSaving = false }
        }
    }
}

// MARK: - Student Cap Reached Sheet (reusable)
struct StudentCapReachedSheet: View {
    let currentCount: Int
    let cap: Int
    let schoolId: String
    var onUpgraded: ((Int) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var upgradeError: String?
    @State private var isUpgrading = false

    private let tiers = FirestoreService.schoolTiers

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("Student Limit Reached")
                    .font(.title2.bold())

                Text("Your plan supports **\(cap)** students. You currently have **\(currentCount)**.\nUpgrade to continue adding students.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider()

                ForEach(tiers, id: \.tier) { t in
                    if t.cap > cap {
                        Button {
                            doUpgrade(t)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.label).font(.subheadline.bold())
                                    Text("Up to \(t.cap) students").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("$\(t.price)/mo")
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundColor(EZTeachColors.accent)
                            }
                            .padding(12)
                            .background(EZTeachColors.secondaryBackground)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if isUpgrading {
                    ProgressView("Upgrading…")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Upgrade Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(upgradeError != nil)) {
                Button("OK") { upgradeError = nil }
            } message: {
                Text(upgradeError ?? "")
            }
        }
    }

    private func doUpgrade(_ t: (tier: String, label: String, cap: Int, price: Int)) {
        isUpgrading = true
        Task {
            do {
                try await FirestoreService.shared.upgradeSchoolTier(schoolId: schoolId, newTier: t.tier)
                await MainActor.run {
                    onUpgraded?(t.cap)
                    dismiss()
                }
            } catch {
                await MainActor.run { upgradeError = error.localizedDescription }
            }
            await MainActor.run { isUpgrading = false }
        }
    }
}
