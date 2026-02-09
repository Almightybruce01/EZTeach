//
//  MultiplayerReadingView.swift
//  EZTeach
//
//  Shared reading experience - read together with friends, family, or classmates
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Reading Session Model
struct ReadingSession: Identifiable, Codable {
    let id: String
    let hostId: String
    let hostName: String
    let bookId: String
    let bookTitle: String
    let schoolId: String
    let currentPage: Int
    let totalPages: Int
    let participants: [String]
    let participantNames: [String]
    let isActive: Bool
    let createdAt: Date
    let sessionCode: String
    
    static func fromDocument(_ doc: DocumentSnapshot) -> ReadingSession? {
        guard let data = doc.data() else { return nil }
        return ReadingSession(
            id: doc.documentID,
            hostId: data["hostId"] as? String ?? "",
            hostName: data["hostName"] as? String ?? "",
            bookId: data["bookId"] as? String ?? "",
            bookTitle: data["bookTitle"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            currentPage: data["currentPage"] as? Int ?? 0,
            totalPages: data["totalPages"] as? Int ?? 10,
            participants: data["participants"] as? [String] ?? [],
            participantNames: data["participantNames"] as? [String] ?? [],
            isActive: data["isActive"] as? Bool ?? true,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            sessionCode: data["sessionCode"] as? String ?? ""
        )
    }
}

// MARK: - Multiplayer Reading Hub
struct MultiplayerReadingHubView: View {
    let userId: String
    let userName: String
    let schoolId: String
    
    @State private var activeSessions: [ReadingSession] = []
    @State private var isLoading = true
    @State private var showCreateSession = false
    @State private var showJoinSession = false
    @State private var joinCode = ""
    @State private var selectedSession: ReadingSession?
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    headerCard
                    
                    // Quick actions
                    quickActions
                    
                    // Active sessions
                    activeSessionsSection
                    
                    // My sessions
                    mySessionsSection
                }
                .padding()
            }
            .background(EZTeachColors.background)
            .navigationTitle("Read Together")
            .sheet(isPresented: $showCreateSession) {
                CreateReadingSessionView(userId: userId, userName: userName, schoolId: schoolId) { session in
                    selectedSession = session
                }
            }
            .sheet(isPresented: $showJoinSession) {
                JoinSessionView(userId: userId, userName: userName, joinCode: $joinCode) { session in
                    selectedSession = session
                }
            }
            .fullScreenCover(item: $selectedSession) { session in
                SharedReadingView(session: session, userId: userId, userName: userName)
            }
            .onAppear { loadSessions() }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📚 Reading Together")
                        .font(.title2.weight(.bold))
                    Text("Share the joy of reading with friends and family!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 12) {
                StatBubble(value: "\(activeSessions.count)", label: "Active", color: .green)
                StatBubble(value: "\(mySessions.count)", label: "My Sessions", color: .blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        HStack(spacing: 12) {
            ActionButton(
                icon: "plus.circle.fill",
                title: "Start Session",
                subtitle: "Host a reading",
                color: EZTeachColors.brightTeal
            ) {
                showCreateSession = true
            }
            
            ActionButton(
                icon: "person.2.fill",
                title: "Join Session",
                subtitle: "Enter code",
                color: .purple
            ) {
                showJoinSession = true
            }
        }
    }
    
    // MARK: - Active Sessions Section
    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.green)
                Text("Active Sessions")
                    .font(.headline)
                
                Spacer()
                
                if !activeSessions.isEmpty {
                    Text("\(activeSessions.count) live")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if activeSessions.isEmpty {
                emptySessionsView
            } else {
                ForEach(activeSessions) { session in
                    SessionCard(session: session, isOwner: session.hostId == userId) {
                        selectedSession = session
                    }
                }
            }
        }
    }
    
    // MARK: - My Sessions Section
    private var mySessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text("My Sessions")
                    .font(.headline)
            }
            
            if mySessions.isEmpty {
                Text("You haven't started any reading sessions yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(mySessions) { session in
                    SessionCard(session: session, isOwner: true) {
                        selectedSession = session
                    }
                }
            }
        }
    }
    
    private var emptySessionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No active reading sessions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Start one or join with a code!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var mySessions: [ReadingSession] {
        activeSessions.filter { $0.hostId == userId }
    }
    
    // MARK: - Load Sessions
    private func loadSessions() {
        isLoading = true
        
        db.collection("readingSessions")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { snap, _ in
                activeSessions = snap?.documents.compactMap { ReadingSession.fromDocument($0) } ?? []
                isLoading = false
            }
    }
}

// MARK: - Stat Bubble
struct StatBubble: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Card
struct SessionCard: View {
    let session: ReadingSession
    let isOwner: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Book icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(EZTeachColors.brightTeal.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text("📖")
                        .font(.title2)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.bookTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if isOwner {
                            Text("HOST")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(EZTeachColors.brightTeal)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("Hosted by \(session.hostName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Label("\(session.participants.count + 1) readers", systemImage: "person.2")
                        Label("Page \(session.currentPage + 1)/\(session.totalPages)", systemImage: "book")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                VStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    Text("LIVE")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Reading Session View
struct CreateReadingSessionView: View {
    let userId: String
    let userName: String
    let schoolId: String
    let onSessionCreated: (ReadingSession) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBook: PictureBook?
    @State private var isCreating = false
    @State private var sessionCode: String?
    @State private var searchText = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let code = sessionCode {
                    // Session created - show code
                    sessionCreatedView(code: code)
                } else {
                    // Book selection
                    bookSelectionView
                }
            }
            .navigationTitle("Start Reading Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var bookSelectionView: some View {
        VStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search books...", text: $searchText)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Book grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredBooks) { book in
                        BookSelectionCard(book: book, isSelected: selectedBook?.id == book.id) {
                            selectedBook = book
                        }
                    }
                }
                .padding()
            }
            
            // Create button
            Button {
                createSession()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    Text(isCreating ? "Creating..." : "Start Session")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedBook == nil ? AnyShapeStyle(Color.gray) : AnyShapeStyle(EZTeachColors.accentGradient))
                .cornerRadius(12)
            }
            .disabled(selectedBook == nil || isCreating)
            .padding()
        }
    }
    
    private func sessionCreatedView(code: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Session Created!")
                .font(.title2.weight(.bold))
            
            VStack(spacing: 8) {
                Text("Share this code with readers:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(code)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(EZTeachColors.brightTeal)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("Copy Code", systemImage: "doc.on.doc")
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            Button {
                if let book = selectedBook {
                    let session = ReadingSession(
                        id: UUID().uuidString,
                        hostId: userId,
                        hostName: userName,
                        bookId: book.id,
                        bookTitle: book.title,
                        schoolId: schoolId,
                        currentPage: 0,
                        totalPages: book.pages,
                        participants: [],
                        participantNames: [],
                        isActive: true,
                        createdAt: Date(),
                        sessionCode: code
                    )
                    onSessionCreated(session)
                    dismiss()
                }
            } label: {
                Text("Start Reading")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(EZTeachColors.accentGradient)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private var filteredBooks: [PictureBook] {
        if searchText.isEmpty {
            return PictureBooksLibrary.allBooks
        }
        return PictureBooksLibrary.search(searchText)
    }
    
    private func createSession() {
        guard let book = selectedBook else { return }
        
        isCreating = true
        let code = generateSessionCode()
        let sessionId = UUID().uuidString
        
        let data: [String: Any] = [
            "hostId": userId,
            "hostName": userName,
            "bookId": book.id,
            "bookTitle": book.title,
            "schoolId": schoolId,
            "currentPage": 0,
            "totalPages": book.pages,
            "participants": [],
            "participantNames": [],
            "isActive": true,
            "createdAt": Timestamp(),
            "sessionCode": code
        ]
        
        db.collection("readingSessions").document(sessionId).setData(data) { error in
            isCreating = false
            if error == nil {
                sessionCode = code
            }
        }
    }
    
    private func generateSessionCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

// MARK: - Book Selection Card
struct BookSelectionCard: View {
    let book: PictureBook
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(book.coverColor)
                        .frame(height: 100)
                    
                    Text(book.coverEmoji)
                        .font(.system(size: 40))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? EZTeachColors.brightTeal : Color.clear, lineWidth: 3)
                )
                
                Text(book.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .background(isSelected ? EZTeachColors.brightTeal.opacity(0.1) : Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Join Session View
struct JoinSessionView: View {
    let userId: String
    let userName: String
    @Binding var joinCode: String
    let onSessionJoined: (ReadingSession) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isJoining = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(EZTeachColors.brightTeal)
                
                VStack(spacing: 8) {
                    Text("Join Reading Session")
                        .font(.title2.weight(.bold))
                    
                    Text("Enter the 6-character code from the host")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Code input
                TextField("XXXXXX", text: $joinCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .onChange(of: joinCode) { _, newValue in
                        joinCode = String(newValue.uppercased().prefix(6))
                    }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button {
                    joinSession()
                } label: {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text(isJoining ? "Joining..." : "Join Session")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(joinCode.count == 6 ? EZTeachColors.accentGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                }
                .disabled(joinCode.count != 6 || isJoining)
                .padding()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func joinSession() {
        isJoining = true
        errorMessage = nil
        
        db.collection("readingSessions")
            .whereField("sessionCode", isEqualTo: joinCode)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snap, error in
                isJoining = false
                
                if let doc = snap?.documents.first,
                   let session = ReadingSession.fromDocument(doc) {
                    // Add participant
                    db.collection("readingSessions").document(doc.documentID).updateData([
                        "participants": FieldValue.arrayUnion([userId]),
                        "participantNames": FieldValue.arrayUnion([userName])
                    ])
                    
                    onSessionJoined(session)
                    dismiss()
                } else {
                    errorMessage = "Session not found. Check the code and try again."
                }
            }
    }
}

// MARK: - Shared Reading View
struct SharedReadingView: View {
    let session: ReadingSession
    let userId: String
    let userName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var participants: [(id: String, name: String)] = []
    @State private var showParticipants = false
    @State private var book: PictureBook?
    @State private var isHost: Bool = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            // Background
            (book?.coverColor ?? EZTeachColors.brightTeal).opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                sharedHeader
                
                // Participants bar
                participantsBar
                
                // Book content
                if let book = book {
                    PictureBookReaderView(book: book)
                } else {
                    ProgressView("Loading book...")
                }
            }
        }
        .onAppear {
            isHost = session.hostId == userId
            loadBook()
            listenToSession()
        }
    }
    
    // MARK: - Shared Header
    private var sharedHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                }
                
                Text(session.bookTitle)
                    .font(.caption.weight(.medium))
            }
            
            Spacer()
            
            Button {
                showParticipants.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                    Text("\(participants.count + 1)")
                }
                .font(.subheadline)
                .foregroundColor(EZTeachColors.brightTeal)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(EZTeachColors.brightTeal.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.white)
    }
    
    // MARK: - Participants Bar
    private var participantsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Host
                ParticipantBubble(name: session.hostName, isHost: true, isSelf: session.hostId == userId)
                
                // Other participants
                ForEach(participants, id: \.id) { participant in
                    ParticipantBubble(name: participant.name, isHost: false, isSelf: participant.id == userId)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.white.opacity(0.8))
    }
    
    private func loadBook() {
        book = PictureBooksLibrary.allBooks.first { $0.id == session.bookId }
    }
    
    private func listenToSession() {
        db.collection("readingSessions").document(session.id)
            .addSnapshotListener { snap, _ in
                guard let data = snap?.data() else { return }
                
                currentPage = data["currentPage"] as? Int ?? 0
                
                let participantIds = data["participants"] as? [String] ?? []
                let participantNames = data["participantNames"] as? [String] ?? []
                
                participants = zip(participantIds, participantNames).map { (id: $0, name: $1) }
            }
    }
}

// MARK: - Participant Bubble
struct ParticipantBubble: View {
    let name: String
    let isHost: Bool
    let isSelf: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isHost ? EZTeachColors.brightTeal : .blue)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(name.prefix(1).uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(isSelf ? "You" : name.components(separatedBy: " ").first ?? name)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                
                if isHost {
                    Text("Host")
                        .font(.caption2)
                        .foregroundColor(EZTeachColors.brightTeal)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelf ? EZTeachColors.brightTeal.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}
