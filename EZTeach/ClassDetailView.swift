//
//  ClassDetailView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ClassDetailView: View {

    let classModel: SchoolClass

    @State private var canEdit = false
    @State private var showEdit = false

    let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {

            Text(classModel.name)
                .font(.largeTitle.bold())
                .foregroundColor(EZTeachColors.navy)

            HStack(spacing: 8) {
                Text(gradeLabel(classModel.grade))
                    .foregroundColor(.secondary)
                if classModel.classType != .regular {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(classModel.classType.displayName)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // CLASS HOME ACTIONS
            NavigationLink("Roster") {
                ClassRosterView(classModel: classModel)
            }

            NavigationLink("Sub Plan") {
                SubPlanDetailView(title: classModel.name)
            }

            NavigationLink("Grades") {
                StudentGradesView(classModel: classModel)
            }

            Spacer()
        }
        .padding()
        .background(EZTeachColors.background)
        .navigationTitle(classModel.name)
        .toolbar {
            if canEdit {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditClassView(classModel: classModel)
        }
        .onAppear(perform: determineEditAccess)
    }

    // MARK: - Permissions
    private func determineEditAccess() {
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

    private func gradeLabel(_ grade: Int) -> String {
        GradeUtils.label(grade)
    }
}
