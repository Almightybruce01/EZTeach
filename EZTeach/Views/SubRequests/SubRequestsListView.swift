//
//  SubRequestsListView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SubRequestsListView: View {
    
    let schoolId: String
    let userRole: String
    
    @State private var requests: [SubRequest] = []
    @State private var filterStatus: SubRequest.RequestStatus?
    @State private var showCreateRequest = false
    @State private var isLoading = true
    @State private var selectedRequest: SubRequest?
    
    @Environment(\.colorScheme) private var colorScheme
    private let db = Firestore.firestore()
    
    private var filteredRequests: [SubRequest] {
        guard let filter = filterStatus else { return requests }
        return requests.filter { $0.status == filter }
    }
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if requests.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Filter chips
                    filterBar
                    
                    // Requests list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRequests) { request in
                                SubRequestCard(request: request, userRole: userRole) {
                                    selectedRequest = request
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Sub Requests")
        .toolbar {
            if userRole == "teacher" || userRole == "school" {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateRequest = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateRequest) {
            CreateSubRequestView(schoolId: schoolId) {
                loadRequests()
            }
        }
        .sheet(item: $selectedRequest) { request in
            SubRequestDetailView(request: request, userRole: userRole) {
                loadRequests()
            }
        }
        .onAppear(perform: loadRequests)
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", status: nil)
                filterChip(label: "Pending", status: .pending)
                filterChip(label: "Approved", status: .approved)
                filterChip(label: "Assigned", status: .assigned)
                filterChip(label: "Completed", status: .completed)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(EZTeachColors.secondaryBackground)
    }
    
    private func filterChip(label: String, status: SubRequest.RequestStatus?) -> some View {
        Button {
            withAnimation {
                filterStatus = status
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(filterStatus == status ? EZTeachColors.accent : EZTeachColors.cardFill)
                .foregroundColor(filterStatus == status ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Sub Requests")
                .font(.title2.bold())
            
            Text("Sub requests will appear here when teachers need coverage.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if userRole == "teacher" {
                Button {
                    showCreateRequest = true
                } label: {
                    Label("Create Request", systemImage: "plus")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(EZTeachColors.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(40)
    }
    
    // MARK: - Load Data
    private func loadRequests() {
        var query: Query = db.collection("subRequests")
            .whereField("schoolId", isEqualTo: schoolId)
        
        // Teachers see their own requests, subs see all approved/assigned
        if userRole == "teacher", let uid = Auth.auth().currentUser?.uid {
            query = query.whereField("teacherUserId", isEqualTo: uid)
        }
        
        query.getDocuments { snap, _ in
            requests = snap?.documents.compactMap { SubRequest.fromDocument($0) }
                .sorted { $0.date > $1.date } ?? []
            isLoading = false
        }
    }
}

// MARK: - Sub Request Card
struct SubRequestCard: View {
    
    let request: SubRequest
    let userRole: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.teacherName)
                            .font(.headline)
                        Text(dateFormatter.string(from: request.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    statusBadge
                }
                
                // Details
                HStack(spacing: 16) {
                    if request.isFullDay {
                        Label("Full Day", systemImage: "sun.max.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label("\(request.startTime ?? "") - \(request.endTime ?? "")", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !request.classNames.isEmpty {
                        Label(request.classNames.joined(separator: ", "), systemImage: "book.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Assigned sub (if any)
                if let subName = request.assignedSubName {
                    HStack {
                        Image(systemName: "person.fill.checkmark")
                            .foregroundColor(EZTeachColors.success)
                        Text("Assigned to: \(subName)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(EZTeachColors.success)
                    }
                }
                
                // Reason
                if !request.reason.isEmpty {
                    Text(request.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: request.status.iconName)
            Text(request.status.displayName)
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .foregroundColor(statusColor)
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending: return EZTeachColors.warning
        case .approved: return EZTeachColors.accent
        case .assigned: return EZTeachColors.success
        case .inProgress: return .purple
        case .completed: return .green
        case .cancelled: return .gray
        case .rejected: return EZTeachColors.error
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
}

// MARK: - Create Sub Request View
struct CreateSubRequestView: View {
    
    let schoolId: String
    let onSave: () -> Void
    
    @State private var selectedDate = Date()
    @State private var isFullDay = true
    @State private var startTime = "08:00"
    @State private var endTime = "15:00"
    @State private var reason = ""
    @State private var notes = ""
    @State private var isSubmitting = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                    
                    Toggle("Full Day", isOn: $isFullDay)
                    
                    if !isFullDay {
                        TextField("Start Time", text: $startTime)
                        TextField("End Time", text: $endTime)
                    }
                }
                
                Section("Reason") {
                    TextField("Why do you need a sub?", text: $reason)
                }
                
                Section("Notes for Substitute") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button {
                        submitRequest()
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Request")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(reason.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Request a Sub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func submitRequest() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSubmitting = true
        
        // Get teacher info
        db.collection("users").document(uid).getDocument { snap, _ in
            let userData = snap?.data() ?? [:]
            let firstName = userData["firstName"] as? String ?? ""
            let lastName = userData["lastName"] as? String ?? ""
            let teacherName = "\(firstName) \(lastName)"
            
            // Find teacher document
            db.collection("teachers")
                .whereField("userId", isEqualTo: uid)
                .limit(to: 1)
                .getDocuments { teacherSnap, _ in
                    let teacherId = teacherSnap?.documents.first?.documentID ?? ""
                    
                    let requestData: [String: Any] = [
                        "schoolId": schoolId,
                        "teacherId": teacherId,
                        "teacherUserId": uid,
                        "teacherName": teacherName,
                        "date": Timestamp(date: selectedDate),
                        "startTime": isFullDay ? NSNull() : startTime,
                        "endTime": isFullDay ? NSNull() : endTime,
                        "isFullDay": isFullDay,
                        "reason": reason,
                        "classIds": [],
                        "classNames": [],
                        "status": "pending",
                        "notes": notes,
                        "createdAt": Timestamp(),
                        "updatedAt": Timestamp()
                    ]
                    
                    db.collection("subRequests").addDocument(data: requestData) { error in
                        isSubmitting = false
                        if error == nil {
                            onSave()
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Sub Request Detail View
struct SubRequestDetailView: View {
    
    let request: SubRequest
    let userRole: String
    let onUpdate: () -> Void
    
    @State private var isUpdating = false
    @State private var availableSubs: [SubInfo] = []
    @State private var selectedSubId: String?
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status card
                    statusCard
                    
                    // Details
                    detailsCard
                    
                    // Actions based on role
                    if userRole == "school" && request.status == .pending {
                        approvalActions
                    }
                    
                    if userRole == "school" && request.status == .approved {
                        assignSubSection
                    }
                    
                    if userRole == "sub" && request.status == .approved {
                        acceptRequestButton
                    }
                }
                .padding()
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: loadAvailableSubs)
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: request.status.iconName)
                .font(.system(size: 48))
                .foregroundColor(statusColor)
            
            Text(request.status.displayName)
                .font(.title2.bold())
            
            Text(dateFormatter.string(from: request.date))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(statusColor.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
            
            detailRow(icon: "person", label: "Teacher", value: request.teacherName)
            detailRow(icon: "clock", label: "Time", value: request.isFullDay ? "Full Day" : "\(request.startTime ?? "") - \(request.endTime ?? "")")
            detailRow(icon: "text.bubble", label: "Reason", value: request.reason)
            
            if let notes = request.notes, !notes.isEmpty {
                detailRow(icon: "note.text", label: "Notes", value: notes)
            }
            
            if let subName = request.assignedSubName {
                detailRow(icon: "person.fill.checkmark", label: "Assigned Sub", value: subName)
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(EZTeachColors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
    
    private var approvalActions: some View {
        HStack(spacing: 16) {
            Button {
                updateStatus(.rejected)
            } label: {
                Text("Reject")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(EZTeachColors.error.opacity(0.1))
                    .foregroundColor(EZTeachColors.error)
                    .cornerRadius(12)
            }
            
            Button {
                updateStatus(.approved)
            } label: {
                Text("Approve")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(EZTeachColors.success)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private var assignSubSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assign Substitute")
                .font(.headline)
            
            if availableSubs.isEmpty {
                Text("No available substitutes found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(12)
            } else {
                ForEach(availableSubs) { sub in
                    Button {
                        selectedSubId = sub.id
                        assignSub(sub)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(sub.name)
                                    .font(.subheadline.weight(.medium))
                                Text(sub.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isUpdating && selectedSubId == sub.id {
                                ProgressView()
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(EZTeachColors.success)
                            }
                        }
                        .padding()
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var acceptRequestButton: some View {
        Button {
            acceptAsSubstitute()
        } label: {
            HStack {
                if isUpdating {
                    ProgressView()
                        .tint(.white)
                }
                Text("Accept This Request")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(EZTeachColors.success)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isUpdating)
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending: return EZTeachColors.warning
        case .approved: return EZTeachColors.accent
        case .assigned: return EZTeachColors.success
        case .inProgress: return .purple
        case .completed: return .green
        case .cancelled: return .gray
        case .rejected: return EZTeachColors.error
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }
    
    // MARK: - Actions
    private func updateStatus(_ newStatus: SubRequest.RequestStatus) {
        isUpdating = true
        
        db.collection("subRequests").document(request.id).updateData([
            "status": newStatus.rawValue,
            "updatedAt": Timestamp()
        ]) { _ in
            isUpdating = false
            onUpdate()
            dismiss()
        }
    }
    
    private func loadAvailableSubs() {
        db.collection("subs")
            .whereField("schoolId", isEqualTo: request.schoolId)
            .getDocuments { snap, _ in
                availableSubs = snap?.documents.compactMap { doc -> SubInfo? in
                    let data = doc.data()
                    return SubInfo(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        name: "\(data["firstName"] as? String ?? "") \(data["lastName"] as? String ?? "")",
                        email: data["email"] as? String ?? ""
                    )
                } ?? []
            }
    }
    
    private func assignSub(_ sub: SubInfo) {
        isUpdating = true
        
        db.collection("subRequests").document(request.id).updateData([
            "status": SubRequest.RequestStatus.assigned.rawValue,
            "assignedSubId": sub.id,
            "assignedSubUserId": sub.userId,
            "assignedSubName": sub.name,
            "updatedAt": Timestamp()
        ]) { _ in
            isUpdating = false
            onUpdate()
            dismiss()
        }
    }
    
    private func acceptAsSubstitute() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isUpdating = true
        
        db.collection("users").document(uid).getDocument { snap, _ in
            let userData = snap?.data() ?? [:]
            let firstName = userData["firstName"] as? String ?? ""
            let lastName = userData["lastName"] as? String ?? ""
            
            // Find sub document
            db.collection("subs")
                .whereField("userId", isEqualTo: uid)
                .limit(to: 1)
                .getDocuments { subSnap, _ in
                    let subId = subSnap?.documents.first?.documentID ?? ""
                    
                    db.collection("subRequests").document(request.id).updateData([
                        "status": SubRequest.RequestStatus.assigned.rawValue,
                        "assignedSubId": subId,
                        "assignedSubUserId": uid,
                        "assignedSubName": "\(firstName) \(lastName)",
                        "updatedAt": Timestamp()
                    ]) { _ in
                        isUpdating = false
                        onUpdate()
                        dismiss()
                    }
                }
        }
    }
}

struct SubInfo: Identifiable {
    let id: String
    let userId: String
    let name: String
    let email: String
}
