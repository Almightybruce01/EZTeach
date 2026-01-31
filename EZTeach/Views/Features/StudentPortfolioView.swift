//
//  StudentPortfolioView.swift
//  EZTeach
//
//  Student work portfolio
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct StudentPortfolioView: View {
    let student: Student
    let schoolId: String
    let canEdit: Bool
    
    @State private var items: [PortfolioItem] = []
    @State private var isLoading = true
    @State private var showAddItem = false
    @State private var selectedFilter: PortfolioItem.PortfolioType?
    
    private let db = Firestore.firestore()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var filteredItems: [PortfolioItem] {
        if let filter = selectedFilter {
            return items.filter { $0.type == filter }
        }
        return items
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(nil, label: "All")
                        ForEach(PortfolioItem.PortfolioType.allCases, id: \.self) { type in
                            filterChip(type, label: type.rawValue)
                        }
                    }
                    .padding()
                }
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredItems.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredItems) { item in
                                PortfolioItemCard(item: item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Portfolio")
            .toolbar {
                if canEdit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddItem = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddPortfolioItemView(studentId: student.id, schoolId: schoolId) {
                    loadItems()
                }
            }
            .onAppear(perform: loadItems)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Portfolio Items")
                .font(.headline)
            Text(canEdit ? "Add work samples to showcase achievements" : "No items yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func filterChip(_ type: PortfolioItem.PortfolioType?, label: String) -> some View {
        Button {
            selectedFilter = type
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedFilter == type ? EZTeachColors.accent : EZTeachColors.secondaryBackground)
                .foregroundColor(selectedFilter == type ? .white : .primary)
                .cornerRadius(20)
        }
    }
    
    private func loadItems() {
        isLoading = true
        db.collection("portfolioItems")
            .whereField("studentId", isEqualTo: student.id)
            .order(by: "createdAt", descending: true)
            .getDocuments { snap, _ in
                items = snap?.documents.compactMap { PortfolioItem.fromDocument($0) } ?? []
                isLoading = false
            }
    }
}

struct PortfolioItemCard: View {
    let item: PortfolioItem
    
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(EZTeachColors.cardFill)
                        .aspectRatio(1.3, contentMode: .fit)
                    
                    if let thumbUrl = item.thumbnailUrl, let url = URL(string: thumbUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .cornerRadius(12)
                    } else {
                        Image(systemName: item.type.icon)
                            .font(.largeTitle)
                            .foregroundColor(EZTeachColors.accent)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(item.subject)
                        if let grade = item.grade {
                            Text("•")
                            Text(grade)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            PortfolioItemDetailView(item: item)
        }
    }
}

struct PortfolioItemDetailView: View {
    let item: PortfolioItem
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Preview
                    if let url = URL(string: item.fileUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(EZTeachColors.cardFill)
                                .aspectRatio(1.5, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                )
                        }
                        .cornerRadius(12)
                    }
                    
                    // Title and type
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.title2.bold())
                            
                            HStack {
                                Label(item.type.rawValue, systemImage: item.type.icon)
                                Text("•")
                                Text(item.subject)
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let grade = item.grade {
                            Text(grade)
                                .font(.title3.bold())
                                .foregroundColor(EZTeachColors.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(EZTeachColors.accent.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Description
                    if !item.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(item.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Teacher comment
                    if let comment = item.teacherComment, !comment.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Teacher Feedback")
                                .font(.headline)
                            Text(comment)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(EZTeachColors.cardFill)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Date
                    Text("Added \(item.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .background(EZTeachColors.background)
            .navigationTitle("Portfolio Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AddPortfolioItemView: View {
    let studentId: String
    let schoolId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var type: PortfolioItem.PortfolioType = .project
    @State private var subject = ""
    @State private var grade = ""
    @State private var teacherComment = ""
    @State private var isUploading = false
    
    private let db = Firestore.firestore()
    private let subjects = ["Math", "Science", "English", "History", "Art", "Music", "PE", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Type", selection: $type) {
                        ForEach(PortfolioItem.PortfolioType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    
                    Picker("Subject", selection: $subject) {
                        Text("Select").tag("")
                        ForEach(subjects, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    
                    TextEditor(text: $description)
                        .frame(height: 80)
                }
                
                Section("Grading (Optional)") {
                    TextField("Grade (e.g. A, 95%)", text: $grade)
                    TextField("Teacher Comment", text: $teacherComment)
                }
            }
            .navigationTitle("Add to Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        saveItem()
                    }
                    .disabled(title.isEmpty || subject.isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        let data: [String: Any] = [
            "studentId": studentId,
            "schoolId": schoolId,
            "title": title,
            "description": description,
            "type": type.rawValue,
            "fileUrl": "",
            "subject": subject,
            "grade": grade.isEmpty ? NSNull() : grade,
            "teacherComment": teacherComment.isEmpty ? NSNull() : teacherComment,
            "createdAt": Timestamp()
        ]
        
        db.collection("portfolioItems").addDocument(data: data) { _ in
            onSave()
            dismiss()
        }
    }
}
