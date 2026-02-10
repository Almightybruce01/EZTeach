//
//  AddAnnouncementView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import UniformTypeIdentifiers

struct AddAnnouncementView: View {

    @Environment(\.dismiss) private var dismiss

    let schoolId: String
    let userRole: String
    let userName: String

    @State private var title = ""
    @State private var message = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var attachmentUrl: String?
    @State private var showCamera = false
    @State private var cameraImageData: Data?
    @State private var showFilePicker = false
    @State private var isPosting = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    init(schoolId: String, userRole: String = "school", userName: String = "") {
        self.schoolId = schoolId
        self.userRole = userRole
        self.userName = userName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New Announcement") {
                    TextField("Title", text: $title)
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(4...10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Attach photo (optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                attachmentOption(icon: "photo.on.rectangle.angled", title: "Photos")
                            }
                            .onChange(of: selectedPhotoItem) { _, item in
                                Task { await uploadAttachment(item) }
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
                            Button {
                                showFilePicker = true
                            } label: {
                                attachmentOption(icon: "icloud.fill", title: "Drive")
                            }
                        }
                        if attachmentUrl != nil {
                            Text("Photo attached")
                                .font(.caption)
                                .foregroundColor(EZTeachColors.success)
                        }
                    }
                }

                // Preview of how it will look
                Section("Preview") {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(previewColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: previewIcon)
                                    .font(.system(size: 12))
                                    .foregroundColor(previewColor)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(previewRoleLabel)
                                .font(.caption2.bold())
                                .foregroundColor(previewColor)
                            Text(userName.isEmpty ? "You" : userName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button {
                    post()
                } label: {
                    if isPosting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Post Announcement")
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
            }
            .navigationTitle("Announcement")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
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

    // MARK: - Preview helpers
    private var previewColor: Color {
        switch userRole {
        case "school":   return Color(red: 0.15, green: 0.22, blue: 0.45)
        case "teacher":  return Color(red: 0.13, green: 0.59, blue: 0.53)
        case "district": return Color(red: 0.55, green: 0.22, blue: 0.67)
        default:         return Color(red: 0.45, green: 0.45, blue: 0.50)
        }
    }

    private var previewIcon: String {
        switch userRole {
        case "school":   return "megaphone.fill"
        case "teacher":  return "person.fill"
        case "district": return "building.columns.fill"
        default:         return "bell.fill"
        }
    }

    private var previewRoleLabel: String {
        switch userRole {
        case "school":   return "Principal"
        case "teacher":  return "Teacher"
        case "district": return "District"
        default:         return "Staff"
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

    private func uploadAttachment(_ item: PhotosPickerItem?) async {
        guard let item else { return }
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
        do {
            let ref = storage.reference().child("documents/\(schoolId)/announcement_\(UUID().uuidString.prefix(8)).jpg")
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            await MainActor.run { attachmentUrl = url.absoluteString }
        } catch { }
    }

    private func post() {
        isPosting = true

        // Resolve the author name if not provided
        let resolvedName: String
        if !userName.isEmpty {
            resolvedName = userName
        } else {
            resolvedName = Auth.auth().currentUser?.displayName ?? "Staff"
        }

        var data: [String: Any] = [
            "schoolId": schoolId,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "body": message.trimmingCharacters(in: .whitespacesAndNewlines),
            "isActive": true,
            "teachersOnly": false,
            "authorRole": userRole,
            "authorName": resolvedName,
            "authorUid": Auth.auth().currentUser?.uid ?? "",
            "createdAt": Timestamp()
        ]
        if let url = attachmentUrl {
            data["attachmentUrl"] = url
        }
        db.collection("announcements").addDocument(data: data) { _ in
            isPosting = false
            dismiss()
        }
    }
}
