//
//  HomeworkSubmissionView.swift
//  EZTeach
//
//  Homework submission with photo and file upload for students and parents
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Submission Model Extension
struct EnhancedHomeworkSubmission: Identifiable, Codable {
    let id: String
    let homeworkId: String
    let studentId: String
    let studentName: String
    let submittedBy: String // userId who submitted (student or parent)
    let submitterRole: String // "student" or "parent"
    let submittedAt: Date
    let photoUrls: [String]
    let fileUrls: [String]
    let fileNames: [String]
    let notes: String
    let status: SubmissionStatus
    var grade: Int?
    var feedback: String?
    var gradedAt: Date?
    var gradedBy: String?
    
    enum SubmissionStatus: String, Codable {
        case submitted = "submitted"
        case late = "late"
        case graded = "graded"
        case returned = "returned"
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> EnhancedHomeworkSubmission? {
        guard let data = doc.data() else { return nil }
        return EnhancedHomeworkSubmission(
            id: doc.documentID,
            homeworkId: data["homeworkId"] as? String ?? "",
            studentId: data["studentId"] as? String ?? "",
            studentName: data["studentName"] as? String ?? "",
            submittedBy: data["submittedBy"] as? String ?? "",
            submitterRole: data["submitterRole"] as? String ?? "student",
            submittedAt: (data["submittedAt"] as? Timestamp)?.dateValue() ?? Date(),
            photoUrls: data["photoUrls"] as? [String] ?? [],
            fileUrls: data["fileUrls"] as? [String] ?? [],
            fileNames: data["fileNames"] as? [String] ?? [],
            notes: data["notes"] as? String ?? "",
            status: SubmissionStatus(rawValue: data["status"] as? String ?? "submitted") ?? .submitted,
            grade: data["grade"] as? Int,
            feedback: data["feedback"] as? String,
            gradedAt: (data["gradedAt"] as? Timestamp)?.dateValue(),
            gradedBy: data["gradedBy"] as? String
        )
    }
}

// MARK: - Submit Homework View
struct SubmitHomeworkView: View {
    let assignment: HomeworkAssignment
    let studentId: String
    let studentName: String
    var submitterRole: String = "student" // "student" or "parent"
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhotos: [UIImage] = []
    @State private var selectedFileURLs: [URL] = []
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var uploadProgress: Double = 0
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var isOverdue: Bool {
        assignment.dueDate < Date()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()
                
                if showSuccess {
                    successView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Assignment Info Card
                            assignmentInfoCard
                            
                            // Photo Upload Section
                            photoUploadSection
                            
                            // File Upload Section
                            fileUploadSection
                            
                            // Notes Section
                            notesSection
                            
                            // Submit Button
                            submitButton
                        }
                        .padding()
                    }
                }
                
                if isSubmitting {
                    uploadOverlay
                }
            }
            .navigationTitle("Submit Homework")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    if let image = image {
                        selectedPhotos.append(image)
                    }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker { images in
                    selectedPhotos.append(contentsOf: images)
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerView { urls in
                    selectedFileURLs.append(contentsOf: urls)
                }
            }
            .alert("Submission Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Assignment Info Card
    private var assignmentInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(EZTeachColors.brightTeal)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(assignment.title)
                        .font(.headline)
                    Text(assignment.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Divider()
            
            HStack {
                Label("\(assignment.pointsWorth) pts", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label {
                    Text("Due \(assignment.dueDate, style: .date)")
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundColor(isOverdue ? .red : .secondary)
            }
            
            if isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("This assignment is past due. Your submission will be marked as late.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            if submitterRole == "parent" {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(EZTeachColors.brightTeal)
                    Text("Submitting on behalf of \(studentName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(EZTeachColors.brightTeal.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - Photo Upload Section
    private var photoUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(EZTeachColors.brightTeal)
                Text("Photos")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedPhotos.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Take a photo of your completed homework or select from your library")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Photo Preview Grid
            if !selectedPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedPhotos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedPhotos[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 130)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                Button {
                                    selectedPhotos.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.red))
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Add Photo Buttons
            HStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(EZTeachColors.brightTeal)
                        .cornerRadius(12)
                }
                
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Choose", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(EZTeachColors.brightTeal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(EZTeachColors.brightTeal.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - File Upload Section
    private var fileUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.purple)
                Text("Files")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedFileURLs.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Upload documents, PDFs, or other files")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // File List
            if !selectedFileURLs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(selectedFileURLs.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: fileIcon(for: selectedFileURLs[index]))
                                .foregroundColor(.purple)
                            
                            Text(selectedFileURLs[index].lastPathComponent)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button {
                                selectedFileURLs.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(10)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Button {
                showFilePicker = true
            } label: {
                Label("Choose Files", systemImage: "folder.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.green)
                Text("Notes (Optional)")
                    .font(.headline)
            }
            
            TextEditor(text: $notes)
                .frame(height: 100)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            Text("Add any notes or comments about your submission")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        VStack(spacing: 12) {
            Button {
                submitHomework()
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Submit Homework")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    canSubmit
                        ? LinearGradient(colors: [EZTeachColors.brightTeal, Color.green], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(14)
            }
            .disabled(!canSubmit || isSubmitting)
            
            if !canSubmit {
                Text("Please add at least one photo or file to submit")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Upload Overlay
    private var uploadOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: uploadProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: EZTeachColors.brightTeal))
                    .frame(width: 200)
                
                Text("Uploading... \(Int(uploadProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Please don't close the app")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
    
    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            Text("Homework Submitted!")
                .font(.title2.bold())
            
            Text("Your \(submitterRole == "parent" ? "child's " : "")homework has been successfully submitted.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if isOverdue {
                Text("Note: This submission was marked as late.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Button {
                onDismiss()
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(EZTeachColors.brightTeal)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Helpers
    private var canSubmit: Bool {
        !selectedPhotos.isEmpty || !selectedFileURLs.isEmpty
    }
    
    private func fileIcon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "ppt", "pptx": return "rectangle.split.3x1.fill"
        case "txt": return "doc.plaintext.fill"
        default: return "doc.fill"
        }
    }
    
    // MARK: - Submit Logic
    private func submitHomework() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isSubmitting = true
        uploadProgress = 0
        
        let submissionId = UUID().uuidString
        let totalItems = selectedPhotos.count + selectedFileURLs.count
        var completedItems = 0
        var photoUrls: [String] = []
        var fileUrls: [String] = []
        var fileNames: [String] = []
        
        let group = DispatchGroup()
        
        // Upload photos
        for (index, photo) in selectedPhotos.enumerated() {
            group.enter()
            
            guard let imageData = photo.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            let photoPath = "homework_submissions/\(submissionId)/photos/photo_\(index).jpg"
            let photoRef = storage.reference().child(photoPath)
            
            photoRef.putData(imageData, metadata: nil) { _, error in
                if error == nil {
                    photoRef.downloadURL { url, _ in
                        if let url = url {
                            photoUrls.append(url.absoluteString)
                        }
                        completedItems += 1
                        uploadProgress = Double(completedItems) / Double(totalItems)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        // Upload files
        for url in selectedFileURLs {
            group.enter()
            
            let fileName = url.lastPathComponent
            fileNames.append(fileName)
            
            let filePath = "homework_submissions/\(submissionId)/files/\(fileName)"
            let fileRef = storage.reference().child(filePath)
            
            // Start accessing the security-scoped resource
            _ = url.startAccessingSecurityScopedResource()
            
            do {
                let fileData = try Data(contentsOf: url)
                fileRef.putData(fileData, metadata: nil) { _, error in
                    url.stopAccessingSecurityScopedResource()
                    if error == nil {
                        fileRef.downloadURL { downloadUrl, _ in
                            if let downloadUrl = downloadUrl {
                                fileUrls.append(downloadUrl.absoluteString)
                            }
                            completedItems += 1
                            uploadProgress = Double(completedItems) / Double(totalItems)
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
            } catch {
                url.stopAccessingSecurityScopedResource()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Save submission to Firestore
            let status: EnhancedHomeworkSubmission.SubmissionStatus = isOverdue ? .late : .submitted
            
            let submissionData: [String: Any] = [
                "homeworkId": assignment.id,
                "studentId": studentId,
                "studentName": studentName,
                "submittedBy": userId,
                "submitterRole": submitterRole,
                "submittedAt": Timestamp(),
                "photoUrls": photoUrls,
                "fileUrls": fileUrls,
                "fileNames": fileNames,
                "notes": notes,
                "status": status.rawValue,
                "schoolId": assignment.schoolId,
                "classId": assignment.classId,
                "assignmentTitle": assignment.title
            ]
            
            db.collection("homeworkSubmissions").document(submissionId).setData(submissionData) { error in
                isSubmitting = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    // Update student assignment status
                    updateAssignmentStatus(submissionId: submissionId, status: status)
                    showSuccess = true
                }
            }
        }
    }
    
    private func updateAssignmentStatus(submissionId: String, status: EnhancedHomeworkSubmission.SubmissionStatus) {
        db.collection("studentAssignments")
            .whereField("studentId", isEqualTo: studentId)
            .whereField("homeworkId", isEqualTo: assignment.id)
            .getDocuments { snap, _ in
                for doc in snap?.documents ?? [] {
                    doc.reference.updateData([
                        "status": status.rawValue,
                        "submissionId": submissionId,
                        "submittedAt": Timestamp()
                    ])
                }
            }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        
        init(onCapture: @escaping (UIImage?) -> Void) {
            self.onCapture = onCapture
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onCapture(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Photo Library Picker
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onSelect: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onSelect: ([UIImage]) -> Void
        
        init(onSelect: @escaping ([UIImage]) -> Void) {
            self.onSelect = onSelect
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.onSelect(images)
            }
        }
    }
}

// MARK: - Document Picker
struct DocumentPickerView: UIViewControllerRepresentable {
    let onSelect: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText, .image, .data])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelect: ([URL]) -> Void
        
        init(onSelect: @escaping ([URL]) -> Void) {
            self.onSelect = onSelect
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onSelect(urls)
        }
    }
}

// MARK: - Enhanced Student Homework Tab with Submission
struct EnhancedStudentHomeworkTab: View {
    let studentId: String
    let studentName: String
    let schoolId: String
    var submitterRole: String = "student" // "student" or "parent"
    
    @State private var assignments: [HomeworkAssignment] = []
    @State private var submissions: [String: EnhancedHomeworkSubmission] = [:] // keyed by homeworkId
    @State private var isLoading = true
    @State private var selectedAssignment: HomeworkAssignment?
    @State private var selectedSubmission: EnhancedHomeworkSubmission?
    @State private var filterOption: FilterOption = .pending
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case submitted = "Submitted"
        case graded = "Graded"
    }
    
    private let db = Firestore.firestore()
    
    private var filteredAssignments: [HomeworkAssignment] {
        switch filterOption {
        case .all:
            return assignments
        case .pending:
            return assignments.filter { submissions[$0.id] == nil }
        case .submitted:
            return assignments.filter {
                guard let sub = submissions[$0.id] else { return false }
                return sub.status == .submitted || sub.status == .late
            }
        case .graded:
            return assignments.filter { submissions[$0.id]?.status == .graded }
        }
    }
    
    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(FilterOption.allCases, id: \.rawValue) { option in
                            FilterPill(
                                title: option.rawValue,
                                count: countFor(option),
                                isSelected: filterOption == option
                            ) {
                                filterOption = option
                            }
                        }
                    }
                    .padding()
                }
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading homework...")
                        .tint(EZTeachColors.brightTeal)
                        .foregroundColor(.white)
                    Spacer()
                } else if filteredAssignments.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No \(filterOption.rawValue) Homework",
                        systemImage: filterOption == .pending ? "checkmark.circle" : "book.closed",
                        description: Text(filterOption == .pending ? "Great job! No pending assignments." : "No homework in this category.")
                    )
                    .tint(EZTeachColors.brightTeal)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAssignments) { assignment in
                                HomeworkAssignmentCard(
                                    assignment: assignment,
                                    submission: submissions[assignment.id],
                                    onSubmit: {
                                        selectedAssignment = assignment
                                    },
                                    onViewSubmission: {
                                        selectedSubmission = submissions[assignment.id]
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear { loadData() }
        .sheet(item: $selectedAssignment) { assignment in
            SubmitHomeworkView(
                assignment: assignment,
                studentId: studentId,
                studentName: studentName,
                submitterRole: submitterRole,
                onDismiss: { loadData() }
            )
        }
        .sheet(item: $selectedSubmission) { submission in
            SubmissionDetailView(submission: submission)
        }
    }
    
    private func countFor(_ option: FilterOption) -> Int {
        switch option {
        case .all: return assignments.count
        case .pending: return assignments.filter { submissions[$0.id] == nil }.count
        case .submitted: return assignments.filter {
            guard let sub = submissions[$0.id] else { return false }
            return sub.status == .submitted || sub.status == .late
        }.count
        case .graded: return assignments.filter { submissions[$0.id]?.status == .graded }.count
        }
    }
    
    private func loadData() {
        isLoading = true
        
        // First get the classes the student is enrolled in
        db.collection("class_rosters")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments { rosterSnap, _ in
                let classIds = Set(rosterSnap?.documents.compactMap { $0["classId"] as? String } ?? [])
                
                guard !classIds.isEmpty else {
                    DispatchQueue.main.async {
                        assignments = []
                        isLoading = false
                    }
                    return
                }
                
                // Load homework for those classes
                db.collection("homework")
                    .whereField("schoolId", isEqualTo: schoolId)
                    .order(by: "dueDate")
                    .getDocuments { snap, _ in
                        let all = snap?.documents.compactMap { HomeworkAssignment.fromDocument($0) } ?? []
                        let filtered = all.filter { classIds.contains($0.classId) }
                        
                        // Load submissions for this student
                        db.collection("homeworkSubmissions")
                            .whereField("studentId", isEqualTo: studentId)
                            .getDocuments { subSnap, _ in
                                var subs: [String: EnhancedHomeworkSubmission] = [:]
                                for doc in subSnap?.documents ?? [] {
                                    if let sub = EnhancedHomeworkSubmission.fromDocument(doc) {
                                        subs[sub.homeworkId] = sub
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    assignments = filtered
                                    submissions = subs
                                    isLoading = false
                                }
                            }
                    }
            }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : EZTeachColors.brightTeal.opacity(0.3))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? EZTeachColors.brightTeal : Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - Homework Assignment Card
struct HomeworkAssignmentCard: View {
    let assignment: HomeworkAssignment
    let submission: EnhancedHomeworkSubmission?
    let onSubmit: () -> Void
    let onViewSubmission: () -> Void
    
    private var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: assignment.dueDate).day ?? 0
        return daysUntilDue <= 2 && daysUntilDue >= 0
    }
    
    private var isOverdue: Bool {
        assignment.dueDate < Date()
    }
    
    private var statusColor: Color {
        if let sub = submission {
            switch sub.status {
            case .graded: return .green
            case .submitted: return EZTeachColors.brightTeal
            case .late: return .orange
            case .returned: return .purple
            }
        }
        return isOverdue ? .red : (isDueSoon ? .orange : EZTeachColors.brightTeal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: submission != nil ? "checkmark.circle.fill" : "doc.text.fill")
                            .foregroundColor(statusColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text(assignment.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Status Badge
                if let sub = submission {
                    statusBadge(for: sub)
                } else if isOverdue {
                    Text("OVERDUE")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                Label("\(assignment.pointsWorth) pts", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label("Due \(assignment.dueDate, style: .date)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(isOverdue && submission == nil ? .red : .white.opacity(0.6))
            }
            
            // Action Button
            if let sub = submission {
                Button(action: onViewSubmission) {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("View Submission")
                        if sub.status == .graded, let grade = sub.grade {
                            Spacer()
                            Text("\(grade)/\(assignment.pointsWorth)")
                                .fontWeight(.bold)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(EZTeachColors.brightTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(EZTeachColors.brightTeal.opacity(0.15))
                    .cornerRadius(10)
                }
            } else {
                Button(action: onSubmit) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Homework")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [EZTeachColors.brightTeal, Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(statusColor.opacity(0.35), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        )
    }
    
    @ViewBuilder
    private func statusBadge(for submission: EnhancedHomeworkSubmission) -> some View {
        let (text, color) = { () -> (String, Color) in
            switch submission.status {
            case .submitted: return ("SUBMITTED", EZTeachColors.brightTeal)
            case .late: return ("LATE", .orange)
            case .graded: return ("GRADED", .green)
            case .returned: return ("RETURNED", .purple)
            }
        }()
        
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}

// MARK: - Submission Detail View
struct SubmissionDetailView: View {
    let submission: EnhancedHomeworkSubmission
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Submission Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(EZTeachColors.brightTeal)
                            Text("Submitted \(submission.submittedAt, style: .date) at \(submission.submittedAt, style: .time)")
                                .font(.subheadline)
                        }
                        
                        if submission.submitterRole == "parent" {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.purple)
                                Text("Submitted by parent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Status
                        HStack {
                            Text("Status:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(submission.status.rawValue.capitalized)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(statusColor)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Grade (if graded)
                    if submission.status == .graded, let grade = submission.grade {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading) {
                                    Text("Grade")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(grade) points")
                                        .font(.title2.bold())
                                        .foregroundColor(.green)
                                }
                            }
                            
                            if let feedback = submission.feedback, !feedback.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Teacher Feedback")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(feedback)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Photos
                    if !submission.photoUrls.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photos (\(submission.photoUrls.count))")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(submission.photoUrls, id: \.self) { url in
                                        AsyncImage(url: URL(string: url)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 150, height: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } placeholder: {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 150, height: 200)
                                                .overlay(ProgressView())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Files
                    if !submission.fileUrls.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Files (\(submission.fileUrls.count))")
                                .font(.headline)
                            
                            ForEach(Array(zip(submission.fileUrls, submission.fileNames)), id: \.0) { url, name in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.purple)
                                    Text(name)
                                        .font(.subheadline)
                                    Spacer()
                                    Link(destination: URL(string: url)!) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(EZTeachColors.brightTeal)
                                    }
                                }
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    // Notes
                    if !submission.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(submission.notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Submission Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch submission.status {
        case .submitted: return EZTeachColors.brightTeal
        case .late: return .orange
        case .graded: return .green
        case .returned: return .purple
        }
    }
}
