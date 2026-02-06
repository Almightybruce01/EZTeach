//
//  SchoolLibraryView.swift
//  EZTeach
//
//  School Library: books curated by the school. All users can view; school & librarian can add/remove.
//

import SwiftUI
import FirebaseAuth

enum LibrarySearchFilter: String, CaseIterable {
    case all = "All"
    case title = "Title"
    case author = "Author"
    case subject = "Subject"
}

struct SchoolLibraryView: View {
    let schoolId: String
    let canEdit: Bool

    @State private var books: [SchoolLibraryBook] = []
    @State private var isLoading = true
    @State private var selectedBook: SchoolLibraryBook?
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var searchFilter: LibrarySearchFilter = .all
    @FocusState private var searchFocused: Bool

    init(schoolId: String, canEdit: Bool) {
        self.schoolId = schoolId
        self.canEdit = canEdit
    }

    private var filteredBooks: [SchoolLibraryBook] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return books }
        return books.filter { book in
            switch searchFilter {
            case .all:
                return book.title.localizedCaseInsensitiveContains(q)
                    || book.authors.contains { $0.localizedCaseInsensitiveContains(q) }
                    || book.subjects.contains { $0.localizedCaseInsensitiveContains(q) }
            case .title:
                return book.title.localizedCaseInsensitiveContains(q)
            case .author:
                return book.authors.contains { $0.localizedCaseInsensitiveContains(q) }
            case .subject:
                return book.subjects.contains { $0.localizedCaseInsensitiveContains(q) }
            }
        }
    }

    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                if canEdit {
                    HStack {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add from Free Books", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(EZTeachColors.brightTeal)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(EZTeachColors.brightTeal.opacity(0.15))
                }

                // Search bar
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(EZTeachColors.brightTeal)
                        TextField("Search by title, author, or subject...", text: $searchText)
                            .foregroundColor(EZTeachColors.textDark)
                            .autocorrectionDisabled()
                            .focused($searchFocused)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(EZTeachColors.brightTeal.opacity(0.3), lineWidth: 1)
                    )

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(LibrarySearchFilter.allCases, id: \.rawValue) { filter in
                                Button {
                                    searchFilter = filter
                                } label: {
                                    Text(filter.rawValue)
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(searchFilter == filter ? .white : EZTeachColors.textMutedLight)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(searchFilter == filter ? EZTeachColors.brightTeal : Color.white.opacity(0.8))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(EZTeachColors.brightTeal.opacity(0.08))

                if isLoading {
                    Spacer()
                    ProgressView("Loading library...")
                        .tint(EZTeachColors.brightTeal)
                    Spacer()
                } else if books.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "School Library",
                        systemImage: "books.vertical.fill",
                        description: Text(canEdit ? "Add books from Free Books to build your school library." : "No books in the library yet.")
                    )
                    .tint(EZTeachColors.brightTeal)
                    Spacer()
                } else if filteredBooks.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(EZTeachColors.brightTeal.opacity(0.6))
                        Text("No matches for \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(EZTeachColors.textDark)
                        Text("Try a different search or filter")
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textMutedLight)
                        Button("Clear search") {
                            searchText = ""
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(EZTeachColors.brightTeal)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBooks) { book in
                                SchoolLibraryBookRow(book: book, canEdit: canEdit) {
                                    selectedBook = book
                                } onRemove: {
                                    removeBook(book)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("School Library")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedBook) { book in
            FlipBookReaderView(book: book.toGutendexBook())
        }
        .sheet(isPresented: $showAddSheet) {
            AddToSchoolLibrarySheet(schoolId: schoolId, onDismiss: { showAddSheet = false })
        }
        .onAppear {
            loadBooks()
        }
    }

    private func loadBooks() {
        isLoading = true
        SchoolLibraryService.shared.fetchBooks(schoolId: schoolId) { result in
            books = result
            isLoading = false
        }
    }

    private func removeBook(_ book: SchoolLibraryBook) {
        SchoolLibraryService.shared.removeBook(gutendexId: book.gutendexId, schoolId: schoolId) { _ in
            loadBooks()
        }
    }
}

struct SchoolLibraryBookRow: View {
    let book: SchoolLibraryBook
    let canEdit: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    private var subjectTags: [String] {
        Array(book.subjects.prefix(3))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [EZTeachColors.brightTeal.opacity(0.85), EZTeachColors.softBlue.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 84)
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(EZTeachColors.textDark)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text(book.authorDisplay)
                                .font(.caption)
                        }
                        .foregroundColor(EZTeachColors.textMutedLight)

                        if !subjectTags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(subjectTags, id: \.self) { s in
                                        Text(s)
                                            .font(.caption2)
                                            .foregroundColor(EZTeachColors.brightTeal)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(EZTeachColors.brightTeal.opacity(0.15))
                                            )
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(EZTeachColors.brightTeal.opacity(0.8))
                }
            }
            .buttonStyle(.plain)

            if canEdit {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.body)
                        .foregroundColor(EZTeachColors.error)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(EZTeachColors.brightTeal.opacity(0.25), lineWidth: 1)
        )
    }
}

struct AddToSchoolLibrarySheet: View {
    let schoolId: String
    let onDismiss: () -> Void

    @State private var searchText = ""
    @State private var gutendexResults: [GutendexBook] = []
    @State private var isSearching = false
    @State private var libraryBookIds: Set<Int> = []

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.lightAppealGradient.ignoresSafeArea()

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search by title or author")
                            .font(.caption.weight(.medium))
                            .foregroundColor(EZTeachColors.textMutedLight)
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(EZTeachColors.brightTeal)
                            TextField("e.g. Alice, Pride, Frankenstein, Austen...", text: $searchText)
                                .foregroundColor(EZTeachColors.textDark)
                                .autocorrectionDisabled()
                                .onSubmit { search() }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(EZTeachColors.brightTeal.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Button {
                        search()
                    } label: {
                        Label("Search Project Gutenberg", systemImage: "book.circle.fill")
                            .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(EZTeachColors.brightTeal)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)

                    if isSearching {
                        ProgressView()
                            .padding()
                    } else if gutendexResults.isEmpty && !searchText.isEmpty {
                        Text("No results. Try another search.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else if gutendexResults.isEmpty {
                        Text("Search for books from Project Gutenberg to add to your school library.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(gutendexResults) { book in
                                    AddLibraryBookRow(
                                        book: book,
                                        isInLibrary: libraryBookIds.contains(book.id),
                                        onAdd: { addBook(book) }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add to Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(EZTeachColors.brightTeal)
                }
            }
            .onAppear {
                SchoolLibraryService.shared.fetchBooks(schoolId: schoolId) { books in
                    libraryBookIds = Set(books.map { $0.gutendexId })
                }
            }
        }
    }

    private func search() {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        isSearching = true
        GutendexService.shared.search(query: q) { results in
            gutendexResults = results
            isSearching = false
        }
    }

    private func addBook(_ book: GutendexBook) {
        let uid = Auth.auth().currentUser?.uid
        SchoolLibraryService.shared.addBook(book, schoolId: schoolId, userId: uid) { _ in
            libraryBookIds.insert(book.id)
        }
    }
}

struct AddLibraryBookRow: View {
    let book: GutendexBook
    let isInLibrary: Bool
    let onAdd: () -> Void

    private var subjectPreview: String {
        book.subjects.prefix(2).joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [EZTeachColors.brightTeal.opacity(0.7), EZTeachColors.softBlue.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 72)
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(EZTeachColors.textDark)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text(book.authors.joined(separator: ", "))
                        .font(.caption)
                }
                .foregroundColor(EZTeachColors.textMutedLight)
                .lineLimit(1)
                if !book.subjects.isEmpty {
                    Text(subjectPreview)
                        .font(.caption2)
                        .foregroundColor(EZTeachColors.brightTeal.opacity(0.9))
                        .lineLimit(1)
                }
            }

            Spacer()

            if isInLibrary {
                Label("Added", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundColor(EZTeachColors.brightTeal)
            } else {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(EZTeachColors.brightTeal)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(EZTeachColors.brightTeal.opacity(0.2), lineWidth: 1)
        )
    }
}
