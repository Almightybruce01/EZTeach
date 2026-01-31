//
//  LessonPlanningView.swift
//  EZTeach
//
//  Lesson planning for teachers
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LessonPlanningView: View {
    let schoolId: String
    
    @State private var lessonPlans: [LessonPlan] = []
    @State private var isLoading = true
    @State private var showAddPlan = false
    @State private var selectedFilter: PlanFilter = .all
    
    private let db = Firestore.firestore()
    
    enum PlanFilter: String, CaseIterable {
        case all = "All"
        case thisWeek = "This Week"
        case shared = "Shared"
    }
    
    var filteredPlans: [LessonPlan] {
        switch selectedFilter {
        case .all: return lessonPlans
        case .thisWeek:
            let calendar = Calendar.current
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return lessonPlans.filter { $0.date >= weekStart && $0.date < weekEnd }
        case .shared:
            return lessonPlans.filter { $0.isShared }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(PlanFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredPlans.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Lesson Plans")
                            .font(.headline)
                        Text("Create your first lesson plan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredPlans) { plan in
                            LessonPlanRow(plan: plan)
                        }
                        .onDelete(perform: deletePlan)
                    }
                    .listStyle(.plain)
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Lesson Plans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPlan = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddPlan) {
                CreateLessonPlanView(schoolId: schoolId) {
                    loadPlans()
                }
            }
            .onAppear(perform: loadPlans)
        }
    }
    
    private func loadPlans() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        db.collection("lessonPlans")
            .whereField("teacherId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .getDocuments { snap, _ in
                lessonPlans = snap?.documents.compactMap { LessonPlan.fromDocument($0) } ?? []
                isLoading = false
            }
    }
    
    private func deletePlan(at offsets: IndexSet) {
        for index in offsets {
            let plan = filteredPlans[index]
            db.collection("lessonPlans").document(plan.id).delete()
        }
        loadPlans()
    }
}

struct LessonPlanRow: View {
    let plan: LessonPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.title)
                    .font(.headline)
                
                Spacer()
                
                if plan.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.accent)
                }
            }
            
            HStack(spacing: 12) {
                Label(plan.subject, systemImage: "book.fill")
                Label("\(plan.duration) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text(plan.date, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct CreateLessonPlanView: View {
    let schoolId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var subject = ""
    @State private var gradeLevel = 1
    @State private var duration = 45
    @State private var date = Date()
    @State private var objectives: [String] = [""]
    @State private var materials: [String] = [""]
    @State private var assessment = ""
    @State private var notes = ""
    @State private var isShared = false
    @State private var isLoading = false
    
    private let db = Firestore.firestore()
    private let subjects = ["Math", "Science", "English", "History", "Art", "Music", "PE", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Lesson Title", text: $title)
                    
                    Picker("Subject", selection: $subject) {
                        Text("Select").tag("")
                        ForEach(subjects, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    
                    Picker("Grade Level", selection: $gradeLevel) {
                        ForEach(GradeUtils.allGrades, id: \.self) { g in
                            Text(GradeUtils.label(g)).tag(g)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Stepper("Duration: \(duration) minutes", value: $duration, in: 15...180, step: 5)
                }
                
                Section("Learning Objectives") {
                    ForEach(objectives.indices, id: \.self) { index in
                        TextField("Objective \(index + 1)", text: $objectives[index])
                    }
                    
                    Button("Add Objective") {
                        objectives.append("")
                    }
                }
                
                Section("Materials Needed") {
                    ForEach(materials.indices, id: \.self) { index in
                        TextField("Material \(index + 1)", text: $materials[index])
                    }
                    
                    Button("Add Material") {
                        materials.append("")
                    }
                }
                
                Section("Assessment") {
                    TextEditor(text: $assessment)
                        .frame(height: 80)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section {
                    Toggle("Share with other teachers", isOn: $isShared)
                }
            }
            .navigationTitle("New Lesson Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        savePlan()
                    }
                    .disabled(title.isEmpty || subject.isEmpty)
                }
            }
        }
    }
    
    private func savePlan() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let data: [String: Any] = [
            "teacherId": uid,
            "schoolId": schoolId,
            "title": title,
            "subject": subject,
            "gradeLevel": gradeLevel,
            "objectives": objectives.filter { !$0.isEmpty },
            "materials": materials.filter { !$0.isEmpty },
            "activities": [],
            "assessment": assessment,
            "notes": notes,
            "duration": duration,
            "date": Timestamp(date: date),
            "isShared": isShared,
            "createdAt": Timestamp()
        ]
        
        db.collection("lessonPlans").addDocument(data: data) { _ in
            onSave()
            dismiss()
        }
    }
}
