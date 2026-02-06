//
//  StudentGradesView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-27.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct StudentGradesView: View {
    
    let classModel: SchoolClass
    
    @State private var students: [Student] = []
    @State private var assignments: [GradeAssignment] = []
    @State private var grades: [String: [String: StudentGrade]] = [:] // [studentId: [assignmentId: grade]]
    @State private var overrides: [String: GradeOverride] = [:] // [studentId: override]
    @State private var categories: [AssignmentCategory] = AssignmentCategory.defaultCategories
    @State private var useWeightedGrades = true
    
    @State private var isLoading = true
    @State private var canEdit = false
    @State private var userRole = ""
    @State private var showAddAssignment = false
    @State private var showSettings = false
    @State private var selectedStudent: StudentInfo?
    @State private var selectedAssignment: GradeAssignment?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading grades...")
            } else if students.isEmpty {
                emptyStudentsView
            } else {
                VStack(spacing: 0) {
                    // Summary header
                    summaryHeader
                    
                    // Main content
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(students) { student in
                                studentGradeCard(student)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Grades")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if canEdit {
                        Button {
                            showAddAssignment = true
                        } label: {
                            Label("Add Assignment", systemImage: "plus")
                        }
                        
                        Button {
                            showSettings = true
                        } label: {
                            Label("Grade Settings", systemImage: "gearshape")
                        }
                    }
                    
                    NavigationLink {
                        AssignmentListView(classModel: classModel, canEdit: canEdit)
                    } label: {
                        Label("All Assignments", systemImage: "list.bullet")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddAssignment) {
            AddAssignmentView(classModel: classModel, categories: categories) {
                loadData()
            }
        }
        .sheet(isPresented: $showSettings) {
            GradeSettingsView(classId: classModel.id, categories: $categories, useWeightedGrades: $useWeightedGrades) {
                loadData()
            }
        }
        .sheet(item: $selectedStudent) { student in
            StudentGradeDetailView(
                student: StudentInfo(id: student.id, name: student.name),
                classModel: classModel,
                assignments: assignments,
                grades: grades[student.id] ?? [:],
                categories: categories,
                useWeightedGrades: useWeightedGrades,
                override: overrides[student.id],
                canEdit: canEdit,
                userRole: userRole
            ) {
                loadData()
            }
        }
        .onAppear {
            checkPermissions()
            loadData()
        }
    }
    
    // MARK: - Summary Header
    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(classModel.name)
                        .font(.headline)
                    Text("\(students.count) students • \(assignments.count) assignments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Class average
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Class Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", calculateClassAverage()))
                        .font(.title2.bold())
                        .foregroundColor(gradeColor(calculateClassAverage()))
                }
            }
            
            // Category breakdown (if weighted)
            if useWeightedGrades && !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories) { category in
                            VStack(spacing: 2) {
                                Text(category.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(Int(category.weight * 100))%")
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(EZTeachColors.cardFill)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
    }
    
    // MARK: - Student Grade Card
    private func studentGradeCard(_ student: Student) -> some View {
        let overallGrade = calculateStudentOverall(studentId: student.id)
        let override = overrides[student.id]
        
        return HStack(spacing: 14) {
            NavigationLink {
                StudentProfileView(student: student)
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(EZTeachColors.accent.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(student.name.prefix(1).uppercased())
                                .font(.headline)
                                .foregroundColor(EZTeachColors.accent)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(student.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        let completed = countCompletedAssignments(studentId: student.id)
                        Text("\(completed)/\(assignments.count) graded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if override != nil {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.warning)
                    }
                    Text(StudentOverallGrade.calculateLetterGrade(from: override?.overridePercentage ?? overallGrade))
                        .font(.title3.bold())
                        .foregroundColor(gradeColor(override?.overridePercentage ?? overallGrade))
                }
                Text(String(format: "%.1f%%", override?.overridePercentage ?? overallGrade))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button {
                selectedStudent = StudentInfo(id: student.id, name: student.name)
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
                    .foregroundColor(EZTeachColors.accent)
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Empty State
    private var emptyStudentsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "graduationcap")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Students")
                .font(.title2.bold())
            
            Text("Add students to this class to start entering grades.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Calculations
    private func calculateClassAverage() -> Double {
        guard !students.isEmpty else { return 0 }
        
        var total = 0.0
        var count = 0
        
        for student in students {
            let grade = calculateStudentOverall(studentId: student.id)
            if grade > 0 {
                total += grade
                count += 1
            }
        }
        
        return count > 0 ? total / Double(count) : 0
    }
    
    private func calculateStudentOverall(studentId: String) -> Double {
        let studentGrades = grades[studentId] ?? [:]
        
        if useWeightedGrades {
            return calculateWeightedGrade(studentGrades: studentGrades)
        } else {
            return calculateSimpleGrade(studentGrades: studentGrades)
        }
    }
    
    private func calculateWeightedGrade(studentGrades: [String: StudentGrade]) -> Double {
        var categoryTotals: [String: (earned: Double, possible: Double)] = [:]
        
        for assignment in assignments {
            guard let grade = studentGrades[assignment.id],
                  let earned = grade.pointsEarned,
                  !grade.isExcused else { continue }
            
            let current = categoryTotals[assignment.categoryId] ?? (0, 0)
            categoryTotals[assignment.categoryId] = (
                current.earned + earned,
                current.possible + grade.pointsPossible
            )
        }
        
        var weightedTotal = 0.0
        var weightUsed = 0.0
        
        for category in categories {
            if let totals = categoryTotals[category.id], totals.possible > 0 {
                let categoryPct = (totals.earned / totals.possible) * 100
                weightedTotal += categoryPct * category.weight
                weightUsed += category.weight
            }
        }
        
        // Normalize for missing categories
        if weightUsed > 0 && weightUsed < 1.0 {
            weightedTotal = weightedTotal / weightUsed
        }
        
        return weightedTotal
    }
    
    private func calculateSimpleGrade(studentGrades: [String: StudentGrade]) -> Double {
        var totalEarned = 0.0
        var totalPossible = 0.0
        
        for (_, grade) in studentGrades {
            guard let earned = grade.pointsEarned, !grade.isExcused else { continue }
            totalEarned += earned
            totalPossible += grade.pointsPossible
        }
        
        return totalPossible > 0 ? (totalEarned / totalPossible) * 100 : 0
    }
    
    private func countCompletedAssignments(studentId: String) -> Int {
        let studentGrades = grades[studentId] ?? [:]
        return studentGrades.values.filter { $0.pointsEarned != nil || $0.isExcused }.count
    }
    
    private func gradeColor(_ percentage: Double) -> Color {
        switch percentage {
        case 90...Double.infinity: return EZTeachColors.success
        case 80..<90: return Color.green.opacity(0.8)
        case 70..<80: return EZTeachColors.warning
        case 60..<70: return .orange
        default: return EZTeachColors.error
        }
    }
    
    // MARK: - Load Data
    private func checkPermissions() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snap, _ in
            let role = snap?.data()?["role"] as? String ?? ""
            userRole = role
            
            if role == "school" {
                canEdit = true
            } else if role == "teacher" {
                canEdit = classModel.teacherIds.contains(uid)
            } else {
                canEdit = false
            }
        }
    }
    
    private func loadData() {
        let group = DispatchGroup()
        
        // Load students
        group.enter()
        loadStudents { group.leave() }
        
        // Load assignments
        group.enter()
        loadAssignments { group.leave() }
        
        // Load grades
        group.enter()
        loadGrades { group.leave() }
        
        // Load overrides
        group.enter()
        loadOverrides { group.leave() }
        
        // Load settings
        group.enter()
        loadSettings { group.leave() }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
    
    private func loadStudents(completion: @escaping () -> Void) {
        db.collection("class_rosters")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                let studentIds = snap?.documents.compactMap { $0["studentId"] as? String } ?? []
                
                guard !studentIds.isEmpty else {
                    completion()
                    return
                }
                
                db.collection("students")
                    .whereField(FieldPath.documentID(), in: Array(studentIds.prefix(10)))
                    .getDocuments { studentSnap, _ in
                        students = studentSnap?.documents.compactMap { Student.fromDocument($0) }
                            .sorted { $0.name < $1.name } ?? []
                        completion()
                    }
            }
    }
    
    private func loadAssignments(completion: @escaping () -> Void) {
        db.collection("gradeAssignments")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                assignments = snap?.documents.compactMap { GradeAssignment.fromDocument($0) }
                    .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) } ?? []
                completion()
            }
    }
    
    private func loadGrades(completion: @escaping () -> Void) {
        db.collection("studentGrades")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                var newGrades: [String: [String: StudentGrade]] = [:]
                
                snap?.documents.forEach { doc in
                    if let grade = StudentGrade.fromDocument(doc) {
                        if newGrades[grade.studentId] == nil {
                            newGrades[grade.studentId] = [:]
                        }
                        newGrades[grade.studentId]?[grade.assignmentId] = grade
                    }
                }
                
                grades = newGrades
                completion()
            }
    }
    
    private func loadOverrides(completion: @escaping () -> Void) {
        db.collection("gradeOverrides")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                var newOverrides: [String: GradeOverride] = [:]
                
                snap?.documents.forEach { doc in
                    if let override = GradeOverride.fromDocument(doc) {
                        newOverrides[override.studentId] = override
                    }
                }
                
                overrides = newOverrides
                completion()
            }
    }
    
    private func loadSettings(completion: @escaping () -> Void) {
        db.collection("classGradeSettings").document(classModel.id).getDocument { snap, _ in
            if let data = snap?.data() {
                useWeightedGrades = data["useWeightedGrades"] as? Bool ?? true
                
                if let catData = data["categories"] as? [[String: Any]] {
                    categories = catData.compactMap { dict in
                        AssignmentCategory(
                            id: dict["id"] as? String ?? UUID().uuidString,
                            name: dict["name"] as? String ?? "",
                            weight: dict["weight"] as? Double ?? 0.1,
                            dropLowest: dict["dropLowest"] as? Int ?? 0
                        )
                    }
                }
            }
            completion()
        }
    }
}

// MARK: - Student Info
struct StudentInfo: Identifiable {
    let id: String
    let name: String
}
