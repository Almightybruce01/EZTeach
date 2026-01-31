//
//  EditGradesView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-18.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditGradesView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedGrades: Set<Int> = []
    @State private var schoolId = ""

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            List {
                ForEach(GradeUtils.allGrades, id: \.self) { grade in
                    Button {
                        toggle(grade)
                    } label: {
                        HStack {
                            Text(GradeUtils.label(grade))
                            Spacer()
                            if selectedGrades.contains(grade) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Grades")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear {
                load()
            }
        }
    }

    private func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let sid = snap?.data()?["activeSchoolId"] as? String else { return }
            schoolId = sid

            db.collection("schools").document(sid).getDocument { schoolSnap, _ in
                let grades = schoolSnap?.data()?["grades"] as? [Int] ?? []
                selectedGrades = Set(grades)
            }
        }
    }

    private func toggle(_ grade: Int) {
        if selectedGrades.contains(grade) {
            selectedGrades.remove(grade)
        } else {
            selectedGrades.insert(grade)
        }
    }

    private func save() {
        db.collection("schools")
            .document(schoolId)
            .updateData([
                "grades": selectedGrades.sorted()
            ])
        dismiss()
    }
}
