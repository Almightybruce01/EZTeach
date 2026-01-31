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
        
        // Generate sample data based on selected period
        // In production, this would fetch from Firestore
        
        switch selectedPeriod {
        case 0: // Week
            weeklyData = [
                DayAttendance(dayName: "Mon", presentCount: 145, tardyCount: 8, absentCount: 12),
                DayAttendance(dayName: "Tue", presentCount: 152, tardyCount: 5, absentCount: 8),
                DayAttendance(dayName: "Wed", presentCount: 148, tardyCount: 10, absentCount: 7),
                DayAttendance(dayName: "Thu", presentCount: 155, tardyCount: 4, absentCount: 6),
                DayAttendance(dayName: "Fri", presentCount: 140, tardyCount: 12, absentCount: 13)
            ]
            
            let totalPresent = weeklyData.reduce(0) { $0 + $1.presentCount }
            let totalTardy = weeklyData.reduce(0) { $0 + $1.tardyCount }
            let totalAbsent = weeklyData.reduce(0) { $0 + $1.absentCount }
            let total = totalPresent + totalTardy + totalAbsent
            
            overallStats = AttendanceStats(
                presentCount: totalPresent,
                tardyCount: totalTardy,
                absentCount: totalAbsent,
                totalCount: total
            )
            
        case 1: // Month
            monthlyData = [
                MonthAttendance(monthName: "Week 1", attendanceRate: 94.5),
                MonthAttendance(monthName: "Week 2", attendanceRate: 92.1),
                MonthAttendance(monthName: "Week 3", attendanceRate: 95.8),
                MonthAttendance(monthName: "Week 4", attendanceRate: 93.2)
            ]
            
            _ = monthlyData.reduce(0) { $0 + $1.attendanceRate } / Double(monthlyData.count)
            overallStats = AttendanceStats(
                presentCount: 620,
                tardyCount: 35,
                absentCount: 45,
                totalCount: 700
            )
            
        default: // Year
            monthlyData = [
                MonthAttendance(monthName: "Sep", attendanceRate: 95.2),
                MonthAttendance(monthName: "Oct", attendanceRate: 93.8),
                MonthAttendance(monthName: "Nov", attendanceRate: 91.5),
                MonthAttendance(monthName: "Dec", attendanceRate: 88.2),
                MonthAttendance(monthName: "Jan", attendanceRate: 94.1)
            ]
            
            overallStats = AttendanceStats(
                presentCount: 2850,
                tardyCount: 180,
                absentCount: 270,
                totalCount: 3300
            )
        }
        
        isLoading = false
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
