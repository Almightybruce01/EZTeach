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

    private let db = Firestore.firestore()
    
    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students
        }
        return students.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.studentCode.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
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
                .searchable(text: $searchText, prompt: "Search by name or code")
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
            AddStudentView(schoolId: schoolId) { loadStudents() }
        }
        .onAppear(perform: loadInitialData)
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
                    
                    Text("Code: \(student.studentCode)")
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
            guard let data = snap?.data(),
                  let school = data["activeSchoolId"] as? String else {
                hasSchool = false
                return
            }
            
            schoolId = school
            userRole = data["role"] as? String ?? ""
            loadStudents()
        }
    }
    
    private func loadStudents() {
        guard !schoolId.isEmpty else { return }
        
        db.collection("students")
            .whereField("schoolId", isEqualTo: schoolId)
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
    
    @State private var isSaving = false
    @State private var createdStudent: Student?
    @State private var showSuccess = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
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
                    Text("Student Code: \(student.studentCode)\n\nShare this code with parents so they can link their account to view grades.")
                }
            }
        }
    }
    
    private func saveStudent() {
        isSaving = true
        
        let studentCode = Student.generateStudentCode()
        let ref = db.collection("students").document()
        
        // Create duplicate key for future checks
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dobString = hasDOB ? formatter.string(from: dateOfBirth) : "nodob"
        let duplicateKey = "\(firstName.lowercased())_\(middleName.lowercased())_\(lastName.lowercased())_\(dobString)"
        
        var data: [String: Any] = [
            "firstName": firstName.trimmingCharacters(in: .whitespaces),
            "middleName": middleName.trimmingCharacters(in: .whitespaces),
            "lastName": lastName.trimmingCharacters(in: .whitespaces),
            "schoolId": schoolId,
            "studentCode": studentCode,
            "gradeLevel": gradeLevel,
            "notes": notes,
            "parentIds": [],
            "duplicateKey": duplicateKey,
            "createdAt": Timestamp()
        ]
        
        if hasDOB {
            data["dateOfBirth"] = Timestamp(date: dateOfBirth)
        }
        
        ref.setData(data) { error in
            isSaving = false
            
            if error == nil {
                createdStudent = Student(
                    id: ref.documentID,
                    firstName: firstName,
                    middleName: middleName,
                    lastName: lastName,
                    schoolId: schoolId,
                    studentCode: studentCode,
                    gradeLevel: gradeLevel,
                    dateOfBirth: hasDOB ? dateOfBirth : nil,
                    notes: notes,
                    parentIds: [],
                    createdAt: Date()
                )
                showSuccess = true
            }
        }
    }
}
