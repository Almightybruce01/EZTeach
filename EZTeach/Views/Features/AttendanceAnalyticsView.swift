//
//  AttendanceAnalyticsView.swift
//  EZTeach
//
//  Attendance analytics and charts
//

import SwiftUI
import Charts
import FirebaseFirestore

struct AttendanceAnalyticsView: View {
    let schoolId: String
    
    @State private var weeklyData: [DayAttendance] = []
    @State private var monthlyData: [MonthAttendance] = []
    @State private var overallStats: AttendanceStats = AttendanceStats()
    @State private var isLoading = true
    @State private var selectedPeriod = 0
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period picker
                    Picker("Period", selection: $selectedPeriod) {
                        Text("This Week").tag(0)
                        Text("This Month").tag(1)
                        Text("This Year").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Stats cards
                    statsSection
                    
                    // Chart
                    if !isLoading {
                        chartSection
                    }
                    
                    // Breakdown
                    breakdownSection
                }
                .padding(.vertical)
            }
            .background(EZTeachColors.background)
            .navigationTitle("Attendance Analytics")
            .onAppear(perform: loadData)
            .onChange(of: selectedPeriod) { _, _ in loadData() }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                value: String(format: "%.1f%%", overallStats.attendanceRate),
                label: "Attendance Rate",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            statCard(
                value: String(format: "%.1f%%", overallStats.tardyRate),
                label: "Tardy Rate",
                icon: "clock.fill",
                color: .orange
            )
            
            statCard(
                value: String(format: "%.1f%%", overallStats.absentRate),
                label: "Absent Rate",
                icon: "xmark.circle.fill",
                color: .red
            )
        }
        .padding(.horizontal)
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }
    
    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attendance Trend")
                .font(.headline)
                .padding(.horizontal)
            
            if selectedPeriod == 0 {
                // Weekly chart
                Chart(weeklyData) { day in
                    BarMark(
                        x: .value("Day", day.dayName),
                        y: .value("Present", day.presentCount)
                    )
                    .foregroundStyle(Color.green.gradient)
                    
                    BarMark(
                        x: .value("Day", day.dayName),
                        y: .value("Absent", day.absentCount)
                    )
                    .foregroundStyle(Color.red.gradient)
                }
                .frame(height: 200)
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                // Monthly chart
                Chart(monthlyData) { month in
                    LineMark(
                        x: .value("Month", month.monthName),
                        y: .value("Rate", month.attendanceRate)
                    )
                    .foregroundStyle(EZTeachColors.accent.gradient)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Month", month.monthName),
                        y: .value("Rate", month.attendanceRate)
                    )
                    .foregroundStyle(EZTeachColors.accent.opacity(0.2).gradient)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 200)
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            
            // Legend
            HStack(spacing: 20) {
                legendItem(color: .green, label: "Present")
                legendItem(color: .orange, label: "Tardy")
                legendItem(color: .red, label: "Absent")
            }
            .font(.caption)
            .padding(.horizontal)
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
            
            HStack(spacing: 16) {
                breakdownBar(label: "Present", value: overallStats.presentCount, total: overallStats.totalCount, color: .green)
                breakdownBar(label: "Tardy", value: overallStats.tardyCount, total: overallStats.totalCount, color: .orange)
                breakdownBar(label: "Absent", value: overallStats.absentCount, total: overallStats.totalCount, color: .red)
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func breakdownBar(label: String, value: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Text("\(value)")
                .font(.title2.bold())
            
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(height: total > 0 ? geo.size.height * CGFloat(value) / CGFloat(total) : 0)
                }
            }
            .frame(width: 30, height: 80)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func loadData() {
        isLoading = true
        let cal = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case 0: // This Week
            loadWeeklyData(calendar: cal, now: now)
        case 1: // This Month
            loadMonthlyData(calendar: cal, now: now)
        default: // This Year
            loadYearlyData(calendar: cal, now: now)
        }
    }
    
    private func loadWeeklyData(calendar: Calendar, now: Date) {
        let weekday = calendar.component(.weekday, from: now)
        let daysBack = (weekday == 1 ? 6 : weekday - 2)
        guard let weekStart = calendar.date(byAdding: .day, value: -daysBack, to: now) else { return }
        let startOfWeek = calendar.startOfDay(for: weekStart)
        
        db.collection("attendance")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek))
            .whereField("date", isLessThan: Timestamp(date: calendar.date(byAdding: .day, value: 7, to: startOfWeek)!))
            .getDocuments { snap, _ in
                var dayBuckets: [String: (present: Int, tardy: Int, absent: Int)] = [:]
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEE"
                
                snap?.documents.forEach { doc in
                    let data = doc.data()
                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                          let status = data["status"] as? String else { return }
                    let dayKey = dayFormatter.string(from: date)
                    var bucket = dayBuckets[dayKey] ?? (0, 0, 0)
                    switch status {
                    case "present": bucket.present += 1
                    case "tardy": bucket.tardy += 1
                    default: bucket.absent += 1
                    }
                    dayBuckets[dayKey] = bucket
                }
                
                let order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                weeklyData = order.compactMap { day in
                    guard let b = dayBuckets[day] else { return DayAttendance(dayName: day, presentCount: 0, tardyCount: 0, absentCount: 0) }
                    return DayAttendance(dayName: day, presentCount: b.present, tardyCount: b.tardy, absentCount: b.absent)
                }
                
                let totalPresent = weeklyData.reduce(0) { $0 + $1.presentCount }
                let totalTardy = weeklyData.reduce(0) { $0 + $1.tardyCount }
                let totalAbsent = weeklyData.reduce(0) { $0 + $1.absentCount }
                let total = totalPresent + totalTardy + totalAbsent
                overallStats = AttendanceStats(presentCount: totalPresent, tardyCount: totalTardy, absentCount: totalAbsent, totalCount: total)
                isLoading = false
            }
    }
    
    private func loadMonthlyData(calendar: Calendar, now: Date) {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return }
        
        db.collection("attendance")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: monthStart))
            .whereField("date", isLessThan: Timestamp(date: nextMonth))
            .getDocuments { snap, _ in
                var weekBuckets: [String: (total: Int, present: Int)] = [:]
                let weekFormatter = DateFormatter()
                weekFormatter.dateFormat = "'Week' w"
                
                snap?.documents.forEach { doc in
                    let data = doc.data()
                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                          let status = data["status"] as? String else { return }
                    let weekKey = weekFormatter.string(from: date)
                    var bucket = weekBuckets[weekKey] ?? (0, 0)
                    bucket.total += 1
                    if status == "present" || status == "tardy" { bucket.present += 1 }
                    weekBuckets[weekKey] = bucket
                }
                
                let sorted = weekBuckets.sorted { ($0.key) < ($1.key) }
                monthlyData = sorted.map { MonthAttendance(monthName: $0.key, attendanceRate: $0.value.total > 0 ? Double($0.value.present) / Double($0.value.total) * 100 : 0) }
                
                let totalPresent = weekBuckets.values.reduce(0) { $0 + $1.present }
                let totalCount = weekBuckets.values.reduce(0) { $0 + $1.total }
                let tardyCount = 0
                let absentCount = max(0, totalCount - totalPresent - tardyCount)
                overallStats = AttendanceStats(presentCount: totalPresent, tardyCount: tardyCount, absentCount: absentCount, totalCount: totalCount)
                isLoading = false
            }
    }
    
    private func loadYearlyData(calendar: Calendar, now: Date) {
        guard let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)),
              let nextYear = calendar.date(byAdding: .year, value: 1, to: yearStart) else { return }
        
        db.collection("attendance")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: yearStart))
            .whereField("date", isLessThan: Timestamp(date: nextYear))
            .getDocuments { snap, _ in
                var monthBuckets: [String: (total: Int, present: Int)] = [:]
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMM"
                
                snap?.documents.forEach { doc in
                    let data = doc.data()
                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                          let status = data["status"] as? String else { return }
                    let monthKey = monthFormatter.string(from: date)
                    var bucket = monthBuckets[monthKey] ?? (0, 0)
                    bucket.total += 1
                    if status == "present" || status == "tardy" { bucket.present += 1 }
                    monthBuckets[monthKey] = bucket
                }
                
                let order = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                monthlyData = order.compactMap { month in
                    guard let b = monthBuckets[month] else { return nil }
                    return MonthAttendance(monthName: month, attendanceRate: b.total > 0 ? Double(b.present) / Double(b.total) * 100 : 0)
                }
                
                let totalPresent = monthBuckets.values.reduce(0) { $0 + $1.present }
                let totalCount = monthBuckets.values.reduce(0) { $0 + $1.total }
                overallStats = AttendanceStats(presentCount: totalPresent, tardyCount: 0, absentCount: max(0, totalCount - totalPresent), totalCount: totalCount)
                isLoading = false
            }
    }
}

struct DayAttendance: Identifiable {
    let id = UUID()
    let dayName: String
    let presentCount: Int
    let tardyCount: Int
    let absentCount: Int
}

struct MonthAttendance: Identifiable {
    let id = UUID()
    let monthName: String
    let attendanceRate: Double
}

struct AttendanceStats {
    var presentCount: Int = 0
    var tardyCount: Int = 0
    var absentCount: Int = 0
    var totalCount: Int = 0
    
    var attendanceRate: Double {
        totalCount > 0 ? Double(presentCount) / Double(totalCount) * 100 : 0
    }
    
    var tardyRate: Double {
        totalCount > 0 ? Double(tardyCount) / Double(totalCount) * 100 : 0
    }
    
    var absentRate: Double {
        totalCount > 0 ? Double(absentCount) / Double(totalCount) * 100 : 0
    }
}
