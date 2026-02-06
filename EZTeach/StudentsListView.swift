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

    @State private var students: [Student] = []
    @State private var hasSchool = true
    @State private var schoolId = ""
    @State private var showAddStudent = false
    @State private var userRole = ""
    @State private var searchText = ""
    @State private var isDistrict = false
    @State private var schoolIds: [String] = []
    @State private var selectedSchoolId = ""
    @State private var schoolNames: [String: String] = [:]

    private let db = Firestore.firestore()

    private var effectiveSchoolId: String {
        !selectedSchoolId.isEmpty ? selectedSchoolId : schoolId
    }
    
    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students
        }
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return students.filter {
            $0.fullName.localizedCaseInsensitiveContains(q) ||
            $0.firstName.localizedCaseInsensitiveContains(q) ||
            $0.middleName.localizedCaseInsensitiveContains(q) ||
            $0.lastName.localizedCaseInsensitiveContains(q) ||
            $0.studentCode.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isDistrict && schoolIds.count > 1 {
                    Picker("School", selection: $selectedSchoolId) {
                        ForEach(schoolIds, id: \.self) { sid in
                            Text(schoolNames[sid] ?? "School").tag(sid)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                }
                
                if students.isEmpty {
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
            AddStudentView(schoolId: effectiveSchoolId) { loadStudents() }
        }
        .onAppear(perform: loadInitialData)
        .onChange(of: selectedSchoolId) { _, _ in loadStudents() }
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
            }
            
            Spacer()
            
            // Parent indicator
            if !student.parentIds.isEmpty {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.caption)
                    .foregroundColor(EZTeachColors.success)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Students")
                .font(.headline)
            
            Text("Add students to track grades and communicate with parents.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
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
        }
        loadStudents()
    }

    private func loadInitialData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

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
                }
            } else {
                DispatchQueue.main.async { hasSchool = false }
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
                students = snapshot?.documents.compactMap { Student.fromDocument($0) } ?? []
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
        }
    }
    
    private func saveStudent() {
        guard isFormValid else { return }
        isSaving = true
        Task {
            do {
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
