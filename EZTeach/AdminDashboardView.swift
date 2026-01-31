//
//  AdminDashboardView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AdminDashboardView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var schoolCode: String = ""
    @State private var schoolName: String = ""
    @State private var isLoading = true

    let db = Firestore.firestore()

    var body: some View {
        NavigationStack {

            VStack(spacing: 24) {

                // ---------- HEADER ----------
                VStack(spacing: 6) {
                    Text("Admin Dashboard")
                        .font(.largeTitle.bold())

                    if !schoolName.isEmpty {
                        Text(schoolName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    if !schoolCode.isEmpty {
                        Text("School Code: \(schoolCode)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top)

                Divider()

                // ---------- ADMIN ACTIONS ----------
                VStack(spacing: 14) {

                    adminNav("Manage Teachers") {
                        ManageTeachersView()
                    }

                    adminNav("Manage Classes") {
                        ManageClassesView()
                    }

                    adminNav("Manage Students") {
                        ManageStudentsView()
                    }

                    adminNav("School Settings") {
                        SchoolSettingsView()
                    }
                }

                Spacer()

                Divider()

                // ---------- SIGN OUT ----------
                Button(role: .destructive) {
                    try? Auth.auth().signOut()
                    dismiss()
                } label: {
                    Text("Sign Out")
                        .font(.headline)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // ✅ GUARANTEED WORKING BACK BUTTON
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .onAppear(perform: loadSchool)
    }

    // MARK: - LOAD ACTIVE SCHOOL
    func loadSchool() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        db.collection("users").document(uid).getDocument { userSnap, _ in
            guard
                let userData = userSnap?.data(),
                let schoolId = userData["activeSchoolId"] as? String
            else {
                isLoading = false
                return
            }

            db.collection("schools").document(schoolId).getDocument { schoolSnap, _ in
                let school = schoolSnap?.data()
                schoolCode = school?["schoolCode"] as? String ?? ""
                schoolName = school?["name"] as? String ?? ""
                isLoading = false
            }
        }
    }

    // MARK: - BUTTON UI
    func adminNav<Destination: View>(
        _ title: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .font(.headline)
                .cornerRadius(14)
        }
    }
}
