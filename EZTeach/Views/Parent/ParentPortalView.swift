//
//  ParentPortalView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-27.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ParentPortalView: View {
    
    @State private var children: [Student] = []
    @State private var isLoading = true
    @State private var showAddChild = false
    @State private var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading...")
            } else if children.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        headerView
                        
                        // Children cards
                        ForEach(children) { child in
                            NavigationLink {
                                ParentChildDetailView(student: child)
                            } label: {
                                childCard(child)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Children")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddChild = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(EZTeachColors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddChild) {
            LinkChildView { loadChildren() }
        }
        .onAppear(perform: loadChildren)
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, Parent!")
                .font(.title2.bold())
            
            Text("View your children's grades, classes, and school information.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Child Card
    private func childCard(_ child: Student) -> some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(EZTeachColors.accent.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(child.firstName.prefix(1).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(EZTeachColors.accent)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(GradeUtils.label(child.gradeLevel))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Children Linked")
                    .font(.title2.bold())
                
                Text("Link your children using their unique student code to view their grades and school information.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showAddChild = true
            } label: {
                Label("Link a Child", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(EZTeachColors.accentGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(40)
    }
    
    // MARK: - Load Data
    private func loadChildren() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        // Find all students where this parent is linked
        db.collection("students")
            .whereField("parentIds", arrayContains: uid)
            .getDocuments { snap, error in
                if let docs = snap?.documents {
                    children = docs.compactMap { Student.fromDocument($0) }
                        .sorted { $0.lastName < $1.lastName }
                }
                isLoading = false
            }
    }
}

// MARK: - Link Child View
struct LinkChildView: View {
    
    let onSuccess: () -> Void
    
    @State private var studentCode = ""
    @State private var relationship: ParentStudentLink.Relationship = .guardian
    @State private var isPrimaryContact = false
    @State private var canPickup = true
    @State private var emergencyContact = false
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var studentFound: Student?
    @State private var step = 1  // 1 = enter code, 2 = confirm
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if step == 1 {
                    enterCodeStep
                } else {
                    confirmStep
                }
            }
            .padding()
            .navigationTitle("Link a Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Step 1: Enter Code
    private var enterCodeStep: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 48))
                .foregroundColor(EZTeachColors.accent)
            
            VStack(spacing: 8) {
                Text("Enter Student Code")
                    .font(.title2.bold())
                
                Text("Ask your child's school for their unique 8-character student code.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Code input
            TextField("e.g. ABC12345", text: $studentCode)
                .font(.title3.monospaced())
                .multilineTextAlignment(.center)
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(12)
                .onChange(of: studentCode) { _, newValue in
                    studentCode = String(newValue.uppercased().prefix(8))
                }
            
            // Error
            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                }
                .font(.subheadline)
                .foregroundColor(EZTeachColors.error)
            }
            
            // Search button
            Button {
                searchStudent()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Searching..." : "Find Student")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(studentCode.count == 8 ? EZTeachColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(studentCode.count == 8 ? .white : .secondary)
                .cornerRadius(12)
            }
            .disabled(studentCode.count != 8 || isLoading)
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Confirm
    private var confirmStep: some View {
        VStack(spacing: 24) {
            if let student = studentFound {
                // Student found card
                VStack(spacing: 16) {
                    Circle()
                        .fill(EZTeachColors.success.opacity(0.1))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(EZTeachColors.success)
                        )
                    
                    Text("Student Found!")
                        .font(.title3.bold())
                    
                    VStack(spacing: 4) {
                        Text(student.fullName)
                            .font(.headline)
                        Text(GradeUtils.label(student.gradeLevel))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(16)
                
                // Relationship form
                Form {
                    Section("Your Relationship") {
                        Picker("Relationship", selection: $relationship) {
                            ForEach(ParentStudentLink.Relationship.allCases, id: \.self) { rel in
                                Text(rel.displayName).tag(rel)
                            }
                        }
                    }
                    
                    Section("Permissions") {
                        Toggle("Primary Contact", isOn: $isPrimaryContact)
                        Toggle("Authorized for Pickup", isOn: $canPickup)
                        Toggle("Emergency Contact", isOn: $emergencyContact)
                    }
                }
                .frame(height: 280)
                .scrollDisabled(true)
                
                // Link button
                Button {
                    linkChild()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLoading ? "Linking..." : "Link This Child")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(EZTeachColors.accentGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                
                // Go back
                Button {
                    step = 1
                    studentFound = nil
                } label: {
                    Text("Try Different Code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func searchStudent() {
        guard studentCode.count == 8 else { return }
        
        isLoading = true
        errorMessage = ""
        
        db.collection("students")
            .whereField("studentCode", isEqualTo: studentCode.uppercased())
            .limit(to: 1)
            .getDocuments { snap, error in
                isLoading = false
                
                if let doc = snap?.documents.first,
                   let student = Student.fromDocument(doc) {
                    studentFound = student
                    step = 2
                } else {
                    errorMessage = "No student found with this code. Please check and try again."
                }
            }
    }
    
    private func linkChild() {
        guard let student = studentFound,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let batch = db.batch()
        
        // 1. Add parent to student's parentIds
        let studentRef = db.collection("students").document(student.id)
        batch.updateData([
            "parentIds": FieldValue.arrayUnion([uid])
        ], forDocument: studentRef)
        
        // 2. Create parent-student link document
        let linkRef = db.collection("parentStudentLinks").document()
        batch.setData([
            "parentUserId": uid,
            "studentId": student.id,
            "schoolId": student.schoolId,
            "relationship": relationship.rawValue,
            "isPrimaryContact": isPrimaryContact,
            "canPickup": canPickup,
            "emergencyContact": emergencyContact,
            "createdAt": Timestamp()
        ], forDocument: linkRef)
        
        // 3. Update parent's childrenIds and schoolIds
        db.collection("parents")
            .whereField("userId", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments { snap, _ in
                if let parentDoc = snap?.documents.first {
                    batch.updateData([
                        "childrenIds": FieldValue.arrayUnion([student.id]),
                        "schoolIds": FieldValue.arrayUnion([student.schoolId])
                    ], forDocument: parentDoc.reference)
                }
                
                // 4. Update user's activeSchoolId if not set
                let userRef = db.collection("users").document(uid)
                batch.updateData([
                    "activeSchoolId": student.schoolId,
                    "joinedSchools": FieldValue.arrayUnion([
                        ["id": student.schoolId, "name": ""]
                    ])
                ], forDocument: userRef)
                
                batch.commit { error in
                    isLoading = false
                    if error == nil {
                        onSuccess()
                        dismiss()
                    } else {
                        errorMessage = error?.localizedDescription ?? "Failed to link child"
                    }
                }
            }
    }
}

// MARK: - Parent Child Detail View
struct ParentChildDetailView: View {
    
    let student: Student
    
    @State private var classes: [SchoolClass] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Student header
                studentHeader
                
                // Quick links
                quickLinks
                
                // Classes
                classesSection
            }
            .padding()
        }
        .background(EZTeachColors.background)
        .navigationTitle(student.firstName)
        .onAppear(perform: loadClasses)
    }
    
    // MARK: - Student Header
    private var studentHeader: some View {
        VStack(spacing: 16) {
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
                
                Text(GradeUtils.label(student.gradeLevel))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Student Code: \(student.studentCode)")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Quick Links
    private var quickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                quickLinkCard(icon: "chart.bar.doc.horizontal", title: "All Grades", color: EZTeachColors.accent) {
                    ParentAllGradesView(student: student, classes: classes)
                }
                
                quickLinkCard(icon: "calendar", title: "Schedule", color: EZTeachColors.success) {
                    ParentScheduleView(student: student)
                }
                
                quickLinkCard(icon: "person.crop.rectangle.stack", title: "Attendance", color: EZTeachColors.warning) {
                    ParentAttendanceView(student: student)
                }
                
                quickLinkCard(icon: "bell", title: "Announcements", color: EZTeachColors.navy) {
                    ParentAnnouncementsView(schoolId: student.schoolId)
                }
            }
        }
    }
    
    private func quickLinkCard<Destination: View>(icon: String, title: String, color: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
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
    }
    
    // MARK: - Classes Section
    private var classesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Classes")
                .font(.headline)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if classes.isEmpty {
                Text("No classes enrolled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(classes) { cls in
                    NavigationLink {
                        ParentClassGradesView(student: student, classModel: cls)
                    } label: {
                        classRow(cls)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func classRow(_ cls: SchoolClass) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(cls.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("View Grades")
                .font(.caption)
                .foregroundColor(EZTeachColors.accent)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(10)
    }
    
    // MARK: - Load Data
    private func loadClasses() {
        // Find classes the student is enrolled in
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

// MARK: - Parent Class Grades View
struct ParentClassGradesView: View {
    
    let student: Student
    let classModel: SchoolClass
    
    @State private var assignments: [GradeAssignment] = []
    @State private var grades: [String: StudentGrade] = [:]
    @State private var categories: [AssignmentCategory] = AssignmentCategory.defaultCategories
    @State private var useWeightedGrades = true
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall grade card
                overallGradeCard
                
                // Category breakdown
                if useWeightedGrades {
                    categoryBreakdown
                }
                
                // Assignments list
                assignmentsList
            }
            .padding()
        }
        .background(EZTeachColors.background)
        .navigationTitle(classModel.name)
        .onAppear(perform: loadData)
    }
    
    // MARK: - Overall Grade Card
    private var overallGradeCard: some View {
        let overall = calculateOverall()
        
        return VStack(spacing: 16) {
            Text(student.fullName)
                .font(.headline)
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(StudentOverallGrade.calculateLetterGrade(from: overall))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(gradeColor(overall))
                    Text("Grade")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text(String(format: "%.1f%%", overall))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(gradeColor(overall))
                    Text("Percentage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Completion
            let completed = grades.values.filter { $0.pointsEarned != nil || $0.isExcused }.count
            Text("\(completed)/\(assignments.count) assignments graded")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
            
            ForEach(categories) { category in
                let catData = getCategoryData(categoryId: category.id)
                
                if catData.possible > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.subheadline)
                            Text("\(Int(category.weight * 100))% of grade")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", catData.percentage))
                            .font(.subheadline.bold())
                            .foregroundColor(gradeColor(catData.percentage))
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
            
            if assignments.isEmpty {
                Text("No assignments yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(assignments) { assignment in
                    assignmentRow(assignment)
                }
            }
        }
    }
    
    private func assignmentRow(_ assignment: GradeAssignment) -> some View {
        let grade = grades[assignment.id]
        
        return HStack {
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
            
            if let g = grade {
                if g.isExcused {
                    Text("EX")
                        .font(.subheadline.bold())
                        .foregroundColor(EZTeachColors.accent)
                } else if let earned = g.pointsEarned {
                    let pct = (earned / g.pointsPossible) * 100
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(formatNumber(earned))/\(formatNumber(g.pointsPossible))")
                            .font(.subheadline.bold())
                        Text(String(format: "%.0f%%", pct))
                            .font(.caption)
                            .foregroundColor(gradeColor(pct))
                    }
                } else {
                    Text("-")
                        .foregroundColor(.secondary)
                }
            } else {
                Text("-")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(10)
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
            guard let grade = grades[assignment.id],
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
        
        if weightUsed > 0 && weightUsed < 1.0 {
            weightedTotal = weightedTotal / weightUsed
        }
        
        return weightedTotal
    }
    
    private func calculateSimple() -> Double {
        var totalEarned = 0.0
        var totalPossible = 0.0
        
        for (_, grade) in grades {
            guard let earned = grade.pointsEarned, !grade.isExcused else { continue }
            totalEarned += earned
            totalPossible += grade.pointsPossible
        }
        
        return totalPossible > 0 ? (totalEarned / totalPossible) * 100 : 0
    }
    
    private func getCategoryData(categoryId: String) -> (earned: Double, possible: Double, percentage: Double) {
        var earned = 0.0
        var possible = 0.0
        
        for assignment in assignments where assignment.categoryId == categoryId {
            guard let grade = grades[assignment.id],
                  let e = grade.pointsEarned,
                  !grade.isExcused else { continue }
            
            earned += e
            possible += grade.pointsPossible
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
    
    // MARK: - Load Data
    private func loadData() {
        let group = DispatchGroup()
        
        // Load assignments
        group.enter()
        db.collection("gradeAssignments")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                assignments = snap?.documents.compactMap { GradeAssignment.fromDocument($0) }
                    .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) } ?? []
                group.leave()
            }
        
        // Load grades for this student
        group.enter()
        db.collection("studentGrades")
            .whereField("classId", isEqualTo: classModel.id)
            .whereField("studentId", isEqualTo: student.id)
            .getDocuments { snap, _ in
                grades = [:]
                snap?.documents.forEach { doc in
                    if let grade = StudentGrade.fromDocument(doc) {
                        grades[grade.assignmentId] = grade
                    }
                }
                group.leave()
            }
        
        // Load settings
        group.enter()
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
            group.leave()
        }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
}

// MARK: - Parent All Grades View
struct ParentAllGradesView: View {
    let student: Student
    let classes: [SchoolClass]
    
    var body: some View {
        List {
            ForEach(classes) { cls in
                NavigationLink {
                    ParentClassGradesView(student: student, classModel: cls)
                } label: {
                    Text(cls.name)
                }
            }
        }
        .navigationTitle("All Grades")
    }
}

// MARK: - Parent Schedule View
struct ParentScheduleView: View {
    let student: Student
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Schedule coming soon")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Schedule")
    }
}

// MARK: - Parent Attendance View
struct ParentAttendanceView: View {
    let student: Student
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Attendance coming soon")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Attendance")
    }
}

// MARK: - Parent Announcements View
struct ParentAnnouncementsView: View {
    let schoolId: String
    
    @State private var announcements: [Announcement] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if announcements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No announcements")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(announcements) { ann in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ann.title)
                                .font(.headline)
                            Text(ann.body)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Announcements")
        .onAppear(perform: loadAnnouncements)
    }
    
    private func loadAnnouncements() {
        db.collection("announcements")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("teachersOnly", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments { snap, _ in
                announcements = snap?.documents.compactMap { doc -> Announcement? in
                    let d = doc.data()
                    return Announcement(
                        id: doc.documentID,
                        schoolId: d["schoolId"] as? String ?? "",
                        title: d["title"] as? String ?? "",
                        body: d["body"] as? String ?? "",
                        isActive: d["isActive"] as? Bool ?? true
                    )
                } ?? []
                isLoading = false
            }
    }
}
