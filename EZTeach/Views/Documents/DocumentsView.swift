//
//  DocumentsView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UniformTypeIdentifiers

struct DocumentsView: View {
    
    let schoolId: String
    let userRole: String
    
    @State private var documents: [SchoolDocument] = []
    @State private var selectedCategory: SchoolDocument.DocumentCategory?
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showUpload = false
    @State private var selectedDocument: SchoolDocument?
    
    private let db = Firestore.firestore()
    
    private var filteredDocuments: [SchoolDocument] {
        var result = documents
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        // Filter by access
        if userRole == "sub" {
            result = result.filter { !$0.teachersOnly }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Category filter
                categoryFilter
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredDocuments.isEmpty {
                    emptyState
                } else {
                    documentsList
                }
            }
        }
        .navigationTitle("Documents")
        .toolbar {
            if userRole == "school" || userRole == "teacher" {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showUpload = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showUpload) {
            UploadDocumentView(schoolId: schoolId, userRole: userRole) {
                loadDocuments()
            }
        }
        .sheet(item: $selectedDocument) { document in
            DocumentDetailView(document: document, userRole: userRole) {
                loadDocuments()
            }
        }
        .onAppear(perform: loadDocuments)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search documents...", text: $searchText)
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(label: "All", category: nil)
                ForEach(SchoolDocument.DocumentCategory.allCases, id: \.self) { category in
                    categoryChip(label: category.displayName, category: category)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    private func categoryChip(label: String, category: SchoolDocument.DocumentCategory?) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selectedCategory == category ? EZTeachColors.accent : EZTeachColors.cardFill)
                .foregroundColor(selectedCategory == category ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Documents List
    private var documentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredDocuments) { document in
                    documentRow(document)
                }
            }
            .padding()
        }
    }
    
    private func documentRow(_ document: SchoolDocument) -> some View {
        Button {
            selectedDocument = document
        } label: {
            HStack(spacing: 14) {
                // File icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor(for: document.fileType).opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: document.fileType.iconName)
                        .font(.title2)
                        .foregroundColor(iconColor(for: document.fileType))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(document.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(document.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if document.teachersOnly {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.warning)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func iconColor(for fileType: SchoolDocument.FileType) -> Color {
        switch fileType {
        case .pdf: return .red
        case .doc, .docx: return .blue
        case .xls, .xlsx: return .green
        case .ppt, .pptx: return .orange
        case .image: return .purple
        case .video: return .pink
        case .other: return .gray
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Documents")
                .font(.title2.bold())
            
            Text(searchText.isEmpty ? "Upload documents to share with your school." : "No documents match your search.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if userRole == "school" || userRole == "teacher" {
                Button {
                    showUpload = true
                } label: {
                    Label("Upload Document", systemImage: "plus")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(EZTeachColors.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Load Data
    private func loadDocuments() {
        db.collection("documents")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                documents = snap?.documents.compactMap { SchoolDocument.fromDocument($0) }
                    .sorted { $0.createdAt > $1.createdAt } ?? []
                isLoading = false
            }
    }
}

// MARK: - Upload Document View
struct UploadDocumentView: View {
    
    let schoolId: String
    let userRole: String
    let onUpload: () -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var category: SchoolDocument.DocumentCategory = .resource
    @State private var teachersOnly = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var selectedFileData: Data?
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Document Info") {
                    TextField("Document Name", text: $name)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                    
                    Picker("Category", selection: $category) {
                        ForEach(SchoolDocument.DocumentCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
                
                Section("Access") {
                    Toggle("Teachers Only", isOn: $teachersOnly)
                    
                    if teachersOnly {
                        Text("This document will only be visible to teachers and school admins.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("File") {
                    if let url = selectedFileURL {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(EZTeachColors.accent)
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                            Spacer()
                            Button("Remove") {
                                selectedFileURL = nil
                                selectedFileData = nil
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Button {
                            showFilePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Select File")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if isUploading {
                    Section {
                        VStack(spacing: 8) {
                            ProgressView(value: uploadProgress)
                            Text("\(Int(uploadProgress * 100))% uploaded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        uploadDocument()
                    } label: {
                        HStack {
                            Spacer()
                            if isUploading {
                                ProgressView()
                            }
                            Text(isUploading ? "Uploading..." : "Upload Document")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || selectedFileData == nil || isUploading)
                }
            }
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .plainText, .image, .data],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access this file."
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                selectedFileData = try Data(contentsOf: url)
                selectedFileURL = url
                
                // Auto-fill name if empty
                if name.isEmpty {
                    name = url.deletingPathExtension().lastPathComponent
                }
            } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "File selection failed: \(error.localizedDescription)"
        }
    }
    
    private func uploadDocument() {
        guard let uid = Auth.auth().currentUser?.uid,
              let fileData = selectedFileData,
              let fileURL = selectedFileURL else { return }
        
        isUploading = true
        errorMessage = ""
        
        let fileExtension = fileURL.pathExtension.lowercased()
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let storagePath = "documents/\(schoolId)/\(fileName)"
        
        let storageRef = storage.reference().child(storagePath)
        
        // Determine content type
        let contentType = getContentType(for: fileExtension)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        // Upload file
        let uploadTask = storageRef.putData(fileData, metadata: metadata)
        
        uploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
        
        uploadTask.observe(.success) { _ in
            // Get download URL
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    isUploading = false
                    errorMessage = "Failed to get download URL"
                    return
                }
                
                // Get user name and save document record
                db.collection("users").document(uid).getDocument { snap, _ in
                    let userData = snap?.data() ?? [:]
                    let userName = "\(userData["firstName"] as? String ?? "") \(userData["lastName"] as? String ?? "")"
                    
                    let docData: [String: Any] = [
                        "schoolId": schoolId,
                        "uploadedByUserId": uid,
                        "uploadedByName": userName.trimmingCharacters(in: .whitespaces),
                        "name": name,
                        "description": description,
                        "fileUrl": downloadURL.absoluteString,
                        "storagePath": storagePath,
                        "fileType": fileExtension,
                        "fileSize": Int64(fileData.count),
                        "category": category.rawValue,
                        "isPublic": true,
                        "teachersOnly": teachersOnly,
                        "tags": [],
                        "downloadCount": 0,
                        "createdAt": Timestamp(),
                        "updatedAt": Timestamp()
                    ]
                    
                    db.collection("documents").addDocument(data: docData) { error in
                        isUploading = false
                        if error == nil {
                            onUpload()
                            dismiss()
                        } else {
                            errorMessage = "Failed to save document: \(error?.localizedDescription ?? "")"
                        }
                    }
                }
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            isUploading = false
            errorMessage = snapshot.error?.localizedDescription ?? "Upload failed"
        }
    }
    
    private func getContentType(for ext: String) -> String {
        switch ext {
        case "pdf": return "application/pdf"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt": return "application/vnd.ms-powerpoint"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Document Detail View
struct DocumentDetailView: View {
    
    let document: SchoolDocument
    let userRole: String
    let onUpdate: () -> Void
    
    @State private var isDeleting = false
    @State private var isDownloading = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // File preview
                    filePreview
                    
                    // Info card
                    infoCard
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var filePreview: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: document.fileType.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(iconColor)
            }
            
            Text(document.name)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Label(document.category.displayName, systemImage: "folder")
                Text("•")
                Label(document.formattedFileSize, systemImage: "doc")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let desc = document.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline.weight(.medium))
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            infoRow(label: "Uploaded by", value: document.uploadedByName)
            infoRow(label: "Uploaded on", value: dateFormatter.string(from: document.createdAt))
            infoRow(label: "Downloads", value: "\(document.downloadCount)")
            
            if document.teachersOnly {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(EZTeachColors.warning)
                    Text("Teachers Only")
                        .font(.subheadline)
                        .foregroundColor(EZTeachColors.warning)
                }
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                downloadDocument()
            } label: {
                HStack {
                    if isDownloading {
                        ProgressView()
                            .tint(.white)
                    }
                    Label(isDownloading ? "Opening..." : "Open Document", systemImage: "arrow.down.circle.fill")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(EZTeachColors.accentGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isDownloading)
            
            if userRole == "school" || document.uploadedByUserId == Auth.auth().currentUser?.uid {
                Button {
                    deleteDocument()
                } label: {
                    Label(isDeleting ? "Deleting..." : "Delete Document", systemImage: "trash")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(EZTeachColors.error.opacity(0.1))
                        .foregroundColor(EZTeachColors.error)
                        .cornerRadius(12)
                }
                .disabled(isDeleting)
            }
        }
    }
    
    private var iconColor: Color {
        switch document.fileType {
        case .pdf: return .red
        case .doc, .docx: return .blue
        case .xls, .xlsx: return .green
        case .ppt, .pptx: return .orange
        case .image: return .purple
        case .video: return .pink
        case .other: return .gray
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
    
    private func downloadDocument() {
        isDownloading = true
        incrementDownloadCount()
        
        // Open the file URL directly
        if let url = URL(string: document.fileUrl) {
            openURL(url)
        }
        
        isDownloading = false
    }
    
    private func incrementDownloadCount() {
        db.collection("documents").document(document.id).updateData([
            "downloadCount": FieldValue.increment(Int64(1))
        ])
    }
    
    private func deleteDocument() {
        isDeleting = true
        
        // Delete from storage if path exists
        if let storagePath = document.storagePath, !storagePath.isEmpty {
            let storageRef = storage.reference().child(storagePath)
            storageRef.delete { _ in
                // Continue even if storage delete fails
                deleteFirestoreRecord()
            }
        } else {
            deleteFirestoreRecord()
        }
    }
    
    private func deleteFirestoreRecord() {
        db.collection("documents").document(document.id).delete { error in
            isDeleting = false
            if error == nil {
                onUpdate()
                dismiss()
            }
        }
    }
}
