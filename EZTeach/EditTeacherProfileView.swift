//
//  EditTeacherProfileView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseFirestore

struct EditTeacherProfileView: View {

    let teacherId: String
    let currentBio: String
    let currentRoomNumber: String
    let currentOfficeHours: String
    let currentEmail: String
    let onSave: () -> Void

    @State private var bio: String
    @State private var roomNumber: String
    @State private var officeHours: String
    @State private var email: String
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    init(teacherId: String, currentBio: String, currentRoomNumber: String, currentOfficeHours: String, currentEmail: String, onSave: @escaping () -> Void) {
        self.teacherId = teacherId
        self.currentBio = currentBio
        self.currentRoomNumber = currentRoomNumber
        self.currentOfficeHours = currentOfficeHours
        self.currentEmail = currentEmail
        self.onSave = onSave
        _bio = State(initialValue: currentBio)
        _roomNumber = State(initialValue: currentRoomNumber)
        _officeHours = State(initialValue: currentOfficeHours)
        _email = State(initialValue: currentEmail)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("About Me") {
                    TextField("Bio / Welcome Message", text: $bio, axis: .vertical)
                        .lineLimit(3...6)

                    Text("Write a short introduction for students and parents.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Contact & Location") {
                    TextField("Room Number", text: $roomNumber)
                    TextField("Office Hours", text: $officeHours)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tips", systemImage: "lightbulb.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)

                        Text("• Your profile is visible to all users at your school")
                            .font(.caption)
                        Text("• Keep your bio friendly and professional")
                            .font(.caption)
                        Text("• Room number helps students find you")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Profile")
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

    private func save() {
        isSaving = true

        db.collection("teachers").document(teacherId).updateData([
            "bio": bio.trimmingCharacters(in: .whitespacesAndNewlines),
            "roomNumber": roomNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            "officeHours": officeHours.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines)
        ]) { error in
            isSaving = false
            if error == nil {
                onSave()
                dismiss()
            }
        }
    }
}
