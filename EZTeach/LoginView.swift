//
//  LoginView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showForgotPassword = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image("EZTeachLogoPolished.jpg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EZTeachColors.accent.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("Welcome Back")
                        .font(.largeTitle.bold())
                    
                    Text("Sign in to continue to EZTeach")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(focusedField == .email ? EZTeachColors.accent : .secondary)
                                .frame(width: 24)
                            
                            TextField("your@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                        }
                        .padding()
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(focusedField == .email ? EZTeachColors.accent : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(focusedField == .password ? EZTeachColors.accent : .secondary)
                                .frame(width: 24)
                            
                            SecureField("Enter your password", text: $password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                        }
                        .padding()
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(focusedField == .password ? EZTeachColors.accent : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    // Forgot password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(EZTeachColors.accent)
                    }
                    .sheet(isPresented: $showForgotPassword) {
                        ForgotPasswordView(prefilledEmail: email)
                    }
                }
                .padding(.horizontal)
                
                // Error message
                if !errorMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(errorMessage)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(EZTeachColors.error)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Login button
                Button {
                    login()
                } label: {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLoading ? "Signing In..." : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canLogin ? EZTeachColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(canLogin ? .white : .secondary)
                    .cornerRadius(16)
                }
                .disabled(!canLogin || isLoading)
                .padding(.horizontal)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                
                // Create account link
                NavigationLink {
                    CreateAccountView()
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(EZTeachColors.accent)
                    }
                    .font(.subheadline)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(EZTeachColors.background)
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    private func login() {
        guard canLogin else { return }
        
        isLoading = true
        errorMessage = ""
        focusedField = nil
        
        let normalizedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        Auth.auth().signIn(withEmail: normalizedEmail, password: password) { result, error in
            isLoading = false
            
            if let error = error {
                errorMessage = friendlyError(error)
            }
        }
    }
    
    private func friendlyError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case 17009: return "Incorrect password. Please try again."
        case 17011: return "No account found with this email."
        case 17020: return "Network error. Check your connection."
        default: return error.localizedDescription
        }
    }
}
