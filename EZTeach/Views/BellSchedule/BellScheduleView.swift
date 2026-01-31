//
//  BellScheduleView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseFirestore
import Combine

struct BellScheduleView: View {
    
    let schoolId: String
    let userRole: String
    
    @State private var schedules: [BellSchedule] = []
    @State private var activeSchedule: BellSchedule?
    @State private var currentPeriod: BellPeriod?
    @State private var isLoading = true
    @State private var showEditSchedule = false
    @State private var selectedSchedule: BellSchedule?
    
    private let db = Firestore.firestore()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Current period card
                        if let schedule = activeSchedule {
                            currentPeriodCard(schedule)
                        }
                        
                        // Today's schedule
                        if let schedule = activeSchedule {
                            todayScheduleSection(schedule)
                        }
                        
                        // All schedules
                        allSchedulesSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Bell Schedule")
        .toolbar {
            if userRole == "school" {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditSchedule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSchedule) {
            EditBellScheduleView(schoolId: schoolId, schedule: nil) {
                loadSchedules()
            }
        }
        .sheet(item: $selectedSchedule) { schedule in
            EditBellScheduleView(schoolId: schoolId, schedule: schedule) {
                loadSchedules()
            }
        }
        .onAppear(perform: loadSchedules)
        .onReceive(timer) { _ in
            updateCurrentPeriod()
        }
    }
    
    // MARK: - Current Period Card
    private func currentPeriodCard(_ schedule: BellSchedule) -> some View {
        VStack(spacing: 16) {
            if let period = currentPeriod {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Period")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(period.name)
                            .font(.title2.bold())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(period.startTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("→ \(period.endTime)")
                            .font(.headline)
                    }
                }
                
                // Progress bar
                progressBar(for: period)
                
                // Next period
                if let nextPeriod = getNextPeriod(after: period, in: schedule) {
                    HStack {
                        Text("Next: \(nextPeriod.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(nextPeriod.startTime)
                            .font(.caption.bold())
                            .foregroundColor(EZTeachColors.accent)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("School Not in Session")
                        .font(.headline)
                    Text("Classes resume tomorrow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EZTeachColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(EZTeachColors.accent.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    private func progressBar(for period: BellPeriod) -> some View {
        let progress = calculateProgress(for: period)
        
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(EZTeachColors.accentGradient)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 8)
    }
    
    // MARK: - Today's Schedule Section
    private func todayScheduleSection(_ schedule: BellSchedule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule")
                    .font(.headline)
                
                Spacer()
                
                Text(schedule.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(EZTeachColors.cardFill)
                    .cornerRadius(8)
            }
            
            ForEach(schedule.periods) { period in
                periodRow(period)
            }
        }
    }
    
    private func periodRow(_ period: BellPeriod) -> some View {
        let isCurrent = currentPeriod?.id == period.id
        
        return HStack(spacing: 16) {
            // Time column
            VStack(alignment: .trailing, spacing: 2) {
                Text(period.startTime)
                    .font(.caption.bold())
                Text(period.endTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Indicator
            Circle()
                .fill(isCurrent ? EZTeachColors.accent : Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(isCurrent ? EZTeachColors.accent : Color.clear, lineWidth: 2)
                        .scaleEffect(1.5)
                        .opacity(isCurrent ? 0.5 : 0)
                )
            
            // Period info
            VStack(alignment: .leading, spacing: 2) {
                Text(period.name)
                    .font(.subheadline.weight(isCurrent ? .bold : .medium))
                Text(period.periodType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let num = period.periodNumber {
                Text("P\(num)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(isCurrent ? EZTeachColors.accent.opacity(0.1) : EZTeachColors.secondaryBackground)
        .cornerRadius(10)
    }
    
    // MARK: - All Schedules Section
    private var allSchedulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Schedules")
                .font(.headline)
            
            ForEach(schedules) { schedule in
                Button {
                    if userRole == "school" {
                        selectedSchedule = schedule
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(schedule.name)
                                    .font(.subheadline.weight(.medium))
                                
                                if schedule.isDefault {
                                    Text("Default")
                                        .font(.caption2.bold())
                                        .foregroundColor(EZTeachColors.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(EZTeachColors.accent.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text("\(schedule.periods.count) periods")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if userRole == "school" {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helpers
    private func calculateProgress(for period: BellPeriod) -> CGFloat {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startComponents = formatter.date(from: period.startTime),
              let endComponents = formatter.date(from: period.endTime) else { return 0 }
        
        let startDate = calendar.date(bySettingHour: calendar.component(.hour, from: startComponents),
                                      minute: calendar.component(.minute, from: startComponents),
                                      second: 0, of: now)!
        let endDate = calendar.date(bySettingHour: calendar.component(.hour, from: endComponents),
                                    minute: calendar.component(.minute, from: endComponents),
                                    second: 0, of: now)!
        
        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsed = now.timeIntervalSince(startDate)
        
        return CGFloat(max(0, min(1, elapsed / totalDuration)))
    }
    
    private func getNextPeriod(after period: BellPeriod, in schedule: BellSchedule) -> BellPeriod? {
        guard let index = schedule.periods.firstIndex(where: { $0.id == period.id }),
              index + 1 < schedule.periods.count else { return nil }
        return schedule.periods[index + 1]
    }
    
    private func updateCurrentPeriod() {
        guard let schedule = activeSchedule else { return }
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: now)
        
        currentPeriod = schedule.periods.first { period in
            period.startTime <= currentTime && period.endTime > currentTime
        }
    }
    
    // MARK: - Load Data
    private func loadSchedules() {
        db.collection("bellSchedules")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                schedules = snap?.documents.compactMap { BellSchedule.fromDocument($0) } ?? []
                activeSchedule = schedules.first { $0.isDefault } ?? schedules.first
                updateCurrentPeriod()
                isLoading = false
            }
    }
}

// MARK: - Edit Bell Schedule View
struct EditBellScheduleView: View {
    
    let schoolId: String
    let schedule: BellSchedule?
    let onSave: () -> Void
    
    @State private var name = ""
    @State private var scheduleType: BellSchedule.ScheduleType = .regular
    @State private var isDefault = false
    @State private var periods: [BellPeriod] = []
    @State private var isSaving = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Schedule Info") {
                    TextField("Schedule Name", text: $name)
                    
                    Picker("Type", selection: $scheduleType) {
                        ForEach(BellSchedule.ScheduleType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Toggle("Default Schedule", isOn: $isDefault)
                }
                
                Section("Periods") {
                    ForEach(Array(periods.enumerated()), id: \.element.id) { index, period in
                        HStack {
                            TextField("Name", text: Binding(
                                get: { periods[index].name },
                                set: { periods[index] = BellPeriod(id: period.id, name: $0, periodNumber: period.periodNumber, startTime: period.startTime, endTime: period.endTime, periodType: period.periodType) }
                            ))
                            
                            TextField("Start", text: Binding(
                                get: { periods[index].startTime },
                                set: { periods[index] = BellPeriod(id: period.id, name: period.name, periodNumber: period.periodNumber, startTime: $0, endTime: period.endTime, periodType: period.periodType) }
                            ))
                            .frame(width: 60)
                            
                            TextField("End", text: Binding(
                                get: { periods[index].endTime },
                                set: { periods[index] = BellPeriod(id: period.id, name: period.name, periodNumber: period.periodNumber, startTime: period.startTime, endTime: $0, periodType: period.periodType) }
                            ))
                            .frame(width: 60)
                        }
                    }
                    .onDelete { indexSet in
                        periods.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        addPeriod()
                    } label: {
                        Label("Add Period", systemImage: "plus")
                    }
                }
                
                Section {
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            }
                            Text(isSaving ? "Saving..." : "Save Schedule")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .navigationTitle(schedule == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }
    
    private func loadExisting() {
        guard let schedule = schedule else { return }
        name = schedule.name
        scheduleType = schedule.scheduleType
        isDefault = schedule.isDefault
        periods = schedule.periods
    }
    
    private func addPeriod() {
        let newPeriod = BellPeriod(
            id: UUID().uuidString,
            name: "Period \(periods.count + 1)",
            periodNumber: periods.count + 1,
            startTime: "08:00",
            endTime: "08:50",
            periodType: .classTime
        )
        periods.append(newPeriod)
    }
    
    private func save() {
        isSaving = true
        
        let docRef = schedule != nil
            ? db.collection("bellSchedules").document(schedule!.id)
            : db.collection("bellSchedules").document()
        
        let data: [String: Any] = [
            "schoolId": schoolId,
            "name": name,
            "scheduleType": scheduleType.rawValue,
            "isDefault": isDefault,
            "periods": periods.map { $0.toDict() },
            "activeDays": [2, 3, 4, 5, 6],
            "createdAt": Timestamp()
        ]
        
        docRef.setData(data, merge: true) { error in
            isSaving = false
            if error == nil {
                onSave()
                dismiss()
            }
        }
    }
}
