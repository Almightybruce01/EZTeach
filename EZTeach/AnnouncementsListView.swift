//
//  AnnouncementsListView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AnnouncementsListView: View {

    @State private var announcements: [Announcement] = []
    @State private var listener: ListenerRegistration?

    private let db = Firestore.firestore()

    var body: some View {
        List {
            if announcements.isEmpty {
                Text("No announcements yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(announcements) { ann in
                    announcementRow(ann)
                }
            }
        }
        .navigationTitle("Announcements")
        .onAppear { startListening() }
        .onDisappear { listener?.remove() }
    }

    private func announcementRow(_ ann: Announcement) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(ann.roleColor.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: ann.roleIcon)
                        .font(.system(size: 14))
                        .foregroundColor(ann.roleColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(ann.roleLabel)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ann.roleColor)
                        .cornerRadius(4)

                    if !ann.authorName.isEmpty {
                        Text(ann.authorName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text(ann.title)
                    .font(.headline)

                Text(ann.body)
                    .font(.body)
                    .foregroundColor(.secondary)

                if let url = ann.attachmentUrl, let u = URL(string: url) {
                    AsyncImage(url: u) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                        .frame(maxWidth: 200, maxHeight: 120).clipped().cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let schoolId = snap?.data()?["activeSchoolId"] as? String else { return }

            listener?.remove()
            listener = db.collection("announcements")
                .whereField("schoolId", isEqualTo: schoolId)
                .addSnapshotListener { snap, _ in
                    let docs = snap?.documents ?? []
                    let active = docs.filter { ($0.data()["isActive"] as? Bool ?? true) }
                    let sorted = active.sorted { d1, d2 in
                        let t1 = (d1.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                        let t2 = (d2.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                        return t1 > t2
                    }
                    announcements = sorted.map { doc in
                        let d = doc.data()
                        return Announcement(
                            id: doc.documentID,
                            schoolId: schoolId,
                            title: d["title"] as? String ?? "",
                            body: d["body"] as? String ?? "",
                            attachmentUrl: d["attachmentUrl"] as? String,
                            isActive: true,
                            authorRole: d["authorRole"] as? String ?? "school",
                            authorName: d["authorName"] as? String ?? "",
                            createdAt: (d["createdAt"] as? Timestamp)?.dateValue()
                        )
                    }
                }
        }
    }
}
