//
//  EditHomepageView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import UIKit
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import UniformTypeIdentifiers

struct EditHomepageView: View {

    let schoolId: String
    let currentLogoUrl: String
    let currentWelcomeMessage: String

    @State private var logoUrl: String
    @State private var welcomeMessage: String
    @State private var isSaving = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraImageData: Data?
    @State private var showFilePicker = false
    @State private var isUploadingPhoto = false

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    init(schoolId: String, currentLogoUrl: String, currentWelcomeMessage: String) {
        self.schoolId = schoolId
        self.currentLogoUrl = currentLogoUrl
        self.currentWelcomeMessage = currentWelcomeMessage
        _logoUrl = State(initialValue: currentLogoUrl)
        _welcomeMessage = State(initialValue: currentWelcomeMessage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        logoPreview
                            .frame(width: 100, height: 100)

                        Text("Logo Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Section("School Logo") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add from")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                attachmentOption(icon: "photo.on.rectangle.angled", title: "Photos")
                            }
                            .onChange(of: selectedPhotoItem) { _, item in
                                Task { await uploadSelectedPhoto(item) }
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

                        TextField("Or paste image URL", text: $logoUrl)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)

                        Text("Photos, Camera, Files, or Drive—or paste a URL. Square images work best.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Welcome Message") {
                    TextField("Welcome message...", text: $welcomeMessage, axis: .vertical)
                        .lineLimit(3...6)

                    Text("This message will be displayed prominently on your homepage for all users.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tips", systemImage: "lightbulb.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)

                        Text("• Keep your welcome message short and friendly")
                            .font(.caption)
                        Text("• Use a high-quality logo image (PNG or JPG)")
                            .font(.caption)
                        Text("• Square images work best for the circular display")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Homepage")
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(EZTeachColors.secondaryBackground)
        .foregroundColor(EZTeachColors.accent)
        .cornerRadius(12)
    }

    private var logoPreview: some View {
        Group {
            if let url = URL(string: logoUrl), !logoUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        placeholderLogo
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderLogo
                    }
                }
            } else {
                placeholderLogo
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(EZTeachColors.navy.opacity(0.3), lineWidth: 3)
        )
    }

    private var placeholderLogo: some View {
        ZStack {
            Circle()
                .fill(EZTeachColors.cardFill)
            Image(systemName: "building.columns.fill")
                .font(.system(size: 36))
                .foregroundColor(EZTeachColors.navy)
        }
    }

    private func uploadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploadingPhoto = true
        defer { Task { @MainActor in isUploadingPhoto = false } }
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
        isUploadingPhoto = true
        defer { Task { @MainActor in isUploadingPhoto = false } }
        do {
            let fileName = "logo_\(UUID().uuidString.prefix(8)).jpg"
            let ref = storage.reference().child("schoolLogos/\(schoolId)/\(fileName)")
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            await MainActor.run { logoUrl = url.absoluteString }
        } catch {
            // Silent fail; user can retry
        }
    }

    private func save() {
        isSaving = true

        db.collection("schools").document(schoolId).updateData([
            "logoUrl": logoUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            "welcomeMessage": welcomeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        ]) { error in
            isSaving = false
            if error == nil {
                dismiss()
            }
        }
    }
}
