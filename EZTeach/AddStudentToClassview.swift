//
//  AddStudentToClassview.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-17.
//

import SwiftUI
import FirebaseFirestore

struct AddStudentToClassView: View {

    let classModel: SchoolClass
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var students: [Student] = []
    @State private var selectedStudents: Set<String> = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showCreateNew = false
    @State private var enrolledStudentIds: Set<String> = []

    private let db = Firestore.firestore()
    
    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return students.filter { !enrolledStudentIds.contains($0.id) }
        }
        return students.filter { student in
            !enrolledStudentIds.contains(student.id) &&
            (student.firstName.localizedCaseInsensitiveContains(searchText) ||
             student.lastName.localizedCaseInsensitiveContains(searchText) ||
             student.studentCode.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search by name or student code...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(12)
                .padding()
                
                // Selected count
                if !selectedStudents.isEmpty {
                    HStack {
                        Text("\(selectedStudents.count) student\(selectedStudents.count > 1 ? "s" : "") selected")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(EZTeachColors.accent)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            selectedStudents.removeAll()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading students...")
                    Spacer()
                } else if filteredStudents.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        if searchText.isEmpty {
                            Text("All students are already enrolled")
                                .font(.headline)
                            Text("Create a new student to add them to this class")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No students found")
                                .font(.headline)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            showCreateNew = true
                        } label: {
                            Label("Create New Student", systemImage: "plus.circle.fill")
                                .ezButton()
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredStudents) { student in
                            StudentRowView(
                                student: student,
                                isSelected: selectedStudents.contains(student.id)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSelection(student.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addSelectedStudents()
                    } label: {
                        Text("Add (\(selectedStudents.count))")
                            .fontWeight(.semibold)
                    }
                    .disabled(selectedStudents.isEmpty)
                }
            }
            .sheet(isPresented: $showCreateNew) {
                CreateStudentView(schoolId: classModel.schoolId) { newStudent in
                    students.append(newStudent)
                    selectedStudents.insert(newStudent.id)
                }
            }
            .onAppear {
                loadEnrolledStudents()
                loadStudents()
            }
        }
    }
    
    private func toggleSelection(_ id: String) {
        if selectedStudents.contains(id) {
            selectedStudents.remove(id)
        } else {
            selectedStudents.insert(id)
        }
    }
    
    private func loadEnrolledStudents() {
        db.collection("class_rosters")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                enrolledStudentIds = Set(snap?.documents.compactMap { $0["studentId"] as? String } ?? [])
            }
    }

    private func loadStudents() {
        isLoading = true
        db.collection("students")
            .whereField("schoolId", isEqualTo: classModel.schoolId)
            .order(by: "lastName")
            .getDocuments { snap, _ in
                students = snap?.documents.compactMap { doc in
                    Student.fromDocument(doc)
                } ?? []
                isLoading = false
            }
    }

    private func addSelectedStudents() {
        let batch = db.batch()
        
        for studentId in selectedStudents {
            let ref = db.collection("class_rosters").document()
            batch.setData([
                "classId": classModel.id,
                "studentId": studentId,
                "schoolId": classModel.schoolId,
                "addedAt": Timestamp()
            ], forDocument: ref)
        }
        
        batch.commit { _ in
            onSave()
            dismiss()
        }
    }
}

// MARK: - Student Row View
struct StudentRowView: View {
    let student: Student
    let isSelected: Bool
    
    private var displayName: String {
        if student.middleName.isEmpty {
            return "\(student.lastName), \(student.firstName)"
        }
        return "\(student.lastName), \(student.firstName) \(student.middleName.prefix(1))."
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(isSelected ? EZTeachColors.accent : EZTeachColors.cardFill)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundColor(.white)
                } else {
                    Text(student.firstName.prefix(1) + student.lastName.prefix(1))
                        .font(.subheadline.bold())
                        .foregroundColor(EZTeachColors.navy)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 8) {
                    Text("Grade \(student.gradeLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(student.studentCode)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(EZTeachColors.accent)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? EZTeachColors.accent.opacity(0.1) : Color.clear)
        .cornerRadius(10)
    }
}

// MARK: - Create Student View
struct CreateStudentView: View {
    let schoolId: String
    let onCreated: (Student) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var middleName = ""
    @State private var lastName = ""
    @State private var gradeLevel = 1
    @State private var dateOfBirth = Date()
    @State private var notes = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showDuplicateWarning = false
    @State private var existingStudent: Student?
    
    private let db = Firestore.firestore()
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !middleName.isEmpty && !lastName.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    
                    TextField("Middle Name (Required)", text: $middleName)
                        .textContentType(.middleName)
                    
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                    
                    Picker("Grade Level", selection: $gradeLevel) {
                        ForEach(GradeUtils.allGrades, id: \.self) { grade in
                            Text(GradeUtils.label(grade)).tag(grade)
                        }
                    }
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
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
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(EZTeachColors.accent)
                        Text("A unique Student Code will be generated automatically for parent linking.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        checkForDuplicateAndCreate()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .alert("Possible Duplicate", isPresented: $showDuplicateWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Create Anyway") {
                    createStudent(skipDuplicateCheck: true)
                }
            } message: {
                if let existing = existingStudent {
                    Text("A student named \(existing.fullName) with the same date of birth already exists in this school.\n\nStudent Code: \(existing.studentCode)\n\nAre you sure this is a different student?")
                } else {
                    Text("A student with similar information already exists. Are you sure you want to create a new record?")
                }
            }
        }
    }
    
    private func checkForDuplicateAndCreate() {
        isLoading = true
        errorMessage = ""
        
        // Create the duplicate key for checking
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dobString = formatter.string(from: dateOfBirth)
        let duplicateKey = "\(firstName.lowercased())_\(middleName.lowercased())_\(lastName.lowercased())_\(dobString)"
        
        // Check for existing student with same duplicate key
        db.collection("students")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("duplicateKey", isEqualTo: duplicateKey)
            .limit(to: 1)
            .getDocuments { snap, error in
                if let doc = snap?.documents.first,
                   let student = Student.fromDocument(doc) {
                    // Found a potential duplicate
                    isLoading = false
                    existingStudent = student
                    showDuplicateWarning = true
                } else {
                    // No duplicate found, create the student
                    createStudent(skipDuplicateCheck: true)
                }
            }
    }
    
    private func createStudent(skipDuplicateCheck: Bool) {
        if !skipDuplicateCheck {
            checkForDuplicateAndCreate()
            return
        }
        
        isLoading = true
        let studentCode = Student.generateStudentCode()
        let ref = db.collection("students").document()
        
        // Create duplicate key for future checks
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dobString = formatter.string(from: dateOfBirth)
        let duplicateKey = "\(firstName.lowercased())_\(middleName.lowercased())_\(lastName.lowercased())_\(dobString)"
        
        let data: [String: Any] = [
            "firstName": firstName.trimmingCharacters(in: .whitespaces),
            "middleName": middleName.trimmingCharacters(in: .whitespaces),
            "lastName": lastName.trimmingCharacters(in: .whitespaces),
            "schoolId": schoolId,
            "studentCode": studentCode,
            "gradeLevel": gradeLevel,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "notes": notes,
            "parentIds": [],
            "duplicateKey": duplicateKey,
            "createdAt": Timestamp()
        ]
        
        ref.setData(data) { error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                let student = Student(
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
                onCreated(student)
                dismiss()
            }
        }
    }
}
