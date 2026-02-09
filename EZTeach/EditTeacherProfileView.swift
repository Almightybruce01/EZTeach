//
//  EditTeacherProfileView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import UniformTypeIdentifiers

struct EditTeacherProfileView: View {

    let teacherId: String
    let teacherUserId: String  // For Storage path - must match auth.uid
    let currentBio: String
    let currentRoomNumber: String
    let currentOfficeHours: String
    let currentEmail: String
    let currentPhotoUrl: String?
    let currentGrade: Int
    let currentClassName: String
    let onSave: () -> Void

    @State private var bio: String
    @State private var roomNumber: String
    @State private var officeHours: String
    @State private var email: String
    @State private var photoUrl: String
    @State private var selectedGrade: Int
    @State private var className: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImageData: Data?
    @State private var showFilePicker = false
    @State private var isSaving = false
    @State private var gradeError = false

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    init(teacherId: String, teacherUserId: String, currentBio: String, currentRoomNumber: String, currentOfficeHours: String, currentEmail: String, currentPhotoUrl: String? = nil, currentGrade: Int = -1, currentClassName: String = "", onSave: @escaping () -> Void) {
        self.teacherId = teacherId
        self.teacherUserId = teacherUserId
        self.currentBio = currentBio
        self.currentRoomNumber = currentRoomNumber
        self.currentOfficeHours = currentOfficeHours
        self.currentEmail = currentEmail
        self.currentPhotoUrl = currentPhotoUrl
        self.currentGrade = currentGrade
        self.currentClassName = currentClassName
        self.onSave = onSave
        _bio = State(initialValue: currentBio)
        _roomNumber = State(initialValue: currentRoomNumber)
        _officeHours = State(initialValue: currentOfficeHours)
        _email = State(initialValue: currentEmail)
        _photoUrl = State(initialValue: currentPhotoUrl ?? "")
        _selectedGrade = State(initialValue: currentGrade)
        _className = State(initialValue: currentClassName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Photo") {
                    HStack(spacing: 12) {
                        if let url = URL(string: photoUrl), !photoUrl.isEmpty {
                            AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { Color.gray }
                                .frame(width: 60, height: 60).clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(EZTeachColors.navy.opacity(0.3))
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add from")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 10) {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                    attachmentOption(icon: "photo.on.rectangle.angled", title: "Photos")
                                }
                                .onChange(of: selectedPhotoItem) { _, item in
                                    Task { await uploadPhoto(item) }
                                }
                                Button {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        showCamera = true
                                    }
                                } label: {
                                    attachmentOption(icon: "camera.fill", title: "Camera")
                                }
                                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                                Button {
                                    showFilePicker = true
                                } label: {
                                    attachmentOption(icon: "doc.fill", title: "Files")
                                }
                            }
                        }
                    }
                }

                // MARK: - Grade & Classroom (Required)
                Section {
                    Picker("Grade Level", selection: $selectedGrade) {
                        Text("Select a grade…").tag(-1)
                        ForEach(GradeUtils.allGrades, id: \.self) { grade in
                            Text(GradeUtils.label(grade)).tag(grade)
                        }
                    }
                    .onChange(of: selectedGrade) { _, _ in
                        gradeError = false
                    }

                    if gradeError {
                        Text("Please select a grade level.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    TextField("Classroom Name (e.g. Room 204)", text: $className)
                } header: {
                    Text("Grade & Classroom")
                } footer: {
                    Text("Your grade level determines which classroom you manage. Changing your grade will move your classroom to the new grade.")
                }

                Section("About Me") {
                    TextField("Bio / Welcome Message", text: $bio, axis: .vertical)
                        .lineLimit(3...6)

                    Text("Write a short introduction for students and parents.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Contact & Location") {
                    TextField("Room Number", text: $roomNumber)
                    TextField("Office Hours", text: $officeHours)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tips", systemImage: "lightbulb.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)

                        Text("• Your profile is visible to all users at your school")
                            .font(.caption)
                        Text("• Keep your bio friendly and professional")
                            .font(.caption)
                        Text("• Room number helps students find you")
                            .font(.caption)
                        Text("• Grade level is required for classroom assignment")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker(imageData: $cameraImageData)
            }
            .onChange(of: cameraImageData) { _, data in
                guard let data else { return }
                Task { await uploadImageData(data) }
                cameraImageData = nil
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.image, .png, .jpeg, .gif],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        Task { await uploadImageData(data) }
                    }
                case .failure: break
                }
            }
        }
    }

    private func attachmentOption(icon: String, title: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(title)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(EZTeachColors.secondaryBackground)
        .foregroundColor(EZTeachColors.accent)
        .cornerRadius(10)
    }

    private func save() {
        // Validate grade is selected
        if selectedGrade < 0 {
            gradeError = true
            return
        }

        isSaving = true

        var updates: [String: Any] = [
            "bio": bio.trimmingCharacters(in: .whitespacesAndNewlines),
            "roomNumber": roomNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            "officeHours": officeHours.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "grade": selectedGrade,
            "grades": [selectedGrade],
            "className": className.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        if !photoUrl.isEmpty {
            updates["photoUrl"] = photoUrl
        }

        let batch = db.batch()

        // Update teacher document
        let teacherRef = db.collection("teachers").document(teacherId)
        batch.updateData(updates, forDocument: teacherRef)

        // If grade changed, update associated class documents
        if selectedGrade != currentGrade {
            // Also update user doc grades
            if let uid = Auth.auth().currentUser?.uid {
                let userRef = db.collection("users").document(uid)
                batch.updateData(["grade": selectedGrade], forDocument: userRef)
            }
        }

        batch.commit { error in
            if error == nil {
                // Update classes that belong to this teacher to the new grade
                if selectedGrade != currentGrade, let uid = Auth.auth().currentUser?.uid {
                    db.collection("classes")
                        .whereField("teacherIds", arrayContains: uid)
                        .getDocuments { snap, _ in
                            let classBatch = db.batch()
                            for doc in snap?.documents ?? [] {
                                classBatch.updateData([
                                    "grade": selectedGrade
                                ], forDocument: doc.reference)
                            }
                            classBatch.commit()
                        }
                }
                isSaving = false
                onSave()
                dismiss()
            } else {
                isSaving = false
            }
        }
    }

    private func uploadPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let uid = Auth.auth().currentUser?.uid, uid == teacherUserId else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                await MainActor.run { selectedPhotoItem = nil }
                return
            }
            await uploadImageData(data)
            await MainActor.run { selectedPhotoItem = nil }
        } catch {
            await MainActor.run { selectedPhotoItem = nil }
        }
    }

    private func uploadImageData(_ data: Data) async {
        guard let uid = Auth.auth().currentUser?.uid, uid == teacherUserId else { return }
        do {
            let ref = storage.reference().child("teacherPhotos/\(uid)/profile_\(UUID().uuidString.prefix(6)).jpg")
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            await MainActor.run { photoUrl = url.absoluteString }
        } catch { }
    }
}
