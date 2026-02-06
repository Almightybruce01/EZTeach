//
//  SchoolLibraryService.swift
//  EZTeach
//
//  Manages school library books stored in Firestore.
//

import Foundation
import FirebaseFirestore

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
        let gutendexId = d["gutendexId"] as? Int ?? 0
        let title = d["title"] as? String ?? ""
        let authors = d["authors"] as? [String] ?? []
        let subjects = d["subjects"] as? [String] ?? []
        let textUrl = d["textUrl"] as? String
        let ts = d["addedAt"] as? Timestamp
        let addedAt = ts?.dateValue() ?? Date()
        let addedByUserId = d["addedByUserId"] as? String
        return SchoolLibraryBook(
            id: doc.documentID,
            gutendexId: gutendexId,
            title: title,
            authors: authors,
            subjects: subjects,
            textUrl: textUrl,
            addedAt: addedAt,
            addedByUserId: addedByUserId
        )
    }

    func toGutendexBook() -> GutendexBook {
        GutendexBook(id: gutendexId, title: title, authors: authors, subjects: subjects, textUrl: textUrl)
    }
}

final class SchoolLibraryService {
    static let shared = SchoolLibraryService()
    private let db = Firestore.firestore()

    private init() {}

    func collectionRef(for schoolId: String) -> CollectionReference {
        db.collection("schoolLibraries").document(schoolId).collection("books")
    }

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
