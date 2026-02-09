//
//  HomeworkView.swift
//  EZTeach
//
//  Homework assignments management
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeworkView: View {
    let schoolId: String
    let classId: String?
    var userRole: String = "teacher"
    
    @State private var assignments: [HomeworkAssignment] = []
    @State private var isLoading = true
    @State private var showAddAssignment = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else if assignments.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(assignments) { assignment in
                            HomeworkRow(assignment: assignment)
                        }
                        .onDelete { offsets in
                            if userRole == "school" || userRole == "teacher" { deleteAssignment(at: offsets) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Homework")
            .toolbar {
                if userRole == "school" || userRole == "teacher" {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddAssignment = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddAssignment) {
                CreateHomeworkView(schoolId: schoolId, classId: classId ?? "") {
                    loadAssignments()
                }
            }
            .onAppear(perform: loadAssignments)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Homework Assigned")
                .font(.headline)
            Text("Tap + to create an assignment")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func loadAssignments() {
        isLoading = true
        var query: Query = db.collection("homework").whereField("schoolId", isEqualTo: schoolId)
        
        if let classId = classId {
            query = query.whereField("classId", isEqualTo: classId)
        }
        
        query.order(by: "dueDate").getDocuments { snap, _ in
            assignments = snap?.documents.compactMap { HomeworkAssignment.fromDocument($0) } ?? []
            isLoading = false
        }
    }
    
    private func deleteAssignment(at offsets: IndexSet) {
        for index in offsets {
            db.collection("homework").document(assignments[index].id).delete()
        }
        loadAssignments()
    }
}

struct HomeworkRow: View {
    let assignment: HomeworkAssignment
    
    var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: assignment.dueDate).day ?? 0
        return daysUntilDue <= 2 && daysUntilDue >= 0
    }
    
    var isOverdue: Bool {
        assignment.dueDate < Date()
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(isOverdue ? Color.red.opacity(0.2) : (isDueSoon ? Color.orange.opacity(0.2) : EZTeachColors.cardFill))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(isOverdue ? .red : (isDueSoon ? .orange : EZTeachColors.accent))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline.weight(.semibold))
                
                Text(assignment.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(assignment.pointsWorth) pts", systemImage: "star.fill")
                    Text("•")
                    Text("Due \(assignment.dueDate, style: .date)")
                }
                .font(.caption2)
                .foregroundColor(isOverdue ? .red : .secondary)
            }
            
            Spacer()
            
            if isOverdue {
                Text("OVERDUE")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateHomeworkView: View {
    let schoolId: String
    let classId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)
    @State private var pointsWorth = 10
    @State private var selectedClass: SchoolClass?
    @State private var classes: [SchoolClass] = []
    @State private var isLoadingClasses = true
    @State private var assignmentType: AssignmentType = .homework
    @State private var subject = ""
    @State private var instructions = ""
    @State private var isSaving = false
    
    enum AssignmentType: String, CaseIterable {
        case homework = "Homework"
        case classwork = "Classwork"
        case project = "Project"
        case quiz = "Quiz"
        case test = "Test"
        case extra = "Extra Credit"
        
        var icon: String {
            switch self {
            case .homework: return "house.fill"
            case .classwork: return "pencil.and.ruler.fill"
            case .project: return "folder.fill"
            case .quiz: return "questionmark.circle.fill"
            case .test: return "doc.text.fill"
            case .extra: return "star.fill"
            }
        }
    }
    
    private let db = Firestore.firestore()
    
    private var canSave: Bool {
        !title.isEmpty && !description.isEmpty && selectedClass != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Class Selection
                Section {
                    if isLoadingClasses {
                        HStack {
                            ProgressView()
                            Text("Loading classes...")
                                .foregroundColor(.secondary)
                        }
                    } else if classes.isEmpty {
                        Text("No classes found")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select Class", selection: $selectedClass) {
                            Text("Select a class").tag(nil as SchoolClass?)
                            ForEach(classes) { cls in
                                HStack {
                                    Image(systemName: cls.subjectType.icon)
                                    Text("\(cls.name) - Grade \(cls.grade)")
                                }
                                .tag(cls as SchoolClass?)
                            }
                        }
                    }
                    
                    if let cls = selectedClass {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("All students in \(cls.name) will receive this assignment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Assign To")
                } footer: {
                    Text("All students enrolled in the selected class will be assigned this homework.")
                }
                
                // Assignment Type
                Section("Assignment Type") {
                    Picker("Type", selection: $assignmentType) {
                        ForEach(AssignmentType.allCases, id: \.rawValue) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Subject (optional)", text: $subject)
                        .textContentType(.none)
                }
                
                // Assignment Details
                Section("Assignment Details") {
                    TextField("Title *", text: $title)
                    
                    VStack(alignment: .leading) {
                        Text("Description *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(height: 100)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Instructions (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $instructions)
                            .frame(height: 80)
                    }
                }
                
                // Due Date & Grading
                Section("Due Date & Grading") {
                    DatePicker("Due Date *", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    
                    Stepper("Points: \(pointsWorth)", value: $pointsWorth, in: 1...100)
                    
                    // Visual due date preview
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Due: \(dueDate, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Preview
                if canSave {
                    Section("Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: assignmentType.icon)
                                    .foregroundColor(EZTeachColors.brightTeal)
                                Text(title)
                                    .font(.headline)
                            }
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            HStack {
                                Label("\(pointsWorth) pts", systemImage: "star.fill")
                                Spacer()
                                Label("Due \(dueDate, style: .date)", systemImage: "calendar")
                            }
                            .font(.caption2)
                            .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Assign") {
                        saveHomework()
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .onAppear { loadClasses() }
        }
    }
    
    private func loadClasses() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoadingClasses = true
        
        // Load classes where the teacher is assigned
        db.collection("classes")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("teacherIds", arrayContains: uid)
            .getDocuments { snap, _ in
                classes = snap?.documents.compactMap { SchoolClass.fromDocument($0) } ?? []
                
                // If a classId was provided, select it
                if !classId.isEmpty {
                    selectedClass = classes.first { $0.id == classId }
                }
                
                isLoadingClasses = false
            }
    }
    
    private func saveHomework() {
        guard let uid = Auth.auth().currentUser?.uid,
              let selectedClass = selectedClass else { return }
        
        isSaving = true
        
        // Create the homework document
        db.collection("homework").addDocument(data: [
            "classId": selectedClass.id,
            "className": selectedClass.name,
            "teacherId": uid,
            "schoolId": schoolId,
            "title": title,
            "description": description,
            "instructions": instructions,
            "subject": subject,
            "assignmentType": assignmentType.rawValue,
            "dueDate": Timestamp(date: dueDate),
            "pointsWorth": pointsWorth,
            "attachmentUrls": [],
            "createdAt": Timestamp(),
            "grade": selectedClass.grade
        ]) { error in
            if error == nil {
                // Assign to all students in the class
                assignToStudents(classId: selectedClass.id)
            } else {
                isSaving = false
            }
        }
    }
    
    private func assignToStudents(classId: String) {
        // Get all students enrolled in this class
        db.collection("classEnrollments")
            .whereField("classId", isEqualTo: classId)
            .getDocuments { snap, _ in
                // For each enrolled student, create an assignment record
                // This ensures students see it in their homework section
                let batch = db.batch()
                
                for doc in snap?.documents ?? [] {
                    if let studentId = doc.data()["studentId"] as? String {
                        let assignmentRef = db.collection("studentAssignments").document()
                        batch.setData([
                            "studentId": studentId,
                            "classId": classId,
                            "schoolId": schoolId,
                            "homeworkId": doc.documentID,
                            "title": title,
                            "dueDate": Timestamp(date: dueDate),
                            "status": "pending",
                            "createdAt": Timestamp()
                        ], forDocument: assignmentRef)
                    }
                }
                
                batch.commit { _ in
                    onSave()
                    dismiss()
                }
            }
    }
}

// MARK: - Enhanced Homework View with Class Filter
struct EnhancedHomeworkView: View {
    let schoolId: String
    let teacherId: String
    var userRole: String = "teacher"
    
    @State private var assignments: [HomeworkAssignment] = []
    @State private var classes: [SchoolClass] = []
    @State private var selectedClass: SchoolClass?
    @State private var isLoading = true
    @State private var showAddAssignment = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Class filter
                if !classes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ClassFilterChip(title: "All", isSelected: selectedClass == nil) {
                                selectedClass = nil
                                loadAssignments()
                            }
                            ForEach(classes) { cls in
                                ClassFilterChip(
                                    title: cls.name,
                                    isSelected: selectedClass?.id == cls.id,
                                    icon: cls.subjectType.icon
                                ) {
                                    selectedClass = cls
                                    loadAssignments()
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.white.shadow(color: .black.opacity(0.05), radius: 2, y: 2))
                }
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if assignments.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Assignments")
                            .font(.headline)
                        Text("Create homework for your classes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(assignments) { assignment in
                            HomeworkRow(assignment: assignment)
                        }
                        .onDelete { offsets in
                            if userRole == "school" || userRole == "teacher" {
                                deleteAssignment(at: offsets)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Homework")
            .toolbar {
                if userRole == "school" || userRole == "teacher" {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddAssignment = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddAssignment) {
                CreateHomeworkView(schoolId: schoolId, classId: selectedClass?.id ?? "") {
                    loadAssignments()
                }
            }
            .onAppear {
                loadClasses()
                loadAssignments()
            }
        }
    }
    
    private func loadClasses() {
        db.collection("classes")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("teacherIds", arrayContains: teacherId)
            .getDocuments { snap, _ in
                classes = snap?.documents.compactMap { SchoolClass.fromDocument($0) } ?? []
            }
    }
    
    private func loadAssignments() {
        isLoading = true
        var query: Query = db.collection("homework")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("teacherId", isEqualTo: teacherId)
        
        if let cls = selectedClass {
            query = query.whereField("classId", isEqualTo: cls.id)
        }
        
        query.order(by: "dueDate").getDocuments { snap, _ in
            assignments = snap?.documents.compactMap { HomeworkAssignment.fromDocument($0) } ?? []
            isLoading = false
        }
    }
    
    private func deleteAssignment(at offsets: IndexSet) {
        for index in offsets {
            db.collection("homework").document(assignments[index].id).delete()
        }
        loadAssignments()
    }
}

struct ClassFilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : EZTeachColors.textDark)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? EZTeachColors.brightTeal : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? EZTeachColors.brightTeal : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
