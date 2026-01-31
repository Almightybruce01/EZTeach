//
//  VideoMeetingView.swift
//  EZTeach
//
//  Video conferencing for parent-teacher meetings
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct VideoMeetingView: View {
    let schoolId: String
    let userRole: String
    
    @State private var meetings: [VideoMeeting] = []
    @State private var isLoading = true
    @State private var showScheduleMeeting = false
    @State private var selectedTab = 0
    
    private let db = Firestore.firestore()
    
    var upcomingMeetings: [VideoMeeting] {
        meetings.filter { $0.scheduledAt > Date() && $0.status == .scheduled }
    }
    
    var pastMeetings: [VideoMeeting] {
        meetings.filter { $0.scheduledAt <= Date() || $0.status == .completed }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    let currentMeetings = selectedTab == 0 ? upcomingMeetings : pastMeetings
                    
                    if currentMeetings.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text(selectedTab == 0 ? "No Upcoming Meetings" : "No Past Meetings")
                                .font(.headline)
                            if selectedTab == 0 && (userRole == "school" || userRole == "teacher") {
                                Button {
                                    showScheduleMeeting = true
                                } label: {
                                    Text("Schedule a Meeting")
                                        .ezButton()
                                }
                            }
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(currentMeetings) { meeting in
                                MeetingRow(meeting: meeting, userRole: userRole)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Video Meetings")
            .toolbar {
                if userRole == "school" || userRole == "teacher" {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showScheduleMeeting = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showScheduleMeeting) {
                ScheduleMeetingView(schoolId: schoolId) {
                    loadMeetings()
                }
            }
            .onAppear(perform: loadMeetings)
        }
    }
    
    private func loadMeetings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        // For teachers/schools, show meetings they're hosting
        // For parents, show meetings they're invited to
        var query: Query
        
        if userRole == "school" || userRole == "teacher" {
            query = db.collection("videoMeetings")
                .whereField("hostId", isEqualTo: uid)
        } else {
            query = db.collection("videoMeetings")
                .whereField("participantIds", arrayContains: uid)
        }
        
        query.order(by: "scheduledAt", descending: true)
            .getDocuments { snap, _ in
                meetings = snap?.documents.compactMap { VideoMeeting.fromDocument($0) } ?? []
                isLoading = false
            }
    }
}

struct MeetingRow: View {
    let meeting: VideoMeeting
    let userRole: String
    
    var isUpcoming: Bool {
        meeting.scheduledAt > Date() && meeting.status == .scheduled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(meeting.scheduledAt, style: .date)
                        Text("•")
                        Text(meeting.scheduledAt, style: .time)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(meeting.duration) min")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(EZTeachColors.cardFill)
                    .cornerRadius(8)
            }
            
            if isUpcoming {
                HStack(spacing: 12) {
                    Button {
                        joinMeeting()
                    } label: {
                        Label("Join Meeting", systemImage: "video.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(EZTeachColors.accentGradient)
                            .cornerRadius(10)
                    }
                    
                    if !meeting.meetingCode.isEmpty {
                        HStack {
                            Text("Code: \(meeting.meetingCode)")
                                .font(.caption.monospaced())
                            
                            Button {
                                UIPasteboard.general.string = meeting.meetingCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                }
            } else if meeting.status == .completed, let recordingUrl = meeting.recordingUrl, !recordingUrl.isEmpty {
                Button {
                    if let url = URL(string: recordingUrl) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("View Recording", systemImage: "play.rectangle.fill")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func joinMeeting() {
        if let url = URL(string: meeting.meetingUrl) {
            UIApplication.shared.open(url)
        }
    }
}

struct ScheduleMeetingView: View {
    let schoolId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var scheduledAt = Date().addingTimeInterval(86400)
    @State private var duration = 30
    @State private var isRecorded = false
    @State private var selectedParents: Set<String> = []
    @State private var parents: [Parent] = []
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meeting Details") {
                    TextField("Meeting Title", text: $title)
                    
                    DatePicker("Date & Time", selection: $scheduledAt, in: Date()...)
                    
                    Picker("Duration", selection: $duration) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("1 hour").tag(60)
                    }
                    
                    Toggle("Record Meeting", isOn: $isRecorded)
                }
                
                Section("Invite Parents") {
                    if parents.isEmpty {
                        Text("No parents found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(parents) { parent in
                            HStack {
                                Text(parent.fullName)
                                Spacer()
                                if selectedParents.contains(parent.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(EZTeachColors.accent)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedParents.contains(parent.id) {
                                    selectedParents.remove(parent.id)
                                } else {
                                    selectedParents.insert(parent.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schedule") {
                        scheduleMeeting()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear(perform: loadParents)
        }
    }
    
    private func loadParents() {
        db.collection("parents")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                parents = snap?.documents.compactMap { Parent.fromDocument($0) } ?? []
            }
    }
    
    private func scheduleMeeting() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let meetingCode = String(format: "%06d", Int.random(in: 100000...999999))
        
        let data: [String: Any] = [
            "schoolId": schoolId,
            "hostId": uid,
            "title": title,
            "scheduledAt": Timestamp(date: scheduledAt),
            "duration": duration,
            "meetingUrl": "https://meet.ezteach.app/\(meetingCode)",
            "meetingCode": meetingCode,
            "participantIds": Array(selectedParents),
            "isRecorded": isRecorded,
            "status": "scheduled",
            "createdAt": Timestamp()
        ]
        
        db.collection("videoMeetings").addDocument(data: data) { _ in
            onSave()
            dismiss()
        }
    }
}
