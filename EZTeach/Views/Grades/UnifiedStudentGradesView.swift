//
//  UnifiedStudentGradesView.swift
//  EZTeach
//
//  Shows all grades for a student across ALL their classes
//

import SwiftUI
import FirebaseFirestore
import PDFKit

struct UnifiedStudentGradesView: View {
    let student: Student
    let schoolId: String
    
    @State private var classGrades: [ClassGradeInfo] = []
    @State private var isLoading = true
    @State private var showReportCard = false
    
    private let db = Firestore.firestore()
    
    var overallGPA: Double {
        guard !classGrades.isEmpty else { return 0 }
        let total = classGrades.reduce(0.0) { $0 + $1.gradePercent }
        return total / Double(classGrades.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Student header
                studentHeader
                
                // Overall GPA card
                overallGPACard
                
                // Classes breakdown
                if isLoading {
                    ProgressView("Loading grades...")
                        .padding(40)
                } else if classGrades.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Classes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(classGrades) { classGrade in
                            classGradeCard(classGrade)
                        }
                    }
                }
            }
            .padding()
        }
        .background(EZTeachColors.background)
        .navigationTitle("All Grades")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showReportCard = true
                } label: {
                    Image(systemName: "doc.text.fill")
                }
            }
        }
        .sheet(isPresented: $showReportCard) {
            ReportCardView(student: student, classGrades: classGrades, overallGPA: overallGPA)
        }
        .onAppear(perform: loadAllGrades)
    }
    
    private var studentHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(EZTeachColors.accentGradient)
                    .frame(width: 60, height: 60)
                
                Text(student.firstName.prefix(1) + student.lastName.prefix(1))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(student.fullName)
                    .font(.title3.bold())
                
                Text("Grade \(student.gradeLevel) • \(student.studentCode)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private var overallGPACard: some View {
        VStack(spacing: 12) {
            Text("Overall Average")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(overallGPA, specifier: "%.1f")%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(gradeColor(overallGPA))
            
            Text(letterGrade(overallGPA))
                .font(.title2.bold())
                .foregroundStyle(gradeColor(overallGPA))
            
            Text("\(classGrades.count) Classes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EZTeachColors.secondaryBackground)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Grades Yet")
                .font(.headline)
            
            Text("Grades will appear here once teachers enter them")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private func classGradeCard(_ classGrade: ClassGradeInfo) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(classGrade.className)
                        .font(.subheadline.weight(.semibold))
                    
                    Text(classGrade.teacherName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(classGrade.gradePercent, specifier: "%.1f")%")
                        .font(.headline)
                        .foregroundStyle(gradeColor(classGrade.gradePercent))
                    
                    Text(letterGrade(classGrade.gradePercent))
                        .font(.caption.bold())
                        .foregroundStyle(gradeColor(classGrade.gradePercent))
                }
            }
            .padding()
            
            if !classGrade.assignments.isEmpty {
                Divider()
                
                VStack(spacing: 8) {
                    ForEach(classGrade.assignments.prefix(3), id: \.id) { assignment in
                        HStack {
                            Text(assignment.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(assignment.earned, specifier: "%.0f")/\(assignment.possible, specifier: "%.0f")")
                                .font(.caption.monospaced())
                        }
                    }
                    
                    if classGrade.assignments.count > 3 {
                        Text("+\(classGrade.assignments.count - 3) more assignments")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }
    
    private func gradeColor(_ percent: Double) -> LinearGradient {
        let color: Color
        switch percent {
        case 90...100: color = .green
        case 80..<90: color = .blue
        case 70..<80: color = .yellow
        case 60..<70: color = .orange
        default: color = .red
        }
        return LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
    }
    
    private func letterGrade(_ percent: Double) -> String {
        switch percent {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    private func loadAllGrades() {
        isLoading = true
        
        // First, find all classes the student is enrolled in
        db.collection("class_rosters")
            .whereField("studentId", isEqualTo: student.id)
            .getDocuments { snap, _ in
                let classIds = snap?.documents.compactMap { $0["classId"] as? String } ?? []
                
                if classIds.isEmpty {
                    isLoading = false
                    return
                }
                
                loadClassDetails(classIds: classIds)
            }
    }
    
    private func loadClassDetails(classIds: [String]) {
        var loadedGrades: [ClassGradeInfo] = []
        let group = DispatchGroup()
        
        for classId in classIds {
            group.enter()
            
            // Get class info
            db.collection("classes").document(classId).getDocument { classSnap, _ in
                guard let classData = classSnap?.data() else {
                    group.leave()
                    return
                }
                
                let className = classData["name"] as? String ?? "Unknown Class"
                let teacherName = classData["teacherName"] as? String ?? ""
                
                // Get student's grades for this class
                db.collection("studentGrades")
                    .whereField("classId", isEqualTo: classId)
                    .whereField("studentId", isEqualTo: student.id)
                    .getDocuments { gradesSnap, _ in
                        
                        var assignments: [AssignmentGrade] = []
                        var totalEarned: Double = 0
                        var totalPossible: Double = 0
                        
                        for doc in gradesSnap?.documents ?? [] {
                            let data = doc.data()
                            let earned = data["pointsEarned"] as? Double ?? 0
                            let possible = data["pointsPossible"] as? Double ?? 0
                            let name = data["assignmentName"] as? String ?? "Assignment"
                            
                            assignments.append(AssignmentGrade(
                                id: doc.documentID,
                                name: name,
                                earned: earned,
                                possible: possible
                            ))
                            
                            totalEarned += earned
                            totalPossible += possible
                        }
                        
                        let percent = totalPossible > 0 ? (totalEarned / totalPossible) * 100 : 0
                        
                        loadedGrades.append(ClassGradeInfo(
                            id: classId,
                            className: className,
                            teacherName: teacherName,
                            gradePercent: percent,
                            assignments: assignments
                        ))
                        
                        group.leave()
                    }
            }
        }
        
        group.notify(queue: .main) {
            classGrades = loadedGrades.sorted { $0.className < $1.className }
            isLoading = false
        }
    }
}

struct ClassGradeInfo: Identifiable {
    let id: String
    let className: String
    let teacherName: String
    let gradePercent: Double
    let assignments: [AssignmentGrade]
}

struct AssignmentGrade: Identifiable {
    let id: String
    let name: String
    let earned: Double
    let possible: Double
}

// MARK: - Report Card View
struct ReportCardView: View {
    let student: Student
    let classGrades: [ClassGradeInfo]
    let overallGPA: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("REPORT CARD")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundColor(.secondary)
                        
                        Text(student.fullName)
                            .font(.title.bold())
                        
                        Text("Grade \(student.gradeLevel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(currentSemester())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(EZTeachColors.primaryGradient)
                    .foregroundColor(.white)
                    
                    // Grades table
                    VStack(spacing: 0) {
                        // Table header
                        HStack {
                            Text("CLASS")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("TEACHER")
                                .frame(width: 100, alignment: .leading)
                            Text("GRADE")
                                .frame(width: 60, alignment: .center)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        
                        ForEach(classGrades) { grade in
                            HStack {
                                Text(grade.className)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(grade.teacherName)
                                    .frame(width: 100, alignment: .leading)
                                    .lineLimit(1)
                                Text(letterGrade(grade.gradePercent))
                                    .font(.headline)
                                    .frame(width: 60, alignment: .center)
                            }
                            .font(.subheadline)
                            .padding()
                            
                            Divider()
                        }
                        
                        // Overall
                        HStack {
                            Text("OVERALL AVERAGE")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(overallGPA, specifier: "%.1f")%")
                                .font(.headline)
                            Text(letterGrade(overallGPA))
                                .font(.title3.bold())
                                .frame(width: 40)
                        }
                        .padding()
                        .background(EZTeachColors.cardFill)
                    }
                    .padding()
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Report Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: "Report Card for \(student.fullName)") {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func letterGrade(_ percent: Double) -> String {
        switch percent {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    private func currentSemester() -> String {
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        if month >= 8 {
            return "Fall Semester \(year)"
        } else if month >= 1 && month <= 5 {
            return "Spring Semester \(year)"
        } else {
            return "Summer \(year)"
        }
    }
}
