//
//  AddTeacherToGradeView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-18.
//

import SwiftUI
import FirebaseFirestore

struct AddTeacherToGradeView: View {

    let grade: Int
    let schoolId: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var teachers: [Teacher] = []
    @State private var searchText = ""

    private let db = Firestore.firestore()

    /// Teachers not yet assigned to this grade
    private var availableTeachers: [Teacher] {
        teachers.filter { !$0.grades.contains(grade) }
    }

    private var filteredTeachers: [Teacher] {
        let available = availableTeachers
        if searchText.isEmpty { return available }
        let q = searchText.lowercased()
        return available.filter {
            $0.firstName.lowercased().contains(q) ||
            $0.lastName.lowercased().contains(q) ||
            $0.displayName.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background
                    .ignoresSafeArea()

                List {
                    if filteredTeachers.isEmpty && !searchText.isEmpty {
                        Text("No teachers found")
                            .foregroundColor(.secondary)
                    } else if availableTeachers.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("All teachers are already assigned to this grade")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        ForEach(filteredTeachers.sorted { $0.lastName < $1.lastName }) { teacher in
                            Button {
                                assign(teacher)
                            } label: {
                                HStack(spacing: 12) {
                                    // Teacher avatar
                                    Circle()
                                        .fill(EZTeachColors.navy.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(teacher.lastName.prefix(1).uppercased())
                                                .font(.headline)
                                                .foregroundColor(EZTeachColors.navy)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(teacher.formattedName)
                                            .font(.headline)

                                        if !teacher.displayName.isEmpty && teacher.displayName != teacher.fullName {
                                            Text(teacher.displayName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(EZTeachColors.background)
            }
            .searchable(text: $searchText, prompt: "Search teachers")
            .navigationTitle("Add Teacher")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadTeachers)
        }
    }

    private func loadTeachers() {
        db.collection("teachers")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                teachers = snap?.documents.map { doc in
                    let d = doc.data()
                    return Teacher(
                        id: doc.documentID,
                        firstName: d["firstName"] as? String ?? "",
                        lastName: d["lastName"] as? String ?? "",
                        displayName: d["displayName"] as? String ?? "",
                        schoolId: schoolId,
                        userId: d["userId"] as? String ?? "",
                        grades: d["grades"] as? [Int] ?? []
                    )
                } ?? []
            }
    }

    private func assign(_ teacher: Teacher) {
        var updatedGrades = teacher.grades
        guard !updatedGrades.contains(grade) else { return }

        updatedGrades.append(grade)

        db.collection("teachers")
            .document(teacher.id)
            .updateData([
                "grades": updatedGrades
            ])

        onSave()
        dismiss()
    }
}
