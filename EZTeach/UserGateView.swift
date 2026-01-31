//
//  UserGateView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserGateView: View {

    @State private var isLoading = true
    @State private var role: String = ""

    let db = Firestore.firestore()

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            }
            // 🏫 SCHOOL ADMIN
            else if role == "school" {
                AdminDashboardView()
            }
            // 👩‍🏫 TEACHER / SUB (ALWAYS ALLOWED IN APP)
            else {
                MainContainerView()
            }
        }
        .onAppear(perform: loadUser)
    }

    func loadUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        db.collection("users").document(uid).getDocument { snap, _ in
            role = snap?.data()?["role"] as? String ?? "teacher"
            isLoading = false
        }
    }
}
