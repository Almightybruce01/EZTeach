//
//  BehaviorTrackingView.swift
//  EZTeach
//
//  Student behavior incident tracking
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BehaviorTrackingView: View {
    let schoolId: String
    let studentId: String?
    
    @State private var incidents: [BehaviorIncident] = []
    @State private var isLoading = true
    @State private var showAddIncident = false
    @State private var filterType: BehaviorIncident.BehaviorType?
    
    private let db = Firestore.firestore()
    
    var filteredIncidents: [BehaviorIncident] {
        if let filter = filterType {
            return incidents.filter { $0.type == filter }
        }
        return incidents
    }
    
    var positiveCount: Int {
        incidents.filter { $0.type == .positive }.count
    }
    
    var negativeCount: Int {
        incidents.filter { $0.type != .positive }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                HStack(spacing: 20) {
                    statCard(value: positiveCount, label: "Positive", color: .green, icon: "star.fill")
                    statCard(value: negativeCount, label: "Incidents", color: .orange, icon: "exclamationmark.triangle.fill")
                }
                .padding()
                
                // Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(nil, label: "All")
                        ForEach(BehaviorIncident.BehaviorType.allCases, id: \.self) { type in
                            filterChip(type, label: type.rawValue)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredIncidents.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("No Incidents")
                            .font(.headline)
                        Text("A clean record!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredIncidents) { incident in
                            IncidentRow(incident: incident)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Behavior")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddIncident = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddIncident) {
                AddBehaviorIncidentView(schoolId: schoolId, studentId: studentId) {
                    loadIncidents()
                }
            }
            .onAppear(perform: loadIncidents)
        }
    }
    
    private func statCard(value: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("\(value)")
                    .font(.title2.bold())
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func filterChip(_ type: BehaviorIncident.BehaviorType?, label: String) -> some View {
        Button {
            filterType = type
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(filterType == type ? EZTeachColors.accent : EZTeachColors.secondaryBackground)
                .foregroundColor(filterType == type ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    private func loadIncidents() {
        isLoading = true
        var query: Query = db.collection("behaviorIncidents").whereField("schoolId", isEqualTo: schoolId)
        
        if let studentId = studentId {
            query = query.whereField("studentId", isEqualTo: studentId)
        }
        
        query.order(by: "date", descending: true).getDocuments { snap, _ in
            incidents = snap?.documents.compactMap { BehaviorIncident.fromDocument($0) } ?? []
            isLoading = false
        }
    }
}

struct IncidentRow: View {
    let incident: BehaviorIncident
    
    var severityColor: Color {
        switch incident.severity {
        case .minor: return .green
        case .moderate: return .yellow
        case .major: return .orange
        case .critical: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(incident.type == .positive ? Color.green.opacity(0.2) : severityColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: incident.type.icon)
                        .foregroundColor(incident.type == .positive ? .green : severityColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(incident.type.rawValue)
                        .font(.subheadline.weight(.semibold))
                    
                    if incident.type != .positive {
                        Text(incident.severity.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(severityColor.opacity(0.2))
                            .foregroundColor(severityColor)
                            .cornerRadius(4)
                    }
                }
                
                Text(incident.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(incident.date, style: .date)
                    if incident.parentNotified {
                        Image(systemName: "envelope.badge.fill")
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddBehaviorIncidentView: View {
    let schoolId: String
    let studentId: String?
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStudentId = ""
    @State private var type: BehaviorIncident.BehaviorType = .positive
    @State private var severity: BehaviorIncident.Severity = .minor
    @State private var description = ""
    @State private var actionTaken = ""
    @State private var parentNotified = false
    @State private var date = Date()
    @State private var students: [Student] = []
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                if studentId == nil {
                    Section("Student") {
                        Picker("Select Student", selection: $selectedStudentId) {
                            Text("Choose...").tag("")
                            ForEach(students) { student in
                                Text(student.name).tag(student.id)
                            }
                        }
                    }
                }
                
                Section("Incident Type") {
                    Picker("Type", selection: $type) {
                        ForEach(BehaviorIncident.BehaviorType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    
                    if type != .positive {
                        Picker("Severity", selection: $severity) {
                            ForEach(BehaviorIncident.Severity.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                    }
                }
                
                Section("Details") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                if type != .positive {
                    Section("Action & Follow-up") {
                        TextField("Action Taken", text: $actionTaken)
                        Toggle("Parent Notified", isOn: $parentNotified)
                    }
                }
            }
            .navigationTitle(type == .positive ? "Log Positive" : "Log Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveIncident()
                    }
                    .disabled(description.isEmpty || (studentId == nil && selectedStudentId.isEmpty))
                }
            }
            .onAppear {
                if let sid = studentId {
                    selectedStudentId = sid
                }
                loadStudents()
            }
        }
    }
    
    private func loadStudents() {
        db.collection("students")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                students = snap?.documents.compactMap { Student.fromDocument($0) } ?? []
            }
    }
    
    private func saveIncident() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let finalStudentId = studentId ?? selectedStudentId
        guard !finalStudentId.isEmpty else { return }
        
        db.collection("behaviorIncidents").addDocument(data: [
            "studentId": finalStudentId,
            "schoolId": schoolId,
            "reportedBy": uid,
            "type": type.rawValue,
            "severity": severity.rawValue,
            "description": description,
            "actionTaken": actionTaken,
            "parentNotified": parentNotified,
            "date": Timestamp(date: date),
            "createdAt": Timestamp()
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}
