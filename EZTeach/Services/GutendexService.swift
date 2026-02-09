//
//  GutendexService.swift
//  EZTeach
//
//  Fetches free public-domain ebooks from multiple sources:
//  - Project Gutenberg (via Gutendex API)
//  - Open Library (Internet Archive)
//  - Standard Ebooks
//  - Feedbooks Public Domain
//

import Foundation

// MARK: - Book Source Enum
enum BookSource: String, CaseIterable {
    case gutenberg = "Project Gutenberg"
    case openLibrary = "Open Library"
    case standardEbooks = "Standard Ebooks"
    case feedbooks = "Feedbooks"
    case internetArchive = "Internet Archive"
    
    var icon: String {
        switch self {
        case .gutenberg: return "book.closed.fill"
        case .openLibrary: return "books.vertical.fill"
        case .standardEbooks: return "text.book.closed.fill"
        case .feedbooks: return "book.fill"
        case .internetArchive: return "archivebox.fill"
        }
    }
}

struct GutendexBook: Identifiable, Equatable {
    let id: Int
    let title: String
    let authors: [String]
    let subjects: [String]
    let textUrl: String?
    let epubUrl: String?
    let pdfUrl: String?
    let htmlUrl: String?
    let source: BookSource
    let coverUrl: String?
    let downloadCount: Int?
    let directReadUrl: String? // Direct link to read in browser
    
    init(id: Int, title: String, authors: [String], subjects: [String], textUrl: String?, epubUrl: String? = nil, pdfUrl: String? = nil, htmlUrl: String? = nil, source: BookSource = .gutenberg, coverUrl: String? = nil, downloadCount: Int? = nil, directReadUrl: String? = nil) {
        self.id = id
        self.title = title
        self.authors = authors
        self.subjects = subjects
        self.textUrl = textUrl
        self.epubUrl = epubUrl
        self.pdfUrl = pdfUrl
        self.htmlUrl = htmlUrl
        self.source = source
        self.coverUrl = coverUrl
        self.downloadCount = downloadCount
        self.directReadUrl = directReadUrl
    }
    
    /// Get the best available download URL
    var bestDownloadUrl: String? {
        return epubUrl ?? pdfUrl ?? textUrl
    }
    
    /// Get direct read URL (for opening in browser)
    var readOnlineUrl: String? {
        if let direct = directReadUrl { return direct }
        if let html = htmlUrl { return html }
        // Gutenberg has online reader
        if source == .gutenberg {
            return "https://www.gutenberg.org/ebooks/\(id)"
        }
        return nil
    }
}

// Parsed manually to avoid Swift 6 Main actor-isolated Decodable conformance
private func parseGutendexResponse(_ data: Data) -> [GutendexBook]? {
    guard let obj = try? JSONSerialization.jsonObject(with: data),
          let json = obj as? [String: Any],
          let results = json["results"] as? [[String: Any]] else { return nil }
    var books: [GutendexBook] = []
    for r in results {
        guard let id = r["id"] as? Int,
              let title = r["title"] as? String else { continue }
        let authors: [String] = (r["authors"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
        let subjects: [String] = r["subjects"] as? [String] ?? []
        let formats = r["formats"] as? [String: String]
        let textUrl = formats?["text/plain"] ?? formats?["text/plain; charset=utf-8"]
        let epubUrl = formats?["application/epub+zip"]
        let pdfUrl = formats?["application/pdf"]
        let htmlUrl = formats?["text/html"] ?? formats?["text/html; charset=utf-8"]
        let coverUrl = formats?["image/jpeg"]
        let downloadCount = r["download_count"] as? Int
        
        books.append(GutendexBook(
            id: id,
            title: title,
            authors: authors,
            subjects: subjects,
            textUrl: textUrl,
            epubUrl: epubUrl,
            pdfUrl: pdfUrl,
            htmlUrl: htmlUrl,
            source: .gutenberg,
            coverUrl: coverUrl,
            downloadCount: downloadCount,
            directReadUrl: "https://www.gutenberg.org/ebooks/\(id)"
        ))
    }
    return books
}

// Parse Open Library response
private func parseOpenLibraryResponse(_ data: Data) -> [GutendexBook]? {
    guard let obj = try? JSONSerialization.jsonObject(with: data),
          let json = obj as? [String: Any],
          let docs = json["docs"] as? [[String: Any]] else { return nil }
    var books: [GutendexBook] = []
    var idCounter = 100000 // Use high IDs to avoid collision with Gutenberg
    
    for doc in docs {
        guard let title = doc["title"] as? String,
              let hasFulltext = doc["has_fulltext"] as? Bool,
              hasFulltext else { continue }
        
        let authors: [String] = doc["author_name"] as? [String] ?? []
        let subjects: [String] = doc["subject"] as? [String] ?? []
        let coverId = doc["cover_i"] as? Int
        let iaIds = doc["ia"] as? [String] ?? []
        let firstIa = iaIds.first
        
        // Build URLs
        var textUrl: String? = nil
        var epubUrl: String? = nil
        var pdfUrl: String? = nil
        var directReadUrl: String? = nil
        var coverUrl: String? = nil
        
        if let coverId = coverId {
            coverUrl = "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
        }
        
        if let ia = firstIa {
            // Internet Archive direct links (no signup required!)
            textUrl = "https://archive.org/download/\(ia)/\(ia)_djvu.txt"
            epubUrl = "https://archive.org/download/\(ia)/\(ia).epub"
            pdfUrl = "https://archive.org/download/\(ia)/\(ia).pdf"
            directReadUrl = "https://archive.org/details/\(ia)"
        }
        
        books.append(GutendexBook(
            id: idCounter,
            title: title,
            authors: authors,
            subjects: Array(subjects.prefix(5)),
            textUrl: textUrl,
            epubUrl: epubUrl,
            pdfUrl: pdfUrl,
            htmlUrl: nil,
            source: .openLibrary,
            coverUrl: coverUrl,
            downloadCount: nil,
            directReadUrl: directReadUrl
        ))
        idCounter += 1
    }
    return books
}

// Parse Standard Ebooks OPDS feed
private func parseStandardEbooksResponse(_ data: Data) -> [GutendexBook]? {
    // Standard Ebooks uses OPDS/Atom XML - simplified parsing
    guard let xmlString = String(data: data, encoding: .utf8) else { return nil }
    var books: [GutendexBook] = []
    var idCounter = 200000
    
    // Simple regex-based parsing for OPDS
    let entryPattern = "<entry>(.*?)</entry>"
    let titlePattern = "<title>(.*?)</title>"
    let authorPattern = "<name>(.*?)</name>"
    let linkPattern = "<link[^>]*href=\"([^\"]+)\"[^>]*type=\"([^\"]+)\"[^>]*/>"
    
    let entryRegex = try? NSRegularExpression(pattern: entryPattern, options: [.dotMatchesLineSeparators])
    let entries = entryRegex?.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString)) ?? []
    
    for entryMatch in entries.prefix(30) {
        guard let entryRange = Range(entryMatch.range(at: 1), in: xmlString) else { continue }
        let entry = String(xmlString[entryRange])
        
        // Extract title
        var title = "Unknown"
        if let titleRegex = try? NSRegularExpression(pattern: titlePattern),
           let titleMatch = titleRegex.firstMatch(in: entry, range: NSRange(entry.startIndex..., in: entry)),
           let titleRange = Range(titleMatch.range(at: 1), in: entry) {
            title = String(entry[titleRange])
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
        }
        
        // Extract author
        var authors: [String] = []
        if let authorRegex = try? NSRegularExpression(pattern: authorPattern),
           let authorMatch = authorRegex.firstMatch(in: entry, range: NSRange(entry.startIndex..., in: entry)),
           let authorRange = Range(authorMatch.range(at: 1), in: entry) {
            authors = [String(entry[authorRange])]
        }
        
        // Extract links
        var epubUrl: String? = nil
        var coverUrl: String? = nil
        if let linkRegex = try? NSRegularExpression(pattern: linkPattern) {
            let linkMatches = linkRegex.matches(in: entry, range: NSRange(entry.startIndex..., in: entry))
            for linkMatch in linkMatches {
                if let hrefRange = Range(linkMatch.range(at: 1), in: entry),
                   let typeRange = Range(linkMatch.range(at: 2), in: entry) {
                    let href = String(entry[hrefRange])
                    let type = String(entry[typeRange])
                    if type.contains("epub") {
                        epubUrl = href
                    } else if type.contains("image") {
                        coverUrl = href
                    }
                }
            }
        }
        
        books.append(GutendexBook(
            id: idCounter,
            title: title,
            authors: authors,
            subjects: ["Literature", "Classic"],
            textUrl: nil,
            epubUrl: epubUrl,
            pdfUrl: nil,
            htmlUrl: nil,
            source: .standardEbooks,
            coverUrl: coverUrl,
            downloadCount: nil,
            directReadUrl: "https://standardebooks.org/ebooks"
        ))
        idCounter += 1
    }
    return books
}

final class GutendexService {
    static let shared = GutendexService()
    private let gutendexBase = "https://gutendex.com"
    private let openLibraryBase = "https://openlibrary.org"
    private let standardEbooksBase = "https://standardebooks.org"
    private let internetArchiveBase = "https://archive.org"
    
    private init() {}
    
    // MARK: - Search All Sources
    func searchAllSources(query: String, completion: @escaping ([GutendexBook]) -> Void) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        var allBooks: [GutendexBook] = []
        let lock = NSLock()
        
        // Search Gutenberg
        group.enter()
        search(query: query) { books in
            lock.lock()
            allBooks.append(contentsOf: books)
            lock.unlock()
            group.leave()
        }
        
        // Search Open Library
        group.enter()
        searchOpenLibrary(query: query) { books in
            lock.lock()
            allBooks.append(contentsOf: books)
            lock.unlock()
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Remove duplicates by title similarity
            var seen = Set<String>()
            let unique = allBooks.filter { book in
                let key = book.title.lowercased().prefix(30)
                if seen.contains(String(key)) { return false }
                seen.insert(String(key))
                return true
            }
            completion(unique)
        }
    }
    
    // MARK: - Gutenberg Search
    func search(query: String, completion: @escaping ([GutendexBook]) -> Void) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion([])
            return
        }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(gutendexBase)/books?search=\(encoded)") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let books = parseGutendexResponse(data)?.prefix(30) ?? []
            DispatchQueue.main.async { completion(Array(books)) }
        }.resume()
    }
    
    // MARK: - Open Library Search
    func searchOpenLibrary(query: String, completion: @escaping ([GutendexBook]) -> Void) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion([])
            return
        }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        // has_fulltext=true ensures we only get books with free full text
        guard let url = URL(string: "\(openLibraryBase)/search.json?q=\(encoded)&has_fulltext=true&limit=20") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let books = parseOpenLibraryResponse(data) ?? []
            DispatchQueue.main.async { completion(books) }
        }.resume()
    }
    
    // MARK: - Fetch Popular
    func fetchPopular(completion: @escaping ([GutendexBook]) -> Void) {
        guard let url = URL(string: "\(gutendexBase)/books?sort=popular") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let books = parseGutendexResponse(data)?.prefix(24) ?? []
            DispatchQueue.main.async { completion(Array(books)) }
        }.resume()
    }
    
    // MARK: - Fetch by Category
    func fetchByCategory(category: String, completion: @escaping ([GutendexBook]) -> Void) {
        let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        guard let url = URL(string: "\(gutendexBase)/books?topic=\(encoded)") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let books = parseGutendexResponse(data)?.prefix(24) ?? []
            DispatchQueue.main.async { completion(Array(books)) }
        }.resume()
    }
    
    // MARK: - Fetch Children's Books
    func fetchChildrensBooks(completion: @escaping ([GutendexBook]) -> Void) {
        guard let url = URL(string: "\(gutendexBase)/books?topic=children") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let books = parseGutendexResponse(data)?.prefix(30) ?? []
            DispatchQueue.main.async { completion(Array(books)) }
        }.resume()
    }
    
    // MARK: - Download Book
    func downloadBook(_ book: GutendexBook, format: BookFormat, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let urlString = format == .epub ? book.epubUrl : (format == .pdf ? book.pdfUrl : book.textUrl),
              let url = URL(string: urlString) else {
            completion(.failure(BookDownloadError.noDownloadUrl))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { tempUrl, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let tempUrl = tempUrl else {
                DispatchQueue.main.async { completion(.failure(BookDownloadError.downloadFailed)) }
                return
            }
            
            // Move to documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let safeTitle = book.title.replacingOccurrences(of: "/", with: "-").prefix(50)
            let fileName = "\(safeTitle).\(format.fileExtension)"
            let destinationUrl = documentsPath.appendingPathComponent(String(fileName))
            
            do {
                // Remove existing file if present
                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                    try FileManager.default.removeItem(at: destinationUrl)
                }
                try FileManager.default.moveItem(at: tempUrl, to: destinationUrl)
                DispatchQueue.main.async { completion(.success(destinationUrl)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        task.resume()
    }
}

// MARK: - Book Format
enum BookFormat: String, CaseIterable {
    case epub = "EPUB"
    case pdf = "PDF"
    case text = "Text"
    
    var fileExtension: String {
        switch self {
        case .epub: return "epub"
        case .pdf: return "pdf"
        case .text: return "txt"
        }
    }
}

// MARK: - Download Errors
enum BookDownloadError: Error, LocalizedError {
    case noDownloadUrl
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .noDownloadUrl: return "No download URL available for this book."
        case .downloadFailed: return "Failed to download the book."
        }
    }
}

// MARK: - Curated Free Book Lists
struct CuratedBookLists {
    /// Classic children's books that are free to read
    static let childrensClassics: [(title: String, gutenbergId: Int)] = [
        ("Alice's Adventures in Wonderland", 11),
        ("The Wonderful Wizard of Oz", 55),
        ("Peter Pan", 16),
        ("The Adventures of Tom Sawyer", 74),
        ("Treasure Island", 120),
        ("The Jungle Book", 236),
        ("Heidi", 1448),
        ("Anne of Green Gables", 45),
        ("The Secret Garden", 113),
        ("Black Beauty", 271),
        ("Little Women", 37),
        ("The Wind in the Willows", 289),
        ("A Little Princess", 146),
        ("The Tale of Peter Rabbit", 14838),
        ("Aesop's Fables", 11339)
    ]
    
    /// Adventure books free to read
    static let adventureBooks: [(title: String, gutenbergId: Int)] = [
        ("Robinson Crusoe", 521),
        ("The Swiss Family Robinson", 3836),
        ("Around the World in 80 Days", 103),
        ("20,000 Leagues Under the Sea", 164),
        ("Journey to the Center of the Earth", 18857),
        ("The Three Musketeers", 1257),
        ("The Count of Monte Cristo", 1184),
        ("King Solomon's Mines", 2166),
        ("The Call of the Wild", 215),
        ("White Fang", 910)
    ]
    
    /// Science & Nature books
    static let scienceBooks: [(title: String, gutenbergId: Int)] = [
        ("The Origin of Species", 1228),
        ("On the Origin of Species", 2009),
        ("The Time Machine", 35),
        ("The War of the Worlds", 36),
        ("The First Men in the Moon", 1013),
        ("Flatland: A Romance of Many Dimensions", 201),
        ("The Voyage of the Beagle", 944)
    ]
    
    /// Poetry collections
    static let poetryBooks: [(title: String, gutenbergId: Int)] = [
        ("Leaves of Grass", 1322),
        ("The Complete Works of William Shakespeare", 100),
        ("The Raven and Other Poems", 17192),
        ("Songs of Innocence and Experience", 1934),
        ("The Waste Land", 1321)
    ]
}
