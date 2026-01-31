//
//  AddAnnouncementView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import FirebaseFirestore

struct AddAnnouncementView: View {

    @Environment(\.dismiss) private var dismiss

    let schoolId: String

    @State private var title = ""
    @State private var message = ""   // ✅ renamed from `body`

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Form {
                Section("New Announcement") {
                    TextField("Title", text: $title)
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(4...10)
                }

                Button("Post") { post() }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("Announcement")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func post() {
        db.collection("announcements").addDocument(data: [
            "schoolId": schoolId,
            "title": title,
            "body": message,
            "isActive": true,
            "createdAt": Timestamp()
        ])
        dismiss()
    }
}
