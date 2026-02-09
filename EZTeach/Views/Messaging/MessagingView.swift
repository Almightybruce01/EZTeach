//
//  MessagingView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MessagingView: View {
    
    let schoolId: String
    
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var showNewConversation = false
    @State private var selectedConversation: Conversation?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if conversations.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(conversations) { conversation in
                            conversationRow(conversation)
                        }
                    }
                }
            }
        }
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewConversation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationView(schoolId: schoolId) { conversation in
                selectedConversation = conversation
                loadConversations()
            }
        }
        .sheet(item: $selectedConversation) { conversation in
            ConversationDetailView(conversation: conversation)
        }
        .onAppear(perform: loadConversations)
    }
    
    // MARK: - Conversation Row
    private func conversationRow(_ conversation: Conversation) -> some View {
        Button {
            selectedConversation = conversation
        } label: {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(EZTeachColors.accent.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if conversation.conversationType == .group || conversation.conversationType == .classGroup {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(EZTeachColors.accent)
                    } else {
                        Text(getInitials(from: conversation))
                            .font(.headline)
                            .foregroundColor(EZTeachColors.accent)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(getTitle(for: conversation))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let lastDate = conversation.lastMessageAt {
                            Text(formatDate(lastDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text(conversation.lastMessage ?? "No messages yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let uid = Auth.auth().currentUser?.uid,
                           conversation.unreadCount(for: uid) > 0 {
                            Text("\(conversation.unreadCount(for: uid))")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(EZTeachColors.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Messages")
                .font(.title2.bold())
            
            Text("Start a conversation with teachers, parents, or staff members.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showNewConversation = true
            } label: {
                Label("New Message", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(EZTeachColors.accentGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(40)
    }
    
    // MARK: - Helpers
    private func getInitials(from conversation: Conversation) -> String {
        guard let uid = Auth.auth().currentUser?.uid else { return "?" }
        
        let otherParticipant = conversation.participantIds.first { $0 != uid }
        if let name = otherParticipant.flatMap({ conversation.participantNames[$0] }) {
            let parts = name.split(separator: " ")
            return parts.prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
        }
        return "?"
    }
    
    private func getTitle(for conversation: Conversation) -> String {
        if let title = conversation.title { return title }
        
        guard let uid = Auth.auth().currentUser?.uid else { return "Conversation" }
        
        let otherNames = conversation.participantIds
            .filter { $0 != uid }
            .compactMap { conversation.participantNames[$0] }
        
        return otherNames.joined(separator: ", ")
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Load Data
    private func loadConversations() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        db.collection("conversations")
            .whereField("participantIds", arrayContains: uid)
            .whereField("schoolId", isEqualTo: schoolId)
            .addSnapshotListener { snap, _ in
                conversations = snap?.documents.compactMap { Conversation.fromDocument($0) }
                    .sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) } ?? []
                isLoading = false
            }
    }
}

// MARK: - New Conversation View
struct NewConversationView: View {
    
    let schoolId: String
    let onCreated: (Conversation) -> Void
    
    @State private var searchText = ""
    @State private var users: [UserInfo] = []
    @State private var selectedUsers: Set<String> = []
    @State private var isLoading = true
    @State private var isCreating = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var filteredUsers: [UserInfo] {
        if searchText.isEmpty { return users }
        return users.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by name...", text: $searchText)
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    // User list
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredUsers) { user in
                                userRow(user)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createConversation()
                    } label: {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(selectedUsers.isEmpty || isCreating)
                }
            }
            .onAppear(perform: loadUsers)
        }
    }
    
    private func userRow(_ user: UserInfo) -> some View {
        Button {
            if selectedUsers.contains(user.id) {
                selectedUsers.remove(user.id)
            } else {
                selectedUsers.insert(user.id)
            }
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(EZTeachColors.accent.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(user.name.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(EZTeachColors.accent)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Text(user.role.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: selectedUsers.contains(user.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedUsers.contains(user.id) ? EZTeachColors.success : .secondary)
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
        }
        .buttonStyle(.plain)
    }
    
    private func loadUsers() {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        var allUsers: [UserInfo] = []
        let group = DispatchGroup()

        // Load teachers
        group.enter()
        db.collection("teachers")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                for doc in snap?.documents ?? [] {
                    let data = doc.data()
                    let uid = data["userId"] as? String ?? doc.documentID
                    if uid != currentUid {
                        let name = "\(data["firstName"] as? String ?? "") \(data["lastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
                        allUsers.append(UserInfo(id: uid, name: name.isEmpty ? "Teacher" : name, role: "teacher"))
                    }
                }
                group.leave()
            }

        // Load parents
        group.enter()
        db.collection("parents")
            .whereField("schoolIds", arrayContains: schoolId)
            .getDocuments { snap, _ in
                for doc in snap?.documents ?? [] {
                    let data = doc.data()
                    let uid = data["userId"] as? String ?? doc.documentID
                    if uid != currentUid {
                        let name = "\(data["firstName"] as? String ?? "") \(data["lastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
                        allUsers.append(UserInfo(id: uid, name: name.isEmpty ? "Parent" : name, role: "parent"))
                    }
                }
                group.leave()
            }

        // Load school admins, librarians, subs, janitors, district — all non-student, non-teacher users
        group.enter()
        db.collection("users")
            .whereField("activeSchoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                for doc in snap?.documents ?? [] {
                    let data = doc.data()
                    let uid = doc.documentID
                    let role = data["role"] as? String ?? ""
                    // Exclude students, teachers (already loaded), parents (already loaded), and self
                    if uid != currentUid && role != "student" && role != "teacher" && role != "parent" {
                        let name = "\(data["firstName"] as? String ?? "") \(data["lastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
                        allUsers.append(UserInfo(id: uid, name: name.isEmpty ? role.capitalized : name, role: role))
                    }
                }
                group.leave()
            }

        group.notify(queue: .main) {
            // Deduplicate by id
            var seen = Set<String>()
            users = allUsers.filter { seen.insert($0.id).inserted }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            isLoading = false
        }
    }
    
    private func createConversation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isCreating = true
        
        // Get current user info
        db.collection("users").document(uid).getDocument { snap, _ in
            let userData = snap?.data() ?? [:]
            let currentName = "\(userData["firstName"] as? String ?? "") \(userData["lastName"] as? String ?? "")"
            
            var participantIds = Array(selectedUsers)
            participantIds.append(uid)
            
            var participantNames: [String: String] = [uid: currentName]
            for user in users where selectedUsers.contains(user.id) {
                participantNames[user.id] = user.name
            }
            
            let conversationData: [String: Any] = [
                "schoolId": schoolId,
                "participantIds": participantIds,
                "participantNames": participantNames,
                "createdByUserId": uid,
                "conversationType": selectedUsers.count > 1 ? "group" : "direct",
                "unreadCounts": [:],
                "createdAt": Timestamp()
            ]
            
            db.collection("conversations").addDocument(data: conversationData) { error in
                isCreating = false
                if error == nil {
                    dismiss()
                }
            }
        }
    }
}

struct UserInfo: Identifiable {
    let id: String
    let name: String
    let role: String
}

// MARK: - Conversation Detail View
struct ConversationDetailView: View {
    
    let conversation: Conversation
    
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    @State private var isSending = false
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input
                inputBar
            }
            .navigationTitle(getTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadMessages()
                markAsRead()
            }
        }
    }
    
    private func messageBubble(_ message: Message) -> some View {
        let isOwnMessage = message.senderId == Auth.auth().currentUser?.uid
        
        return HStack {
            if isOwnMessage { Spacer() }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                if !isOwnMessage {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(12)
                    .background(isOwnMessage ? EZTeachColors.accent : EZTeachColors.secondaryBackground)
                    .foregroundColor(isOwnMessage ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isOwnMessage { Spacer() }
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $newMessage)
                .textFieldStyle(.plain)
                .padding(12)
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(20)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(EZTeachColors.accentGradient)
            }
            .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
        }
        .padding()
    }
    
    private func getTitle() -> String {
        if let title = conversation.title { return title }
        
        guard let uid = Auth.auth().currentUser?.uid else { return "Chat" }
        
        let otherNames = conversation.participantIds
            .filter { $0 != uid }
            .compactMap { conversation.participantNames[$0] }
        
        return otherNames.joined(separator: ", ")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadMessages() {
        db.collection("messages")
            .whereField("conversationId", isEqualTo: conversation.id)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, _ in
                messages = snap?.documents.compactMap { Message.fromDocument($0) } ?? []
                isLoading = false
            }
    }
    
    private func sendMessage() {
        guard let uid = Auth.auth().currentUser?.uid,
              !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isSending = true
        let content = newMessage
        newMessage = ""
        
        // Get sender name
        db.collection("users").document(uid).getDocument { snap, _ in
            let userData = snap?.data() ?? [:]
            let senderName = "\(userData["firstName"] as? String ?? "") \(userData["lastName"] as? String ?? "")"
            let senderRole = userData["role"] as? String ?? ""
            
            let messageData: [String: Any] = [
                "conversationId": conversation.id,
                "senderId": uid,
                "senderName": senderName,
                "senderRole": senderRole,
                "content": content,
                "messageType": "text",
                "isRead": false,
                "createdAt": Timestamp()
            ]
            
            db.collection("messages").addDocument(data: messageData) { _ in
                // Update conversation with last message
                db.collection("conversations").document(conversation.id).updateData([
                    "lastMessage": content,
                    "lastMessageAt": Timestamp()
                ])
                
                isSending = false
            }
        }
    }
    
    private func markAsRead() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("conversations").document(conversation.id).updateData([
            "unreadCounts.\(uid)": 0
        ])
    }
}
