//
//  SubNotesView.swift
//  EZTeach
//
//  Substitute teacher notes for students and daily notes for absent teachers
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Sub Student Note Model
struct SubStudentNote: Identifiable, Codable {
    let id: String
    let studentId: String
    let studentName: String
    let schoolId: String
    let classId: String
    let className: String
    let subId: String
    let subName: String
    let note: String
    let category: NoteCategory
    let date: Date
    let createdAt: Date
    
    enum NoteCategory: String, Codable, CaseIterable {
        case behavior = "Behavior"
        case participation = "Participation"
        case academic = "Academic"
        case positive = "Positive"
        case concern = "Concern"
        case general = "General"
        
        var icon: String {
            switch self {
            case .behavior: return "hand.raised.fill"
            case .participation: return "hand.thumbsup.fill"
            case .academic: return "book.fill"
            case .positive: return "star.fill"
            case .concern: return "exclamationmark.triangle.fill"
            case .general: return "note.text"
            }
        }
        
        var color: Color {
            switch self {
            case .behavior: return .orange
            case .participation: return .blue
            case .academic: return .purple
            case .positive: return .green
            case .concern: return .red
            case .general: return .gray
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> SubStudentNote? {
        guard let data = doc.data() else { return nil }
        return SubStudentNote(
            id: doc.documentID,
            studentId: data["studentId"] as? String ?? "",
            studentName: data["studentName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            classId: data["classId"] as? String ?? "",
            className: data["className"] as? String ?? "",
            subId: data["subId"] as? String ?? "",
            subName: data["subName"] as? String ?? "",
            note: data["note"] as? String ?? "",
            category: NoteCategory(rawValue: data["category"] as? String ?? "") ?? .general,
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Daily Notes Model (for absent teacher)
struct DailySubNote: Identifiable, Codable {
    let id: String
    let schoolId: String
    let classId: String
    let className: String
    let teacherId: String
    let teacherName: String
    let subId: String
    let subName: String
    let date: Date
    let summary: String
    let lessonsCompleted: String
    let behaviorSummary: String
    let issues: String
    let supplies: String
    let otherNotes: String
    let rating: Int // 1-5 how the day went
    let createdAt: Date
    
    static func fromDocument(_ doc: DocumentSnapshot) -> DailySubNote? {
        guard let data = doc.data() else { return nil }
        return DailySubNote(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            classId: data["classId"] as? String ?? "",
            className: data["className"] as? String ?? "",
            teacherId: data["teacherId"] as? String ?? "",
            teacherName: data["teacherName"] as? String ?? "",
            subId: data["subId"] as? String ?? "",
            subName: data["subName"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            summary: data["summary"] as? String ?? "",
            lessonsCompleted: data["lessonsCompleted"] as? String ?? "",
            behaviorSummary: data["behaviorSummary"] as? String ?? "",
            issues: data["issues"] as? String ?? "",
            supplies: data["supplies"] as? String ?? "",
            otherNotes: data["otherNotes"] as? String ?? "",
            rating: data["rating"] as? Int ?? 3,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Main Sub Notes View
struct SubNotesView: View {
    let schoolId: String
    let classId: String
    let className: String
    let teacherId: String
    let teacherName: String
    let subName: String
    
    @State private var studentNotes: [SubStudentNote] = []
    @State private var dailyNotes: [DailySubNote] = []
    @State private var students: [Student] = []
    @State private var isLoading = true
    @State private var showAddStudentNote = false
    @State private var showAddDailyNote = false
    @State private var selectedTab = 0
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.lightAppealGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab selector
                    Picker("Notes Type", selection: $selectedTab) {
                        Text("Student Notes").tag(0)
                        Text("Daily Summary").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        if selectedTab == 0 {
                            studentNotesTab
                        } else {
                            dailyNotesTab
                        }
                    }
                }
            }
            .navigationTitle("Sub Notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if selectedTab == 0 {
                            showAddStudentNote = true
                        } else {
                            showAddDailyNote = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(EZTeachColors.brightTeal)
                    }
                }
            }
            .sheet(isPresented: $showAddStudentNote) {
                AddSubStudentNoteView(
                    schoolId: schoolId,
                    classId: classId,
                    className: className,
                    subName: subName,
                    students: students
                ) {
                    loadNotes()
                }
            }
            .sheet(isPresented: $showAddDailyNote) {
                AddDailySubNoteView(
                    schoolId: schoolId,
                    classId: classId,
                    className: className,
                    teacherId: teacherId,
                    teacherName: teacherName,
                    subName: subName
                ) {
                    loadNotes()
                }
            }
            .onAppear {
                loadNotes()
                loadStudents()
            }
        }
    }
    
    // MARK: - Student Notes Tab
    private var studentNotesTab: some View {
        Group {
            if studentNotes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(EZTeachColors.textMutedLight)
                    Text("No Student Notes Yet")
                        .font(.headline)
                    Text("Add notes about individual students for the regular teacher")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showAddStudentNote = true
                    } label: {
                        Label("Add Student Note", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(EZTeachColors.brightTeal)
                            .cornerRadius(12)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(studentNotes) { note in
                        StudentNoteRow(note: note)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Daily Notes Tab
    private var dailyNotesTab: some View {
        Group {
            if dailyNotes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(EZTeachColors.textMutedLight)
                    Text("No Daily Summary Yet")
                        .font(.headline)
                    Text("Add a summary of how the day went for the regular teacher")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showAddDailyNote = true
                    } label: {
                        Label("Add Daily Summary", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(EZTeachColors.brightTeal)
                            .cornerRadius(12)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(dailyNotes) { note in
                        DailyNoteRow(note: note)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private func loadNotes() {
        isLoading = true
        let today = Calendar.current.startOfDay(for: Date())
        
        // Load student notes for today
        db.collection("subStudentNotes")
            .whereField("classId", isEqualTo: classId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
            .getDocuments(source: .default) { snap, _ in
                studentNotes = snap?.documents.compactMap { SubStudentNote.fromDocument($0) } ?? []
            }
        
        // Load daily notes
        db.collection("dailySubNotes")
            .whereField("classId", isEqualTo: classId)
            .order(by: "date", descending: true)
            .limit(to: 10)
            .getDocuments(source: .default) { snap, _ in
                dailyNotes = snap?.documents.compactMap { DailySubNote.fromDocument($0) } ?? []
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

// MARK: - Student Note Row
struct StudentNoteRow: View {
    let note: SubStudentNote
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(note.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: note.category.icon)
                    .foregroundColor(note.category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.studentName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(note.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(note.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(note.category.color.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Text(note.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("By \(note.subName)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Daily Note Row
struct DailyNoteRow: View {
    let note: DailySubNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.date, style: .date)
                        .font(.headline)
                    Text("Sub: \(note.subName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Rating stars
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= note.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(i <= note.rating ? .yellow : .gray)
                    }
                }
            }
            
            Divider()
            
            if !note.summary.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summary")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Text(note.summary)
                        .font(.caption)
                }
            }
            
            if !note.lessonsCompleted.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lessons Completed")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Text(note.lessonsCompleted)
                        .font(.caption)
                }
            }
            
            if !note.issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    Text(note.issues)
                        .font(.caption)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Add Sub Student Note View
struct AddSubStudentNoteView: View {
    let schoolId: String
    let classId: String
    let className: String
    let subName: String
    let students: [Student]
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedStudent: Student?
    @State private var note = ""
    @State private var category: SubStudentNote.NoteCategory = .general
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
                Section("Select Student") {
                    if let student = selectedStudent {
                        HStack {
                            Text("\(student.firstName) \(student.lastName)")
                                .font(.headline)
                            Spacer()
                            Button("Change") { selectedStudent = nil }
                                .font(.caption)
                        }
                    } else {
                        TextField("Search student...", text: $searchText)
                        ForEach(filteredStudents.prefix(5)) { student in
                            Button {
                                selectedStudent = student
                                searchText = ""
                            } label: {
                                Text("\(student.firstName) \(student.lastName)")
                            }
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(SubStudentNote.NoteCategory.allCases, id: \.rawValue) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.rawValue)
                            }
                            .tag(cat)
                        }
                    }
                }
                
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(height: 150)
                }
            }
            .navigationTitle("Add Student Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveNote() }
                        .disabled(selectedStudent == nil || note.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveNote() {
        guard let student = selectedStudent,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        isSaving = true
        
        db.collection("subStudentNotes").addDocument(data: [
            "studentId": student.id,
            "studentName": "\(student.firstName) \(student.lastName)",
            "schoolId": schoolId,
            "classId": classId,
            "className": className,
            "subId": uid,
            "subName": subName,
            "note": note,
            "category": category.rawValue,
            "date": Timestamp(),
            "createdAt": Timestamp()
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}

// MARK: - Add Daily Sub Note View
struct AddDailySubNoteView: View {
    let schoolId: String
    let classId: String
    let className: String
    let teacherId: String
    let teacherName: String
    let subName: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var summary = ""
    @State private var lessonsCompleted = ""
    @State private var behaviorSummary = ""
    @State private var issues = ""
    @State private var supplies = ""
    @State private var otherNotes = ""
    @State private var rating = 3
    @State private var isSaving = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("How Did It Go?") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall Rating")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    rating = i
                                } label: {
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundColor(i <= rating ? .yellow : .gray)
                                }
                            }
                        }
                    }
                }
                
                Section("Summary") {
                    TextEditor(text: $summary)
                        .frame(height: 100)
                }
                
                Section("Lessons & Activities") {
                    TextField("What lessons were completed?", text: $lessonsCompleted)
                }
                
                Section("Behavior") {
                    TextField("How was student behavior overall?", text: $behaviorSummary)
                }
                
                Section("Issues (Optional)") {
                    TextField("Any issues to report?", text: $issues)
                }
                
                Section("Supplies (Optional)") {
                    TextField("Any supplies needed?", text: $supplies)
                }
                
                Section("Other Notes (Optional)") {
                    TextEditor(text: $otherNotes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Daily Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveNote() }
                        .disabled(summary.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveNote() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isSaving = true
        
        db.collection("dailySubNotes").addDocument(data: [
            "schoolId": schoolId,
            "classId": classId,
            "className": className,
            "teacherId": teacherId,
            "teacherName": teacherName,
            "subId": uid,
            "subName": subName,
            "date": Timestamp(date: date),
            "summary": summary,
            "lessonsCompleted": lessonsCompleted,
            "behaviorSummary": behaviorSummary,
            "issues": issues,
            "supplies": supplies,
            "otherNotes": otherNotes,
            "rating": rating,
            "createdAt": Timestamp()
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}
