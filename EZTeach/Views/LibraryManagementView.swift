//
//  LibraryManagementView.swift
//  EZTeach
//
//  Comprehensive school library management — catalog, check-in/out,
//  digital book creation, overdue tracking, and student history.
//  All data is school-scoped.
//

import SwiftUI
import FirebaseAuth
import PhotosUI

// MARK: - Library Tab
enum LibraryTab: String, CaseIterable {
    case catalog = "Catalog"
    case checkouts = "Checked Out"
    case overdue = "Overdue"
    case history = "History"
    case digital = "Digital Books"
    
    var icon: String {
        switch self {
        case .catalog: return "books.vertical.fill"
        case .checkouts: return "arrow.right.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .history: return "clock.fill"
        case .digital: return "camera.fill"
        }
    }
}

// MARK: - Main Library Management View
struct LibraryManagementView: View {
    let schoolId: String
    let canEdit: Bool
    
    @State private var selectedTab: LibraryTab = .catalog
    @State private var catalog: [LibraryBook] = []
    @State private var activeCheckouts: [CheckoutRecord] = []
    @State private var overdueCheckouts: [CheckoutRecord] = []
    @State private var allHistory: [CheckoutRecord] = []
    @State private var searchText = ""
    @State private var selectedCategory: LibraryBookCategory?
    @State private var isLoading = true
    @State private var showAddBook = false
    @State private var showCreateDigitalBook = false
    @State private var selectedBook: LibraryBook?
    @State private var showCheckoutSheet = false
    @State private var bookForCheckout: LibraryBook?
    @State private var successMessage: String?
    @State private var errorMessage: String?
    
    private let service = SchoolLibraryService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats banner
                statsBanner
                
                // Tab bar
                tabBar
                
                // Search
                searchBar
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Loading library...")
                    Spacer()
                } else {
                    switch selectedTab {
                    case .catalog: catalogView
                    case .checkouts: checkoutsView
                    case .overdue: overdueView
                    case .history: historyView
                    case .digital: digitalBooksView
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Library Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canEdit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showAddBook = true
                            } label: {
                                Label("Add Physical Book", systemImage: "plus.circle")
                            }
                            Button {
                                showCreateDigitalBook = true
                            } label: {
                                Label("Create Digital Book", systemImage: "camera.fill")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(EZTeachColors.brightTeal)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddBook) {
                AddLibraryBookSheet(schoolId: schoolId) { _ in
                    loadData()
                }
            }
            .sheet(isPresented: $showCreateDigitalBook) {
                CreateDigitalBookSheet(schoolId: schoolId) {
                    loadData()
                }
            }
            .sheet(item: $selectedBook) { book in
                BookDetailSheet(book: book, schoolId: schoolId, canEdit: canEdit) {
                    loadData()
                }
            }
            .sheet(item: $bookForCheckout) { book in
                CheckoutSheet(book: book, schoolId: schoolId) {
                    loadData()
                }
            }
            .overlay(alignment: .top) {
                if let msg = successMessage {
                    Text(msg)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.cornerRadius(12))
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { successMessage = nil } } }
                }
            }
            .onAppear { loadData() }
        }
    }
    
    // MARK: - Stats Banner
    private var statsBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatPill(label: "Total Books", value: "\(catalog.count)", color: .blue, icon: "books.vertical.fill")
                StatPill(label: "Checked Out", value: "\(activeCheckouts.count)", color: .orange, icon: "arrow.right.circle.fill")
                StatPill(label: "Overdue", value: "\(overdueCheckouts.count)", color: .red, icon: "exclamationmark.triangle.fill")
                StatPill(label: "Available", value: "\(catalog.filter { $0.isAvailable }.count)", color: .green, icon: "checkmark.circle.fill")
                StatPill(label: "Digital", value: "\(catalog.filter { $0.isDigital }.count)", color: .purple, icon: "camera.fill")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color.white)
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(LibraryTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.caption.weight(.semibold))
                            if tab == .overdue && !overdueCheckouts.isEmpty {
                                Text("\(overdueCheckouts.count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? EZTeachColors.brightTeal : Color.gray.opacity(0.12))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(Color.white.shadow(color: .black.opacity(0.05), radius: 2, y: 1))
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search by title, author, ISBN, ID...", text: $searchText)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Catalog View
    private var catalogView: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button {
                        withAnimation { selectedCategory = nil }
                    } label: {
                        Text("All")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selectedCategory == nil ? .white : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.12))
                            .cornerRadius(14)
                    }
                    ForEach(LibraryBookCategory.allCases, id: \.rawValue) { cat in
                        Button {
                            withAnimation { selectedCategory = cat }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: cat.icon)
                                    .font(.caption2)
                                Text(cat.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(selectedCategory == cat ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedCategory == cat ? Color.blue : Color.gray.opacity(0.12))
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 4)
            
            let filtered = filteredCatalog
            if filtered.isEmpty {
                Spacer()
                ContentUnavailableView("No Books Found", systemImage: "books.vertical.fill", description: Text(canEdit ? "Tap + to add your first book" : "Library is empty"))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { book in
                            CatalogBookCard(book: book, canEdit: canEdit, onTap: {
                                selectedBook = book
                            }, onCheckout: {
                                bookForCheckout = book
                            })
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Checkouts View
    private var checkoutsView: some View {
        Group {
            if activeCheckouts.isEmpty {
                Spacer()
                ContentUnavailableView("No Active Checkouts", systemImage: "tray.fill", description: Text("All books are currently checked in"))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredCheckouts(activeCheckouts)) { record in
                            CheckoutRecordCard(record: record, canEdit: canEdit, onReturn: {
                                returnBook(record)
                            }, onRenew: {
                                renewBook(record)
                            })
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Overdue View
    private var overdueView: some View {
        Group {
            if overdueCheckouts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("No Overdue Books!")
                        .font(.headline)
                    Text("All checked-out books are within their due dates")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(overdueCheckouts) { record in
                            CheckoutRecordCard(record: record, canEdit: canEdit, isOverdueHighlight: true, onReturn: {
                                returnBook(record)
                            }, onRenew: {
                                renewBook(record)
                            })
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - History View
    private var historyView: some View {
        Group {
            if allHistory.isEmpty {
                Spacer()
                ContentUnavailableView("No History", systemImage: "clock.fill", description: Text("Checkout history will appear here"))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredCheckouts(allHistory)) { record in
                            CheckoutRecordCard(record: record, canEdit: false, onReturn: {}, onRenew: {})
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Digital Books View
    private var digitalBooksView: some View {
        let digital = catalog.filter { $0.isDigital }
        return Group {
            if digital.isEmpty {
                Spacer()
                ContentUnavailableView("No Digital Books", systemImage: "camera.fill", description: Text(canEdit ? "Create a digital book by photographing each page" : "No digital books yet"))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(digital.filter { matchesSearch($0) }) { book in
                            CatalogBookCard(book: book, canEdit: canEdit, onTap: {
                                selectedBook = book
                            }, onCheckout: {
                                bookForCheckout = book
                            })
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Filtering
    private var filteredCatalog: [LibraryBook] {
        var result = catalog
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        return result.filter { matchesSearch($0) }
    }
    
    private func matchesSearch(_ book: LibraryBook) -> Bool {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return true }
        return book.title.lowercased().contains(q) ||
               book.author.lowercased().contains(q) ||
               book.isbn.lowercased().contains(q) ||
               book.bookId.lowercased().contains(q) ||
               book.tags.contains { $0.lowercased().contains(q) }
    }
    
    private func filteredCheckouts(_ records: [CheckoutRecord]) -> [CheckoutRecord] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return records }
        return records.filter {
            $0.bookTitle.lowercased().contains(q) ||
            $0.studentName.lowercased().contains(q) ||
            $0.bookCatalogId.lowercased().contains(q)
        }
    }
    
    // MARK: - Actions
    private func loadData() {
        isLoading = true
        let group = DispatchGroup()
        
        group.enter()
        service.fetchCatalog(schoolId: schoolId) { books in
            catalog = books
            group.leave()
        }
        group.enter()
        service.fetchActiveCheckouts(schoolId: schoolId) { records in
            activeCheckouts = records
            group.leave()
        }
        group.enter()
        service.fetchOverdueCheckouts(schoolId: schoolId) { records in
            overdueCheckouts = records
            group.leave()
        }
        group.enter()
        service.fetchAllCheckouts(schoolId: schoolId) { records in
            allHistory = records
            group.leave()
        }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
    
    private func returnBook(_ record: CheckoutRecord) {
        service.returnBook(checkout: record) { error in
            if error == nil {
                withAnimation { successMessage = "\(record.bookTitle) returned!" }
                loadData()
            }
        }
    }
    
    private func renewBook(_ record: CheckoutRecord) {
        service.renewCheckout(record) { error in
            if error == nil {
                withAnimation { successMessage = "\(record.bookTitle) renewed for 14 days" }
                loadData()
            }
        }
    }
}

// MARK: - Stat Pill
private struct StatPill: View {
    let label: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Catalog Book Card
private struct CatalogBookCard: View {
    let book: LibraryBook
    let canEdit: Bool
    let onTap: () -> Void
    let onCheckout: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Cover
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 85)
                    if book.isDigital {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: book.category.icon)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(book.bookId)
                            .font(.caption2.monospaced())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        if book.isDigital {
                            Text("DIGITAL")
                                .font(.caption2.bold())
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(book.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Label(book.condition.rawValue, systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(conditionColor)
                        
                        if !book.isbn.isEmpty {
                            Text("ISBN: \(book.isbn)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        Text("\(book.availableCopies)/\(book.totalCopies) available")
                            .font(.caption.weight(.medium))
                            .foregroundColor(book.isAvailable ? .green : .red)
                        
                        if !book.location.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "mappin")
                                    .font(.caption2)
                                Text(book.location)
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if canEdit && book.isAvailable && !book.isDigital {
                    Button {
                        onCheckout()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(EZTeachColors.brightTeal)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    private var conditionColor: Color {
        switch book.condition {
        case .new: return .green
        case .excellent: return .blue
        case .good: return .teal
        case .fair: return .orange
        case .poor: return .red
        case .damaged: return .gray
        }
    }
}

// MARK: - Checkout Record Card
private struct CheckoutRecordCard: View {
    let record: CheckoutRecord
    let canEdit: Bool
    var isOverdueHighlight: Bool = false
    let onReturn: () -> Void
    let onRenew: () -> Void
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.bookTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(record.bookCatalogId)
                        .font(.caption2.monospaced())
                        .foregroundColor(.blue)
                }
                Spacer()
                statusBadge
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Student")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(record.studentName)
                        .font(.caption.weight(.medium))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grade")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(record.studentGrade)
                        .font(.caption.weight(.medium))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Checked Out")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(dateFormatter.string(from: record.checkedOutAt))
                        .font(.caption.weight(.medium))
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Due Date")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(dateFormatter.string(from: record.dueDate))
                        .font(.caption.weight(.medium))
                        .foregroundColor(record.isOverdue ? .red : .primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(record.daysCheckedOut) days")
                        .font(.caption.weight(.medium))
                }
                
                if record.isOverdue {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Overdue By")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(record.daysOverdue) days")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                }
                
                if record.renewCount > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Renewed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(record.renewCount)x")
                            .font(.caption.weight(.medium))
                    }
                }
            }
            
            if canEdit && record.status == .checkedOut {
                HStack(spacing: 12) {
                    Button {
                        onReturn()
                    } label: {
                        Label("Return", systemImage: "arrow.uturn.left.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        onRenew()
                    } label: {
                        Label("Renew (+14d)", systemImage: "arrow.clockwise.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(10)
                    }
                }
            }
            
            if let returnedAt = record.returnedAt {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Returned \(dateFormatter.string(from: returnedAt))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(14)
        .background(isOverdueHighlight ? Color.red.opacity(0.04) : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isOverdueHighlight ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
    
    private var statusBadge: some View {
        Text(record.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2.bold())
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.12))
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch record.status {
        case .checkedOut: return record.isOverdue ? .red : .orange
        case .returned: return .green
        case .overdue: return .red
        case .lost: return .gray
        }
    }
}

// MARK: - Add Library Book Sheet
struct AddLibraryBookSheet: View {
    let schoolId: String
    let onSave: (LibraryBook) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var publisher = ""
    @State private var publishYear = ""
    @State private var category: LibraryBookCategory = .fiction
    @State private var condition: BookCondition = .good
    @State private var totalCopies = 1
    @State private var gradeLevel = ""
    @State private var description = ""
    @State private var location = ""
    @State private var tags = ""
    @State private var pageCount = ""
    @State private var barcode = ""
    @State private var notes = ""
    @State private var generatedId = ""
    @State private var isSaving = false
    
    private let gradeLevelOptions = ["Pre-K", "K-2", "3-5", "6-8", "9-12", "All"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "book.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Book to Library")
                                .font(.headline)
                            if !generatedId.isEmpty {
                                Text("ID: \(generatedId)")
                                    .font(.caption.monospaced())
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(Color.blue.opacity(0.08))
                }
                
                Section("Book Information") {
                    TextField("Title *", text: $title)
                    TextField("Author *", text: $author)
                    TextField("ISBN (optional)", text: $isbn)
                        .keyboardType(.numberPad)
                    TextField("Publisher", text: $publisher)
                    TextField("Publish Year", text: $publishYear)
                        .keyboardType(.numberPad)
                    TextField("Page Count", text: $pageCount)
                        .keyboardType(.numberPad)
                    TextField("Barcode / QR (optional)", text: $barcode)
                }
                
                Section("Classification") {
                    Picker("Category", selection: $category) {
                        ForEach(LibraryBookCategory.allCases, id: \.rawValue) {
                            Label($0.rawValue, systemImage: $0.icon).tag($0)
                        }
                    }
                    Picker("Condition", selection: $condition) {
                        ForEach(BookCondition.allCases, id: \.rawValue) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Picker("Grade Level", selection: $gradeLevel) {
                        Text("Select...").tag("")
                        ForEach(gradeLevelOptions, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                }
                
                Section("Inventory") {
                    Stepper("Copies: \(totalCopies)", value: $totalCopies, in: 1...100)
                    TextField("Shelf Location (e.g., Shelf A3)", text: $location)
                }
                
                Section("Additional") {
                    TextField("Tags (comma separated)", text: $tags)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Librarian Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
                    Button {
                        saveBook()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Add to Library")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                    }
                    .disabled(title.isEmpty || author.isEmpty || isSaving)
                    .listRowBackground(
                        (title.isEmpty || author.isEmpty) ? Color.gray : Color.blue
                    )
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                SchoolLibraryService.shared.generateBookId(schoolId: schoolId) { id in
                    generatedId = id
                }
            }
        }
    }
    
    private func saveBook() {
        isSaving = true
        let uid = Auth.auth().currentUser?.uid ?? ""
        let userName = Auth.auth().currentUser?.displayName ?? "Librarian"
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let book = LibraryBook(
            id: UUID().uuidString,
            bookId: generatedId,
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            isbn: isbn.trimmingCharacters(in: .whitespaces),
            publisher: publisher,
            publishYear: Int(publishYear),
            category: category,
            condition: condition,
            totalCopies: totalCopies,
            availableCopies: totalCopies,
            gradeLevel: gradeLevel,
            description: description,
            coverImageUrl: nil,
            location: location,
            tags: tagArray,
            isDigital: false,
            digitalPages: [],
            pageCount: Int(pageCount) ?? 0,
            addedAt: Date(),
            addedByUserId: uid,
            addedByName: userName,
            lastEditedAt: Date(),
            schoolId: schoolId,
            barcode: barcode.isEmpty ? nil : barcode,
            notes: notes
        )
        
        SchoolLibraryService.shared.addBook(book) { error in
            isSaving = false
            if error == nil {
                onSave(book)
                dismiss()
            }
        }
    }
}

// MARK: - Checkout Sheet
struct CheckoutSheet: View {
    let book: LibraryBook
    let schoolId: String
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var studentName = ""
    @State private var studentId = ""
    @State private var studentGrade = ""
    @State private var loanDays = 14
    @State private var notes = ""
    @State private var isProcessing = false
    @State private var errorMsg: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Check Out")
                                .font(.headline)
                            Text(book.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(book.bookId)
                                .font(.caption.monospaced())
                                .foregroundColor(.blue)
                        }
                    }
                    .listRowBackground(Color.orange.opacity(0.08))
                }
                
                Section("Student Information") {
                    TextField("Student Name *", text: $studentName)
                    TextField("Student ID", text: $studentId)
                    TextField("Grade", text: $studentGrade)
                }
                
                Section("Loan Period") {
                    Stepper("Days: \(loanDays)", value: $loanDays, in: 1...90)
                    let due = Calendar.current.date(byAdding: .day, value: loanDays, to: Date()) ?? Date()
                    Text("Due: \(due, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Notes (optional)") {
                    TextField("Notes about checkout", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                if let error = errorMsg {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        processCheckout()
                    } label: {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Check Out Book")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                    }
                    .disabled(studentName.isEmpty || isProcessing)
                    .listRowBackground(studentName.isEmpty ? Color.gray : Color.orange)
                }
            }
            .navigationTitle("Check Out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func processCheckout() {
        isProcessing = true
        let uid = Auth.auth().currentUser?.uid ?? ""
        let userName = Auth.auth().currentUser?.displayName ?? "Librarian"
        
        SchoolLibraryService.shared.checkOutBook(
            book: book,
            studentId: studentId,
            studentName: studentName,
            studentGrade: studentGrade,
            loanDays: loanDays,
            librarianId: uid,
            librarianName: userName,
            notes: notes
        ) { result in
            isProcessing = false
            switch result {
            case .success:
                onComplete()
                dismiss()
            case .failure(let error):
                errorMsg = error.localizedDescription
            }
        }
    }
}

// MARK: - Book Detail Sheet
struct BookDetailSheet: View {
    let book: LibraryBook
    let schoolId: String
    let canEdit: Bool
    let onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var checkouts: [CheckoutRecord] = []
    @State private var isLoadingHistory = true
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 110)
                            Image(systemName: book.isDigital ? "camera.fill" : book.category.icon)
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(book.bookId)
                                .font(.caption.monospaced())
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                            
                            Text(book.title)
                                .font(.title3.bold())
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !book.isbn.isEmpty {
                                Text("ISBN: \(book.isbn)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Info Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InfoTile(title: "Category", value: book.category.rawValue, icon: book.category.icon)
                        InfoTile(title: "Condition", value: book.condition.rawValue, icon: "circle.fill")
                        InfoTile(title: "Copies", value: "\(book.availableCopies) / \(book.totalCopies)", icon: "number")
                        InfoTile(title: "Grade Level", value: book.gradeLevel.isEmpty ? "All" : book.gradeLevel, icon: "graduationcap.fill")
                        InfoTile(title: "Location", value: book.location.isEmpty ? "N/A" : book.location, icon: "mappin")
                        InfoTile(title: "Pages", value: book.pageCount > 0 ? "\(book.pageCount)" : "N/A", icon: "doc.fill")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Digital pages preview
                    if book.isDigital && !book.digitalPages.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Digital Pages (\(book.digitalPages.count))")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(book.digitalPages.enumerated()), id: \.offset) { idx, url in
                                        AsyncImage(url: URL(string: url)) { phase in
                                            switch phase {
                                            case .success(let img):
                                                img.resizable().aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 140)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            default:
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 100, height: 140)
                                                    .overlay(Text("Pg \(idx+1)").font(.caption))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    
                    // Checkout history
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Checkout History")
                            .font(.headline)
                        
                        if isLoadingHistory {
                            ProgressView()
                        } else if checkouts.isEmpty {
                            Text("No checkout history for this book")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(checkouts) { record in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(record.status == .returned ? Color.green : Color.orange)
                                        .frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.studentName)
                                            .font(.subheadline.weight(.medium))
                                        Text("\(dateFormatter.string(from: record.checkedOutAt)) — \(record.daysCheckedOut) days")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(record.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption2.bold())
                                        .foregroundColor(record.status == .returned ? .green : .orange)
                                }
                                .padding(.vertical, 4)
                                if record.id != checkouts.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Notes
                    if !book.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Librarian Notes")
                                .font(.headline)
                            Text(book.notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Added by \(book.addedByName) on \(dateFormatter.string(from: book.addedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !book.publisher.isEmpty {
                            Text("Publisher: \(book.publisher)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let year = book.publishYear {
                            Text("Published: \(year)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if canEdit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            SchoolLibraryService.shared.deleteBook(book) { _ in
                                onUpdate()
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onAppear {
                SchoolLibraryService.shared.fetchCheckoutsForBook(bookId: book.id, schoolId: schoolId) { records in
                    checkouts = records
                    isLoadingHistory = false
                }
            }
        }
    }
}

private struct InfoTile: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
            }
            Spacer()
        }
        .padding(10)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - Create Digital Book Sheet (Photo Pages)
struct CreateDigitalBookSheet: View {
    let schoolId: String
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var category: LibraryBookCategory = .pictureBook
    @State private var gradeLevel = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var pages: [UIImage] = []
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isSaving = false
    @State private var uploadProgress: Double = 0
    @State private var generatedId = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "camera.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Digital Book")
                                .font(.headline)
                            Text("Photograph each page to digitize a book")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if !generatedId.isEmpty {
                                Text("ID: \(generatedId)")
                                    .font(.caption.monospaced())
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .listRowBackground(Color.purple.opacity(0.08))
                }
                
                Section("Book Info") {
                    TextField("Title *", text: $title)
                    TextField("Author *", text: $author)
                    TextField("ISBN (optional)", text: $isbn)
                    Picker("Category", selection: $category) {
                        ForEach(LibraryBookCategory.allCases, id: \.rawValue) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Picker("Grade Level", selection: $gradeLevel) {
                        Text("Select...").tag("")
                        ForEach(["Pre-K", "K-2", "3-5", "6-8", "9-12", "All"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                }
                
                Section("Pages (\(pages.count) captured)") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(pages.enumerated()), id: \.offset) { idx, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("\(idx + 1)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(4)
                                    
                                    Button {
                                        pages.remove(at: idx)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                            
                            // Add page buttons
                            VStack(spacing: 8) {
                                Button {
                                    showCamera = true
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.title3)
                                        Text("Camera")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.purple)
                                    .frame(width: 80, height: 50)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 50, matching: .images) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.title3)
                                        Text("Photos")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.blue)
                                    .frame(width: 80, height: 50)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }
                
                Section("Additional") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...3)
                }
                
                if isSaving {
                    Section {
                        VStack(spacing: 8) {
                            ProgressView(value: uploadProgress)
                                .tint(.purple)
                            Text("Uploading pages... \(Int(uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button {
                        saveDigitalBook()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Digital Book (\(pages.count) pages)")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                    }
                    .disabled(title.isEmpty || author.isEmpty || pages.isEmpty || isSaving)
                    .listRowBackground(
                        (title.isEmpty || author.isEmpty || pages.isEmpty) ? Color.gray : Color.purple
                    )
                }
            }
            .navigationTitle("Digital Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                LibraryCameraView { image in
                    if let image = image {
                        pages.append(image)
                    }
                }
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run { pages.append(image) }
                        }
                    }
                    await MainActor.run { selectedPhotoItems = [] }
                }
            }
            .onAppear {
                SchoolLibraryService.shared.generateBookId(schoolId: schoolId) { id in
                    generatedId = id
                }
            }
        }
    }
    
    private func saveDigitalBook() {
        isSaving = true
        uploadProgress = 0
        
        let uid = Auth.auth().currentUser?.uid ?? ""
        let userName = Auth.auth().currentUser?.displayName ?? "Librarian"
        let totalPages = pages.count
        var uploadedUrls: [String] = Array(repeating: "", count: totalPages)
        let group = DispatchGroup()
        
        for (idx, image) in pages.enumerated() {
            group.enter()
            guard let data = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            let path = "schoolLibraries/\(schoolId)/digitalBooks/\(generatedId)/page_\(String(format: "%03d", idx + 1)).jpg"
            SchoolLibraryService.shared.uploadImage(data, path: path) { result in
                switch result {
                case .success(let url):
                    uploadedUrls[idx] = url
                case .failure:
                    break
                }
                DispatchQueue.main.async {
                    uploadProgress = Double(uploadedUrls.filter { !$0.isEmpty }.count) / Double(totalPages)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let validUrls = uploadedUrls.filter { !$0.isEmpty }
            let book = LibraryBook(
                id: UUID().uuidString,
                bookId: generatedId,
                title: title,
                author: author,
                isbn: isbn,
                publisher: "",
                publishYear: nil,
                category: category,
                condition: .new,
                totalCopies: 1,
                availableCopies: 1,
                gradeLevel: gradeLevel,
                description: description,
                coverImageUrl: validUrls.first,
                location: "Digital",
                tags: ["digital", "photo-scanned"],
                isDigital: true,
                digitalPages: validUrls,
                pageCount: validUrls.count,
                addedAt: Date(),
                addedByUserId: uid,
                addedByName: userName,
                lastEditedAt: Date(),
                schoolId: schoolId,
                barcode: nil,
                notes: notes
            )
            
            SchoolLibraryService.shared.addBook(book) { error in
                isSaving = false
                if error == nil {
                    onComplete()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Library Camera View
struct LibraryCameraView: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LibraryCameraView
        init(_ parent: LibraryCameraView) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            parent.completion(image)
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            parent.dismiss()
        }
    }
}
