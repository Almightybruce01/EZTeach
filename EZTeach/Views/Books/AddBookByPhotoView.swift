//
//  AddBookByPhotoView.swift
//  EZTeach
//
//  Allows users to create books by taking photos of each page
//  With OCR text extraction for searchability
//

import SwiftUI
import PhotosUI
import Vision
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// MARK: - Book Page Model
struct PhotoBookPage: Identifiable, Codable {
    let id: String
    var pageNumber: Int
    var imageUrl: String?
    var extractedText: String
    var localImageData: Data?  // For preview before upload
    
    var hasImage: Bool { imageUrl != nil || localImageData != nil }
}

// MARK: - Photo Book Model
struct PhotoBook: Identifiable, Codable {
    let id: String
    let creatorId: String
    let creatorName: String
    let schoolId: String
    var title: String
    var author: String
    var description: String
    var coverImageUrl: String?
    var pages: [PhotoBookPage]
    var gradeLevel: Int
    var subject: String
    var isPublished: Bool
    var createdAt: Date
    var updatedAt: Date
    
    var pageCount: Int { pages.count }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> PhotoBook? {
        guard let data = doc.data() else { return nil }
        
        let pagesData = data["pages"] as? [[String: Any]] ?? []
        let pages = pagesData.map { pageData -> PhotoBookPage in
            PhotoBookPage(
                id: pageData["id"] as? String ?? UUID().uuidString,
                pageNumber: pageData["pageNumber"] as? Int ?? 0,
                imageUrl: pageData["imageUrl"] as? String,
                extractedText: pageData["extractedText"] as? String ?? "",
                localImageData: nil
            )
        }
        
        return PhotoBook(
            id: doc.documentID,
            creatorId: data["creatorId"] as? String ?? "",
            creatorName: data["creatorName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            author: data["author"] as? String ?? "",
            description: data["description"] as? String ?? "",
            coverImageUrl: data["coverImageUrl"] as? String,
            pages: pages,
            gradeLevel: data["gradeLevel"] as? Int ?? 1,
            subject: data["subject"] as? String ?? "",
            isPublished: data["isPublished"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Main View
struct AddBookByPhotoView: View {
    let schoolId: String
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var description = ""
    @State private var gradeLevel = 1
    @State private var subject = "Reading"
    @State private var pages: [PhotoBookPage] = []
    @State private var coverImage: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var editingPageIndex: Int?
    @State private var isProcessing = false
    @State private var isSaving = false
    @State private var showingPreview = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    let subjects = ["Reading", "Math", "Science", "Social Studies", "Art", "Music", "Other"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Book Info
                    bookInfoSection
                    
                    // Cover Image
                    coverImageSection
                    
                    // Pages
                    pagesSection
                    
                    // Add Page Buttons
                    addPageButtons
                    
                    // Actions
                    actionButtons
                }
                .padding()
            }
            .background(EZTeachColors.backgroundColor)
            .navigationTitle("Add Book by Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPickerView(image: Binding(
                    get: { nil },
                    set: { image in
                        if let image = image {
                            processNewImage(image)
                        }
                    }
                ))
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView { images in
                    for image in images {
                        processNewImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                BookPreviewView(
                    title: title,
                    author: author,
                    pages: pages,
                    coverImage: coverImage
                )
            }
            .overlay {
                if isProcessing {
                    ProcessingOverlay(message: "Processing image...")
                }
                if isSaving {
                    ProcessingOverlay(message: "Saving book...")
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.brown.gradient)
                    .frame(width: 60, height: 60)
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Book from Photos")
                    .font(.title3.bold())
                    .foregroundColor(EZTeachColors.textPrimary)
                Text("Take photos of each page to digitize a book")
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Book Info
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Book Information")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            VStack(spacing: 12) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                    TextField("Enter book title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Author
                VStack(alignment: .leading, spacing: 4) {
                    Text("Author")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                    TextField("Enter author name", text: $author)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                    TextField("Brief description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack(spacing: 12) {
                    // Grade Level
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Grade Level")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textSecondary)
                        Picker("Grade", selection: $gradeLevel) {
                            ForEach(1...12, id: \.self) { grade in
                                Text("Grade \(grade)").tag(grade)
                            }
                        }
                        .pickerStyle(.menu)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Subject
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Subject")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textSecondary)
                        Picker("Subject", selection: $subject) {
                            ForEach(subjects, id: \.self) { subj in
                                Text(subj).tag(subj)
                            }
                        }
                        .pickerStyle(.menu)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Cover Image
    private var coverImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cover Image")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            if let cover = coverImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: cover)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                    
                    Button {
                        coverImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .background(Circle().fill(.white))
                    }
                    .padding(8)
                }
            } else {
                Button {
                    showingPhotoPicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.brown)
                        Text("Add Cover Photo")
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.brown.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(.brown.opacity(0.3))
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Pages Section
    private var pagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pages (\(pages.count))")
                    .font(.headline)
                    .foregroundColor(EZTeachColors.textPrimary)
                Spacer()
                if !pages.isEmpty {
                    Button("Reorder") {
                        // Future: Add drag-to-reorder
                    }
                    .font(.caption)
                    .foregroundColor(EZTeachColors.softBlue)
                }
            }
            
            if pages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No pages added yet")
                        .font(.subheadline)
                        .foregroundColor(EZTeachColors.textSecondary)
                    Text("Take photos of each page or upload from your library")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        PageThumbnailView(
                            page: page,
                            pageNumber: index + 1,
                            onDelete: {
                                pages.remove(at: index)
                                reorderPages()
                            },
                            onDuplicate: {
                                duplicatePage(at: index)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Add Page Buttons
    private var addPageButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take Photo")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brown.gradient)
                .cornerRadius(12)
            }
            
            Button {
                showingPhotoPicker = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Upload")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.brown)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brown.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !pages.isEmpty {
                Button {
                    showingPreview = true
                } label: {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("Preview Book")
                    }
                    .font(.headline)
                    .foregroundColor(EZTeachColors.softBlue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(EZTeachColors.softBlue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Button {
                saveBook()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Book")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    canSave ? AnyView(LinearGradient(colors: [EZTeachColors.brightTeal, EZTeachColors.brightTeal.opacity(0.8)], startPoint: .leading, endPoint: .trailing)) : AnyView(LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                )
                .cornerRadius(12)
            }
            .disabled(!canSave)
        }
    }
    
    // MARK: - Helpers
    private var canSave: Bool {
        !title.isEmpty && !author.isEmpty && !pages.isEmpty
    }
    
    private func processNewImage(_ image: UIImage) {
        isProcessing = true
        
        // Extract text using Vision
        extractText(from: image) { text in
            let page = PhotoBookPage(
                id: UUID().uuidString,
                pageNumber: pages.count + 1,
                imageUrl: nil,
                extractedText: text,
                localImageData: image.jpegData(compressionQuality: 0.8)
            )
            
            DispatchQueue.main.async {
                pages.append(page)
                isProcessing = false
            }
        }
    }
    
    private func extractText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(text)
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    private func reorderPages() {
        for i in 0..<pages.count {
            pages[i].pageNumber = i + 1
        }
    }
    
    private func duplicatePage(at index: Int) {
        var newPage = pages[index]
        newPage = PhotoBookPage(
            id: UUID().uuidString,
            pageNumber: pages.count + 1,
            imageUrl: newPage.imageUrl,
            extractedText: newPage.extractedText,
            localImageData: newPage.localImageData
        )
        pages.append(newPage)
        reorderPages()
    }
    
    private func saveBook() {
        guard canSave else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isSaving = true
        
        let bookId = UUID().uuidString
        
        // Upload images and then save book
        uploadAllImages(bookId: bookId) { uploadedPages, coverUrl in
            let book: [String: Any] = [
                "creatorId": userId,
                "creatorName": Auth.auth().currentUser?.displayName ?? "Teacher",
                "schoolId": schoolId,
                "title": title,
                "author": author,
                "description": description,
                "coverImageUrl": coverUrl ?? "",
                "pages": uploadedPages.map { page -> [String: Any] in
                    [
                        "id": page.id,
                        "pageNumber": page.pageNumber,
                        "imageUrl": page.imageUrl ?? "",
                        "extractedText": page.extractedText
                    ]
                },
                "gradeLevel": gradeLevel,
                "subject": subject,
                "isPublished": true,
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
            
            db.collection("photoBooks").document(bookId).setData(book) { error in
                isSaving = false
                if error == nil {
                    dismiss()
                } else {
                    errorMessage = error?.localizedDescription
                }
            }
        }
    }
    
    private func uploadAllImages(bookId: String, completion: @escaping ([PhotoBookPage], String?) -> Void) {
        var uploadedPages = pages
        let group = DispatchGroup()
        var coverUrl: String?
        
        // Upload cover
        if let coverData = coverImage?.jpegData(compressionQuality: 0.8) {
            group.enter()
            let coverRef = storage.reference().child("photoBooks/\(bookId)/cover.jpg")
            coverRef.putData(coverData) { _, _ in
                coverRef.downloadURL { url, _ in
                    coverUrl = url?.absoluteString
                    group.leave()
                }
            }
        }
        
        // Upload pages
        for (index, page) in pages.enumerated() {
            if let imageData = page.localImageData {
                group.enter()
                let pageRef = storage.reference().child("photoBooks/\(bookId)/page_\(index).jpg")
                pageRef.putData(imageData) { _, _ in
                    pageRef.downloadURL { url, _ in
                        uploadedPages[index] = PhotoBookPage(
                            id: page.id,
                            pageNumber: page.pageNumber,
                            imageUrl: url?.absoluteString,
                            extractedText: page.extractedText,
                            localImageData: nil
                        )
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadedPages, coverUrl)
        }
    }
}

// MARK: - Page Thumbnail View
struct PageThumbnailView: View {
    let page: PhotoBookPage
    let pageNumber: Int
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    @State private var showingMenu = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                if let data = page.localImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 130)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 130)
                        .overlay(
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                        )
                }
                
                Text("Page \(pageNumber)")
                    .font(.caption2)
                    .foregroundColor(EZTeachColors.textSecondary)
            }
            
            Menu {
                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .padding(4)
        }
    }
}

// MARK: - Camera Picker View
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Picker View
struct PhotoPickerView: View {
    let onSelect: ([UIImage]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(EZTeachColors.softBlue)
                        Text("Select Photos")
                            .font(.headline)
                            .foregroundColor(EZTeachColors.textPrimary)
                        Text("Choose up to 20 photos at once")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedItems) { _, items in
                Task {
                    var images: [UIImage] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            images.append(image)
                        }
                    }
                    onSelect(images)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Book Preview View
struct BookPreviewView: View {
    let title: String
    let author: String
    let pages: [PhotoBookPage]
    let coverImage: UIImage?
    
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // Page indicator
                Text("Page \(currentPage + 1) of \(pages.count)")
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textSecondary)
                
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        VStack {
                            if let data = page.localImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(12)
                            }
                            
                            if !page.extractedText.isEmpty {
                                ScrollView {
                                    Text(page.extractedText)
                                        .font(.body)
                                        .padding()
                                }
                                .frame(maxHeight: 150)
                                .background(Color.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}
