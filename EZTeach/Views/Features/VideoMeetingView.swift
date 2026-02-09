//
//  VideoMeetingView.swift
//  EZTeach
//
//  Video conferencing for school staff meetings
//  All users except students can create, join, and participate
//

import SwiftUI
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Video Meeting List View
struct VideoMeetingView: View {
    let schoolId: String
    let userRole: String

    @State private var meetings: [VideoMeeting] = []
    @State private var isLoading = true
    @State private var showScheduleMeeting = false
    @State private var selectedTab = 0
    @State private var listener: ListenerRegistration?
    @State private var showInstantMeeting = false

    private let db = Firestore.firestore()

    private var canCreate: Bool {
        userRole != "student"
    }

    var upcomingMeetings: [VideoMeeting] {
        meetings.filter { $0.scheduledAt > Date() && $0.status == .scheduled }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    var pastMeetings: [VideoMeeting] {
        meetings.filter { $0.scheduledAt <= Date() || $0.status == .completed }
            .sorted { $0.scheduledAt > $1.scheduledAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick action bar
                if canCreate {
                    HStack(spacing: 12) {
                        Button {
                            showInstantMeeting = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "video.fill")
                                    .font(.headline)
                                Text("Start Now")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.gradient)
                            .cornerRadius(12)
                        }

                        Button {
                            showScheduleMeeting = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.headline)
                                Text("Schedule")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(EZTeachColors.accentGradient)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    let currentMeetings = selectedTab == 0 ? upcomingMeetings : pastMeetings

                    if currentMeetings.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text(selectedTab == 0 ? "No Upcoming Meetings" : "No Past Meetings")
                                .font(.headline)
                            Text("Tap \"Start Now\" for an instant meeting or \"Schedule\" to plan ahead.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(currentMeetings) { meeting in
                                MeetingRow(meeting: meeting, userRole: userRole, schoolId: schoolId)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Video Meetings")
            .sheet(isPresented: $showScheduleMeeting) {
                ScheduleMeetingView(schoolId: schoolId, userRole: userRole) { }
            }
            .fullScreenCover(isPresented: $showInstantMeeting) {
                InCallView(meetingTitle: "Instant Meeting", meetingCode: String(format: "%06d", Int.random(in: 100000...999999)), schoolId: schoolId)
            }
            .onAppear { startListening() }
            .onDisappear { listener?.remove() }
        }
    }

    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        // All non-student users see meetings they host OR are invited to
        // We do two queries and merge
        let hostQuery = db.collection("videoMeetings")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("hostId", isEqualTo: uid)

        let participantQuery = db.collection("videoMeetings")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("participantIds", arrayContains: uid)

        var hostMeetings: [VideoMeeting] = []
        var participantMeetings: [VideoMeeting] = []
        let group = DispatchGroup()

        group.enter()
        hostQuery.addSnapshotListener { snap, _ in
            hostMeetings = snap?.documents.compactMap { VideoMeeting.fromDocument($0) } ?? []
            group.leave()
        }

        group.enter()
        participantQuery.addSnapshotListener { snap, _ in
            participantMeetings = snap?.documents.compactMap { VideoMeeting.fromDocument($0) } ?? []
            group.leave()
        }

        group.notify(queue: .main) {
            // Merge and deduplicate
            var seen = Set<String>()
            var merged: [VideoMeeting] = []
            for m in hostMeetings + participantMeetings {
                if !seen.contains(m.id) {
                    seen.insert(m.id)
                    merged.append(m)
                }
            }
            meetings = merged
            isLoading = false
        }
    }
}

// MARK: - Meeting Row
struct MeetingRow: View {
    let meeting: VideoMeeting
    let userRole: String
    let schoolId: String

    @State private var showInCall = false

    var isUpcoming: Bool {
        meeting.scheduledAt > Date() && meeting.status == .scheduled
    }

    // Allow joining if within 15 minutes of start or if meeting is in-progress
    var canJoinNow: Bool {
        let minutesToStart = meeting.scheduledAt.timeIntervalSinceNow / 60
        return (minutesToStart < 15 && meeting.status == .scheduled) || meeting.status == .inProgress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.headline)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text(meeting.scheduledAt, style: .date)
                        Text("•")
                        Text(meeting.scheduledAt, style: .time)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Text(meeting.meetingType == .group ? "Group" : "1-on-1")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(meeting.meetingType == .group ? Color.blue.opacity(0.15) : Color.purple.opacity(0.15))
                            .foregroundColor(meeting.meetingType == .group ? .blue : .purple)
                            .cornerRadius(6)

                        Text("\(meeting.participantIds.count + 1) participants")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("\(meeting.duration)")
                        .font(.title3.bold().monospacedDigit())
                    Text("min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(10)
            }

            if isUpcoming || canJoinNow {
                Button {
                    showInCall = true
                } label: {
                    HStack {
                        Image(systemName: "video.fill")
                        Text(canJoinNow ? "Join Meeting Room" : "Join Meeting")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(canJoinNow ? Color.green.gradient : EZTeachColors.accentGradient)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

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
        }
        .padding(.vertical, 8)
        .fullScreenCover(isPresented: $showInCall) {
            InCallView(meetingTitle: meeting.title, meetingCode: meeting.meetingCode, schoolId: schoolId)
        }
    }
}

// MARK: - In-Call Video View (Full Camera UI)
struct InCallView: View {
    let meetingTitle: String
    let meetingCode: String
    let schoolId: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraManager()
    @State private var isMuted = false
    @State private var isCameraOff = false
    @State private var isUsingFrontCamera = true
    @State private var callDuration: Int = 0
    @State private var timer: Timer?
    @State private var showParticipants = false
    @State private var showChat = false
    @State private var chatText = ""
    @State private var chatMessages: [(sender: String, text: String, time: Date)] = []

    var formattedDuration: String {
        let mins = callDuration / 60
        let secs = callDuration % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        ZStack {
            // Camera preview (full screen)
            if isCameraOff {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Camera Off")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            } else {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            }

            // Top bar overlay
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meetingTitle)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text(formattedDuration)
                                .font(.caption.monospacedDigit().bold())
                                .foregroundColor(.white)
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Text("Code: \(meetingCode)")
                                .font(.caption.monospaced())
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial.opacity(0.8))
                    .cornerRadius(12)

                    Spacer()

                    // Participants button
                    Button {
                        showParticipants.toggle()
                    } label: {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Self view (picture-in-picture style)
                if !isCameraOff {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 120, height: 160)
                            .overlay(
                                VStack {
                                    Image(systemName: "person.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("You")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                    }
                }

                // Bottom controls
                HStack(spacing: 20) {
                    // Mute
                    callButton(
                        icon: isMuted ? "mic.slash.fill" : "mic.fill",
                        label: isMuted ? "Unmute" : "Mute",
                        color: isMuted ? .red : .white.opacity(0.2),
                        iconColor: isMuted ? .white : .white
                    ) {
                        isMuted.toggle()
                    }

                    // Camera
                    callButton(
                        icon: isCameraOff ? "video.slash.fill" : "video.fill",
                        label: isCameraOff ? "Start Video" : "Stop Video",
                        color: isCameraOff ? .red : .white.opacity(0.2),
                        iconColor: isCameraOff ? .white : .white
                    ) {
                        isCameraOff.toggle()
                        if isCameraOff {
                            camera.stop()
                        } else {
                            camera.start()
                        }
                    }

                    // Flip camera
                    callButton(
                        icon: "camera.rotate.fill",
                        label: "Flip",
                        color: .white.opacity(0.2),
                        iconColor: .white
                    ) {
                        isUsingFrontCamera.toggle()
                        camera.switchCamera(toFront: isUsingFrontCamera)
                    }

                    // Chat
                    callButton(
                        icon: "bubble.left.fill",
                        label: "Chat",
                        color: showChat ? .blue : .white.opacity(0.2),
                        iconColor: .white
                    ) {
                        showChat.toggle()
                    }

                    // End call
                    callButton(
                        icon: "phone.down.fill",
                        label: "End",
                        color: .red,
                        iconColor: .white
                    ) {
                        endCall()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial.opacity(0.9))
            }

            // Chat overlay
            if showChat {
                chatOverlay
            }
        }
        .onAppear {
            camera.checkPermissionsAndStart()
            startTimer()
        }
        .onDisappear {
            camera.stop()
            timer?.invalidate()
        }
        .statusBarHidden(true)
    }

    // MARK: - Call Button
    private func callButton(icon: String, label: String, color: Color, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                    .frame(width: 56, height: 56)
                    .background(color)
                    .clipShape(Circle())
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Chat Overlay
    private var chatOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                HStack {
                    Text("Meeting Chat")
                        .font(.headline)
                    Spacer()
                    Button { showChat = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(chatMessages.indices, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(chatMessages[i].sender)
                                    .font(.caption2.bold())
                                    .foregroundColor(.blue)
                                Text(chatMessages[i].text)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 200)

                Divider()

                HStack(spacing: 12) {
                    TextField("Type a message...", text: $chatText)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(20)
                    Button {
                        if !chatText.trimmingCharacters(in: .whitespaces).isEmpty {
                            chatMessages.append((sender: "You", text: chatText, time: Date()))
                            chatText = ""
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(EZTeachColors.accentGradient)
                    }
                }
                .padding()
            }
            .background(.regularMaterial)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
        .transition(.move(edge: .bottom))
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            callDuration += 1
        }
    }

    private func endCall() {
        timer?.invalidate()
        camera.stop()
        dismiss()
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Camera Manager
class CameraManager: ObservableObject {
    let session = AVCaptureSession()
    private var currentInput: AVCaptureDeviceInput?
    private var isRunning = false

    func checkPermissionsAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupAndStart(front: true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupAndStart(front: true)
                    }
                }
            }
        default:
            break
        }

        // Also request microphone
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }
    }

    func setupAndStart(front: Bool) {
        session.beginConfiguration()

        // Remove existing input
        if let input = currentInput {
            session.removeInput(input)
        }

        // Add camera
        let position: AVCaptureDevice.Position = front ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }

        // Add audio if not already added
        if session.inputs.count < 2,
           let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        session.commitConfiguration()
        start()
    }

    func switchCamera(toFront: Bool) {
        setupAndStart(front: toFront)
    }

    func start() {
        guard !isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }
}

// MARK: - Camera Preview (UIKit wrapper)
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                layer.frame = uiView.bounds
            }
        }
    }
}

// MARK: - Schedule Meeting View (invite any non-student user)
struct ScheduleMeetingView: View {
    let schoolId: String
    let userRole: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var scheduledAt = Date().addingTimeInterval(3600)
    @State private var duration = 30
    @State private var meetingType: VideoMeeting.MeetingType = .group
    @State private var hasPresentationMode = true
    @State private var isRecorded = false
    @State private var selectedUsers: Set<String> = []
    @State private var availableUsers: [MeetingInvitee] = []
    @State private var searchText = ""
    @State private var isLoadingUsers = true

    private let db = Firestore.firestore()

    var filteredUsers: [MeetingInvitee] {
        if searchText.isEmpty { return availableUsers }
        let q = searchText.lowercased()
        return availableUsers.filter { $0.name.lowercased().contains(q) || $0.role.lowercased().contains(q) }
    }

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
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                    }

                    Picker("Meeting Type", selection: $meetingType) {
                        Text("Group").tag(VideoMeeting.MeetingType.group)
                        Text("1-on-1").tag(VideoMeeting.MeetingType.oneOnOne)
                    }

                    Toggle("Presentation Mode", isOn: $hasPresentationMode)
                    Toggle("Record Meeting", isOn: $isRecorded)
                }

                Section {
                    if isLoadingUsers {
                        ProgressView("Loading users...")
                    } else if availableUsers.isEmpty {
                        Text("No users found at this school")
                            .foregroundColor(.secondary)
                    } else {
                        TextField("Search by name...", text: $searchText)

                        ForEach(filteredUsers) { user in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(.subheadline.weight(.medium))
                                    Text(user.role.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedUsers.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(EZTeachColors.accent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedUsers.contains(user.id) {
                                    selectedUsers.remove(user.id)
                                } else {
                                    selectedUsers.insert(user.id)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Invite Participants (\(selectedUsers.count) selected)")
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
                    .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadSchoolUsers)
        }
    }

    /// Load all non-student users for this school
    private func loadSchoolUsers() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        isLoadingUsers = true
        var allUsers: [MeetingInvitee] = []
        let group = DispatchGroup()

        // Teachers
        group.enter()
        db.collection("teachers")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                for doc in snap?.documents ?? [] {
                    let d = doc.data()
                    let uid = d["userId"] as? String ?? doc.documentID
                    if uid != currentUid {
                        let name = "\(d["firstName"] as? String ?? "") \(d["lastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
                        allUsers.append(MeetingInvitee(id: uid, name: name.isEmpty ? "Teacher" : name, role: "teacher"))
                    }
                }
                group.leave()
            }

        // Parents
        group.enter()
        db.collection("parents")
            .whereField("schoolIds", arrayContains: schoolId)
            .getDocuments { snap, _ in
                for doc in snap?.documents ?? [] {
                    let d = doc.data()
                    let uid = d["userId"] as? String ?? doc.documentID
                    if uid != currentUid {
                        let name = "\(d["firstName"] as? String ?? "") \(d["lastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
                        allUsers.append(MeetingInvitee(id: uid, name: name.isEmpty ? "Parent" : name, role: "parent"))
                    }
                }
                group.leave()
            }

        // School admins, librarians, subs, janitors, district — from "users" with matching schoolId
        group.enter()
        db.collection("users")
            .whereField("activeSchoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                for doc in snap?.documents ?? [] {
                    let d = doc.data()
                    let uid = doc.documentID
                    let role = d["role"] as? String ?? ""
                    // Exclude students and current user, and avoid duplicates with teachers
                    if uid != currentUid && role != "student" && role != "teacher" {
                        let name = "\(d["firstName"] as? String ?? "") \(d["lastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
                        allUsers.append(MeetingInvitee(id: uid, name: name.isEmpty ? role.capitalized : name, role: role))
                    }
                }
                group.leave()
            }

        group.notify(queue: .main) {
            // Deduplicate by id
            var seen = Set<String>()
            availableUsers = allUsers.filter { seen.insert($0.id).inserted }
                .sorted { $0.name < $1.name }
            isLoadingUsers = false
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
            "meetingUrl": "ezteach://meeting/\(meetingCode)",
            "meetingCode": meetingCode,
            "participantIds": Array(selectedUsers),
            "isRecorded": isRecorded,
            "meetingType": meetingType.rawValue,
            "hasPresentationMode": hasPresentationMode,
            "status": "scheduled",
            "createdAt": Timestamp()
        ]

        db.collection("videoMeetings").addDocument(data: data) { _ in
            onSave()
            dismiss()
        }
    }
}

struct MeetingInvitee: Identifiable {
    let id: String
    let name: String
    let role: String
}
