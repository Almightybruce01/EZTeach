//
//  AttendanceView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AttendanceView: View {
    
    let classModel: SchoolClass
    
    @State private var selectedDate = Date()
    @State private var students: [Student] = []
    @State private var attendanceRecords: [String: AttendanceRecord.AttendanceStatus] = [:]
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSummary = false
    
    private let db = Firestore.firestore()
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Date picker header
                dateHeader
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if students.isEmpty {
                    emptyState
                } else {
                    // Student list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(students) { student in
                                studentAttendanceRow(student)
                            }
                        }
                        .padding()
                    }
                    
                    // Summary bar
                    summaryBar
                }
            }
        }
        .navigationTitle("Attendance")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSummary = true
                } label: {
                    Image(systemName: "chart.bar.fill")
                }
            }
        }
        .sheet(isPresented: $showSummary) {
            AttendanceSummaryView(classModel: classModel)
        }
        .onAppear(perform: loadData)
        .onChange(of: selectedDate) { _, _ in
            loadAttendance()
        }
    }
    
    // MARK: - Date Header
    private var dateHeader: some View {
        HStack {
            Button {
                selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: selectedDate))
                    .font(.headline)
                Text(dateFormatter.string(from: selectedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                if selectedDate < Date() {
                    selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
            }
            .disabled(calendar.isDateInToday(selectedDate))
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
    }
    
    // MARK: - Student Row
    private func studentAttendanceRow(_ student: Student) -> some View {
        HStack(spacing: 16) {
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
                    Text(student.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // Status buttons
            HStack(spacing: 8) {
                attendanceButton(.present, for: student)
                attendanceButton(.absent, for: student)
                attendanceButton(.tardy, for: student)
            }
        }
        .padding(12)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func attendanceButton(_ status: AttendanceRecord.AttendanceStatus, for student: Student) -> some View {
        let isSelected = attendanceRecords[student.id] == status
        
        return Button {
            setAttendance(status, for: student)
        } label: {
            Image(systemName: status.iconName)
                .font(.title3)
                .foregroundColor(isSelected ? .white : statusColor(status))
                .frame(width: 40, height: 40)
                .background(isSelected ? statusColor(status) : statusColor(status).opacity(0.1))
                .cornerRadius(10)
        }
    }
    
    private func statusColor(_ status: AttendanceRecord.AttendanceStatus) -> Color {
        switch status {
        case .present: return EZTeachColors.success
        case .absent: return EZTeachColors.error
        case .tardy: return EZTeachColors.warning
        case .excused: return .blue
        case .earlyDismissal: return .purple
        }
    }
    
    // MARK: - Summary Bar
    private var summaryBar: some View {
        let present = attendanceRecords.values.filter { $0 == .present }.count
        let absent = attendanceRecords.values.filter { $0 == .absent }.count
        let tardy = attendanceRecords.values.filter { $0 == .tardy }.count
        let unmarked = students.count - attendanceRecords.count
        
        return VStack(spacing: 12) {
            HStack(spacing: 24) {
                summaryItem(count: present, label: "Present", color: EZTeachColors.success)
                summaryItem(count: absent, label: "Absent", color: EZTeachColors.error)
                summaryItem(count: tardy, label: "Tardy", color: EZTeachColors.warning)
                if unmarked > 0 {
                    summaryItem(count: unmarked, label: "Unmarked", color: .gray)
                }
            }
            
            Button {
                saveAttendance()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSaving ? "Saving..." : "Save Attendance")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(attendanceRecords.count == students.count ? EZTeachColors.accentGradient : LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isSaving || attendanceRecords.count != students.count)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
    }
    
    private func summaryItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Students")
                .font(.title2.bold())
            
            Text("Add students to this class to take attendance.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Formatters
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f
    }
    
    // MARK: - Data Methods
    private func loadData() {
        loadStudents()
    }
    
    private func loadStudents() {
        db.collection("class_rosters")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in
                let studentIds = snap?.documents.compactMap { $0["studentId"] as? String } ?? []
                
                guard !studentIds.isEmpty else {
                    isLoading = false
                    return
                }
                
                db.collection("students")
                    .whereField(FieldPath.documentID(), in: Array(studentIds.prefix(10)))
                    .getDocuments { studentSnap, _ in
                        students = (studentSnap?.documents.compactMap { doc in
                            Student.fromDocument(doc)
                        } ?? []).sorted { $0.name < $1.name }
                        
                        loadAttendance()
                    }
            }
    }
    
    private func loadAttendance() {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        db.collection("attendance")
            .whereField("classId", isEqualTo: classModel.id)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snap, _ in
                var records: [String: AttendanceRecord.AttendanceStatus] = [:]
                
                snap?.documents.forEach { doc in
                    if let record = AttendanceRecord.fromDocument(doc) {
                        records[record.studentId] = record.status
                    }
                }
                
                attendanceRecords = records
                isLoading = false
            }
    }
    
    private func setAttendance(_ status: AttendanceRecord.AttendanceStatus, for student: Student) {
        attendanceRecords[student.id] = status
    }
    
    private func saveAttendance() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        
        let batch = db.batch()
        let dateStart = calendar.startOfDay(for: selectedDate)
        
        for student in students {
            guard let status = attendanceRecords[student.id] else { continue }
            
            // Create or update attendance record
            let ref = db.collection("attendance").document("\(classModel.id)_\(student.id)_\(Int(dateStart.timeIntervalSince1970))")
            
            batch.setData([
                "schoolId": classModel.schoolId,
                "classId": classModel.id,
                "studentId": student.id,
                "studentName": student.name,
                "date": Timestamp(date: dateStart),
                "status": status.rawValue,
                "markedByUserId": uid,
                "markedByRole": "teacher",
                "createdAt": Timestamp(),
                "updatedAt": Timestamp()
            ], forDocument: ref, merge: true)
        }
        
        batch.commit { error in
            isSaving = false
            if error == nil {
                // Success feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Attendance Summary View
struct AttendanceSummaryView: View {
    
    let classModel: SchoolClass
    
    @State private var summaries: [DailyAttendanceSummary] = []
    @State private var isLoading = true
    @State private var selectedPeriod = "week"
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Period selector
                            Picker("Period", selection: $selectedPeriod) {
                                Text("Week").tag("week")
                                Text("Month").tag("month")
                                Text("Year").tag("year")
                            }
                            .pickerStyle(.segmented)
                            
                            // Overall rate card
                            overallRateCard
                            
                            // Daily breakdown
                            dailyBreakdownSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Attendance Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: loadSummary)
            .onChange(of: selectedPeriod) { _, _ in loadSummary() }
        }
    }
    
    private var overallRateCard: some View {
        let totalPresent = summaries.reduce(0) { $0 + $1.presentCount }
        let totalStudents = summaries.reduce(0) { $0 + $1.totalStudents }
        let rate = totalStudents > 0 ? Double(totalPresent) / Double(totalStudents) * 100 : 0
        
        return VStack(spacing: 16) {
            Text("Average Attendance Rate")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.1f%%", rate))
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(rate >= 90 ? EZTeachColors.success : rate >= 80 ? EZTeachColors.warning : EZTeachColors.error)
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(summaries.count)")
                        .font(.title2.bold())
                    Text("Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(totalPresent)")
                        .font(.title2.bold())
                        .foregroundColor(EZTeachColors.success)
                    Text("Present")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(summaries.reduce(0) { $0 + $1.absentCount })")
                        .font(.title2.bold())
                        .foregroundColor(EZTeachColors.error)
                    Text("Absent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Breakdown")
                .font(.headline)
            
            ForEach(summaries) { summary in
                HStack {
                    Text(dayFormatter.string(from: summary.date))
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", summary.attendanceRate))
                        .font(.subheadline.bold())
                        .foregroundColor(summary.attendanceRate >= 90 ? EZTeachColors.success : summary.attendanceRate >= 80 ? EZTeachColors.warning : EZTeachColors.error)
                    
                    // Mini bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(summary.attendanceRate >= 90 ? EZTeachColors.success : summary.attendanceRate >= 80 ? EZTeachColors.warning : EZTeachColors.error)
                                .frame(width: geo.size.width * CGFloat(summary.attendanceRate / 100))
                        }
                    }
                    .frame(width: 60, height: 8)
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(10)
            }
        }
    }
    
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }
    
    private func loadSummary() {
        // Implementation would aggregate attendance data
        isLoading = false
        // For demo, create sample data
        summaries = (0..<7).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            return DailyAttendanceSummary(
                id: UUID().uuidString,
                date: date,
                totalStudents: 25,
                presentCount: Int.random(in: 20...25),
                absentCount: Int.random(in: 0...3),
                tardyCount: Int.random(in: 0...2),
                excusedCount: Int.random(in: 0...1)
            )
        }.reversed()
    }
}
