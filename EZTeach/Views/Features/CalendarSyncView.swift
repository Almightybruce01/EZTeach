//
//  CalendarSyncView.swift
//  EZTeach
//
//  Calendar sync with Apple/Google Calendar
//

import SwiftUI
import EventKit

struct CalendarSyncView: View {
    let schoolId: String
    let events: [SchoolEvent]
    
    @State private var isExporting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var calendarAccess = false
    @State private var selectedEvents: Set<String> = []
    @State private var selectAll = true
    
    private let eventStore = EKEventStore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 50))
                        .foregroundStyle(EZTeachColors.accentGradient)
                    
                    Text("Export to Calendar")
                        .font(.title2.bold())
                    
                    Text("Add school events to your personal calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Select all toggle
                Toggle("Select All Events", isOn: $selectAll)
                    .padding()
                    .background(EZTeachColors.secondaryBackground)
                    .onChange(of: selectAll) { _, newValue in
                        if newValue {
                            selectedEvents = Set(events.map { $0.id })
                        } else {
                            selectedEvents.removeAll()
                        }
                    }
                
                // Events list
                if events.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Events")
                            .font(.headline)
                        Text("There are no upcoming events to export")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(events) { event in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.subheadline.weight(.medium))
                                    Text(event.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedEvents.contains(event.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(EZTeachColors.accent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleEvent(event.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                // Export button
                Button {
                    exportToCalendar()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isExporting ? "Exporting..." : "Export \(selectedEvents.count) Events")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedEvents.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(EZTeachColors.accentGradient))
                    .foregroundColor(selectedEvents.isEmpty ? .secondary : .white)
                    .cornerRadius(14)
                }
                .disabled(selectedEvents.isEmpty || isExporting)
                .padding()
            }
            .background(EZTeachColors.background)
            .navigationTitle("Calendar Sync")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Events Exported", isPresented: $showSuccess) {
                Button("OK") { }
            } message: {
                Text("\(selectedEvents.count) events have been added to your calendar.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                selectedEvents = Set(events.map { $0.id })
                checkCalendarAccess()
            }
        }
    }
    
    private func toggleEvent(_ id: String) {
        if selectedEvents.contains(id) {
            selectedEvents.remove(id)
            selectAll = false
        } else {
            selectedEvents.insert(id)
            if selectedEvents.count == events.count {
                selectAll = true
            }
        }
    }
    
    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            calendarAccess = status == .fullAccess || status == .writeOnly
        } else {
            calendarAccess = status == .authorized
        }
    }
    
    private func exportToCalendar() {
        isExporting = true
        
        // Request access if needed
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if granted {
                    addEventsToCalendar()
                } else {
                    DispatchQueue.main.async {
                        isExporting = false
                        errorMessage = "Calendar access denied. Please enable it in Settings."
                        showError = true
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    addEventsToCalendar()
                } else {
                    DispatchQueue.main.async {
                        isExporting = false
                        errorMessage = "Calendar access denied. Please enable it in Settings."
                        showError = true
                    }
                }
            }
        }
    }
    
    private func addEventsToCalendar() {
        let eventsToExport = events.filter { selectedEvents.contains($0.id) }
        var addedCount = 0
        
        for schoolEvent in eventsToExport {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = schoolEvent.title
            ekEvent.startDate = schoolEvent.date
            ekEvent.endDate = schoolEvent.date.addingTimeInterval(3600) // 1 hour duration
            ekEvent.notes = "School Event: \(schoolEvent.type)"
            ekEvent.calendar = eventStore.defaultCalendarForNewEvents
            
            do {
                try eventStore.save(ekEvent, span: .thisEvent)
                addedCount += 1
            } catch {
                print("Failed to save event: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            isExporting = false
            if addedCount > 0 {
                showSuccess = true
            } else {
                errorMessage = "Failed to export events"
                showError = true
            }
        }
    }
}
