//
//  SupportView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SupportView: View {

    @State private var selectedSection: SupportSection = .help
    @State private var showNewClaim = false
    @State private var showChat = false
    @State private var claims: [SupportClaim] = []

    @Environment(\.dismiss) private var dismiss

    enum SupportSection: String, CaseIterable {
        case help = "Help Center"
        case contact = "Contact Us"
        case claims = "My Claims"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Section picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(SupportSection.allCases, id: \.self) { section in
                            Text(section.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // Content
                    ScrollView {
                        switch selectedSection {
                        case .help:
                            helpCenterContent
                        case .contact:
                            contactContent
                        case .claims:
                            claimsContent
                        }
                    }
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showNewClaim) {
                NewClaimView { loadClaims() }
            }
            .sheet(isPresented: $showChat) {
                ChatSupportView()
            }
            .onAppear(perform: loadClaims)
        }
    }

    // MARK: - Help Center Content
    private var helpCenterContent: some View {
        VStack(spacing: 16) {
            // Search bar placeholder
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                Text("Search help articles...")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(12)

            // FAQ Categories
            VStack(alignment: .leading, spacing: 16) {
                Text("Frequently Asked Questions")
                    .font(.headline)

                faqItem(
                    question: "How do I add teachers to my school?",
                    answer: "Teachers can join your school using your 6-digit school code. Go to School Settings to find your code, then share it with your teachers."
                )

                faqItem(
                    question: "How do I create a sub plan?",
                    answer: "Navigate to the teacher's profile, then select 'Sub Plans'. You can create templates that substitutes can access when covering your class."
                )

                faqItem(
                    question: "How do I manage my account?",
                    answer: "Go to Account > Manage Account in the app, which opens our website. There you can view billing details and manage your account."
                )

                faqItem(
                    question: "Can teachers access other schools' data?",
                    answer: "No. Teachers can only access data from schools they've joined. Each school's data is completely separate and secure."
                )

                faqItem(
                    question: "How do I reset my password?",
                    answer: "On the login screen, tap 'Forgot Password' and enter your email. You'll receive a link to reset your password."
                )
            }
        }
        .padding()
    }

    private func faqItem(question: String, answer: String) -> some View {
        DisclosureGroup {
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        } label: {
            Text(question)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }

    // MARK: - Contact Content
    private var contactContent: some View {
        VStack(spacing: 20) {
            // Live chat card
            Button {
                showChat = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(EZTeachColors.success.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: "message.fill")
                            .font(.title2)
                            .foregroundColor(EZTeachColors.success)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Live Chat Support")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Circle()
                                .fill(EZTeachColors.success)
                                .frame(width: 8, height: 8)
                        }

                        Text("Get instant help from our AI assistant")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)

            // Submit claim
            contactCard(
                icon: "envelope.fill",
                title: "Submit a Claim",
                subtitle: "Tap 'Submit New Claim' above for support. We'll respond via email.",
                color: EZTeachColors.accent
            )

            contactCard(
                icon: "clock.fill",
                title: "Response Time",
                subtitle: "We respond within 2–4 hours, Mon–Fri 9am–5pm EST",
                color: EZTeachColors.navy
            )

            // Response time note
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("Average response time: 2-4 hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
        }
        .padding()
    }

    private func contactCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }

    // MARK: - Claims Content
    private var claimsContent: some View {
        VStack(spacing: 16) {
            // New claim button
            Button {
                showNewClaim = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Submit New Claim")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(EZTeachColors.accentGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Claims list
            if claims.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No Claims")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("You haven't submitted any support claims yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(40)
            } else {
                ForEach(claims) { claim in
                    claimCard(claim)
                }
            }
        }
        .padding()
    }

    private func claimCard(_ claim: SupportClaim) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(claim.subject)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(claim.status)
                    .font(.caption.bold())
                    .foregroundColor(statusColor(claim.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(claim.status).opacity(0.1))
                    .cornerRadius(8)
            }

            Text(claim.preview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Text(claim.date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "open": return EZTeachColors.warning
        case "in progress": return EZTeachColors.accent
        case "resolved": return EZTeachColors.success
        default: return .secondary
        }
    }

    // MARK: - Load Claims
    private func loadClaims() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("supportClaims")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { snap, _ in
                claims = snap?.documents.compactMap { doc -> SupportClaim? in
                    let data = doc.data()
                    let date = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    return SupportClaim(
                        id: doc.documentID,
                        subject: data["subject"] as? String ?? "",
                        preview: data["message"] as? String ?? "",
                        status: data["status"] as? String ?? "Open",
                        date: formatter.string(from: date)
                    )
                } ?? []
            }
    }
}

// MARK: - Support Claim Model
struct SupportClaim: Identifiable {
    let id: String
    let subject: String
    let preview: String
    let status: String
    let date: String
}

// MARK: - New Claim View
struct NewClaimView: View {

    let onSubmit: () -> Void

    @State private var subject = ""
    @State private var message = ""
    @State private var category = "General"
    @State private var isSubmitting = false
    @State private var showSuccess = false

    @Environment(\.dismiss) private var dismiss

    private let categories = ["General", "Billing", "Technical", "Account", "Feature Request", "Bug Report"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                }

                Section("Subject") {
                    TextField("Brief description", text: $subject)
                }

                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }

                Section {
                    Button {
                        submitClaim()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.9)
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Claim")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(subject.isEmpty || message.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("New Claim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Claim Submitted", isPresented: $showSuccess) {
                Button("OK") {
                    onSubmit()
                    dismiss()
                }
            } message: {
                Text("We'll get back to you within 24-48 hours.")
            }
        }
    }

    private func submitClaim() {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else { return }

        isSubmitting = true

        Firestore.firestore().collection("supportClaims").addDocument(data: [
            "userId": uid,
            "email": email,
            "category": category,
            "subject": subject,
            "message": message,
            "status": "Open",
            "createdAt": Timestamp()
        ]) { error in
            isSubmitting = false
            if error == nil {
                showSuccess = true
            }
        }
    }
}

// MARK: - Chat Support View (AI Assistant)
struct ChatSupportView: View {

    @State private var messages: [ChatMessage] = [
        ChatMessage(isUser: false, text: "Hi! I'm the EZTeach AI assistant. How can I help you today?")
    ]
    @State private var inputText = ""
    @State private var isTyping = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                chatBubble(message)
                            }

                            if isTyping {
                                HStack {
                                    typingIndicator
                                    Spacer()
                                }
                                .padding(.horizontal)
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

                Divider()

                // Input area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(20)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(EZTeachColors.accentGradient)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Chat Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer() }

            Text(message.text)
                .padding(12)
                .background(message.isUser ? EZTeachColors.accent : EZTeachColors.secondaryBackground)
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)

            if !message.isUser { Spacer() }
        }
        .id(message.id)
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .opacity(0.5)
            }
        }
        .padding(12)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(isUser: true, text: text))
        inputText = ""
        isTyping = true

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTyping = false
            let response = generateResponse(for: text)
            messages.append(ChatMessage(isUser: false, text: response))
        }
    }

    private func generateResponse(for input: String) -> String {
        let lowered = input.lowercased()

        if lowered.contains("subscription") || lowered.contains("billing") || lowered.contains("payment") {
            return "For account and billing questions, manage your account from our website (Account > Manage Account in the app). If you're having issues, please submit a claim and our team will assist you within 24 hours."
        } else if lowered.contains("teacher") || lowered.contains("add") {
            return "To add teachers, share your 6-digit school code with them. They can enter it in the 'Switch Schools' section to join your school."
        } else if lowered.contains("password") || lowered.contains("login") {
            return "To reset your password, tap 'Forgot Password' on the login screen. You'll receive an email with instructions to create a new password."
        } else if lowered.contains("sub") || lowered.contains("substitute") {
            return "Sub plans can be created from a teacher's profile. Navigate to Grades > Select Teacher > Sub Plans to create or view substitute instructions."
        } else {
            return "I'd be happy to help! For detailed assistance, please submit a support claim using the form above. Is there anything specific about EZTeach I can help explain?"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}
