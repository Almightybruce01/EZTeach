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
    /// The role of the person editing: "teacher", "school", "district"
    var editorRole: String = "teacher"

    @State private var name: String
    @State private var grade: Int
    @State private var classType: SchoolClass.ClassType
    @State private var subjectType: SchoolClass.SubjectType
    @State private var period: String
    @State private var scheduleDay: String
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss

    let db = Firestore.firestore()

    init(classModel: SchoolClass, editorRole: String = "teacher") {
        self.classModel = classModel
        self.editorRole = editorRole
        _name = State(initialValue: classModel.name)
        _grade = State(initialValue: classModel.grade)
        _classType = State(initialValue: classModel.classType)
        _subjectType = State(initialValue: classModel.subjectType)
        _period = State(initialValue: classModel.period != nil ? "\(classModel.period!)" : "")
        _scheduleDay = State(initialValue: classModel.scheduleDay ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Class Details") {
                    TextField("Class Name", text: $name)

                    Picker("Grade Level", selection: $grade) {
                        ForEach(GradeUtils.allGrades, id: \.self) { g in
                            Text(GradeUtils.label(g)).tag(g)
                        }
                    }

                    Picker("Class Type", selection: $classType) {
                        ForEach(SchoolClass.ClassType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Subject", selection: $subjectType) {
                        ForEach(SchoolClass.SubjectType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }

                Section("Schedule (Optional)") {
                    TextField("Period (e.g. 1, 2, 3)", text: $period)
                        .keyboardType(.numberPad)
                    TextField("Schedule Day (e.g. A Day, B Day)", text: $scheduleDay)
                }

                if editorRole == "school" || editorRole == "district" {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Admin Note", systemImage: "shield.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(EZTeachColors.accent)
                            Text("As a \(editorRole == "district" ? "district admin" : "school admin"), changing the grade level will reassign this class and its roster to the new grade.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    func save() {
        isSaving = true
        var updates: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "grade": grade,
            "classType": classType.rawValue,
            "subjectType": subjectType.rawValue
        ]

        if let p = Int(period) {
            updates["period"] = p
        } else {
            updates["period"] = FieldValue.delete()
        }

        let trimDay = scheduleDay.trimmingCharacters(in: .whitespaces)
        if !trimDay.isEmpty {
            updates["scheduleDay"] = trimDay
        } else {
            updates["scheduleDay"] = FieldValue.delete()
        }

        db.collection("classes").document(classModel.id).updateData(updates) { error in
            isSaving = false
            if error == nil {
                dismiss()
            }
        }
    }
}
