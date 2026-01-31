//
//  EmergencyAlertsView.swift
//  EZTeach
//
//  Emergency alert system for schools
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmergencyAlertsView: View {
    let schoolId: String
    let isAdmin: Bool
    
    @State private var alerts: [EmergencyAlert] = []
    @State private var activeAlert: EmergencyAlert?
    @State private var isLoading = true
    @State private var showCreateAlert = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Active alert banner
                    if let active = activeAlert {
                        ActiveAlertBanner(alert: active, isAdmin: isAdmin) {
                            resolveAlert(active)
                        }
                    }
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if alerts.isEmpty && activeAlert == nil {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("All Clear")
                                .font(.title2.bold())
                            Text("No active or recent alerts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        List {
                            if !alerts.isEmpty {
                                Section("Recent Alerts") {
                                    ForEach(alerts) { alert in
                                        AlertHistoryRow(alert: alert)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Emergency Alerts")
            .toolbar {
                if isAdmin {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(EmergencyAlert.AlertType.allCases, id: \.self) { type in
                                Button {
                                    showQuickAlert(type: type)
                                } label: {
                                    Label(type.rawValue, systemImage: type.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateAlert) {
                CreateEmergencyAlertView(schoolId: schoolId) {
                    loadAlerts()
                }
            }
            .onAppear(perform: loadAlerts)
        }
    }
    
    private func showQuickAlert(type: EmergencyAlert.AlertType) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let title: String
        let message: String
        
        switch type {
        case .lockdown:
            title = "LOCKDOWN"
            message = "All students and staff should shelter in place. Lock doors, turn off lights, stay away from windows."
        case .weather:
            title = "SEVERE WEATHER"
            message = "Severe weather alert. Move to designated safe areas immediately."
        case .fire:
            title = "FIRE DRILL"
            message = "Evacuate the building using designated exit routes. Meet at assigned rally points."
        case .evacuation:
            title = "EVACUATION"
            message = "Building evacuation required. Follow evacuation procedures."
        case .shelter:
            title = "SHELTER IN PLACE"
            message = "All students and staff should remain indoors until further notice."
        case .medical:
            title = "MEDICAL EMERGENCY"
            message = "Medical emergency in progress. Clear hallways for emergency responders."
        case .other:
            title = "GENERAL ALERT"
            message = "Please await further instructions."
        }
        
        db.collection("emergencyAlerts").addDocument(data: [
            "schoolId": schoolId,
            "type": type.rawValue,
            "title": title,
            "message": message,
            "isActive": true,
            "createdBy": uid,
            "createdAt": Timestamp()
        ]) { _ in
            loadAlerts()
        }
    }
    
    private func resolveAlert(_ alert: EmergencyAlert) {
        db.collection("emergencyAlerts").document(alert.id).updateData([
            "isActive": false,
            "resolvedAt": Timestamp()
        ]) { _ in
            loadAlerts()
        }
    }
    
    private func loadAlerts() {
        isLoading = true
        
        // Load active alert
        db.collection("emergencyAlerts")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments { snap, _ in
                activeAlert = snap?.documents.first.flatMap { EmergencyAlert.fromDocument($0) }
            }
        
        // Load history
        db.collection("emergencyAlerts")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("isActive", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments { snap, _ in
                alerts = snap?.documents.compactMap { EmergencyAlert.fromDocument($0) } ?? []
                isLoading = false
            }
    }
}

struct ActiveAlertBanner: View {
    let alert: EmergencyAlert
    let isAdmin: Bool
    let onResolve: () -> Void
    
    @State private var isPulsing = false
    
    var alertColor: Color {
        switch alert.type {
        case .lockdown, .medical: return .red
        case .weather: return .blue
        case .fire: return .orange
        case .evacuation, .shelter: return .yellow
        case .other: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: alert.type.icon)
                    .font(.title)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                
                VStack(alignment: .leading) {
                    Text(alert.title)
                        .font(.headline.bold())
                    Text("Active since \(alert.createdAt, style: .time)")
                        .font(.caption)
                }
                
                Spacer()
                
                if isAdmin {
                    Button("ALL CLEAR") {
                        onResolve()
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundColor(alertColor)
                    .cornerRadius(8)
                }
            }
            
            Text(alert.message)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundColor(.white)
        .padding()
        .background(alertColor)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct AlertHistoryRow: View {
    let alert: EmergencyAlert
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: alert.type.icon)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.subheadline.weight(.medium))
                
                HStack {
                    Text(alert.createdAt, style: .date)
                    Text("•")
                    Text(alert.createdAt, style: .time)
                    if let resolved = alert.resolvedAt {
                        Text("• Resolved \(resolved, style: .time)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

struct CreateEmergencyAlertView: View {
    let schoolId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: EmergencyAlert.AlertType = .other
    @State private var title = ""
    @State private var message = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Alert Type") {
                    Picker("Type", selection: $type) {
                        ForEach(EmergencyAlert.AlertType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                }
                
                Section("Message") {
                    TextField("Title", text: $title)
                    TextEditor(text: $message)
                        .frame(height: 100)
                }
                
                Section {
                    Text("This will immediately notify all users at this school.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Create Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Send Alert") {
                        sendAlert()
                    }
                    .foregroundColor(.red)
                    .disabled(title.isEmpty || message.isEmpty)
                }
            }
        }
    }
    
    private func sendAlert() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("emergencyAlerts").addDocument(data: [
            "schoolId": schoolId,
            "type": type.rawValue,
            "title": title,
            "message": message,
            "isActive": true,
            "createdBy": uid,
            "createdAt": Timestamp()
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}
