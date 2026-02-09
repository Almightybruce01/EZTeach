//
//  SchoolLibraryService.swift
//  EZTeach
//
//  Comprehensive school library management service.
//  Handles book catalog, check-in/out, digital books, and analytics.
//  All data is school-scoped — each school only sees their own library.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Book Condition
enum BookCondition: String, CaseIterable, Codable {
    case new = "New"
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case damaged = "Damaged"
    
    var color: String {
        switch self {
        case .new: return "green"
        case .excellent: return "blue"
        case .good: return "teal"
        case .fair: return "orange"
        case .poor: return "red"
        case .damaged: return "gray"
        }
    }
}

// MARK: - Book Category
enum LibraryBookCategory: String, CaseIterable, Codable {
    case fiction = "Fiction"
    case nonFiction = "Non-Fiction"
    case science = "Science"
    case math = "Math"
    case history = "History"
    case biography = "Biography"
    case fantasy = "Fantasy"
    case mystery = "Mystery"
    case adventure = "Adventure"
    case poetry = "Poetry"
    case reference = "Reference"
    case graphic = "Graphic Novel"
    case pictureBook = "Picture Book"
    case earlyReader = "Early Reader"
    case chapterBook = "Chapter Book"
    case youngAdult = "Young Adult"
    case textbook = "Textbook"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .fiction: return "book.fill"
        case .nonFiction: return "newspaper.fill"
        case .science: return "atom"
        case .math: return "function"
        case .history: return "clock.fill"
        case .biography: return "person.fill"
        case .fantasy: return "sparkles"
        case .mystery: return "magnifyingglass"
        case .adventure: return "map.fill"
        case .poetry: return "text.quote"
        case .reference: return "books.vertical.fill"
        case .graphic: return "paintpalette.fill"
        case .pictureBook: return "photo.fill"
        case .earlyReader: return "graduationcap.fill"
        case .chapterBook: return "bookmark.fill"
        case .youngAdult: return "person.2.fill"
        case .textbook: return "text.book.closed.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Checkout Status
enum CheckoutStatus: String, Codable {
    case checkedOut = "checked_out"
    case returned = "returned"
    case overdue = "overdue"
    case lost = "lost"
}

// MARK: - Library Book (Physical or Digital)
struct LibraryBook: Identifiable, Equatable {
    let id: String                     // Firestore document ID
    var bookId: String                 // Unique catalog ID (e.g., "LIB-00142")
    var title: String
    var author: String
    var isbn: String                   // ISBN-10 or ISBN-13
    var publisher: String
    var publishYear: Int?
    var category: LibraryBookCategory
    var condition: BookCondition
    var totalCopies: Int               // How many physical copies the school owns
    var availableCopies: Int           // Currently available (not checked out)
    var gradeLevel: String             // e.g., "K-2", "3-5", "6-8", "9-12"
    var description: String
    var coverImageUrl: String?         // URL to uploaded cover photo
    var location: String               // Shelf location (e.g., "Shelf A3", "Room 102")
    var tags: [String]                 // Searchable tags
    var isDigital: Bool                // If this is a digitized photo-page book
    var digitalPages: [String]         // URLs to page images (for digital books)
    var pageCount: Int
    var addedAt: Date
    var addedByUserId: String
    var addedByName: String
    var lastEditedAt: Date
    var schoolId: String
    var barcode: String?               // Optional barcode/QR for scanning
    var notes: String                  // Librarian notes
    
    // Gutenberg integration (if added from free books)
    var gutendexId: Int?
    var textUrl: String?
    
    var isAvailable: Bool { availableCopies > 0 }
    var checkedOutCount: Int { totalCopies - availableCopies }
    
    static func == (lhs: LibraryBook, rhs: LibraryBook) -> Bool {
        lhs.id == rhs.id
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> LibraryBook? {
        guard let d = doc.data() else { return nil }
        return LibraryBook(
            id: doc.documentID,
            bookId: d["bookId"] as? String ?? "",
            title: d["title"] as? String ?? "",
            author: d["author"] as? String ?? "",
            isbn: d["isbn"] as? String ?? "",
            publisher: d["publisher"] as? String ?? "",
            publishYear: d["publishYear"] as? Int,
            category: LibraryBookCategory(rawValue: d["category"] as? String ?? "") ?? .fiction,
            condition: BookCondition(rawValue: d["condition"] as? String ?? "") ?? .good,
            totalCopies: d["totalCopies"] as? Int ?? 1,
            availableCopies: d["availableCopies"] as? Int ?? 1,
            gradeLevel: d["gradeLevel"] as? String ?? "",
            description: d["description"] as? String ?? "",
            coverImageUrl: d["coverImageUrl"] as? String,
            location: d["location"] as? String ?? "",
            tags: d["tags"] as? [String] ?? [],
            isDigital: d["isDigital"] as? Bool ?? false,
            digitalPages: d["digitalPages"] as? [String] ?? [],
            pageCount: d["pageCount"] as? Int ?? 0,
            addedAt: (d["addedAt"] as? Timestamp)?.dateValue() ?? Date(),
            addedByUserId: d["addedByUserId"] as? String ?? "",
            addedByName: d["addedByName"] as? String ?? "",
            lastEditedAt: (d["lastEditedAt"] as? Timestamp)?.dateValue() ?? Date(),
            schoolId: d["schoolId"] as? String ?? "",
            barcode: d["barcode"] as? String,
            notes: d["notes"] as? String ?? "",
            gutendexId: d["gutendexId"] as? Int,
            textUrl: d["textUrl"] as? String
        )
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "bookId": bookId,
            "title": title,
            "author": author,
            "isbn": isbn,
            "publisher": publisher,
            "category": category.rawValue,
            "condition": condition.rawValue,
            "totalCopies": totalCopies,
            "availableCopies": availableCopies,
            "gradeLevel": gradeLevel,
            "description": description,
            "location": location,
            "tags": tags,
            "isDigital": isDigital,
            "digitalPages": digitalPages,
            "pageCount": pageCount,
            "addedAt": Timestamp(date: addedAt),
            "addedByUserId": addedByUserId,
            "addedByName": addedByName,
            "lastEditedAt": FieldValue.serverTimestamp(),
            "schoolId": schoolId,
            "notes": notes
        ]
        if let coverImageUrl = coverImageUrl { data["coverImageUrl"] = coverImageUrl }
        if let barcode = barcode { data["barcode"] = barcode }
        if let publishYear = publishYear { data["publishYear"] = publishYear }
        if let gutendexId = gutendexId { data["gutendexId"] = gutendexId }
        if let textUrl = textUrl { data["textUrl"] = textUrl }
        return data
    }
    
    // Convert from old GutendexBook for backward compatibility
    static func fromGutendexBook(_ book: GutendexBook, schoolId: String, userId: String, userName: String) -> LibraryBook {
        LibraryBook(
            id: UUID().uuidString,
            bookId: "GUT-\(book.id)",
            title: book.title,
            author: book.authors.joined(separator: ", "),
            isbn: "",
            publisher: "Project Gutenberg",
            publishYear: nil,
            category: .fiction,
            condition: .excellent,
            totalCopies: 1,
            availableCopies: 1,
            gradeLevel: "",
            description: "",
            coverImageUrl: book.coverUrl,
            location: "Digital",
            tags: book.subjects,
            isDigital: true,
            digitalPages: [],
            pageCount: 0,
            addedAt: Date(),
            addedByUserId: userId,
            addedByName: userName,
            lastEditedAt: Date(),
            schoolId: schoolId,
            barcode: nil,
            notes: "",
            gutendexId: book.id,
            textUrl: book.textUrl
        )
    }
}

// MARK: - Checkout Record
struct CheckoutRecord: Identifiable, Equatable {
    let id: String
    let bookId: String           // LibraryBook document ID
    let bookTitle: String
    let bookCatalogId: String    // The bookId field (e.g., "LIB-00142")
    let studentId: String
    let studentName: String
    let studentGrade: String
    let checkedOutAt: Date
    var dueDate: Date
    var returnedAt: Date?
    var status: CheckoutStatus
    let schoolId: String
    let checkedOutByUserId: String   // Librarian/teacher who processed
    let checkedOutByName: String
    var renewCount: Int
    var notes: String
    
    var daysCheckedOut: Int {
        let end = returnedAt ?? Date()
        return Calendar.current.dateComponents([.day], from: checkedOutAt, to: end).day ?? 0
    }
    
    var isOverdue: Bool {
        status == .checkedOut && Date() > dueDate
    }
    
    var daysOverdue: Int {
        guard isOverdue else { return 0 }
        return Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
    }
    
    var daysUntilDue: Int {
        guard status == .checkedOut else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    static func == (lhs: CheckoutRecord, rhs: CheckoutRecord) -> Bool {
        lhs.id == rhs.id
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> CheckoutRecord? {
        guard let d = doc.data() else { return nil }
        return CheckoutRecord(
            id: doc.documentID,
            bookId: d["bookId"] as? String ?? "",
            bookTitle: d["bookTitle"] as? String ?? "",
            bookCatalogId: d["bookCatalogId"] as? String ?? "",
            studentId: d["studentId"] as? String ?? "",
            studentName: d["studentName"] as? String ?? "",
            studentGrade: d["studentGrade"] as? String ?? "",
            checkedOutAt: (d["checkedOutAt"] as? Timestamp)?.dateValue() ?? Date(),
            dueDate: (d["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
            returnedAt: (d["returnedAt"] as? Timestamp)?.dateValue(),
            status: CheckoutStatus(rawValue: d["status"] as? String ?? "") ?? .checkedOut,
            schoolId: d["schoolId"] as? String ?? "",
            checkedOutByUserId: d["checkedOutByUserId"] as? String ?? "",
            checkedOutByName: d["checkedOutByName"] as? String ?? "",
            renewCount: d["renewCount"] as? Int ?? 0,
            notes: d["notes"] as? String ?? ""
        )
    }
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "bookId": bookId,
            "bookTitle": bookTitle,
            "bookCatalogId": bookCatalogId,
            "studentId": studentId,
            "studentName": studentName,
            "studentGrade": studentGrade,
            "checkedOutAt": Timestamp(date: checkedOutAt),
            "dueDate": Timestamp(date: dueDate),
            "status": status.rawValue,
            "schoolId": schoolId,
            "checkedOutByUserId": checkedOutByUserId,
            "checkedOutByName": checkedOutByName,
            "renewCount": renewCount,
            "notes": notes
        ]
        if let returnedAt = returnedAt { data["returnedAt"] = Timestamp(date: returnedAt) }
        return data
    }
}

// MARK: - Library Service
final class SchoolLibraryService {
    static let shared = SchoolLibraryService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Collection References (school-scoped)
    private func booksRef(for schoolId: String) -> CollectionReference {
        db.collection("schoolLibraries").document(schoolId).collection("catalog")
    }
    
    private func checkoutsRef(for schoolId: String) -> CollectionReference {
        db.collection("schoolLibraries").document(schoolId).collection("checkouts")
    }
    
    // Old collection for backward compatibility
    func collectionRef(for schoolId: String) -> CollectionReference {
        db.collection("schoolLibraries").document(schoolId).collection("books")
    }
    
    // MARK: - Generate Book ID
    func generateBookId(schoolId: String, completion: @escaping (String) -> Void) {
        booksRef(for: schoolId).getDocuments { snap, _ in
            let count = snap?.documents.count ?? 0
            let nextId = String(format: "LIB-%05d", count + 1)
            completion(nextId)
        }
    }
    
    // MARK: - CRUD: Books
    
    func addBook(_ book: LibraryBook, completion: @escaping (Error?) -> Void) {
        let ref = booksRef(for: book.schoolId).document()
        var data = book.toFirestoreData()
        data["addedAt"] = FieldValue.serverTimestamp()
        data["lastEditedAt"] = FieldValue.serverTimestamp()
        ref.setData(data) { completion($0) }
    }
    
    func updateBook(_ book: LibraryBook, completion: @escaping (Error?) -> Void) {
        let ref = booksRef(for: book.schoolId).document(book.id)
        var data = book.toFirestoreData()
        data["lastEditedAt"] = FieldValue.serverTimestamp()
        ref.setData(data, merge: true) { completion($0) }
    }
    
    func deleteBook(_ book: LibraryBook, completion: @escaping (Error?) -> Void) {
        booksRef(for: book.schoolId).document(book.id).delete { completion($0) }
    }
    
    func fetchCatalog(schoolId: String, completion: @escaping ([LibraryBook]) -> Void) {
        booksRef(for: schoolId)
            .order(by: "title")
            .getDocuments { snap, _ in
                let books = snap?.documents.compactMap { LibraryBook.fromDocument($0) } ?? []
                DispatchQueue.main.async { completion(books) }
            }
    }
    
    func listenToCatalog(schoolId: String, completion: @escaping ([LibraryBook]) -> Void) -> ListenerRegistration {
        booksRef(for: schoolId)
            .order(by: "title")
            .addSnapshotListener { snap, _ in
                let books = snap?.documents.compactMap { LibraryBook.fromDocument($0) } ?? []
                DispatchQueue.main.async { completion(books) }
            }
    }
    
    // MARK: - Check Out
    
    func checkOutBook(book: LibraryBook, studentId: String, studentName: String, studentGrade: String, loanDays: Int = 14, librarianId: String, librarianName: String, notes: String = "", completion: @escaping (Result<CheckoutRecord, Error>) -> Void) {
        guard book.availableCopies > 0 else {
            completion(.failure(NSError(domain: "Library", code: 1, userInfo: [NSLocalizedDescriptionKey: "No copies available"])))
            return
        }
        
        let dueDate = Calendar.current.date(byAdding: .day, value: loanDays, to: Date()) ?? Date()
        
        let record = CheckoutRecord(
            id: UUID().uuidString,
            bookId: book.id,
            bookTitle: book.title,
            bookCatalogId: book.bookId,
            studentId: studentId,
            studentName: studentName,
            studentGrade: studentGrade,
            checkedOutAt: Date(),
            dueDate: dueDate,
            returnedAt: nil,
            status: .checkedOut,
            schoolId: book.schoolId,
            checkedOutByUserId: librarianId,
            checkedOutByName: librarianName,
            renewCount: 0,
            notes: notes
        )
        
        let batch = db.batch()
        
        // Create checkout record
        let checkoutRef = checkoutsRef(for: book.schoolId).document()
        batch.setData(record.toFirestoreData(), forDocument: checkoutRef)
        
        // Decrement available copies
        let bookRef = booksRef(for: book.schoolId).document(book.id)
        batch.updateData(["availableCopies": FieldValue.increment(Int64(-1))], forDocument: bookRef)
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(record))
            }
        }
    }
    
    // MARK: - Return Book
    
    func returnBook(checkout: CheckoutRecord, condition: BookCondition? = nil, notes: String? = nil, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        // Update checkout record
        let checkoutRef = checkoutsRef(for: checkout.schoolId).document(checkout.id)
        var updateData: [String: Any] = [
            "status": CheckoutStatus.returned.rawValue,
            "returnedAt": FieldValue.serverTimestamp()
        ]
        if let notes = notes { updateData["notes"] = checkout.notes + " | Return: \(notes)" }
        batch.updateData(updateData, forDocument: checkoutRef)
        
        // Increment available copies
        let bookRef = booksRef(for: checkout.schoolId).document(checkout.bookId)
        batch.updateData(["availableCopies": FieldValue.increment(Int64(1))], forDocument: bookRef)
        
        // Update book condition if specified
        if let condition = condition {
            batch.updateData(["condition": condition.rawValue], forDocument: bookRef)
        }
        
        batch.commit { completion($0) }
    }
    
    // MARK: - Renew Checkout
    
    func renewCheckout(_ checkout: CheckoutRecord, additionalDays: Int = 14, completion: @escaping (Error?) -> Void) {
        let newDue = Calendar.current.date(byAdding: .day, value: additionalDays, to: checkout.dueDate) ?? checkout.dueDate
        checkoutsRef(for: checkout.schoolId).document(checkout.id).updateData([
            "dueDate": Timestamp(date: newDue),
            "renewCount": checkout.renewCount + 1,
            "status": CheckoutStatus.checkedOut.rawValue
        ]) { completion($0) }
    }
    
    // MARK: - Mark Lost
    
    func markLost(_ checkout: CheckoutRecord, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        let checkoutRef = checkoutsRef(for: checkout.schoolId).document(checkout.id)
        batch.updateData([
            "status": CheckoutStatus.lost.rawValue,
            "returnedAt": FieldValue.serverTimestamp(),
            "notes": checkout.notes + " | MARKED LOST"
        ], forDocument: checkoutRef)
        
        // Decrease total copies
        let bookRef = booksRef(for: checkout.schoolId).document(checkout.bookId)
        batch.updateData(["totalCopies": FieldValue.increment(Int64(-1))], forDocument: bookRef)
        
        batch.commit { completion($0) }
    }
    
    // MARK: - Fetch Checkouts
    
    func fetchActiveCheckouts(schoolId: String, completion: @escaping ([CheckoutRecord]) -> Void) {
        checkoutsRef(for: schoolId)
            .whereField("status", isEqualTo: CheckoutStatus.checkedOut.rawValue)
            .order(by: "dueDate")
            .getDocuments { snap, _ in
                let records = snap?.documents.compactMap { CheckoutRecord.fromDocument($0) } ?? []
                DispatchQueue.main.async { completion(records) }
            }
    }
    
    func fetchCheckoutsForBook(bookId: String, schoolId: String, completion: @escaping ([CheckoutRecord]) -> Void) {
        checkoutsRef(for: schoolId)
            .whereField("bookId", isEqualTo: bookId)
            .order(by: "checkedOutAt", descending: true)
            .getDocuments { snap, _ in
                let records = snap?.documents.compactMap { CheckoutRecord.fromDocument($0) } ?? []
                DispatchQueue.main.async { completion(records) }
            }
    }
    
    func fetchCheckoutsForStudent(studentId: String, schoolId: String, completion: @escaping ([CheckoutRecord]) -> Void) {
        checkoutsRef(for: schoolId)
            .whereField("studentId", isEqualTo: studentId)
            .order(by: "checkedOutAt", descending: true)
            .getDocuments { snap, _ in
                let records = snap?.documents.compactMap { CheckoutRecord.fromDocument($0) } ?? []
                DispatchQueue.main.async { completion(records) }
            }
    }
    
    func fetchAllCheckouts(schoolId: String, completion: @escaping ([CheckoutRecord]) -> Void) {
        checkoutsRef(for: schoolId)
            .order(by: "checkedOutAt", descending: true)
            .limit(to: 200)
            .getDocuments { snap, _ in
                let records = snap?.documents.compactMap { CheckoutRecord.fromDocument($0) } ?? []
                DispatchQueue.main.async { completion(records) }
            }
    }
    
    func fetchOverdueCheckouts(schoolId: String, completion: @escaping ([CheckoutRecord]) -> Void) {
        checkoutsRef(for: schoolId)
            .whereField("status", isEqualTo: CheckoutStatus.checkedOut.rawValue)
            .whereField("dueDate", isLessThan: Timestamp(date: Date()))
            .getDocuments { snap, _ in
                let records = snap?.documents.compactMap { CheckoutRecord.fromDocument($0) } ?? []
                DispatchQueue.main.async { completion(records) }
            }
    }
    
    // MARK: - Upload Image (Cover or Page)
    
    func uploadImage(_ imageData: Data, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    // MARK: - Legacy compatibility for old SchoolLibraryBook
    
    func addBook(_ book: GutendexBook, schoolId: String, userId: String?, completion: @escaping (Error?) -> Void) {
        let ref = collectionRef(for: schoolId).document("g\(book.id)")
        let data: [String: Any] = [
            "gutendexId": book.id,
            "title": book.title,
            "authors": book.authors,
            "subjects": book.subjects,
            "textUrl": book.textUrl ?? "",
            "addedAt": FieldValue.serverTimestamp(),
            "addedByUserId": userId ?? ""
        ]
        ref.setData(data, merge: true) { completion($0) }
    }

    func removeBook(gutendexId: Int, schoolId: String, completion: @escaping (Error?) -> Void) {
        collectionRef(for: schoolId).document("g\(gutendexId)").delete(completion: completion)
    }

    func isInLibrary(gutendexId: Int, schoolId: String) async -> Bool {
        let doc = try? await collectionRef(for: schoolId).document("g\(gutendexId)").getDocument()
        return doc?.exists ?? false
    }

    func fetchBooks(schoolId: String, completion: @escaping ([SchoolLibraryBook]) -> Void) {
        collectionRef(for: schoolId)
            .order(by: "addedAt", descending: true)
            .getDocuments { snap, _ in
                let books = snap?.documents.compactMap { SchoolLibraryBook.fromDoc($0) } ?? []
                DispatchQueue.main.async { completion(books) }
            }
    }

    func addListener(schoolId: String, completion: @escaping ([SchoolLibraryBook]) -> Void) -> ListenerRegistration {
        collectionRef(for: schoolId)
            .order(by: "addedAt", descending: true)
            .addSnapshotListener { snap, _ in
                let books = snap?.documents.compactMap { SchoolLibraryBook.fromDoc($0) } ?? []
                DispatchQueue.main.async { completion(books) }
            }
    }
}

// MARK: - Legacy Model (keep for backward compatibility)
struct SchoolLibraryBook: Identifiable, Equatable {
    let id: String
    let gutendexId: Int
    let title: String
    let authors: [String]
    let subjects: [String]
    let textUrl: String?
    let addedAt: Date
    let addedByUserId: String?

    var authorDisplay: String {
        authors.isEmpty ? "Unknown" : authors.joined(separator: ", ")
    }

    static func fromDoc(_ doc: DocumentSnapshot) -> SchoolLibraryBook? {
        guard let d = doc.data() else { return nil }
        return SchoolLibraryBook(
            id: doc.documentID,
            gutendexId: d["gutendexId"] as? Int ?? 0,
            title: d["title"] as? String ?? "",
            authors: d["authors"] as? [String] ?? [],
            subjects: d["subjects"] as? [String] ?? [],
            textUrl: d["textUrl"] as? String,
            addedAt: (d["addedAt"] as? Timestamp)?.dateValue() ?? Date(),
            addedByUserId: d["addedByUserId"] as? String
        )
    }

    func toGutendexBook() -> GutendexBook {
        GutendexBook(id: gutendexId, title: title, authors: authors, subjects: subjects, textUrl: textUrl)
    }
}
