//
//  GradesListView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GradesListView: View {

    @State private var grades: [Int] = []
    @State private var hasSchool = true
    @State private var activeSchoolId = ""
    @State private var role = ""
    @State private var showEditGrades = false

    private let db = Firestore.firestore()

    var body: some View {
        Group {
            if !hasSchool {
                VStack(spacing: 12) {
                    Text("No grades configured.")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(grades, id: \.self) { grade in
                        NavigationLink {
                            GradeTeachersListView(
                                grade: grade,
                                schoolId: activeSchoolId
                            )
                        } label: {
                            Text(GradeUtils.label(grade))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(EZTeachColors.background)
            }
        }
        .navigationTitle("Grades")
        .toolbar {
            if role == "school" {
                Button {
                    showEditGrades = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditGrades) {
            EditGradesView()
        }
        .onAppear {
            loadUser()
        }
    }

    private func loadUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            role = snap?.data()?["role"] as? String ?? ""

            guard let schoolId = snap?.data()?["activeSchoolId"] as? String else {
                hasSchool = false
                return
            }

            activeSchoolId = schoolId
            loadGrades()
        }
    }

    private func loadGrades() {
        db.collection("schools")
            .document(activeSchoolId)
            .getDocument { snap, _ in
                grades = snap?.data()?["grades"] as? [Int] ?? []
                grades.sort()
            }
    }
}
