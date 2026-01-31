//
//  EditHomeBackgroundView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import FirebaseFirestore

struct EditHomeBackgroundView: View {

    @Environment(\.dismiss) private var dismiss

    let schoolId: String
    let currentValue: String
    let onSaved: (String) -> Void

    @State private var selected: String

    private let db = Firestore.firestore()

    // Put these in Assets as images
    private let options = [
        "bg_default",
        "bg_1",
        "bg_2",
        "bg_3"
    ]

    init(schoolId: String, currentValue: String, onSaved: @escaping (String) -> Void) {
        self.schoolId = schoolId
        self.currentValue = currentValue
        self.onSaved = onSaved
        _selected = State(initialValue: currentValue)
    }

    var body: some View {
        List {
            ForEach(options, id: \.self) { name in
                Button {
                    selected = name
                } label: {
                    HStack {
                        Text(name)
                        Spacer()
                        if selected == name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .navigationTitle("Home Background")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
        }
    }

    private func save() {
        db.collection("schools").document(schoolId).setData([
            "homeBackground": selected
        ], merge: true)

        onSaved(selected)
        dismiss()
    }
}
