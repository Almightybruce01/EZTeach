//
//  CalendarStripView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

// ==============================
// CalendarStripView.swift (FULL)
// ==============================
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CalendarStripView: View {

    @State private var events: [SchoolEvent] = []
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            // your existing calendar strip UI can stay here

            CalendarBottomSheetView(events: events)
        }
        .onAppear { loadEvents() }
    }

    // MARK: - LOAD EVENTS
    private func loadEvents() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let schoolId = snap?.data()?["activeSchoolId"] as? String else { return }

            db.collection("events")
                .whereField("schoolId", isEqualTo: schoolId)
                .getDocuments { snap, _ in
                    let docs = snap?.documents ?? []
                    events = docs.map { SchoolEvent.fromDoc($0, schoolId: schoolId) }
                        .sorted { $0.date < $1.date }
                }
        }
    }
}
