//
//  GradesListView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GradesListView: View {

    @State private var grades: [Int] = []
    @State private var classes: [SchoolClass] = []
    @State private var hasSchool = true
    @State private var activeSchoolId = ""
    @State private var role = ""
    @State private var showEditGrades = false
    @State private var showAddClassroom = false
    @State private var isLoading = true

    private let db = Firestore.firestore()

    /// Can this user manage classrooms?
    private var canManage: Bool {
        role == "school" || role == "district" || role == "teacher"
    }

    /// Classes grouped by grade, sorted
    private var classesForGrade: [Int: [SchoolClass]] {
        Dictionary(grouping: classes, by: \.grade)
    }

    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()

            if !hasSchool {
                VStack(spacing: 12) {
                    Image(systemName: "building.2")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No grades configured.")
                        .foregroundColor(.secondary)
                }
            } else if isLoading {
                ProgressView("Loading...")
            } else {
                List {
                    ForEach(grades, id: \.self) { grade in
                        Section {
                            // Classes under this grade
                            let gradeClasses = classesForGrade[grade] ?? []

                            if gradeClasses.isEmpty {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.secondary)
                                    Text("No classrooms yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                ForEach(gradeClasses) { cls in
                                    NavigationLink {
                                        ClassDetailView(schoolClass: cls, userRole: role)
                                    } label: {
                                        classRow(cls)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteClasses(in: grade, at: offsets)
                                }
                            }
                        } header: {
                            HStack {
                                Text(GradeUtils.label(grade))
                                    .font(.headline)
                                Spacer()
                                Text("\(classesForGrade[grade]?.count ?? 0) class\((classesForGrade[grade]?.count ?? 0) == 1 ? "" : "es")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(EZTeachColors.background)
            }
        }
        .navigationTitle("Grades & Classrooms")
        .toolbar {
            if canManage {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddClassroom = true
                        } label: {
                            Label("Add Classroom", systemImage: "plus.rectangle.on.folder")
                        }

                        if role == "school" || role == "district" {
                            Button {
                                showEditGrades = true
                            } label: {
                                Label("Edit Grade Levels", systemImage: "pencil")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditGrades, onDismiss: reloadAll) {
            EditGradesView()
        }
        .sheet(isPresented: $showAddClassroom, onDismiss: reloadAll) {
            AddClassroomSheet(schoolId: activeSchoolId, availableGrades: grades)
        }
        .onAppear {
            loadUser()
        }
    }

    // MARK: - Class Row
    private func classRow(_ cls: SchoolClass) -> some View {
        HStack(spacing: 12) {
            Image(systemName: cls.subjectType.icon)
                .font(.title3)
                .foregroundColor(EZTeachColors.accent)
                .frame(width: 36, height: 36)
                .background(EZTeachColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(cls.name.isEmpty ? "Unnamed Class" : cls.name)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 6) {
                    Text(cls.subjectType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if cls.classType != .regular {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(cls.classType.displayName)
                            .font(.caption)
                            .foregroundColor(EZTeachColors.accent)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Delete
    private func deleteClasses(in grade: Int, at offsets: IndexSet) {
        guard canManage else { return }
        let gradeClasses = classesForGrade[grade] ?? []
        for idx in offsets {
            let cls = gradeClasses[idx]
            Task {
                try? await FirestoreService.shared.deleteClassroom(classId: cls.id)
                await MainActor.run { reloadAll() }
            }
        }
    }

    // MARK: - Data Loading
    private func loadUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            role = snap?.data()?["role"] as? String ?? ""

            guard let schoolId = snap?.data()?["activeSchoolId"] as? String else {
                hasSchool = false
                isLoading = false
                return
            }

            activeSchoolId = schoolId
            reloadAll()
        }
    }

    private func reloadAll() {
        loadGrades()
        loadClasses()
    }

    private func loadGrades() {
        let sid = activeSchoolId
        guard !sid.isEmpty else { return }
        db.collection("schools")
            .document(sid)
            .getDocument { snap, _ in
                grades = snap?.data()?["grades"] as? [Int] ?? []
                grades.sort()
            }
    }

    private func loadClasses() {
        let sid = activeSchoolId
        guard !sid.isEmpty else { return }
        db.collection("classes")
            .whereField("schoolId", isEqualTo: sid)
            .order(by: "grade")
            .getDocuments { snap, _ in
                classes = snap?.documents.compactMap { SchoolClass.fromDocument($0) } ?? []
                isLoading = false
            }
    }
}

// MARK: - Add Classroom Sheet
struct AddClassroomSheet: View {
    let schoolId: String
    let availableGrades: [Int]

    @State private var name = ""
    @State private var selectedGrade: Int = 0
    @State private var classType: SchoolClass.ClassType = .regular
    @State private var subjectType: SchoolClass.SubjectType = .homeroom
    @State private var isSaving = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Classroom Details") {
                    TextField("Classroom Name (e.g. Mrs. Smith's Class)", text: $name)

                    Picker("Grade Level", selection: $selectedGrade) {
                        ForEach(availableGrades.isEmpty ? GradeUtils.allGrades : availableGrades, id: \.self) { g in
                            Text(GradeUtils.label(g)).tag(g)
                        }
                    }

                    Picker("Subject", selection: $subjectType) {
                        ForEach(SchoolClass.SubjectType.allCases, id: \.self) { s in
                            Label(s.displayName, systemImage: s.icon).tag(s)
                        }
                    }

                    Picker("Class Type", selection: $classType) {
                        ForEach(SchoolClass.ClassType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your classroom will include:", systemImage: "checkmark.seal.fill")
                            .font(.caption.bold())
                            .foregroundColor(EZTeachColors.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            featureItem("Homeroom Dashboard")
                            featureItem("Lesson Plans")
                            featureItem("Class Roster")
                            featureItem("Attendance Tracking")
                            featureItem("Homework & Assignments")
                        }
                    }
                } header: {
                    Text("What's Included")
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Classroom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createClassroom() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func featureItem(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.green)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func createClassroom() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        errorMessage = nil

        // Include the current user as teacher if they're a teacher
        var teacherIds: [String] = []
        if let uid = Auth.auth().currentUser?.uid {
            teacherIds = [uid]
        }

        Task {
            do {
                try await FirestoreService.shared.createClassroom(
                    schoolId: schoolId,
                    name: trimmed,
                    grade: selectedGrade,
                    teacherIds: teacherIds,
                    classType: classType.rawValue,
                    subjectType: subjectType.rawValue
                )
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

