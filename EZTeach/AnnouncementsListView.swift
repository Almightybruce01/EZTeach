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

    @State private var announcements: [QueryDocumentSnapshot] = []
    @State private var listener: ListenerRegistration?

    private let db = Firestore.firestore()

    var body: some View {
        List {
            if announcements.isEmpty {
                Text("No announcements yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(announcements, id: \.documentID) { doc in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(doc["title"] as? String ?? "")
                            .font(.headline)

                        Text(doc["body"] as? String ?? "")
                            .font(.body)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Announcements")
        .onAppear { startListening() }
        .onDisappear { listener?.remove() }
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
                    announcements = active.sorted { d1, d2 in
                        let t1 = (d1.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                        let t2 = (d2.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                        return t1 > t2
                    }
                }
        }
    }
}
