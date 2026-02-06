//
//  StudentLoginView.swift
//  EZTeach
//

import SwiftUI
import FirebaseAuth
import FirebaseFunctions

struct StudentLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var studentId = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Field?

    enum Field { case studentId, password }

    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 36) {
                    VStack(spacing: 16) {
                        Image("EZTeachLogoPolished.jpg")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(EZTeachColors.tronCyan.opacity(0.6), lineWidth: 2)
                            )
                            .shadow(color: EZTeachColors.tronCyan.opacity(0.4), radius: 20)
                        
                        Text("STUDENT LOGIN")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [EZTeachColors.tronCyan, EZTeachColors.tronBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: EZTeachColors.tronCyan.opacity(0.6), radius: 8)
                        
                        Text("No school code needed. Just your Student ID and password.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 48)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("STUDENT ID")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(EZTeachColors.tronCyan.opacity(0.9))
                        
                        HStack(spacing: 14) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(focusedField == .studentId ? EZTeachColors.tronCyan : .white.opacity(0.5))
                                .font(.title3)
                            TextField("Your 8-character Student ID", text: $studentId)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .studentId)
                                .foregroundColor(.white)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(focusedField == .studentId ? EZTeachColors.tronCyan : Color.white.opacity(0.2), lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("PASSWORD")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(EZTeachColors.tronCyan.opacity(0.9))
                        
                        HStack(spacing: 14) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(focusedField == .password ? EZTeachColors.tronCyan : .white.opacity(0.5))
                                .font(.title3)
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .focused($focusedField, equals: .password)
                            .foregroundColor(.white)
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(EZTeachColors.tronCyan.opacity(0.9))
                                    .font(.body)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(focusedField == .password ? EZTeachColors.tronCyan : Color.white.opacity(0.2), lineWidth: 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                        )
                        
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(EZTeachColors.tronCyan.opacity(0.8))
                            Text("Default password: Student ID + ! (e.g. ABC12345!)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    if !errorMessage.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(EZTeachColors.tronPink.opacity(0.6))
                        .cornerRadius(14)
                    }

                    Button {
                        login()
                    } label: {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(isLoading ? "SIGNING IN..." : "SIGN IN")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: canLogin ? [EZTeachColors.tronCyan, EZTeachColors.tronBlue] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(canLogin ? .black : .white.opacity(0.5))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(canLogin ? EZTeachColors.tronCyan : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: canLogin ? EZTeachColors.tronCyan.opacity(0.5) : .clear, radius: 12)
                    }
                    .disabled(!canLogin || isLoading)

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 28)
            }
        }
        .navigationTitle("Student Login")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canLogin: Bool {
        !studentId.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    private static let studentEmailDomain = "@students.ezteach.app"

    private func login() {
        guard canLogin else { return }
        isLoading = true
        errorMessage = ""
        focusedField = nil
        let code = studentId.trimmingCharacters(in: .whitespaces).uppercased()
        let pwd = password.trimmingCharacters(in: .whitespaces)
        let email = code + Self.studentEmailDomain

        Auth.auth().signIn(withEmail: email, password: pwd) { _, authError in
            if authError == nil {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            let nsErr = authError as NSError?
            if nsErr?.domain == AuthErrorDomain, nsErr?.code == AuthErrorCode.userNotFound.rawValue {
                tryLegacyStudentLogin(code: code, password: pwd)
                return
            }
            DispatchQueue.main.async {
                isLoading = false
                errorMessage = parseAuthError(nsErr) ?? nsErr?.localizedDescription ?? "Sign in failed"
            }
        }
    }

    private func tryLegacyStudentLogin(code: String, password: String) {
        Functions.functions().httpsCallable("studentLogin").call(["studentCode": code, "password": password]) { result, error in
            if let err = error as NSError? {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = parseCallableError(err)
                }
                return
            }
            guard let data = result?.data as? [String: Any], let token = data["token"] as? String else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Could not sign in"
                }
                return
            }
            Auth.auth().signIn(withCustomToken: token) { _, signInError in
                DispatchQueue.main.async {
                    isLoading = false
                    if let e = signInError {
                        errorMessage = e.localizedDescription
                    }
                }
            }
        }
    }

    private func parseAuthError(_ err: NSError?) -> String? {
        guard let e = err, e.domain == AuthErrorDomain else { return nil }
        switch e.code {
        case AuthErrorCode.userNotFound.rawValue: return "Student account not found. Check your Student ID."
        case AuthErrorCode.wrongPassword.rawValue: return "Incorrect password. Default is Student ID + ! (e.g. ABC12345!)"
        case AuthErrorCode.invalidEmail.rawValue: return "Invalid Student ID format."
        default: return e.localizedDescription
        }
    }

    private func parseCallableError(_ err: NSError) -> String {
        if err.localizedDescription.lowercased().contains("internal") || err.localizedDescription.isEmpty {
            switch err.code {
            case 5: return "Student account not found. Check your Student ID."
            case 16: return "Incorrect password. Default is Student ID + ! (e.g. ABC12345!)"
            case 7: return "Access denied. Ask your school to complete setup."
            default: return "Sign in failed. Check your Student ID and password."
            }
        }
        return err.localizedDescription
    }
}
