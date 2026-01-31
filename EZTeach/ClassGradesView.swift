//
//  ClassGradesView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-17.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClassGradesView: View {

    let classModel: SchoolClass

    @State private var rows: [Row] = []
    @State private var canEdit = false

    private let db = Firestore.firestore()

    // MARK: - Models
    struct Row: Identifiable {
        let id: String          // studentId
        let name: String
        var finalOverride: String
        var assignments: [Assignment]
    }

    struct Assignment: Identifiable {
        let id = UUID()
        var name: String
        var percent: String
    }

    // MARK: - UI
    var body: some View {
        List {
            ForEach($rows) { $row in
                Section(row.name) {

                    TextField(
                        "Final Grade Override",
                        text: $row.finalOverride
                    )
                    .keyboardType(.decimalPad)
                    .disabled(!canEdit)

                    ForEach($row.assignments) { $a in
                        HStack {
                            TextField("Assignment", text: $a.name)

                            TextField("%", text: $a.percent)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                        }
                        .disabled(!canEdit)
                    }

                    if canEdit {
                        Button("Add Assignment") {
                            row.assignments.append(
                                Assignment(name: "", percent: "")
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Grades")
        .toolbar {
            if canEdit {
                Button("Save") {
                    saveAll()
                }
            }
        }
        .onAppear {
            checkPermissions()
            loadStudentsAndGrades()
        }
    }

    // MARK: - Permissions
    private func checkPermissions() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            let role = snap?.data()?["role"] as? String ?? ""

            if role == "school" {
                canEdit = true
            } else if role == "teacher" {
                canEdit = classModel.teacherIds.contains(uid)
            } else {
                canEdit = false
            }
        }
    }

    // MARK: - Load students + grades
    private func loadStudentsAndGrades() {
        db.collection("classEnrollments")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in

                let studentIds = snap?.documents.compactMap {
                    $0["studentId"] as? String
                } ?? []

                guard !studentIds.isEmpty else {
                    rows = []
                    return
                }

                db.collection("students")
                    .whereField(FieldPath.documentID(), in: studentIds)
                    .getDocuments { studentSnap, _ in

                        let students = studentSnap?.documents ?? []

                        rows = students.map { doc in
                            let d = doc.data()
                            return Row(
                                id: doc.documentID,
                                name: "\(d["firstName"] as? String ?? "") \(d["lastName"] as? String ?? "")",
                                finalOverride: "",
                                assignments: []
                            )
                        }

                        loadExistingGrades()
                    }
            }
    }

    private func loadExistingGrades() {
        db.collection("classGrades")
            .whereField("classId", isEqualTo: classModel.id)
            .getDocuments { snap, _ in

                let docs = snap?.documents ?? []

                for doc in docs {
                    let d = doc.data()
                    let studentId = d["studentId"] as? String ?? ""

                    guard let index = rows.firstIndex(where: { $0.id == studentId }) else {
                        continue
                    }

                    if let override = d["finalOverride"] as? Double {
                        rows[index].finalOverride = String(override)
                    }

                    let assigns = d["assignments"] as? [[String: Any]] ?? []
                    rows[index].assignments = assigns.map {
                        Assignment(
                            name: $0["name"] as? String ?? "",
                            percent: String($0["percent"] as? Double ?? 0)
                        )
                    }
                }
            }
    }

    // MARK: - Save
    private func saveAll() {
        for row in rows {

            let assignmentData = row.assignments.compactMap { a -> [String: Any]? in
                guard let percent = Double(a.percent), !a.name.isEmpty else {
                    return nil
                }
                return [
                    "name": a.name,
                    "percent": percent
                ]
            }

            var data: [String: Any] = [
                "classId": classModel.id,
                "studentId": row.id,
                "assignments": assignmentData,
                "updatedAt": Timestamp()
            ]
            
            if let finalOverride = Double(row.finalOverride) {
                data["finalOverride"] = finalOverride
            }

            db.collection("classGrades")
                .document("\(classModel.id)_\(row.id)")
                .setData(data, merge: true)
        }
    }
}
