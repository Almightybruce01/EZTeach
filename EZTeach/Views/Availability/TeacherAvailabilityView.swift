//
//  TeacherAvailabilityView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TeacherAvailabilityView: View {
    
    let teacherId: String
    let schoolId: String
    
    @State private var selectedDate = Date()
    @State private var availability: [Date: TeacherAvailability.AvailabilityStatus] = [:]
    @State private var showAddUnavailable = false
    @State private var isLoading = true
    @State private var currentMonth = Date()
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Calendar header
                        calendarHeader
                        
                        // Calendar grid
                        calendarGrid
                        
                        // Legend
                        legendView
                        
                        // Upcoming unavailability
                        upcomingSection
                    }
                    .padding()
                }
            }
            .navigationTitle("My Availability")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddUnavailable = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddUnavailable) {
                AddUnavailabilityView(teacherId: teacherId, schoolId: schoolId) {
                    loadAvailability()
                }
            }
            .onAppear(perform: loadAvailability)
        }
    }
    
    // MARK: - Calendar Header
    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
            }
            
            Spacer()
            
            Text(monthYearString(from: currentMonth))
                .font(.title3.bold())
            
            Spacer()
            
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            let days = generateMonthDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isPast = date < calendar.startOfDay(for: Date())
        let status = availability[calendar.startOfDay(for: date)]
        
        return Button {
            if !isPast {
                selectedDate = date
                showAddUnavailable = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(backgroundColor(for: status, isToday: isToday))
                    .frame(width: 40, height: 40)
                
                if isToday {
                    Circle()
                        .stroke(EZTeachColors.accent, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundColor(textColor(for: status, isPast: isPast))
            }
        }
        .disabled(isPast)
    }
    
    private func backgroundColor(for status: TeacherAvailability.AvailabilityStatus?, isToday: Bool) -> Color {
        guard let status = status else {
            return isToday ? EZTeachColors.accent.opacity(0.1) : Color.clear
        }
        
        switch status {
        case .available:
            return EZTeachColors.success.opacity(0.2)
        case .unavailable:
            return EZTeachColors.error.opacity(0.2)
        case .partialDay:
            return EZTeachColors.warning.opacity(0.2)
        case .pendingLeave:
            return Color.yellow.opacity(0.2)
        case .approvedLeave:
            return Color.blue.opacity(0.2)
        }
    }
    
    private func textColor(for status: TeacherAvailability.AvailabilityStatus?, isPast: Bool) -> Color {
        if isPast { return .secondary }
        guard let status = status else { return .primary }
        
        switch status {
        case .available: return EZTeachColors.success
        case .unavailable: return EZTeachColors.error
        case .partialDay: return EZTeachColors.warning
        case .pendingLeave: return .yellow
        case .approvedLeave: return .blue
        }
    }
    
    // MARK: - Legend
    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: EZTeachColors.success, label: "Available")
            legendItem(color: EZTeachColors.error, label: "Unavailable")
            legendItem(color: EZTeachColors.warning, label: "Partial")
            legendItem(color: .blue, label: "Leave")
        }
        .font(.caption)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Upcoming Section
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Unavailability")
                .font(.headline)
            
            let upcomingDates = availability.filter { $0.key >= Date() && $0.value != .available }
                .sorted { $0.key < $1.key }
                .prefix(5)
            
            if upcomingDates.isEmpty {
                Text("No upcoming unavailability scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(12)
            } else {
                ForEach(Array(upcomingDates), id: \.key) { date, status in
                    upcomingRow(date: date, status: status)
                }
            }
        }
    }
    
    private func upcomingRow(date: Date, status: TeacherAvailability.AvailabilityStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline.weight(.medium))
                Text(status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(statusColor(status))
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(10)
    }
    
    private func statusColor(_ status: TeacherAvailability.AvailabilityStatus) -> Color {
        switch status {
        case .available: return EZTeachColors.success
        case .unavailable: return EZTeachColors.error
        case .partialDay: return EZTeachColors.warning
        case .pendingLeave: return .yellow
        case .approvedLeave: return .blue
        }
    }
    
    // MARK: - Helpers
    private func generateMonthDays() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstDay = interval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        var current = firstDay
        while current < interval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return days
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // MARK: - Load Data
    private func loadAvailability() {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        db.collection("teacherAvailability")
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfMonth))
            .getDocuments { snap, _ in
                var newAvailability: [Date: TeacherAvailability.AvailabilityStatus] = [:]
                
                snap?.documents.forEach { doc in
                    if let avail = TeacherAvailability.fromDocument(doc) {
                        let day = calendar.startOfDay(for: avail.date)
                        newAvailability[day] = avail.status
                    }
                }
                
                availability = newAvailability
                isLoading = false
            }
    }
}

// MARK: - Add Unavailability View
struct AddUnavailabilityView: View {
    
    let teacherId: String
    let schoolId: String
    let onSave: () -> Void
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var status: TeacherAvailability.AvailabilityStatus = .unavailable
    @State private var reason = ""
    @State private var isSubmitting = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach([TeacherAvailability.AvailabilityStatus.unavailable, .partialDay, .pendingLeave], id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Reason") {
                    TextField("Enter reason (optional)", text: $reason)
                }
                
                Section {
                    Button {
                        saveAvailability()
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            }
                            Text(isSubmitting ? "Saving..." : "Save")
                            Spacer()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("Mark Unavailable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveAvailability() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSubmitting = true
        
        let batch = db.batch()
        var currentDate = startDate
        
        while currentDate <= endDate {
            let ref = db.collection("teacherAvailability").document()
            batch.setData([
                "teacherId": teacherId,
                "teacherUserId": uid,
                "schoolId": schoolId,
                "date": Timestamp(date: currentDate),
                "status": status.rawValue,
                "reason": reason,
                "createdAt": Timestamp()
            ], forDocument: ref)
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        batch.commit { error in
            isSubmitting = false
            if error == nil {
                onSave()
                dismiss()
            }
        }
    }
}
