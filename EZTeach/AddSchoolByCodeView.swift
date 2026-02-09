//
//  AddSchoolByCodeView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddSchoolByCodeView: View {

    var onSuccess: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Two-step: 1) select school from list, 2) verify with code
    @State private var selectedSchoolId = ""
    @State private var selectedSchoolName = ""
    @State private var selectedSchoolCode = ""
    @State private var showSchoolPicker = false
    
    @State private var enteredCode = ""
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

                        // School selection
                        schoolSelectionSection
                        
                        // Code verification (only if school selected)
                        if !selectedSchoolId.isEmpty {
                            codeInputSection
                        }

                        // Messages
                        messagesSection

                        // Submit button
                        if !selectedSchoolId.isEmpty {
                            submitButton
                        }

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
            .sheet(isPresented: $showSchoolPicker) {
                SearchableSchoolPicker(
                    selectedSchoolId: $selectedSchoolId,
                    isPresented: $showSchoolPicker,
                    requireCodeVerification: false // We handle code verification ourselves
                ) { school in
                    selectedSchoolName = school.name
                    selectedSchoolCode = school.code
                    // Focus on code input after school selection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isCodeFocused = true
                    }
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

                Image(systemName: "building.2.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(EZTeachColors.accentGradient)
            }

            VStack(spacing: 8) {
                Text("Join a School")
                    .font(.title2.bold())

                Text("Search for your school, then enter the school code from your administrator to join.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - School Selection Section
    private var schoolSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 1: Select Your School")
                .font(.headline)
            
            Button {
                showSchoolPicker = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(EZTeachColors.brightTeal.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: selectedSchoolId.isEmpty ? "magnifyingglass" : "building.2.fill")
                            .foregroundColor(EZTeachColors.brightTeal)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedSchoolId.isEmpty ? "Search Schools" : selectedSchoolName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Text(selectedSchoolId.isEmpty ? "Tap to find your school" : "Tap to change")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if selectedSchoolId.isEmpty {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedSchoolId.isEmpty ? EZTeachColors.cardStroke : Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Code Input Section
    private var codeInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 2: Enter School Code")
                .font(.headline)
            
            Text("Get this code from your school administrator")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    codeDigitBox(index: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Hidden TextField for input
            TextField("", text: $enteredCode)
                .keyboardType(.default)
                .textInputAutocapitalization(.characters)
                .focused($isCodeFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: enteredCode) { _, newValue in
                    enteredCode = String(newValue.uppercased().prefix(6))
                }
        }
        .onTapGesture {
            isCodeFocused = true
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func codeDigitBox(index: Int) -> some View {
        let digit = index < enteredCode.count ? String(enteredCode[enteredCode.index(enteredCode.startIndex, offsetBy: index)]) : ""
        let isCurrent = index == enteredCode.count && isCodeFocused

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(EZTeachColors.secondaryBackground)
                .frame(width: 48, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? EZTeachColors.accent : EZTeachColors.cardStroke, lineWidth: isCurrent ? 2 : 1)
                )

            Text(digit)
                .font(.title.bold().monospaced())
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
                Text(loading ? "Joining School..." : "Join School")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                enteredCode.count == 6 && !loading
                ? EZTeachColors.accentGradient
                : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(enteredCode.count == 6 && !loading ? .white : .secondary)
            .cornerRadius(14)
        }
        .disabled(enteredCode.count != 6 || loading)
    }

    // MARK: - Add Action
    @MainActor
    private func add() async {
        guard Auth.auth().currentUser != nil else {
            errorMessage = "You must be logged in."
            return
        }
        
        guard !selectedSchoolId.isEmpty else {
            errorMessage = "Please select a school first."
            return
        }

        loading = true
        errorMessage = ""
        successMessage = nil

        do {
            // Fetch the school document directly for reliable code verification
            let schoolDoc = try await Firestore.firestore()
                .collection("schools").document(selectedSchoolId).getDocument()

            guard let schoolData = schoolDoc.data() else {
                errorMessage = "School not found. Please try again."
                loading = false
                return
            }

            let actualCode = (schoolData["schoolCode"] as? String ?? "")
                .trimmingCharacters(in: .whitespaces).uppercased()
            let typedCode = enteredCode.trimmingCharacters(in: .whitespaces).uppercased()

            if typedCode != actualCode {
                errorMessage = "Invalid school code. Please check with your administrator."
                loading = false
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                return
            }

            // Code verified — join the school
            try await FirestoreService.shared.joinSchoolById(selectedSchoolId)

            successMessage = "Successfully joined \(selectedSchoolName)!"

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            try? await Task.sleep(nanoseconds: 800_000_000)
            onSuccess?()
            dismiss()

        } catch let err as NSError {
            errorMessage = err.localizedDescription

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }

        loading = false
    }
}
