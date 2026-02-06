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
    
    /// School and district only can edit
    private var canEdit: Bool { userRole == "school" || userRole == "district" }
    
    @State private var schedules: [BellSchedule] = []
    @State private var activeSchedule: BellSchedule?
    @State private var currentPeriod: BellPeriod?
    @State private var isLoading = true
    @State private var showEditSchedule = false
    @State private var selectedSchedule: BellSchedule?
    
    private let db = Firestore.firestore()
    @State private var timerCancellable: AnyCancellable?
    
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
            if canEdit {
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
        .onAppear {
            loadSchedules()
            timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
                .autoconnect()
                .sink { _ in updateCurrentPeriod() }
        }
        .onDisappear {
            timerCancellable?.cancel()
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
    
    // MARK: - Today's Schedule Section (Time-Slot Grid)
    private func todayScheduleSection(_ schedule: BellSchedule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule (\(schedule.slotSize)-min slots)")
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
            
            timeSlotGrid(schedule)
        }
    }
    
    private func timeSlotGrid(_ schedule: BellSchedule) -> some View {
        let slots = timeSlots(from: schedule.effectiveStart, to: schedule.effectiveEnd, stepMinutes: schedule.slotSize)
        let periodForSlot: (String) -> BellPeriod? = { time in
            schedule.periods.first { period in
                period.startTime <= time && period.endTime > time
            }
        }
        
        return VStack(spacing: 0) {
            ForEach(slots, id: \.self) { slotTime in
                let period = periodForSlot(slotTime)
                let isSlotStart = schedule.periods.contains { $0.startTime == slotTime }
                
                HStack(alignment: .top, spacing: 12) {
                    Text(slotTime)
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    if let p = period {
                        VStack(alignment: .leading, spacing: 2) {
                            if isSlotStart {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(periodColor(p.periodType))
                                        .frame(width: 8, height: 8)
                                    Text(p.name + (p.gradeLabel.isEmpty ? "" : " (\(p.gradeLabel))"))
                                        .font(.subheadline.weight(.medium))
                                    Text(p.periodType.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(periodColor(p.periodType).opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: isSlotStart ? 44 : 20)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func periodColor(_ type: BellPeriod.PeriodType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .intercom: return .purple
        case .homeroom: return EZTeachColors.accent
        case .classTime: return EZTeachColors.navy
        case .lunch: return .green
        case .dismissal: return .red
        case .passing: return .gray
        default: return EZTeachColors.accent
        }
    }
    
    private func timeSlots(from start: String, to end: String, stepMinutes: Int) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else { return [] }
        let cal = Calendar.current
        var slots: [String] = []
        var current = startDate
        while current < endDate {
            slots.append(formatter.string(from: current))
            current = cal.date(byAdding: .minute, value: stepMinutes, to: current) ?? current
        }
        return slots
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
                    if canEdit {
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
                        
                        if canEdit {
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
    @State private var schoolStartTime = "07:00"
    @State private var schoolEndTime = "15:30"
    @State private var slotMinutes = 10
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
                    TextField("School Start", text: $schoolStartTime)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("School End", text: $schoolEndTime)
                        .keyboardType(.numbersAndPunctuation)
                    Picker("Time Grid Slots", selection: $slotMinutes) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                    }
                }
                
                Section("Quick Add") {
                    Button { addQuickPeriod(.breakfast, "Breakfast", "07:00", "07:30") } label: {
                        Label("Breakfast", systemImage: "cup.and.saucer.fill")
                    }
                    Button { addQuickPeriod(.intercom, "Intercom / Good Morning", "07:25", "07:35") } label: {
                        Label("Intercom / Good Morning", systemImage: "speaker.wave.2.fill")
                    }
                    Button { addGradeLunches() } label: {
                        Label("Add Grade Lunches (K-5)", systemImage: "fork.knife")
                    }
                    Button { addQuickPeriod(.dismissal, "Dismissal Bell", schoolEndTime, addMinutes(schoolEndTime, 5)) } label: {
                        Label("Dismissal Bell", systemImage: "bell.badge.fill")
                    }
                }
                
                Section("Periods") {
                    ForEach(Array(periods.enumerated()), id: \.element.id) { index, period in
                        periodEditRow(index: index, period: period)
                    }
                    .onDelete { indexSet in
                        periods.remove(atOffsets: indexSet)
                    }
                    Button { addPeriod() } label: {
                        Label("Add Period", systemImage: "plus")
                    }
                }
                
                Section {
                    Button { save() } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView() }
                            Text(isSaving ? "Saving..." : "Save Schedule").fontWeight(.semibold)
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
    
    private func periodEditRow(index: Int, period: BellPeriod) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Name", text: Binding(
                    get: { periods[index].name },
                    set: { periods[index] = BellPeriod(id: period.id, name: $0, periodNumber: period.periodNumber, startTime: period.startTime, endTime: period.endTime, periodType: period.periodType, gradeLevel: period.gradeLevel) }
                ))
                Picker("Type", selection: Binding(
                    get: { periods[index].periodType },
                    set: { periods[index] = BellPeriod(id: period.id, name: period.name, periodNumber: period.periodNumber, startTime: period.startTime, endTime: period.endTime, periodType: $0, gradeLevel: period.gradeLevel) }
                )) {
                    ForEach(BellPeriod.PeriodType.allCases, id: \.self) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .pickerStyle(.menu)
            }
            HStack {
                TextField("Start", text: Binding(
                    get: { periods[index].startTime },
                    set: { periods[index] = BellPeriod(id: period.id, name: period.name, periodNumber: period.periodNumber, startTime: $0, endTime: period.endTime, periodType: period.periodType, gradeLevel: period.gradeLevel) }
                ))
                .frame(width: 70)
                .keyboardType(.numbersAndPunctuation)
                TextField("End", text: Binding(
                    get: { periods[index].endTime },
                    set: { periods[index] = BellPeriod(id: period.id, name: period.name, periodNumber: period.periodNumber, startTime: period.startTime, endTime: $0, periodType: period.periodType, gradeLevel: period.gradeLevel) }
                ))
                .frame(width: 70)
                .keyboardType(.numbersAndPunctuation)
                if periods[index].periodType == .lunch {
                    Picker("Grade", selection: Binding(
                        get: { periods[index].gradeLevel ?? -1 },
                        set: { val in
                            let gl: Int? = val >= 0 ? val : nil
                            periods[index] = BellPeriod(id: period.id, name: period.name, periodNumber: period.periodNumber, startTime: period.startTime, endTime: period.endTime, periodType: period.periodType, gradeLevel: gl)
                        }
                    )) {
                        Text("All").tag(-1)
                        Text("K").tag(0)
                        ForEach(1...8, id: \.self) { g in
                            Text("\(g)").tag(g)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 60)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func addMinutes(_ time: String, _ mins: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let d = formatter.date(from: time) else { return time }
        let cal = Calendar.current
        let new = cal.date(byAdding: .minute, value: mins, to: d) ?? d
        return formatter.string(from: new)
    }

    private func addQuickPeriod(_ type: BellPeriod.PeriodType, _ name: String, _ start: String, _ end: String) {
        let p = BellPeriod(
            id: UUID().uuidString,
            name: name,
            periodNumber: nil,
            startTime: start,
            endTime: end,
            periodType: type,
            gradeLevel: nil
        )
        periods.append(p)
    }
    
    private func addGradeLunches() {
        let times = [(11,0,11,25), (11,25,11,50), (11,50,12,15), (12,15,12,40), (12,40,13,5), (13,5,13,30)]
        for (g, (sh, sm, eh, em)) in times.enumerated() {
            let startStr = String(format: "%02d:%02d", sh, sm)
            let endStr = String(format: "%02d:%02d", eh, em)
            let gradeName = g == 0 ? "K Lunch" : "Grade \(g) Lunch"
            periods.append(BellPeriod(
                id: UUID().uuidString,
                name: gradeName,
                periodNumber: nil,
                startTime: startStr,
                endTime: endStr,
                periodType: .lunch,
                gradeLevel: g
            ))
        }
    }
    
    private func loadExisting() {
        guard let schedule = schedule else {
            name = "Regular Day"
            schoolStartTime = "08:00"
            schoolEndTime = "15:15"
            slotMinutes = 10
            addQuickPeriod(.breakfast, "Breakfast", "07:30", "08:00")
            addQuickPeriod(.intercom, "Intercom / Good Morning", "07:55", "08:00")
            addQuickPeriod(.homeroom, "Homeroom", "08:00", "08:15")
            addQuickPeriod(.classTime, "Period 1", "08:15", "09:00")
            addQuickPeriod(.passing, "Passing", "09:00", "09:05")
            addQuickPeriod(.classTime, "Period 2", "09:05", "09:50")
            addQuickPeriod(.passing, "Passing", "09:50", "09:55")
            addQuickPeriod(.classTime, "Period 3", "09:55", "10:40")
            addQuickPeriod(.passing, "Passing", "10:40", "10:45")
            addQuickPeriod(.classTime, "Period 4", "10:45", "11:30")
            addQuickPeriod(.lunch, "Lunch", "11:30", "12:00")
            addQuickPeriod(.classTime, "Period 5", "12:00", "12:45")
            addQuickPeriod(.passing, "Passing", "12:45", "12:50")
            addQuickPeriod(.classTime, "Period 6", "12:50", "13:35")
            addQuickPeriod(.passing, "Passing", "13:35", "13:40")
            addQuickPeriod(.classTime, "Period 7", "13:40", "14:25")
            addQuickPeriod(.passing, "Passing", "14:25", "14:30")
            addQuickPeriod(.classTime, "Period 8", "14:30", "15:15")
            addQuickPeriod(.dismissal, "Dismissal Bell", "15:15", "15:20")
            return
        }
        name = schedule.name
        scheduleType = schedule.scheduleType
        isDefault = schedule.isDefault
        periods = schedule.periods
        schoolStartTime = schedule.schoolStartTime ?? schedule.effectiveStart
        schoolEndTime = schedule.schoolEndTime ?? schedule.effectiveEnd
        slotMinutes = schedule.slotMinutes ?? 10
    }
    
    private func addPeriod() {
        periods.append(BellPeriod(
            id: UUID().uuidString,
            name: "Period \(periods.count + 1)",
            periodNumber: periods.count + 1,
            startTime: "08:00",
            endTime: "08:50",
            periodType: .classTime,
            gradeLevel: nil
        ))
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
            "schoolStartTime": schoolStartTime,
            "schoolEndTime": schoolEndTime,
            "slotMinutes": slotMinutes,
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
