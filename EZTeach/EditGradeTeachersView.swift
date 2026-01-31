//
//  EditGradeTeachersView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-18.
//

import SwiftUI
import FirebaseFirestore

struct EditGradeTeachersView: View {

    let grade: Int
    let schoolId: String
    let allTeachers: [Teacher]
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<String> = []

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            List {
                ForEach(allTeachers) { teacher in
                    HStack {
                        Text(
                            teacher.displayName.isEmpty
                            ? teacher.fullName
                            : teacher.displayName
                        )
                        Spacer()
                        if selected.contains(teacher.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggle(teacher)
                    }
                }
            }
            .navigationTitle("Edit \(GradeUtils.label(grade))")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear(perform: preload)
        }
    }

    // MARK: - Preload existing assignments
    private func preload() {
        for t in allTeachers {
            if t.grades.contains(grade) {
                selected.insert(t.id)
            }
        }
    }

    private func toggle(_ teacher: Teacher) {
        if selected.contains(teacher.id) {
            selected.remove(teacher.id)
        } else {
            selected.insert(teacher.id)
        }
    }

    // MARK: - Save
    private func save() {
        for teacher in allTeachers {
            var grades = teacher.grades

            if selected.contains(teacher.id) {
                if !grades.contains(grade) {
                    grades.append(grade)
                }
            } else {
                grades.removeAll { $0 == grade }
            }

            db.collection("teachers")
                .document(teacher.id)
                .updateData([
                    "grades": grades
                ])
        }

        onSave()
        dismiss()
    }
}
