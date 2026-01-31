//
//  EditClassView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import FirebaseFirestore

struct EditClassView: View {

    let classModel: SchoolClass

    @State private var name: String
    @State private var classType: SchoolClass.ClassType
    @Environment(\.dismiss) private var dismiss

    let db = Firestore.firestore()

    init(classModel: SchoolClass) {
        self.classModel = classModel
        _name = State(initialValue: classModel.name)
        _classType = State(initialValue: classModel.classType)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Class Name", text: $name)
                Picker("Class Type", selection: $classType) {
                    ForEach(SchoolClass.ClassType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                Button("Save Changes") {
                    save()
                }
            }
            .navigationTitle("Edit Class")
        }
    }

    func save() {
        db.collection("classes").document(classModel.id).updateData([
            "name": name,
            "classType": classType.rawValue
        ])
        dismiss()
    }
}
