//
//  AnalyticsDashboardView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseFirestore

struct AnalyticsDashboardView: View {
    
    let schoolId: String
    
    @State private var selectedPeriod: SchoolAnalytics.AnalyticsPeriod = .week
    @State private var isLoading = true
    
    // Stats
    @State private var totalTeachers = 0
    @State private var totalStudents = 0
    @State private var totalSubs = 0
    @State private var attendanceRate = 0.0
    @State private var subRequestsFilled = 0
    @State private var subRequestsTotal = 0
    @State private var announcementsCount = 0
    @State private var eventsCount = 0
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Period selector
                    periodSelector
                    
                    // Overview cards
                    overviewSection
                    
                    // Attendance chart
                    attendanceSection
                    
                    // Sub coverage
                    subCoverageSection
                    
                    // Engagement
                    engagementSection
                }
                .padding()
            }
        }
        .navigationTitle("Analytics")
        .onAppear(perform: loadAnalytics)
        .onChange(of: selectedPeriod) { _, _ in loadAnalytics() }
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([SchoolAnalytics.AnalyticsPeriod.today, .week, .month, .quarter], id: \.self) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedPeriod == period ? EZTeachColors.accent : EZTeachColors.cardFill)
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(
                title: "Teachers",
                value: "\(totalTeachers)",
                icon: "person.fill",
                color: EZTeachColors.accent
            )
            
            statCard(
                title: "Students",
                value: "\(totalStudents)",
                icon: "graduationcap.fill",
                color: EZTeachColors.success
            )
            
            statCard(
                title: "Substitutes",
                value: "\(totalSubs)",
                icon: "person.badge.clock.fill",
                color: EZTeachColors.warning
            )
            
            statCard(
                title: "Attendance",
                value: String(format: "%.1f%%", attendanceRate),
                icon: "checkmark.circle.fill",
                color: attendanceRate >= 90 ? EZTeachColors.success : EZTeachColors.warning
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Attendance Section
    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Attendance Trend")
                    .font(.headline)
                Spacer()
                Text(selectedPeriod.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Simple bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 4) {
                        let rate = Double.random(in: 85...98) // Sample data
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rate >= 90 ? EZTeachColors.success : EZTeachColors.warning)
                            .frame(width: 30, height: CGFloat(rate))
                        
                        Text(dayLabel(for: i))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private func dayLabel(for offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -6 + offset, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    // MARK: - Sub Coverage Section
    private var subCoverageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sub Coverage")
                .font(.headline)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(subRequestsFilled)/\(subRequestsTotal)")
                        .font(.title2.bold())
                    Text("Requests Filled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: subRequestsTotal > 0 ? CGFloat(subRequestsFilled) / CGFloat(subRequestsTotal) : 0)
                        .stroke(EZTeachColors.success, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text(subRequestsTotal > 0 ? "\(Int(Double(subRequestsFilled) / Double(subRequestsTotal) * 100))%" : "0%")
                        .font(.caption.bold())
                }
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Engagement Section
    private var engagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Engagement")
                .font(.headline)
            
            HStack(spacing: 16) {
                engagementItem(
                    icon: "megaphone.fill",
                    value: "\(announcementsCount)",
                    label: "Announcements",
                    color: EZTeachColors.accent
                )
                
                engagementItem(
                    icon: "calendar",
                    value: "\(eventsCount)",
                    label: "Events",
                    color: EZTeachColors.warning
                )
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private func engagementItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Load Data
    private func loadAnalytics() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // Load teachers count
        group.enter()
        db.collection("teachers")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                totalTeachers = snap?.documents.count ?? 0
                group.leave()
            }
        
        // Load students count
        group.enter()
        db.collection("students")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                totalStudents = snap?.documents.count ?? 0
                group.leave()
            }
        
        // Load subs count
        group.enter()
        db.collection("subs")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                totalSubs = snap?.documents.count ?? 0
                group.leave()
            }
        
        // Load sub requests
        group.enter()
        db.collection("subRequests")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                let requests = snap?.documents ?? []
                subRequestsTotal = requests.count
                subRequestsFilled = requests.filter { doc in
                    let status = doc["status"] as? String ?? ""
                    return status == "assigned" || status == "completed"
                }.count
                group.leave()
            }
        
        // Load announcements count
        group.enter()
        db.collection("announcements")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                announcementsCount = snap?.documents.count ?? 0
                group.leave()
            }
        
        // Load events count
        group.enter()
        db.collection("events")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                eventsCount = snap?.documents.count ?? 0
                group.leave()
            }
        
        group.notify(queue: .main) {
            // Calculate attendance rate (sample for now)
            attendanceRate = Double.random(in: 88...96)
            isLoading = false
        }
    }
}
