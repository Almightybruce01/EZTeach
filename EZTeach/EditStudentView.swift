//
//  EditStudentView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseFirestore

struct EditStudentView: View {

    let student: Student

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var notes: String = ""

    private let db = Firestore.firestore()

    init(student: Student) {
        self.student = student
        _name = State(initialValue: student.name)
    }

    var body: some View {
        Form {
            Section("Student") {
                TextField("Full Name", text: $name)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 120)
            }

            Button("Save") {
                save()
            }
        }
        .navigationTitle("Edit Student")
    }

    private func save() {
        db.collection("students").document(student.id).updateData([
            "name": name,
            "notes": notes
        ])
        dismiss()
    }
}
