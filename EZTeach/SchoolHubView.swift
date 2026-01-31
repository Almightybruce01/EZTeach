//
//  SchoolHubView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SchoolHubView: View {
    
    @State private var schoolId = ""
    @State private var userRole = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink("School Overview") {
                    SchoolOverviewView()
                }

                NavigationLink("Office Info") {
                    OfficeInfoView()
                }

                NavigationLink("Policies & Emergency") {
                    SchoolPoliciesView()
                }

                if !schoolId.isEmpty {
                    NavigationLink("Bell Schedule") {
                        BellScheduleView(schoolId: schoolId, userRole: userRole)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("School")
        .onAppear(perform: loadUserData)
    }
    
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            schoolId = data["activeSchoolId"] as? String ?? ""
            userRole = data["role"] as? String ?? ""
        }
    }
}
