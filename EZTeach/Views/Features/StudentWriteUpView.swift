//
//  StudentWriteUpView.swift
//  EZTeach
//
//  Faculty write-up and report system for students
//  Available for all roles except students and parents
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Write-Up Model
struct StudentWriteUp: Identifiable, Codable {
    let id: String
    let studentId: String
    let studentName: String
    let schoolId: String
    let authorId: String
    let authorName: String
    let authorRole: String
    let type: WriteUpType
    let subject: String
    let description: String
    let severity: Severity
    let actionTaken: String
    let followUpRequired: Bool
    let parentNotified: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum WriteUpType: String, Codable, CaseIterable {
        case behavioral = "Behavioral"
        case academic = "Academic"
        case attendance = "Attendance"
        case positive = "Positive Recognition"
        case incident = "Incident Report"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .behavioral: return "exclamationmark.triangle.fill"
            case .academic: return "book.fill"
            case .attendance: return "calendar.badge.exclamationmark"
            case .positive: return "star.fill"
            case .incident: return "doc.text.fill"
            case .other: return "folder.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .behavioral: return .orange
            case .academic: return .blue
            case .attendance: return .purple
            case .positive: return .green
            case .incident: return .red
            case .other: return .gray
            }
        }
    }
    
    enum Severity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> StudentWriteUp? {
        guard let data = doc.data() else { return nil }
        return StudentWriteUp(
            id: doc.documentID,
            studentId: data["studentId"] as? String ?? "",
            studentName: data["studentName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            authorId: data["authorId"] as? String ?? "",
            authorName: data["authorName"] as? String ?? "",
            authorRole: data["authorRole"] as? String ?? "",
            type: WriteUpType(rawValue: data["type"] as? String ?? "") ?? .other,
            subject: data["subject"] as? String ?? "",
            description: data["description"] as? String ?? "",
            severity: Severity(rawValue: data["severity"] as? String ?? "") ?? .low,
            actionTaken: data["actionTaken"] as? String ?? "",
            followUpRequired: data["followUpRequired"] as? Bool ?? false,
            parentNotified: data["parentNotified"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Main Write-Up View
struct StudentWriteUpView: View {
    let schoolId: String
    let userRole: String
    let userName: String
    
    @State private var writeUps: [StudentWriteUp] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showCreateWriteUp = false
    @State private var selectedWriteUp: StudentWriteUp?
    @State private var filterType: StudentWriteUp.WriteUpType?
    @State private var students: [Student] = []
    
    private let db = Firestore.firestore()
    
    private var filteredWriteUps: [StudentWriteUp] {
        var result = writeUps
        if let type = filterType {
            result = result.filter { $0.type == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.studentName.lowercased().contains(searchText.lowercased()) ||
                $0.subject.lowercased().contains(searchText.lowercased())
            }
        }
        return result.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.lightAppealGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and filter bar
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(EZTeachColors.textMutedLight)
                            TextField("Search by student name...", text: $searchText)
                                .textFieldStyle(.plain)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4)
                        
                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(title: "All", isSelected: filterType == nil) {
                                    filterType = nil
                                }
                                ForEach(StudentWriteUp.WriteUpType.allCases, id: \.rawValue) { type in
                                    FilterChip(title: type.rawValue, isSelected: filterType == type, color: type.color) {
                                        filterType = type
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredWriteUps.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredWriteUps) { writeUp in
                                WriteUpRow(writeUp: writeUp)
                                    .onTapGesture {
                                        selectedWriteUp = writeUp
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Student Write-Ups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateWriteUp = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(EZTeachColors.brightTeal)
                    }
                }
            }
            .sheet(isPresented: $showCreateWriteUp) {
                CreateWriteUpView(
                    schoolId: schoolId,
                    userRole: userRole,
                    userName: userName,
                    students: students
                ) {
                    loadWriteUps()
                }
            }
            .sheet(item: $selectedWriteUp) { writeUp in
                WriteUpDetailView(writeUp: writeUp)
            }
            .onAppear {
                loadWriteUps()
                loadStudents()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(EZTeachColors.textMutedLight)
            Text("No Write-Ups Found")
                .font(.headline)
                .foregroundColor(EZTeachColors.textDark)
            Text("Search for a student or create a new write-up")
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textMutedLight)
            
            Button {
                showCreateWriteUp = true
            } label: {
                Label("Create Write-Up", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(EZTeachColors.brightTeal)
                    .cornerRadius(12)
            }
        }
    }
    
    private func loadWriteUps() {
        isLoading = true
        db.collection("writeups")
            .whereField("schoolId", isEqualTo: schoolId)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments { snap, _ in
                writeUps = snap?.documents.compactMap { StudentWriteUp.fromDocument($0) } ?? []
                isLoading = false
            }
    }
    
    private func loadStudents() {
        db.collection("students")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments(source: .default) { snap, _ in
                students = snap?.documents.compactMap { Student.fromDocument($0) } ?? []
            }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = EZTeachColors.brightTeal
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : EZTeachColors.textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Write-Up Row
struct WriteUpRow: View {
    let writeUp: StudentWriteUp
    
    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            ZStack {
                Circle()
                    .fill(writeUp.type.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: writeUp.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(writeUp.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(writeUp.studentName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(EZTeachColors.textDark)
                    
                    Spacer()
                    
                    // Severity badge
                    Text(writeUp.severity.rawValue)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(writeUp.severity.color)
                        .cornerRadius(6)
                }
                
                Text(writeUp.subject)
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textMutedLight)
                    .lineLimit(1)
                
                HStack {
                    Text(writeUp.type.rawValue)
                        .font(.caption2)
                        .foregroundColor(writeUp.type.color)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(writeUp.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if writeUp.followUpRequired {
                        Text("•")
                            .foregroundColor(.gray)
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Create Write-Up View
struct CreateWriteUpView: View {
    let schoolId: String
    let userRole: String
    let userName: String
    let students: [Student]
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedStudent: Student?
    @State private var type: StudentWriteUp.WriteUpType = .behavioral
    @State private var subject = ""
    @State private var description = ""
    @State private var severity: StudentWriteUp.Severity = .low
    @State private var actionTaken = ""
    @State private var followUpRequired = false
    @State private var parentNotified = false
    @State private var isSaving = false
    
    private let db = Firestore.firestore()
    
    private var filteredStudents: [Student] {
        if searchText.isEmpty { return students }
        return students.filter {
            $0.firstName.lowercased().contains(searchText.lowercased()) ||
            $0.lastName.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Student Selection
                Section("Select Student") {
                    if let student = selectedStudent {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(student.firstName) \(student.lastName)")
                                    .font(.headline)
                                Text("Grade \(student.gradeLevel)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                selectedStudent = nil
                            }
                            .font(.caption)
                        }
                    } else {
                        TextField("Search student name...", text: $searchText)
                        
                        if !searchText.isEmpty {
                            ForEach(filteredStudents.prefix(5)) { student in
                                Button {
                                    selectedStudent = student
                                    searchText = ""
                                } label: {
                                    HStack {
                                        Text("\(student.firstName) \(student.lastName)")
                                        Spacer()
                                        Text("Grade \(student.gradeLevel)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Write-Up Type
                Section("Write-Up Type") {
                    Picker("Type", selection: $type) {
                        ForEach(StudentWriteUp.WriteUpType.allCases, id: \.rawValue) { t in
                            HStack {
                                Image(systemName: t.icon)
                                Text(t.rawValue)
                            }
                            .tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Severity", selection: $severity) {
                        ForEach(StudentWriteUp.Severity.allCases, id: \.rawValue) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Details
                Section("Details") {
                    TextField("Subject / Title", text: $subject)
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(height: 120)
                    }
                    
                    TextField("Action Taken (optional)", text: $actionTaken)
                }
                
                // Follow-up
                Section("Follow-Up") {
                    Toggle("Follow-up Required", isOn: $followUpRequired)
                    Toggle("Parent Notified", isOn: $parentNotified)
                }
            }
            .navigationTitle("New Write-Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveWriteUp()
                    }
                    .disabled(selectedStudent == nil || subject.isEmpty || description.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveWriteUp() {
        guard let student = selectedStudent,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        isSaving = true
        
        db.collection("writeups").addDocument(data: [
            "studentId": student.id,
            "studentName": "\(student.firstName) \(student.lastName)",
            "schoolId": schoolId,
            "authorId": uid,
            "authorName": userName,
            "authorRole": userRole,
            "type": type.rawValue,
            "subject": subject,
            "description": description,
            "severity": severity.rawValue,
            "actionTaken": actionTaken,
            "followUpRequired": followUpRequired,
            "parentNotified": parentNotified,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}

// MARK: - Write-Up Detail View
struct WriteUpDetailView: View {
    let writeUp: StudentWriteUp
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        ZStack {
                            Circle()
                                .fill(writeUp.type.color.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Image(systemName: writeUp.type.icon)
                                .font(.system(size: 28))
                                .foregroundColor(writeUp.type.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(writeUp.studentName)
                                .font(.title2.weight(.bold))
                            Text(writeUp.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(writeUp.type.color)
                        }
                        
                        Spacer()
                        
                        Text(writeUp.severity.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(writeUp.severity.color)
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Subject
                    DetailSection(title: "Subject", content: writeUp.subject)
                    
                    // Description
                    DetailSection(title: "Description", content: writeUp.description)
                    
                    // Action Taken
                    if !writeUp.actionTaken.isEmpty {
                        DetailSection(title: "Action Taken", content: writeUp.actionTaken)
                    }
                    
                    // Meta Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            Text("Written by: \(writeUp.authorName) (\(writeUp.authorRole))")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text("Date: \(writeUp.createdAt, style: .date)")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: writeUp.followUpRequired ? "flag.fill" : "flag")
                                .foregroundColor(writeUp.followUpRequired ? .orange : .gray)
                            Text("Follow-up: \(writeUp.followUpRequired ? "Required" : "Not required")")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: writeUp.parentNotified ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(writeUp.parentNotified ? .green : .gray)
                            Text("Parent notified: \(writeUp.parentNotified ? "Yes" : "No")")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                }
                .padding()
            }
            .background(EZTeachColors.lightSky)
            .navigationTitle("Write-Up Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundColor(.gray)
            Text(content)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}
