//
//  ActiveTimeView.swift
//  EZTeach
//
//  Dashboard for viewing active time analytics
//  Visible to: Schools, Teachers, Parents, Districts, Librarians, Subs
//  NOT visible to: Students
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ActiveTimeView: View {
    let schoolId: String
    let userRole: String
    var specificStudentId: String? = nil  // For parents viewing their child
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedStudent: Student? = nil
    @State private var students: [Student] = []
    @State private var summaries: [DailyActivitySummary] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    private let db = Firestore.firestore()
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"
        
        var startDate: Date {
            let calendar = Calendar.current
            switch self {
            case .today:
                return calendar.startOfDay(for: Date())
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            case .allTime:
                return calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Time Range Picker
                timeRangePicker
                
                // If specific student (parent view) or selected student
                if let student = selectedStudent ?? getSpecificStudent() {
                    studentDetailView(student)
                } else {
                    // School overview for admins/teachers
                    schoolOverviewSection
                    
                    // Student list
                    studentListSection
                }
            }
            .padding()
        }
        .background(EZTeachColors.backgroundColor)
        .navigationTitle("Active Time")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadData() }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 40))
                    .foregroundColor(EZTeachColors.teal)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Time Analytics")
                        .font(.title2.bold())
                        .foregroundColor(EZTeachColors.textPrimary)
                    Text("Track actual engagement, not just screen time")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                }
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [EZTeachColors.teal.opacity(0.2), EZTeachColors.softBlue.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
    
    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.rawValue) { range in
                Button {
                    selectedTimeRange = range
                    loadData()
                } label: {
                    Text(range.rawValue)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTimeRange == range ? EZTeachColors.teal : Color.gray.opacity(0.2))
                        .foregroundColor(selectedTimeRange == range ? .white : EZTeachColors.textPrimary)
                        .cornerRadius(20)
                }
            }
        }
    }
    
    // MARK: - School Overview
    private var schoolOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("School Overview")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            // Aggregate stats
            let totalActive = summaries.reduce(0) { $0 + $1.totalActiveMinutes }
            let totalScreen = summaries.reduce(0) { $0 + $1.totalScreenMinutes }
            let totalInteractions = summaries.reduce(0) { $0 + $1.totalInteractions }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Active Time",
                    value: formatMinutes(totalActive),
                    subtitle: "Engaged learning",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Screen Time",
                    value: formatMinutes(totalScreen),
                    subtitle: "Total time",
                    icon: "display",
                    color: .blue
                )
                
                StatCard(
                    title: "Interactions",
                    value: "\(totalInteractions)",
                    subtitle: "Taps & answers",
                    icon: "hand.tap.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Engagement",
                    value: totalScreen > 0 ? "\(Int((Double(totalActive) / Double(totalScreen)) * 100))%" : "0%",
                    subtitle: "Active/Screen ratio",
                    icon: "chart.bar.fill",
                    color: .green
                )
            }
            
            // Activity breakdown
            activityBreakdown
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Activity Breakdown
    private var activityBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Breakdown")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(EZTeachColors.textPrimary)
            
            let gameMin = summaries.reduce(0) { $0 + $1.gameMinutes }
            let readMin = summaries.reduce(0) { $0 + $1.readingMinutes }
            let studyMin = summaries.reduce(0) { $0 + $1.studyingMinutes }
            let electiveMin = summaries.reduce(0) { $0 + $1.electiveMinutes }
            let homeworkMin = summaries.reduce(0) { $0 + $1.homeworkMinutes }
            
            ActivityBar(label: "Games", minutes: gameMin, color: .teal, icon: "gamecontroller.fill")
            ActivityBar(label: "Reading", minutes: readMin, color: .purple, icon: "book.fill")
            ActivityBar(label: "Studying", minutes: studyMin, color: .blue, icon: "brain.head.profile")
            ActivityBar(label: "Electives", minutes: electiveMin, color: .orange, icon: "paintpalette.fill")
            ActivityBar(label: "Homework", minutes: homeworkMin, color: .green, icon: "doc.text.fill")
        }
    }
    
    // MARK: - Student List
    private var studentListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Students")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search students...", text: $searchText)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                let filtered = students.filter {
                    searchText.isEmpty ||
                    $0.firstName.localizedCaseInsensitiveContains(searchText) ||
                    $0.lastName.localizedCaseInsensitiveContains(searchText)
                }
                
                ForEach(filtered) { student in
                    StudentActivityRow(student: student, summaries: getSummariesForStudent(student.id)) {
                        selectedStudent = student
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Student Detail View
    private func studentDetailView(_ student: Student) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back button (not for parent view)
            if specificStudentId == nil {
                Button {
                    selectedStudent = nil
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to All Students")
                    }
                    .foregroundColor(EZTeachColors.teal)
                }
            }
            
            // Student header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(EZTeachColors.softBlue)
                        .frame(width: 60, height: 60)
                    Text(student.firstName.prefix(1).uppercased())
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(student.firstName) \(student.lastName)")
                        .font(.title2.bold())
                        .foregroundColor(EZTeachColors.textPrimary)
                    Text("Grade \(student.gradeLevel)")
                        .font(.subheadline)
                        .foregroundColor(EZTeachColors.textSecondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            
            // Student stats
            let studentSummaries = getSummariesForStudent(student.id)
            let totalActive = studentSummaries.reduce(0) { $0 + $1.totalActiveMinutes }
            let totalScreen = studentSummaries.reduce(0) { $0 + $1.totalScreenMinutes }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Active Time",
                    value: formatMinutes(totalActive),
                    subtitle: "Engaged learning",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Screen Time",
                    value: formatMinutes(totalScreen),
                    subtitle: "Total time",
                    icon: "display",
                    color: .blue
                )
            }
            
            // Daily breakdown chart
            dailyBreakdownChart(studentSummaries)
            
            // Activity breakdown for this student
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Breakdown")
                    .font(.headline)
                    .foregroundColor(EZTeachColors.textPrimary)
                
                let gameMin = studentSummaries.reduce(0) { $0 + $1.gameMinutes }
                let readMin = studentSummaries.reduce(0) { $0 + $1.readingMinutes }
                let studyMin = studentSummaries.reduce(0) { $0 + $1.studyingMinutes }
                let electiveMin = studentSummaries.reduce(0) { $0 + $1.electiveMinutes }
                let homeworkMin = studentSummaries.reduce(0) { $0 + $1.homeworkMinutes }
                
                ActivityBar(label: "Games", minutes: gameMin, color: .teal, icon: "gamecontroller.fill")
                ActivityBar(label: "Reading", minutes: readMin, color: .purple, icon: "book.fill")
                ActivityBar(label: "Studying", minutes: studyMin, color: .blue, icon: "brain.head.profile")
                ActivityBar(label: "Electives", minutes: electiveMin, color: .orange, icon: "paintpalette.fill")
                ActivityBar(label: "Homework", minutes: homeworkMin, color: .green, icon: "doc.text.fill")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
    
    // MARK: - Daily Breakdown Chart
    private func dailyBreakdownChart(_ studentSummaries: [DailyActivitySummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Activity")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            let sortedSummaries = studentSummaries.sorted { $0.date < $1.date }.suffix(7)
            let maxMinutes = sortedSummaries.map { $0.totalActiveMinutes }.max() ?? 1
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(sortedSummaries), id: \.id) { summary in
                    VStack(spacing: 4) {
                        Text("\(summary.totalActiveMinutes)m")
                            .font(.caption2)
                            .foregroundColor(EZTeachColors.textSecondary)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [EZTeachColors.teal, EZTeachColors.softBlue],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: CGFloat(summary.totalActiveMinutes) / CGFloat(maxMinutes) * 100)
                        
                        Text(formatDayName(summary.date))
                            .font(.caption2)
                            .foregroundColor(EZTeachColors.textSecondary)
                    }
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Helpers
    private func loadData() {
        isLoading = true
        
        // Load students
        db.collection("students")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments(source: .default) { snap, _ in
                self.students = snap?.documents.compactMap { Student.fromDocument($0) } ?? []
            }
        
        // Load summaries
        ActiveTimeService.shared.getSchoolActivitySummary(
            schoolId: schoolId,
            startDate: selectedTimeRange.startDate,
            endDate: Date()
        ) { results in
            self.summaries = results
            self.isLoading = false
        }
    }
    
    private func getSummariesForStudent(_ studentId: String) -> [DailyActivitySummary] {
        summaries.filter { $0.userId == studentId }
    }
    
    private func getSpecificStudent() -> Student? {
        guard let sid = specificStudentId else { return nil }
        return students.first { $0.id == sid }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title.bold())
                .foregroundColor(EZTeachColors.textPrimary)
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(EZTeachColors.textPrimary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(EZTeachColors.textSecondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActivityBar: View {
    let label: String
    let minutes: Int
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textPrimary)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: min(CGFloat(minutes) / 60.0 * geo.size.width, geo.size.width))
                }
            }
            .frame(height: 8)
            
            Text("\(minutes)m")
                .font(.caption.weight(.medium))
                .foregroundColor(EZTeachColors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct StudentActivityRow: View {
    let student: Student
    let summaries: [DailyActivitySummary]
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(EZTeachColors.softBlue.opacity(0.3))
                        .frame(width: 44, height: 44)
                    Text(student.firstName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(EZTeachColors.softBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(student.firstName) \(student.lastName)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(EZTeachColors.textPrimary)
                    Text("Grade \(student.gradeLevel)")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                }
                
                Spacer()
                
                let totalActive = summaries.reduce(0) { $0 + $1.totalActiveMinutes }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalActive)m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(EZTeachColors.teal)
                    Text("active")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}
