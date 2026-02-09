//
//  StudentProfileView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StudentProfileView: View {

    let student: Student

    @State private var notes: String
    @State private var linkedParents: [ParentInfo] = []
    @State private var isLoading = true
    @State private var canEdit = false
    @State private var showCopiedAlert = false
    
    private let db = Firestore.firestore()

    init(student: Student) {
        self.student = student
        _notes = State(initialValue: student.notes)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Student header card
                headerCard
                
                // Student code card — only visible to school, teacher, district
                if canEdit {
                    studentCodeCard
                }
                
                // Quick links
                quickLinksSection
                
                // Linked parents (only staff)
                if canEdit {
                    linkedParentsSection
                }
                
                // Notes section
                if canEdit {
                    notesSection
                }
            }
            .padding()
        }
        .background(EZTeachColors.background)
        .navigationTitle(student.fullName)
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            EditStudentView(student: student)
                        } label: {
                            Text("Edit")
                        }
                        Button("Save") {
                            saveNotes()
                        }
                    }
                }
            }
        }
        .alert("Code Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Student code has been copied to clipboard.")
        }
        .onAppear {
            checkPermissions()
            loadLinkedParents()
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(EZTeachColors.accent.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(student.firstName.prefix(1).uppercased() + student.lastName.prefix(1).uppercased())
                        .font(.title.bold())
                        .foregroundColor(EZTeachColors.accent)
                )
            
            VStack(spacing: 4) {
                Text(student.fullName)
                    .font(.title2.bold())
                
                // Only show student code to school/teacher/district
                if canEdit {
                    Text("Student ID: \(student.studentCode)")
                        .font(.subheadline.monospaced())
                        .foregroundColor(EZTeachColors.accent)
                }
                
                Text(GradeUtils.label(student.gradeLevel))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let dob = student.dateOfBirth {
                    Text("Born: \(dateFormatter.string(from: dob))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private var defaultPasswordBanner: some View {
        Group {
            if student.usesDefaultPassword {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(EZTeachColors.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Password")
                            .font(.subheadline.weight(.semibold))
                        Text("Password is Student ID + ! (e.g. \(student.studentCode)!). Schools and teachers can change it.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(EZTeachColors.warning.opacity(0.15))
                .cornerRadius(12)
            }
        }
    }
    
    private var studentCodeCard: some View {
        VStack(spacing: 12) {
            defaultPasswordBanner
            
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(EZTeachColors.accent)
                Text("Student ID")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text(student.studentCode)
                    .font(.title.monospaced())
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = student.studentCode
                    showCopiedAlert = true
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(EZTeachColors.accent)
                }
            }
            
            Text("Students sign in with Student ID and password (default: Student ID!). Share with parents to link their account.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Quick Links
    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    StudentGradesOverviewView(student: student)
                } label: {
                    quickLinkCard(icon: "chart.bar.doc.horizontal", title: "Grades", color: EZTeachColors.accent)
                }
                
                NavigationLink {
                    StudentAttendanceView(student: student)
                } label: {
                    quickLinkCard(icon: "calendar.badge.clock", title: "Attendance", color: EZTeachColors.success)
                }
            }
        }
    }
    
    private func quickLinkCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Linked Parents Section
    private var linkedParentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Linked Parents")
                    .font(.headline)
                Spacer()
                if !student.parentIds.isEmpty {
                    Text("\(student.parentIds.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(EZTeachColors.cardFill)
                        .cornerRadius(8)
                }
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if linkedParents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No parents linked yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(EZTeachColors.cardFill)
                .cornerRadius(12)
            } else {
                ForEach(linkedParents) { parent in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(EZTeachColors.success.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(EZTeachColors.success)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(parent.name)
                                .font(.subheadline.weight(.medium))
                            if let email = parent.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(10)
                .disabled(!canEdit)
        }
    }
    
    // MARK: - Helpers
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
    
    // MARK: - Actions
    private func checkPermissions() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snap, _ in
            let role = snap?.data()?["role"] as? String ?? ""
            let districtId = snap?.data()?["districtId"] as? String ?? ""
            canEdit = role == "school" || role == "teacher" ||
                (role == "district" && !districtId.isEmpty)
        }
    }
    
    private func loadLinkedParents() {
        guard !student.parentIds.isEmpty else {
            isLoading = false
            return
        }
        
        db.collection("users")
            .whereField(FieldPath.documentID(), in: Array(student.parentIds.prefix(10)))
            .getDocuments { snap, _ in
                linkedParents = snap?.documents.map { doc in
                    let d = doc.data()
                    return ParentInfo(
                        id: doc.documentID,
                        name: d["fullName"] as? String ?? "Parent",
                        email: d["email"] as? String
                    )
                } ?? []
                isLoading = false
            }
    }

    private func saveNotes() {
        db.collection("students")
            .document(student.id)
            .updateData([
                "notes": notes
            ])
    }
}

// MARK: - Parent Info
struct ParentInfo: Identifiable {
    let id: String
    let name: String
    let email: String?
}

// MARK: - Student Grades Overview View
struct StudentGradesOverviewView: View {
    let student: Student
    
    @State private var classes: [SchoolClass] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if classes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Not enrolled in any classes")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(classes) { cls in
                        NavigationLink {
                            StudentClassGradesView(student: student, classModel: cls)
                        } label: {
                            Text(cls.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("Grades")
        .onAppear(perform: loadClasses)
    }
    
    private func loadClasses() {
        db.collection("class_rosters")
            .whereField("studentId", isEqualTo: student.id)
            .getDocuments { snap, _ in
                let classIds = snap?.documents.compactMap { $0["classId"] as? String } ?? []
                
                guard !classIds.isEmpty else {
                    isLoading = false
                    return
                }
                
                db.collection("classes")
                    .whereField(FieldPath.documentID(), in: Array(classIds.prefix(10)))
                    .getDocuments { classSnap, _ in
                        classes = classSnap?.documents.compactMap { doc -> SchoolClass? in
                            let d = doc.data()
                            let ct = SchoolClass.ClassType(rawValue: d["classType"] as? String ?? "regular") ?? .regular
                            return SchoolClass(
                                id: doc.documentID,
                                name: d["name"] as? String ?? "",
                                grade: d["grade"] as? Int ?? 0,
                                schoolId: d["schoolId"] as? String ?? "",
                                teacherIds: d["teacherIds"] as? [String] ?? [],
                                classType: ct
                            )
                        }.sorted { $0.name < $1.name } ?? []
                        isLoading = false
                    }
            }
    }
}

// MARK: - Student Class Grades View (Staff Version)
struct StudentClassGradesView: View {
    let student: Student
    let classModel: SchoolClass
    
    var body: some View {
        StudentGradesView(classModel: classModel)
    }
}

// MARK: - Student Profile Loader (for navigation by student ID)
struct StudentProfileLoaderView: View {
    let studentId: String
    let schoolId: String
    
    @State private var student: Student?
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        Group {
            if let s = student {
                StudentProfileView(student: s)
            } else if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("Student Not Found", systemImage: "person.crop.circle.badge.questionmark")
            }
        }
        .onAppear {
            db.collection("students").document(studentId).getDocument { snap, _ in
                student = snap.flatMap { Student.fromDocument($0) }
                isLoading = false
            }
        }
    }
}

// MARK: - Student Attendance View
struct StudentAttendanceView: View {
    let student: Student
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Attendance records will appear here")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Attendance")
    }
}
