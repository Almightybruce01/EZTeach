//
//  ClassesHubView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClassesHubView: View {

    var teacherId: String?   // nil = school / sub

    @State private var classes: [SchoolClass] = []
    let db = Firestore.firestore()

    var body: some View {
        List {
            ForEach(classes) { cls in
                NavigationLink {
                    ClassDetailView(classModel: cls)
                } label: {
                    VStack(alignment: .leading) {
                        Text(cls.name)
                            .font(.headline)
                        Text(gradeLabel(cls.grade))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Classes")
        .onAppear(perform: loadClasses)
    }

    func loadClasses() {
        var query: Query = db.collection("classes")

        if let teacherId {
            query = query.whereField("teacherIds", arrayContains: teacherId)
        }

        query.getDocuments { snap, _ in
            classes = snap?.documents.compactMap { doc in
                let d = doc.data()
                let ct = SchoolClass.ClassType(rawValue: d["classType"] as? String ?? "regular") ?? .regular
                return SchoolClass(
                    id: doc.documentID,
                    name: d["name"] as? String ?? "",
                    grade: d["grade"] as? Int ?? 0,
                    schoolId: d["schoolId"] as? String ?? "",
                    teacherIds: d["teacherIds"] as? [String] ?? [],
                    classType: ct
                )
            } ?? []
        }
    }

    func gradeLabel(_ grade: Int) -> String {
        switch grade {
        case 0: return "Pre‑K"
        case 1: return "Kindergarten"
        case 2: return "1st Grade"
        case 3: return "2nd Grade"
        default: return "Grade \(grade - 1)"
        }
    }
}
