//
//  TeacherHomeView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// View for when a teacher accesses their own homepage (from their own account)
struct TeacherHomeView: View {

    let teacherId: String

    @State private var teacher: Teacher?
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let teacher = teacher {
                TeacherPortalView(teacher: teacher, viewerRole: "teacher")
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Teacher profile not found")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear(perform: loadTeacher)
        .task {
            await FirestoreService.shared.syncDerivedCollectionsForCurrentUser()
        }
    }

    private func loadTeacher() {
        // Find teacher document by userId
        db.collection("teachers")
            .whereField("userId", isEqualTo: teacherId)
            .limit(to: 1)
            .getDocuments { snap, _ in
                if let doc = snap?.documents.first {
                    let d = doc.data()
                    teacher = Teacher(
                        id: doc.documentID,
                        firstName: d["firstName"] as? String ?? "",
                        lastName: d["lastName"] as? String ?? "",
                        displayName: d["displayName"] as? String ?? "",
                        schoolId: d["schoolId"] as? String ?? "",
                        userId: d["userId"] as? String ?? "",
                        grades: d["grades"] as? [Int] ?? []
                    )
                }
                isLoading = false
            }
    }
}
