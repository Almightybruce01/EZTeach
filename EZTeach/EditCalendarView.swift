//
//  EditCalendarView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import FirebaseFirestore

struct EditCalendarView: View {

    let schoolId: String

    @State private var title = ""
    @State private var date = Date()
    @State private var type = "event"
    @State private var teachersOnly = false

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Event Title", text: $title)

                DatePicker("Date", selection: $date, displayedComponents: .date)

                Picker("Type", selection: $type) {
                    Text("Event").tag("event")
                    Text("Day Off").tag("dayOff")
                }

                Toggle("Teachers only", isOn: $teachersOnly)
                Text("Only teachers and school accounts will see this event.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Save") {
                    save()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("Edit Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func save() {
        db.collection("events").addDocument(data: [
            "schoolId": schoolId,
            "title": title,
            "date": Timestamp(date: date),
            "type": type,
            "teachersOnly": teachersOnly,
            "createdAt": Timestamp()
        ])

        dismiss()
    }
}
