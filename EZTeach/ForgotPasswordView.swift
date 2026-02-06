//
//  ForgotPasswordView.swift
//  EZTeach
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    let prefilledEmail: String
    @State private var email: String
    @State private var isLoading = false

    init(prefilledEmail: String = "") {
        self.prefilledEmail = prefilledEmail
        _email = State(initialValue: prefilledEmail)
    }

    @State private var errorMessage = ""
    @State private var resetEmailSent = false
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 48))
                        .foregroundColor(EZTeachColors.accent)
                        .padding(.top, 32)

                    Text("Reset your password")
                        .font(.title2.bold())

                    Text("Enter the email address for your account. We'll send you a link to create a new password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)

                        TextField("your@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($isEmailFocused)
                            .padding()
                            .background(EZTeachColors.secondaryBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isEmailFocused ? EZTeachColors.accent : Color.clear, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal)

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

                    Button {
                        sendPasswordReset()
                    } label: {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isLoading ? "Sending..." : "Send Reset Link")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canSend ? EZTeachColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(canSend ? .white : .secondary)
                        .cornerRadius(16)
                    }
                    .disabled(!canSend || isLoading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer(minLength: 24)
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(EZTeachColors.accent)
                }
            }
            .alert("Check Your Email", isPresented: $resetEmailSent) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("We've sent a password reset link to \(email). Open the email and tap the link to set a new password. The link may take a few minutes to arrive.")
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            isEmailFocused = true
        }
    }

    private var canSend: Bool {
        isValidEmail(email)
    }

    private func isValidEmail(_ str: String) -> Bool {
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let regex = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }

    private func sendPasswordReset() {
        guard canSend else { return }

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        isLoading = true
        errorMessage = ""

        Auth.auth().sendPasswordReset(withEmail: trimmedEmail) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = friendlyResetError(error)
                } else {
                    resetEmailSent = true
                }
            }
        }
    }

    private func friendlyResetError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case 17010: return "This user account has been disabled."
        case 17011: return "No account found with this email address."
        case 17020: return "Network error. Please check your connection and try again."
        case 17026: return "This operation requires recent login. Please sign in again first."
        default: return error.localizedDescription
        }
    }
}
