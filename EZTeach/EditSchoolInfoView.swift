//
//  EditSchoolInfoView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseFirestore

struct EditSchoolInfoView: View {

    let schoolId: String
    var onSave: () -> Void = {}

    @State private var name = ""
    @State private var overview = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Form {
                Section("School Information") {
                    TextField("School Name", text: $name)
                }

                Section("Overview") {
                    TextField("About your school...", text: $overview, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section("Location") {
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zip)
                }
            }
            .navigationTitle("Edit School Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        db.collection("schools").document(schoolId).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            name = data["name"] as? String ?? ""
            overview = data["overview"] as? String ?? ""
            address = data["address"] as? String ?? ""
            city = data["city"] as? String ?? ""
            state = data["state"] as? String ?? ""
            zip = data["zip"] as? String ?? ""
        }
    }

    private func save() {
        db.collection("schools").document(schoolId).updateData([
            "name": name.trimmingCharacters(in: .whitespaces),
            "overview": overview,
            "address": address,
            "city": city,
            "state": state,
            "zip": zip
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}
