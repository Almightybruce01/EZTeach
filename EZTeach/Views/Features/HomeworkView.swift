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
                        .onDelete(perform: deleteAssignment)
                    }
                    .listStyle(.plain)
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Homework")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAssignment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
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
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section("Grading") {
                    Stepper("Points: \(pointsWorth)", value: $pointsWorth, in: 1...100)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("New Homework")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Assign") {
                        saveHomework()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveHomework() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("homework").addDocument(data: [
            "classId": classId,
            "teacherId": uid,
            "schoolId": schoolId,
            "title": title,
            "description": description,
            "dueDate": Timestamp(date: dueDate),
            "pointsWorth": pointsWorth,
            "attachmentUrls": [],
            "createdAt": Timestamp()
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}
