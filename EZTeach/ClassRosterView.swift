//
//  ClassRosterView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-16.
//

import SwiftUI
import FirebaseFirestore

struct ClassRosterView: View {

    let classModel: SchoolClass

    @State private var students: [Student] = []
    @State private var searchText = ""
    @State private var showAddStudent = false

    private let db = Firestore.firestore()

    private var filteredStudents: [Student] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return students }
        return students.filter {
            $0.fullName.localizedCaseInsensitiveContains(q) ||
            $0.firstName.localizedCaseInsensitiveContains(q) ||
            $0.lastName.localizedCaseInsensitiveContains(q) ||
            $0.studentCode.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        List {
            if students.isEmpty {
                Text("No students in this class yet.")
                    .foregroundColor(.secondary)
            } else if filteredStudents.isEmpty {
                Text("No students match \"\(searchText)\"")
                    .foregroundColor(.secondary)
            } else {
                ForEach(filteredStudents) { student in
                    NavigationLink {
                        StudentProfileView(student: student)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(student.name)
                                    .font(.subheadline.weight(.medium))
                                Text("Student ID: \(student.studentCode)")
                                    .font(.caption.monospaced())
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by name or Student ID")
        .navigationTitle("Roster")
        .toolbar {
            Button {
                showAddStudent = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAddStudent) {
            AddStudentToClassView(classModel: classModel) {
                loadRoster()
            }
        }
        .onAppear(perform: loadRoster)
    }

    private func loadRoster() {
        db.collection("class_rosters")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in

                let studentIds = snap?.documents.compactMap {
                    $0["studentId"] as? String
                } ?? []

                guard !studentIds.isEmpty else {
                    students = []
                    return
                }

                db.collection("students")
                    .whereField(FieldPath.documentID(), in: studentIds)
                    .getDocuments { studentSnap, _ in
                        students = studentSnap?.documents.compactMap { doc in
                            Student.fromDocument(doc)
                        } ?? []
                    }
            }
    }
}
