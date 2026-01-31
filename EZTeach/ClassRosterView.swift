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
    @State private var showAddStudent = false

    private let db = Firestore.firestore()

    var body: some View {
        List {
            if students.isEmpty {
                Text("No students in this class yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(students) { student in
                    NavigationLink {
                        StudentProfileView(student: student)
                    } label: {
                        Text(student.name)
                    }
                }
            }
        }
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
