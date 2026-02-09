//
//  FreeBooksView.swift
//  EZTeach
//
//  Free public-domain books from multiple sources:
//  - Project Gutenberg, Open Library, Internet Archive
//  - Direct read links, download support
//

import SwiftUI
import FirebaseAuth

struct FreeBooksView: View {
    @State private var searchText = ""
    @State private var books: [GutendexBook] = []
    @State private var isLoading = false
    @State private var selectedBook: GutendexBook?
    @State private var floatingBooks: [Int] = Array(0..<6)
    @State private var animateHeader = false
    @State private var selectedSource: BookSource? = nil
    @State private var selectedCategory: String? = nil
    @State private var showDownloadSheet = false
    @State private var bookToDownload: GutendexBook?
    @State private var downloadProgress: String = ""
    @State private var showDirectLinkSheet = false
    @State private var bookForDirectLink: GutendexBook?
    
    private let categories = ["Children", "Adventure", "Science Fiction", "Mystery", "Fantasy", "Poetry", "History", "Biography"]
    
    var body: some View {
        ZStack {
            // Animated library background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.93, blue: 0.88),
                    Color(red: 0.9, green: 0.87, blue: 0.8),
                    Color(red: 0.85, green: 0.8, blue: 0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating book decorations
            GeometryReader { geo in
                ForEach(floatingBooks, id: \.self) { i in
                    FloatingBookDecoration(index: i)
                        .position(
                            x: CGFloat.random(in: 40...(geo.size.width - 40)),
                            y: CGFloat(i) * (geo.size.height / 6) + 50
                        )
                }
            }
            .opacity(0.3)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Animated header
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "books.vertical.fill")
                                .font(.title)
                                .foregroundColor(.brown)
                                .rotationEffect(.degrees(animateHeader ? -5 : 5))
                            Text("FREE LIBRARY")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.15))
                            Image(systemName: "books.vertical.fill")
                                .font(.title)
                                .foregroundColor(.brown)
                                .rotationEffect(.degrees(animateHeader ? 5 : -5))
                        }
                        
                        Text("100+ picture books & thousands of free classics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Source badges
                        HStack(spacing: 8) {
                            ForEach([BookSource.gutenberg, .openLibrary, .internetArchive], id: \.rawValue) { source in
                                HStack(spacing: 4) {
                                    Image(systemName: source.icon)
                                        .font(.caption2)
                                    Text(source.rawValue)
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .foregroundColor(.brown.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            animateHeader = true
                        }
                    }
                    
                    // Search bar with book styling
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.brown)
                        TextField("Search millions of free books...", text: $searchText)
                            .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                            .autocorrectionDisabled()
                            .onSubmit { search() }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                loadPopular()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .brown.opacity(0.15), radius: 10, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.brown.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Category pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                    loadCategory(category)
                                } label: {
                                    Text(category)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedCategory == category ? .white : .brown)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color.brown : Color.white.opacity(0.8))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    Button {
                        search()
                    } label: {
                        HStack {
                            Image(systemName: "text.magnifyingglass")
                            Text("Search All Libraries")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.5, green: 0.35, blue: 0.2), Color(red: 0.4, green: 0.25, blue: 0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .brown.opacity(0.3), radius: 8)
                    }
                    
                    // Picture Books Collection (100 classic children's books)
                    pictureBooksBanner
                    
                    // Read Together Feature
                    readTogetherBanner
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            AnimatedBookLoader()
                            Text("Searching libraries worldwide...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else if books.isEmpty {
                        EmptyLibraryView()
                    } else {
                        // Results count
                        HStack {
                            Text("\(books.count) classic books shown  •  100+ picture books below")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        // Book grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(books) { book in
                                EnhancedBookCardWithActions(
                                    book: book,
                                    onRead: { selectedBook = book },
                                    onDirectLink: {
                                        bookForDirectLink = book
                                        showDirectLinkSheet = true
                                    },
                                    onDownload: {
                                        bookToDownload = book
                                        showDownloadSheet = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Free Books")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedBook) { book in
            FlipBookReaderView(book: book)
        }
        .sheet(isPresented: $showDirectLinkSheet) {
            if let book = bookForDirectLink {
                DirectLinkSheet(book: book)
            }
        }
        .sheet(isPresented: $showDownloadSheet) {
            if let book = bookToDownload {
                DownloadSheet(book: book)
            }
        }
        .onAppear {
            if books.isEmpty && searchText.isEmpty {
                loadPopular()
            }
        }
    }
    
    // MARK: - Picture Books Banner
    private var pictureBooksBanner: some View {
        NavigationLink {
            PictureBooksView()
        } label: {
            HStack(spacing: 16) {
                // Book stack icon
                VStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill([Color.red, Color.blue, Color.green][i])
                            .frame(width: 32, height: 8)
                            .offset(x: CGFloat(i - 1) * 3)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("100 Picture Books")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("NEW")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    
                    Text("Pete the Cat, Dr. Seuss, Eric Carle & more!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(EZTeachColors.brightTeal)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .brown.opacity(0.15), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.red.opacity(0.3), .blue.opacity(0.3), .green.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Read Together Banner
    private var readTogetherBanner: some View {
        NavigationLink {
            MultiplayerReadingHubView(
                userId: Auth.auth().currentUser?.uid ?? "",
                userName: Auth.auth().currentUser?.displayName ?? "Reader",
                schoolId: ""
            )
        } label: {
            HStack(spacing: 16) {
                // Reader icons
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Read Together")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("MULTIPLAYER")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .cornerRadius(4)
                    }
                    
                    Text("Share reading sessions with friends & family")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .purple.opacity(0.15), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func search() {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        selectedCategory = nil
        if q.isEmpty {
            loadPopular()
        } else {
            isLoading = true
            // Search all sources
            GutendexService.shared.searchAllSources(query: q) { results in
                books = results
                isLoading = false
            }
        }
    }
    
    private func loadPopular() {
        isLoading = true
        selectedCategory = nil
        GutendexService.shared.fetchPopular { results in
            books = results
            isLoading = false
        }
    }
    
    private func loadCategory(_ category: String) {
        isLoading = true
        GutendexService.shared.fetchByCategory(category: category.lowercased()) { results in
            books = results
            isLoading = false
        }
    }
}

// MARK: - Enhanced Book Card with Actions (Proper Book Aspect Ratio)
struct EnhancedBookCardWithActions: View {
    let book: GutendexBook
    let onRead: () -> Void
    let onDirectLink: () -> Void
    let onDownload: () -> Void
    @State private var isHovered = false
    
    private var bookColor: Color {
        colorForSubject(book.subjects.first ?? book.title)
    }
    
    // Fallback cover when no cover image URL is available from the API
    private var fallbackCover: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [bookColor, bookColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.12), .clear, .black.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: iconForSubject(book.subjects.first ?? ""))
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 2)
                Text(book.title.prefix(25) + (book.title.count > 25 ? "..." : ""))
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                Spacer()
            }
            .padding(.vertical, 8)
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.yellow.opacity(0.4), lineWidth: 2)
                .padding(8)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Book cover - show real cover image if available
            ZStack {
                HStack(spacing: 0) {
                    // Spine
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [bookColor.opacity(0.5), bookColor.opacity(0.8), bookColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        VStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.1))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .frame(width: 12)
                    
                    // Cover — real image or fallback
                    ZStack {
                        if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                            // Real cover image from API
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    fallbackCover
                                case .empty:
                                    ZStack {
                                        Rectangle().fill(bookColor.opacity(0.3))
                                        ProgressView()
                                            .tint(.white)
                                    }
                                @unknown default:
                                    fallbackCover
                                }
                            }
                        } else {
                            fallbackCover
                        }
                        
                        // Source badge overlay (bottom-left)
                        VStack {
                            Spacer()
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: book.source.icon)
                                        .font(.system(size: 8))
                                    Text(book.source.rawValue.prefix(10))
                                        .font(.system(size: 7, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.55))
                                .cornerRadius(6)
                                Spacer()
                            }
                            .padding(6)
                        }
                    }
                    .clipped()
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.25), radius: isHovered ? 12 : 8, x: 4, y: isHovered ? 8 : 6)
                
                // Page edges
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(red: 0.95, green: 0.93, blue: 0.88))
                            .frame(width: 2, height: 20)
                    }
                }
                .offset(x: 58)
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onTapGesture { onRead() }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isHovered = true
                }
            }
            
            // Book info below cover
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Action buttons row
                HStack(spacing: 6) {
                    // Read button
                    Button(action: onRead) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 10))
                            Text("Read")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(bookColor)
                        .cornerRadius(8)
                    }
                    
                    // Direct link button
                    Button(action: onDirectLink) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(8)
                    }
                    
                    // Download button
                    if book.bestDownloadUrl != nil {
                        Button(action: onDownload) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                                .padding(6)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .brown.opacity(0.12), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.brown.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Direct Link Sheet
struct DirectLinkSheet: View {
    let book: GutendexBook
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Book cover preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorForSubject(book.subjects.first ?? book.title))
                        .frame(width: 100, height: 140)
                    Image(systemName: iconForSubject(book.subjects.first ?? ""))
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .shadow(radius: 10)
                
                Text(book.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("Choose how to read this book")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    // Read online button
                    if let url = book.readOnlineUrl, let linkUrl = URL(string: url) {
                        Button {
                            openURL(linkUrl)
                        } label: {
                            HStack {
                                Image(systemName: "safari.fill")
                                Text("Read Online (No Signup)")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Gutenberg direct link
                    if book.source == .gutenberg {
                        Button {
                            if let url = URL(string: "https://www.gutenberg.org/ebooks/\(book.id)") {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                Text("Project Gutenberg")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.brown)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Internet Archive link
                    if book.source == .openLibrary, let url = book.directReadUrl, let linkUrl = URL(string: url) {
                        Button {
                            openURL(linkUrl)
                        } label: {
                            HStack {
                                Image(systemName: "archivebox.fill")
                                Text("Internet Archive")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
                    
                    // HTML version
                    if let htmlUrl = book.htmlUrl, let url = URL(string: htmlUrl) {
                        Button {
                            openURL(url)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Read HTML Version")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .foregroundColor(.brown)
                            .padding()
                            .background(Color.brown.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Read Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Download Sheet
struct DownloadSheet: View {
    let book: GutendexBook
    @Environment(\.dismiss) private var dismiss
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var downloadError: String?
    @State private var downloadedUrl: URL?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Book cover preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorForSubject(book.subjects.first ?? book.title))
                        .frame(width: 100, height: 140)
                    Image(systemName: iconForSubject(book.subjects.first ?? ""))
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .shadow(radius: 10)
                
                Text(book.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if isDownloading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Downloading...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if downloadComplete {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("Download Complete!")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("Saved to your device")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = downloadError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text("Download Failed")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text("Choose download format")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        // EPUB download
                        if book.epubUrl != nil {
                            Button {
                                downloadBook(format: .epub)
                            } label: {
                                HStack {
                                    Image(systemName: "book.fill")
                                    Text("Download EPUB")
                                    Spacer()
                                    Text("Best for reading")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        
                        // PDF download
                        if book.pdfUrl != nil {
                            Button {
                                downloadBook(format: .pdf)
                            } label: {
                                HStack {
                                    Image(systemName: "doc.fill")
                                    Text("Download PDF")
                                    Spacer()
                                    Text("Universal format")
                                        .font(.caption)
                                        .foregroundColor(.brown.opacity(0.7))
                                }
                                .foregroundColor(.brown)
                                .padding()
                                .background(Color.brown.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Text download
                        if book.textUrl != nil {
                            Button {
                                downloadBook(format: .text)
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Download Text")
                                    Spacer()
                                    Text("Smallest size")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .foregroundColor(.gray)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Download Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func downloadBook(format: BookFormat) {
        isDownloading = true
        downloadError = nil
        
        GutendexService.shared.downloadBook(book, format: format) { result in
            isDownloading = false
            switch result {
            case .success(let url):
                downloadedUrl = url
                downloadComplete = true
            case .failure(let error):
                downloadError = error.localizedDescription
            }
        }
    }
}

// MARK: - Floating Book Decoration
struct FloatingBookDecoration: View {
    let index: Int
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    
    private var bookColor: Color {
        [Color.brown, .red.opacity(0.7), .blue.opacity(0.7), .green.opacity(0.7), .purple.opacity(0.7), .orange.opacity(0.7)][index % 6]
    }
    
    var body: some View {
        ZStack {
            // Book spine
            RoundedRectangle(cornerRadius: 4)
                .fill(bookColor)
                .frame(width: 30, height: 45)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(bookColor.opacity(0.5), lineWidth: 1)
                )
            
            // Spine detail
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 2, height: 35)
                .offset(x: -8)
        }
        .shadow(color: .black.opacity(0.1), radius: 4)
        .offset(y: offset)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 3...5)).repeatForever(autoreverses: true)) {
                offset = CGFloat.random(in: -20...20)
                rotation = Double.random(in: -10...10)
            }
        }
    }
}

// MARK: - Animated Book Loader
struct AnimatedBookLoader: View {
    @State private var pageFlip: Double = 0
    
    var body: some View {
        ZStack {
            // Book base
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.brown)
                .frame(width: 60, height: 80)
            
            // Animated pages
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.92))
                    .frame(width: 50, height: 70)
                    .rotation3DEffect(
                        .degrees(pageFlip + Double(i * 45)),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading
                    )
                    .opacity(0.9)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                pageFlip = 180
            }
        }
    }
}

// MARK: - Empty Library View
struct EmptyLibraryView: View {
    @State private var bookScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Bookshelf
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.brown.opacity(0.4))
                        .frame(height: 10)
                        .cornerRadius(2)
                }
                .frame(width: 160, height: 120)
                
                // Books on shelf
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill([Color.red, .blue, .green, .purple, .orange][i].opacity(0.6))
                            .frame(width: 20, height: CGFloat([60, 70, 55, 65, 58][i]))
                            .offset(y: 30 - CGFloat([60, 70, 55, 65, 58][i]) / 2)
                    }
                }
            }
            .scaleEffect(bookScale)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    bookScale = 1.05
                }
            }
            
            Text("Discover Classic Literature")
                .font(.headline)
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.15))
            
            Text("Search for titles like:\n\"Alice in Wonderland\" • \"Pride and Prejudice\"\n\"Frankenstein\" • \"Sherlock Holmes\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Enhanced Book Card
struct EnhancedBookCard: View {
    let book: GutendexBook
    @State private var isHovered = false
    
    private var bookColor: Color {
        colorForSubject(book.subjects.first ?? book.title)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Book cover
            ZStack {
                // 3D book effect
                HStack(spacing: 0) {
                    // Spine
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [bookColor.opacity(0.6), bookColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 8)
                    
                    // Cover
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [bookColor, bookColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Cover sheen
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear, .black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Topic icon
                        VStack(spacing: 8) {
                            Image(systemName: iconForSubject(book.subjects.first ?? ""))
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.9))
                            
                            if book.subjects.count > 1 {
                                Image(systemName: iconForSubject(book.subjects[1]))
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        // Gold border
                        Rectangle()
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                            .padding(6)
                    }
                }
                .frame(height: 140)
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.2), radius: isHovered ? 12 : 6, y: isHovered ? 8 : 4)
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isHovered = true
                }
            }
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Subject tags
                if let subject = book.subjects.first {
                    Text(subject.components(separatedBy: " -- ").first ?? subject)
                        .font(.system(size: 9))
                        .foregroundColor(bookColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(bookColor.opacity(0.15))
                        .cornerRadius(4)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .brown.opacity(0.1), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brown.opacity(0.15), lineWidth: 1)
        )
    }
}

// Legacy row for compatibility
struct FreeBookRow: View {
    let book: GutendexBook
    
    var body: some View {
        EnhancedBookCard(book: book)
    }
}

struct GutendexBookReaderView: View {
    let book: GutendexBook
    @Environment(\.dismiss) private var dismiss
    @State private var textContent = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.lightAppealGradient.ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView("Loading...")
                            .tint(EZTeachColors.brightTeal)
                    } else if let err = errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(EZTeachColors.lightCoral.opacity(0.8))
                            Text(err)
                                .font(.subheadline)
                                .foregroundColor(EZTeachColors.textDark)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            Text(textContent)
                                .font(.body)
                                .foregroundColor(EZTeachColors.textDark)
                                .lineSpacing(10)
                                .padding(24)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.6))
                                .padding(16)
                        )
                    }
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(EZTeachColors.brightTeal)
                }
            }
            .onAppear { fetchContent() }
        }
    }
    
    private func fetchContent() {
        guard var urlString = book.textUrl else {
            errorMessage = "No text available for this book."
            isLoading = false
            return
        }
        if urlString.hasPrefix("http://") && urlString.contains("gutenberg") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid book URL."
            isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    errorMessage = err.localizedDescription
                    return
                }
                guard let data = data,
                      let str = String(data: data, encoding: .utf8) else {
                    errorMessage = "Could not load book content."
                    return
                }
                let startRange = str.range(of: "*** START OF")
                let endRange = str.range(of: "*** END OF")
                let start = startRange?.lowerBound ?? str.startIndex
                let end = endRange?.lowerBound ?? str.endIndex
                textContent = String(str[start..<end])
                    .replacingOccurrences(of: "\r\n", with: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }.resume()
    }
}
