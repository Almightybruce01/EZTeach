//
//  AuthView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI

struct AuthView: View {
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        EZTeachColors.navy,
                        EZTeachColors.navyLight,
                        Color(red: 30/255, green: 64/255, blue: 130/255)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                // Decorative elements
                GeometryReader { geo in
                    Circle()
                        .fill(.white.opacity(0.05))
                        .frame(width: geo.size.width * 0.8)
                        .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.1)
                    
                    Circle()
                        .fill(.white.opacity(0.03))
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.7)
                }
                
                // Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo section
                    VStack(spacing: 24) {
                        // Logo with glow
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 160, height: 160)
                                .blur(radius: 30)
                            
                            Image("EZTeachLogoPolished.jpg")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                        }
                        
                        // App name and tagline
                        VStack(spacing: 8) {
                            Text("EZTeach")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("School Management Made Simple")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Feature highlights
                    VStack(spacing: 16) {
                        featureRow(icon: "graduationcap.fill", text: "Manage grades & attendance")
                        featureRow(icon: "person.2.fill", text: "Connect teachers, parents & subs")
                        featureRow(icon: "bell.badge.fill", text: "Real-time announcements")
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        NavigationLink {
                            LoginView()
                        } label: {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(EZTeachColors.navy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                        }
                        
                        NavigationLink {
                            CreateAccountView()
                        } label: {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(.white.opacity(0.2))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.4), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") { }
                                .font(.caption.weight(.medium))
                            Text("and")
                                .font(.caption)
                            Button("Privacy Policy") { }
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.15))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}
