//
//  EditHomepageView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseFirestore

struct EditHomepageView: View {

    let schoolId: String
    let currentLogoUrl: String
    let currentWelcomeMessage: String

    @State private var logoUrl: String
    @State private var welcomeMessage: String
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    init(schoolId: String, currentLogoUrl: String, currentWelcomeMessage: String) {
        self.schoolId = schoolId
        self.currentLogoUrl = currentLogoUrl
        self.currentWelcomeMessage = currentWelcomeMessage
        _logoUrl = State(initialValue: currentLogoUrl)
        _welcomeMessage = State(initialValue: currentWelcomeMessage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        // Logo preview
                        logoPreview
                            .frame(width: 100, height: 100)

                        Text("Logo Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Section("School Logo") {
                    TextField("Image URL", text: $logoUrl)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    Text("Paste a URL to your school's logo image. For best results, use a square image.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Welcome Message") {
                    TextField("Welcome message...", text: $welcomeMessage, axis: .vertical)
                        .lineLimit(3...6)

                    Text("This message will be displayed prominently on your homepage for all users.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tips", systemImage: "lightbulb.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)

                        Text("• Keep your welcome message short and friendly")
                            .font(.caption)
                        Text("• Use a high-quality logo image (PNG or JPG)")
                            .font(.caption)
                        Text("• Square images work best for the circular display")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Homepage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private var logoPreview: some View {
        Group {
            if let url = URL(string: logoUrl), !logoUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        placeholderLogo
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderLogo
                    }
                }
            } else {
                placeholderLogo
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(EZTeachColors.navy.opacity(0.3), lineWidth: 3)
        )
    }

    private var placeholderLogo: some View {
        ZStack {
            Circle()
                .fill(EZTeachColors.cardFill)
            Image(systemName: "building.columns.fill")
                .font(.system(size: 36))
                .foregroundColor(EZTeachColors.navy)
        }
    }

    private func save() {
        isSaving = true

        db.collection("schools").document(schoolId).updateData([
            "logoUrl": logoUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            "welcomeMessage": welcomeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        ]) { error in
            isSaving = false
            if error == nil {
                dismiss()
            }
        }
    }
}
