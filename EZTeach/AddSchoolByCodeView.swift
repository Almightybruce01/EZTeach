//
//  AddSchoolByCodeView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import SwiftUI
import FirebaseAuth

struct AddSchoolByCodeView: View {

    var onSuccess: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var code = ""
    @State private var errorMessage = ""
    @State private var successMessage: String?
    @State private var loading = false

    @FocusState private var isCodeFocused: Bool

    init(onSuccess: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header illustration
                        headerSection

                        // Code input
                        codeInputSection

                        // Messages
                        messagesSection

                        // Submit button
                        submitButton

                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add School")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isCodeFocused = true
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(EZTeachColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 44))
                    .foregroundStyle(EZTeachColors.accentGradient)
            }

            VStack(spacing: 8) {
                Text("Enter School Code")
                    .font(.title2.bold())

                Text("Ask your school administrator for the 6-digit code to join their school.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Code Input Section
    private var codeInputSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    codeDigitBox(index: index)
                }
            }

            // Hidden TextField for input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isCodeFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    code = String(newValue.prefix(6).filter { $0.isNumber })
                }
        }
        .onTapGesture {
            isCodeFocused = true
        }
    }

    private func codeDigitBox(index: Int) -> some View {
        let digit = index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
        let isCurrent = index == code.count && isCodeFocused

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(EZTeachColors.secondaryBackground)
                .frame(width: 48, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? EZTeachColors.accent : EZTeachColors.cardStroke, lineWidth: isCurrent ? 2 : 1)
                )

            Text(digit)
                .font(.title.bold())
                .foregroundColor(.primary)
        }
    }

    // MARK: - Messages Section
    @ViewBuilder
    private var messagesSection: some View {
        if let successMessage {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(EZTeachColors.success)
                Text(successMessage)
                    .foregroundColor(EZTeachColors.success)
            }
            .font(.subheadline.bold())
            .padding()
            .frame(maxWidth: .infinity)
            .background(EZTeachColors.success.opacity(0.1))
            .cornerRadius(12)
        }

        if !errorMessage.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(EZTeachColors.error)
                Text(errorMessage)
                    .foregroundColor(EZTeachColors.error)
            }
            .font(.subheadline.bold())
            .padding()
            .frame(maxWidth: .infinity)
            .background(EZTeachColors.error.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            Task { await add() }
        } label: {
            HStack(spacing: 10) {
                if loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                Text(loading ? "Adding School..." : "Add School")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                code.count == 6 && !loading
                ? EZTeachColors.accentGradient
                : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(code.count == 6 && !loading ? .white : .secondary)
            .cornerRadius(14)
        }
        .disabled(code.count != 6 || loading)
    }

    // MARK: - Add Action
    @MainActor
    private func add() async {
        guard Auth.auth().currentUser != nil else {
            errorMessage = "You must be logged in."
            return
        }

        loading = true
        errorMessage = ""
        successMessage = nil

        do {
            try await FirestoreService.shared.joinSchoolByCode(code)

            successMessage = "School successfully added!"

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            try? await Task.sleep(nanoseconds: 800_000_000)
            onSuccess?()
            dismiss()

        } catch {
            errorMessage = "Invalid school code. Please check and try again."

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }

        loading = false
    }
}
