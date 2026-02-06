//
//  EditStudentView.swift
//  EZTeach
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

struct EditStudentView: View {
    let student: Student

    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var middleName: String
    @State private var lastName: String
    @State private var notes: String
    @State private var email: String
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChangingPassword = false
    @State private var isResettingToDefault = false
    @State private var passwordError = ""
    @State private var saveError = ""
    @State private var resetSuccess = false

    private let db = Firestore.firestore()

    init(student: Student) {
        self.student = student
        _firstName = State(initialValue: student.firstName)
        _middleName = State(initialValue: student.middleName)
        _lastName = State(initialValue: student.lastName)
        _notes = State(initialValue: student.notes)
        _email = State(initialValue: student.email ?? "")
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("First Name", text: $firstName)
                TextField("Middle Name", text: $middleName)
                TextField("Last Name", text: $lastName)
            }

            Section("Contact") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 120)
            }

            Section {
                if student.usesDefaultPassword {
                    Text("Default password is Student ID + ! (\(student.studentCode)!)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                SecureField("New Password (6+ characters)", text: $newPassword)
                SecureField("Confirm Password", text: $confirmPassword)
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(EZTeachColors.error)
                }
                Button("Change Password") {
                    changePassword()
                }
                .disabled(newPassword.count < 6 || newPassword != confirmPassword || isChangingPassword)
                Button {
                    resetToDefaultPassword()
                } label: {
                    if isResettingToDefault {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.9)
                            Text("Resetting...")
                        }
                    } else {
                        Text("Reset to Default (\(student.studentCode)!)")
                    }
                }
                .disabled(isResettingToDefault || isChangingPassword)
            } header: {
                Text("Change Student Password")
            } footer: {
                Text("Students sign in with Student ID and password (default: Student ID!). Use Reset to Default if a student cannot log in.")
            }

            if !saveError.isEmpty {
                Section {
                    Text(saveError)
                        .foregroundColor(EZTeachColors.error)
                }
            }

            Section {
                Button("Save") {
                    save()
                }
            }
        }
        .navigationTitle("Edit Student")
        .alert("Password Reset", isPresented: $resetSuccess) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Student can now sign in with Student ID: \(student.studentCode) and password: \(student.studentCode)!")
        }
        .onAppear { }
    }

    private func save() {
        db.collection("students").document(student.id).updateData([
            "firstName": firstName.trimmingCharacters(in: .whitespaces),
            "middleName": middleName.trimmingCharacters(in: .whitespaces),
            "lastName": lastName.trimmingCharacters(in: .whitespaces),
            "notes": notes,
            "email": email.trimmingCharacters(in: .whitespaces).isEmpty ? FieldValue.delete() : email.trimmingCharacters(in: .whitespaces).lowercased()
        ]) { error in
            if let e = error {
                saveError = e.localizedDescription
            } else {
                dismiss()
            }
        }
    }

    private func changePassword() {
        guard newPassword.count >= 6, newPassword == confirmPassword else {
            passwordError = "Password must be 6+ characters and match."
            return
        }
        passwordError = ""
        isChangingPassword = true
        Functions.functions().httpsCallable("changeStudentPassword").call([
            "studentId": student.id,
            "newPassword": newPassword
        ]) { _, error in
            isChangingPassword = false
            if let e = error as NSError? {
                passwordError = (e.userInfo["NSLocalizedDescription"] as? String) ?? e.localizedDescription
            } else {
                newPassword = ""
                confirmPassword = ""
            }
        }
    }

    private func resetToDefaultPassword() {
        guard !isResettingToDefault else { return }
        isResettingToDefault = true
        passwordError = ""
        Functions.functions().httpsCallable("resetStudentToDefaultPassword").call([
            "studentId": student.id
        ]) { _, error in
            isResettingToDefault = false
            if let e = error as NSError? {
                passwordError = (e.userInfo["NSLocalizedDescription"] as? String) ?? e.localizedDescription
            } else {
                resetSuccess = true
            }
        }
    }
}
