//
//  AppRootView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI
import FirebaseAuth

struct AppRootView: View {
    @State private var showSplash = true
    @State private var isLoggedIn = Auth.auth().currentUser != nil
    @State private var authListener: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if isLoggedIn {
                MainContainerView()   // ✅ ALWAYS go home
            } else {
                AuthView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showSplash = false }
            }

            authListener = Auth.auth().addStateDidChangeListener { _, user in
                isLoggedIn = (user != nil)
            }
        }
        .onDisappear {
            if let listener = authListener {
                Auth.auth().removeStateDidChangeListener(listener)
            }
        }
    }
}
