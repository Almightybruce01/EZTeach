//
//  GradeEntryViews.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-27.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Add Assignment View
struct AddAssignmentView: View {
    
    let classModel: SchoolClass
    let categories: [AssignmentCategory]
    let onSave: () -> Void
    
    @State private var name = ""
    @State private var selectedCategoryId = "homework"
    @State private var pointsPossible = "100"
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var description = ""
    @State private var isSaving = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Info") {
                    TextField("Assignment Name", text: $name)
                    
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                    
                    HStack {
                        Text("Points Possible")
                        Spacer()
                        TextField("100", text: $pointsPossible)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Due Date") {
                    Toggle("Has Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section("Description (Optional)") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }
                
                Section {
                    Button {
                        saveAssignment()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            }
                            Text(isSaving ? "Creating..." : "Create Assignment")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .navigationTitle("New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveAssignment() {
        guard let points = Double(pointsPossible), points > 0 else { return }
        isSaving = true
        
        let assignment = GradeAssignment(
            id: UUID().uuidString,
            classId: classModel.id,
            schoolId: classModel.schoolId,
            name: name,
            categoryId: selectedCategoryId,
            pointsPossible: points,
            dueDate: hasDueDate ? dueDate : nil,
            description: description.isEmpty ? nil : description,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        db.collection("gradeAssignments").document(assignment.id).setData(assignment.toDict()) { error in
            isSaving = false
            if error == nil {
                onSave()
                dismiss()
            }
        }
    }
}

// MARK: - Student Grade Detail View
struct StudentGradeDetailView: View {
    
    let student: StudentInfo
    let classModel: SchoolClass
    let assignments: [GradeAssignment]
    let grades: [String: StudentGrade]
    let categories: [AssignmentCategory]
    let useWeightedGrades: Bool
    let override: GradeOverride?
    let canEdit: Bool
    let userRole: String
    let onSave: () -> Void
    
    @State private var editedGrades: [String: GradeInput] = [:]
    @State private var showOverrideSheet = false
    @State private var isSaving = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    struct GradeInput {
        var pointsEarned: String
        var isExcused: Bool
        var isMissing: Bool
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Student header with overall grade
                    studentHeader
                    
                    // Category breakdown
                    if useWeightedGrades {
                        categoryBreakdown
                    }
                    
                    // Assignments by category
                    assignmentsList
                    
                    // Override option
                    if canEdit {
                        overrideSection
                    }
                }
                .padding()
            }
            .background(EZTeachColors.background)
            .navigationTitle(student.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                if canEdit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveGrades()
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .sheet(isPresented: $showOverrideSheet) {
                GradeOverrideSheet(
                    student: student,
                    classModel: classModel,
                    currentOverride: override,
                    calculatedPercentage: calculateOverall(),
                    userRole: userRole
                ) {
                    onSave()
                    dismiss()
                }
            }
            .onAppear {
                initializeEditedGrades()
            }
        }
    }
    
    // MARK: - Student Header
    private var studentHeader: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(EZTeachColors.accent.opacity(0.1))
                .frame(width: 70, height: 70)
                .overlay(
                    Text(student.name.prefix(1).uppercased())
                        .font(.title.bold())
                        .foregroundColor(EZTeachColors.accent)
                )
            
            VStack(spacing: 4) {
                Text(student.name)
                    .font(.title3.bold())
                
                if override != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(EZTeachColors.warning)
                        Text("Grade Overridden")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.warning)
                    }
                }
            }
            
            // Grade display
            let displayPct = override?.overridePercentage ?? calculateOverall()
            
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(StudentOverallGrade.calculateLetterGrade(from: displayPct))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(gradeColor(displayPct))
                    Text("Letter Grade")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f%%", displayPct))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(gradeColor(displayPct))
                    Text("Percentage")
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
    
    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
            
            ForEach(categories) { category in
                let catGrades = getCategoryGrades(categoryId: category.id)
                
                if catGrades.possible > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.subheadline)
                            Text("\(Int(category.weight * 100))% of grade")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f%%", catGrades.percentage))
                                .font(.subheadline.bold())
                                .foregroundColor(gradeColor(catGrades.percentage))
                            Text("\(formatNumber(catGrades.earned))/\(formatNumber(catGrades.possible))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(EZTeachColors.cardFill)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Assignments List
    private var assignmentsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assignments")
                .font(.headline)
            
            ForEach(categories) { category in
                let catAssignments = assignments.filter { $0.categoryId == category.id }
                
                if !catAssignments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        ForEach(catAssignments) { assignment in
                            assignmentRow(assignment)
                        }
                    }
                }
            }
            
            // Uncategorized assignments
            let uncategorized = assignments.filter { a in !categories.contains { $0.id == a.categoryId } }
            if !uncategorized.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Other")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(uncategorized) { assignment in
                        assignmentRow(assignment)
                    }
                }
            }
        }
    }
    
    private func assignmentRow(_ assignment: GradeAssignment) -> some View {
        let input = editedGrades[assignment.id] ?? GradeInput(pointsEarned: "", isExcused: false, isMissing: false)
        
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.name)
                    .font(.subheadline)
                
                if let dueDate = assignment.dueDate {
                    Text("Due: \(dateFormatter.string(from: dueDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if canEdit {
                // Points input
                HStack(spacing: 4) {
                    TextField("0", text: Binding(
                        get: { editedGrades[assignment.id]?.pointsEarned ?? "" },
                        set: { editedGrades[assignment.id]?.pointsEarned = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    
                    Text("/\(formatNumber(assignment.pointsPossible))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Excused button
                Button {
                    editedGrades[assignment.id]?.isExcused.toggle()
                } label: {
                    Text("EX")
                        .font(.caption.bold())
                        .foregroundColor(input.isExcused ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(input.isExcused ? EZTeachColors.accent : Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            } else {
                // Display only
                if input.isExcused {
                    Text("EX")
                        .font(.subheadline.bold())
                        .foregroundColor(EZTeachColors.accent)
                } else if let earned = Double(input.pointsEarned) {
                    let pct = (earned / assignment.pointsPossible) * 100
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(formatNumber(earned))/\(formatNumber(assignment.pointsPossible))")
                            .font(.subheadline.bold())
                        Text(String(format: "%.0f%%", pct))
                            .font(.caption)
                            .foregroundColor(gradeColor(pct))
                    }
                } else {
                    Text("-")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(10)
    }
    
    // MARK: - Override Section
    private var overrideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grade Override")
                .font(.headline)
            
            Button {
                showOverrideSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil.circle")
                    Text(override != nil ? "Edit Override" : "Override Final Grade")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.primary)
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(10)
            }
            
            Text("Use this to manually set a final grade that differs from the calculated grade.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Calculations
    private func calculateOverall() -> Double {
        if useWeightedGrades {
            return calculateWeighted()
        } else {
            return calculateSimple()
        }
    }
    
    private func calculateWeighted() -> Double {
        var categoryTotals: [String: (earned: Double, possible: Double)] = [:]
        
        for assignment in assignments {
            guard let input = editedGrades[assignment.id],
                  !input.isExcused,
                  let earned = Double(input.pointsEarned) else { continue }
            
            let current = categoryTotals[assignment.categoryId] ?? (0, 0)
            categoryTotals[assignment.categoryId] = (
                current.earned + earned,
                current.possible + assignment.pointsPossible
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
        
        if weightUsed > 0 && weightUsed < 1.0 {
            weightedTotal = weightedTotal / weightUsed
        }
        
        return weightedTotal
    }
    
    private func calculateSimple() -> Double {
        var totalEarned = 0.0
        var totalPossible = 0.0
        
        for assignment in assignments {
            guard let input = editedGrades[assignment.id],
                  !input.isExcused,
                  let earned = Double(input.pointsEarned) else { continue }
            
            totalEarned += earned
            totalPossible += assignment.pointsPossible
        }
        
        return totalPossible > 0 ? (totalEarned / totalPossible) * 100 : 0
    }
    
    private func getCategoryGrades(categoryId: String) -> (earned: Double, possible: Double, percentage: Double) {
        var earned = 0.0
        var possible = 0.0
        
        for assignment in assignments where assignment.categoryId == categoryId {
            guard let input = editedGrades[assignment.id],
                  !input.isExcused,
                  let e = Double(input.pointsEarned) else { continue }
            
            earned += e
            possible += assignment.pointsPossible
        }
        
        let pct = possible > 0 ? (earned / possible) * 100 : 0
        return (earned, possible, pct)
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
    
    private func formatNumber(_ num: Double) -> String {
        if num == floor(num) {
            return String(format: "%.0f", num)
        }
        return String(format: "%.1f", num)
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }
    
    // MARK: - Data
    private func initializeEditedGrades() {
        for assignment in assignments {
            if let existing = grades[assignment.id] {
                editedGrades[assignment.id] = GradeInput(
                    pointsEarned: existing.pointsEarned != nil ? formatNumber(existing.pointsEarned!) : "",
                    isExcused: existing.isExcused,
                    isMissing: existing.isMissing
                )
            } else {
                editedGrades[assignment.id] = GradeInput(pointsEarned: "", isExcused: false, isMissing: false)
            }
        }
    }
    
    private func saveGrades() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        
        let batch = db.batch()
        
        for assignment in assignments {
            guard let input = editedGrades[assignment.id] else { continue }
            
            let docId = "\(classModel.id)_\(student.id)_\(assignment.id)"
            let ref = db.collection("studentGrades").document(docId)
            
            var data: [String: Any] = [
                "assignmentId": assignment.id,
                "studentId": student.id,
                "classId": classModel.id,
                "pointsPossible": assignment.pointsPossible,
                "isExcused": input.isExcused,
                "isMissing": input.isMissing,
                "isLate": false,
                "gradedByUserId": uid,
                "gradedAt": Timestamp(),
                "createdAt": Timestamp(),
                "updatedAt": Timestamp()
            ]
            
            if let points = Double(input.pointsEarned) {
                data["pointsEarned"] = points
            }
            
            batch.setData(data, forDocument: ref, merge: true)
        }
        
        batch.commit { error in
            isSaving = false
            if error == nil {
                onSave()
                dismiss()
            }
        }
    }
}

// MARK: - Grade Override Sheet
struct GradeOverrideSheet: View {
    
    let student: StudentInfo
    let classModel: SchoolClass
    let currentOverride: GradeOverride?
    let calculatedPercentage: Double
    let userRole: String
    let onSave: () -> Void
    
    @State private var overridePercentage = ""
    @State private var overrideLetterGrade = ""
    @State private var reason = ""
    @State private var isSaving = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Calculated Grade") {
                    HStack {
                        Text("Percentage")
                        Spacer()
                        Text(String(format: "%.1f%%", calculatedPercentage))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Letter Grade")
                        Spacer()
                        Text(StudentOverallGrade.calculateLetterGrade(from: calculatedPercentage))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Override") {
                    HStack {
                        Text("New Percentage")
                        Spacer()
                        TextField("e.g. 85", text: $overridePercentage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                    }
                    
                    HStack {
                        Text("Or Letter Grade")
                        Spacer()
                        TextField("e.g. B+", text: $overrideLetterGrade)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Reason (Required)") {
                    TextField("Why are you overriding this grade?", text: $reason, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    if currentOverride != nil {
                        Button(role: .destructive) {
                            removeOverride()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Remove Override")
                                Spacer()
                            }
                        }
                    }
                    
                    Button {
                        saveOverride()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            }
                            Text("Save Override")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(reason.isEmpty || (overridePercentage.isEmpty && overrideLetterGrade.isEmpty) || isSaving)
                }
            }
            .navigationTitle("Grade Override")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let current = currentOverride {
                    overridePercentage = current.overridePercentage != nil ? String(format: "%.1f", current.overridePercentage!) : ""
                    overrideLetterGrade = current.overrideLetterGrade ?? ""
                    reason = current.reason ?? ""
                }
            }
        }
    }
    
    private func saveOverride() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        
        let docId = "\(classModel.id)_\(student.id)"
        
        var data: [String: Any] = [
            "classId": classModel.id,
            "studentId": student.id,
            "reason": reason,
            "overriddenByUserId": uid,
            "overriddenByRole": userRole,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        if let pct = Double(overridePercentage) {
            data["overridePercentage"] = pct
        }
        
        if !overrideLetterGrade.isEmpty {
            data["overrideLetterGrade"] = overrideLetterGrade.uppercased()
        }
        
        db.collection("gradeOverrides").document(docId).setData(data, merge: true) { error in
            isSaving = false
            if error == nil {
                onSave()
            }
        }
    }
    
    private func removeOverride() {
        isSaving = true
        let docId = "\(classModel.id)_\(student.id)"
        
        db.collection("gradeOverrides").document(docId).delete { error in
            isSaving = false
            if error == nil {
                onSave()
            }
        }
    }
}

// MARK: - Assignment List View
struct AssignmentListView: View {
    
    let classModel: SchoolClass
    let canEdit: Bool
    
    @State private var assignments: [GradeAssignment] = []
    @State private var isLoading = true
    @State private var showAddAssignment = false
    @State private var categories: [AssignmentCategory] = AssignmentCategory.defaultCategories
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if assignments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Assignments")
                        .font(.headline)
                    if canEdit {
                        Button("Add Assignment") {
                            showAddAssignment = true
                        }
                    }
                }
            } else {
                List {
                    ForEach(categories) { category in
                        let catAssignments = assignments.filter { $0.categoryId == category.id }
                        
                        if !catAssignments.isEmpty {
                            Section(category.name) {
                                ForEach(catAssignments) { assignment in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(assignment.name)
                                                .font(.subheadline)
                                            if let due = assignment.dueDate {
                                                Text("Due: \(dateFormatter.string(from: due))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text("\(Int(assignment.pointsPossible)) pts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .onDelete { indexSet in
                                    deleteAssignments(catAssignments, at: indexSet)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Assignments")
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAssignment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddAssignment) {
            AddAssignmentView(classModel: classModel, categories: categories) {
                loadAssignments()
            }
        }
        .onAppear {
            loadCategories()
            loadAssignments()
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        return f
    }
    
    private func loadCategories() {
        db.collection("classGradeSettings").document(classModel.id).getDocument { snap, _ in
            if let data = snap?.data(),
               let catData = data["categories"] as? [[String: Any]] {
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
    }
    
    private func loadAssignments() {
        db.collection("gradeAssignments")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                assignments = snap?.documents.compactMap { GradeAssignment.fromDocument($0) }
                    .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) } ?? []
                isLoading = false
            }
    }
    
    private func deleteAssignments(_ catAssignments: [GradeAssignment], at offsets: IndexSet) {
        for index in offsets {
            let assignment = catAssignments[index]
            db.collection("gradeAssignments").document(assignment.id).delete()
        }
        loadAssignments()
    }
}

// MARK: - Grade Settings View
struct GradeSettingsView: View {
    
    let classId: String
    @Binding var categories: [AssignmentCategory]
    @Binding var useWeightedGrades: Bool
    let onSave: () -> Void
    
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    private var totalWeight: Double {
        categories.reduce(0) { $0 + $1.weight }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use Weighted Grades", isOn: $useWeightedGrades)
                    
                    if useWeightedGrades {
                        Text("Categories will be weighted according to the percentages below.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if useWeightedGrades {
                    Section("Categories (Total: \(Int(totalWeight * 100))%)") {
                        ForEach(Array(categories.enumerated()), id: \.element.id) { index, _ in
                            HStack {
                                TextField("Name", text: $categories[index].name)
                                
                                Spacer()
                                
                                TextField("0", value: Binding(
                                    get: { Int(categories[index].weight * 100) },
                                    set: { categories[index].weight = Double($0) / 100.0 }
                                ), format: .number)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .multilineTextAlignment(.trailing)
                                
                                Text("%")
                            }
                        }
                        .onDelete { indexSet in
                            categories.remove(atOffsets: indexSet)
                        }
                        
                        Button {
                            categories.append(AssignmentCategory(
                                id: UUID().uuidString,
                                name: "New Category",
                                weight: 0.1,
                                dropLowest: 0
                            ))
                        } label: {
                            Label("Add Category", systemImage: "plus")
                        }
                    }
                    
                    if abs(totalWeight - 1.0) > 0.01 {
                        Section {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(EZTeachColors.warning)
                                Text("Category weights should add up to 100%")
                                    .font(.caption)
                                    .foregroundColor(EZTeachColors.warning)
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        saveSettings()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            }
                            Text("Save Settings")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Grade Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveSettings() {
        isSaving = true
        
        let catData = categories.map { cat -> [String: Any] in
            return [
                "id": cat.id,
                "name": cat.name,
                "weight": cat.weight,
                "dropLowest": cat.dropLowest
            ]
        }
        
        db.collection("classGradeSettings").document(classId).setData([
            "useWeightedGrades": useWeightedGrades,
            "categories": catData,
            "updatedAt": Timestamp()
        ], merge: true) { error in
            isSaving = false
            if error == nil {
                onSave()
                dismiss()
            }
        }
    }
}
