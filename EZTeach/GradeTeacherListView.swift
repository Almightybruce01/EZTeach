//
//  GradeTeacherListView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GradeTeachersListView: View {

    let grade: Int
    let schoolId: String

    @State private var teachers: [Teacher] = []
    @State private var role = ""
    @State private var showAddTeacher = false

    private let db = Firestore.firestore()

    var body: some View {
        List {
            if teachers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No teachers assigned to \(GradeUtils.label(grade))")
                        .foregroundColor(.secondary)
                    if role == "school" {
                        Text("Tap + to add teachers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .listRowBackground(Color.clear)
            } else {
                ForEach(teachers.sorted { $0.lastName < $1.lastName }) { teacher in
                    NavigationLink {
                        TeacherPortalView(teacher: teacher, viewerRole: role)
                    } label: {
                        HStack(spacing: 12) {
                            // Teacher avatar
                            Circle()
                                .fill(EZTeachColors.navy.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(teacher.lastName.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundColor(EZTeachColors.navy)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                // Last Name, First Name format
                                Text(teacher.formattedName)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if !teacher.displayName.isEmpty && teacher.displayName != teacher.fullName {
                                    Text(teacher.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(GradeUtils.label(grade))
        .toolbar {
            if role == "school" {
                Button {
                    showAddTeacher = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTeacher) {
            AddTeacherToGradeView(
                grade: grade,
                schoolId: schoolId
            ) {
                loadTeachers()
            }
        }
        .onAppear {
            loadRole()
            loadTeachers()
        }
    }

    private func loadRole() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snap, _ in
            role = snap?.data()?["role"] as? String ?? ""
        }
    }

    private func loadTeachers() {
        db.collection("teachers")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("grades", arrayContains: grade)
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
}
