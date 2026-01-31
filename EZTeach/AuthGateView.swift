//
//  AuthGateView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AuthGateView: View {

    @State private var showSplash = true
    @State private var isLoggedIn = Auth.auth().currentUser != nil

    let db = Firestore.firestore()

    var body: some View {
        ZStack {
            // Main content (ready behind splash)
            Group {
                if isLoggedIn {
                    UserGateView()
                } else {
                    AuthView()
                }
            }
            
            // Splash overlay
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Splash animation completes at ~1.6s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showSplash = false
                }
            }

            _ = Auth.auth().addStateDidChangeListener { _, user in
                isLoggedIn = user != nil
            }
        }
    }
}
