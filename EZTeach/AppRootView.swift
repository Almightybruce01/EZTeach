//
//  AppRootView.swift
//  EZTeach
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct AppRootView: View {
    @State private var showSplash = true
    @State private var isLoggedIn = Auth.auth().currentUser != nil
    @State private var isStudent = false
    @State private var roleResolved = false
    @State private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if isLoggedIn && roleResolved {
                if isStudent {
                    StudentPortalView()
                } else {
                    MainContainerView()
                }
            } else if !isLoggedIn {
                AuthView()
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showSplash = false }
            }

            authListener = Auth.auth().addStateDidChangeListener { _, user in
                let nowLoggedIn = (user != nil)
                isLoggedIn = nowLoggedIn
                if nowLoggedIn {
                    roleResolved = false
                    resolveRole()
                } else {
                    roleResolved = false
                    isStudent = false
                }
            }
        }
        .onChange(of: isLoggedIn) { _, nowLoggedIn in
            if nowLoggedIn && !roleResolved {
                resolveRole()
            }
        }
        .onDisappear {
            if let listener = authListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
    }

    /// Students: users/uid with role "student" OR students/uid exists (legacy).
    /// Check both so students always get StudentPortalView.
    private func resolveRole() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { userSnap, _ in
            let role = (userSnap?.data()?["role"] as? String) ?? ""
            if role == "student" {
                DispatchQueue.main.async {
                    isStudent = true
                    roleResolved = true
                }
                return
            }
            if userSnap?.exists == true {
                DispatchQueue.main.async {
                    isStudent = false
                    roleResolved = true
                }
                return
            }
            db.collection("students").document(uid).getDocument { studentSnap, _ in
                let studentExists = studentSnap?.exists == true
                if studentExists {
                    Functions.functions().httpsCallable("ensureStudentUserDoc").call { _, _ in }
                }
                DispatchQueue.main.async {
                    isStudent = studentExists
                    roleResolved = true
                }
            }
        }
    }
}
