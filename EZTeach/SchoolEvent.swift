//
//  SchoolEvent.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

// ==============================
// SchoolEvent.swift (FULL)
// ==============================
import Foundation
import FirebaseFirestore

struct SchoolEvent: Identifiable {

    let id: String
    let schoolId: String
    let title: String
    let startDate: String
    let endDate: String
    let type: String
    /// When true, only teachers and school accounts see this event; hidden from subs.
    let teachersOnly: Bool

    // ✅ Used everywhere in UI (CalendarBottomSheetView + ContentView)
    var date: Date {
        // try ISO8601 first (best)
        if let d = ISO8601DateFormatter().date(from: startDate) { return d }

        // try common human formats
        let f1 = DateFormatter()
        f1.locale = Locale(identifier: "en_US_POSIX")
        f1.dateFormat = "MMMM d, yyyy"     // "January 6, 2026"
        if let d = f1.date(from: startDate) { return d }

        let f2 = DateFormatter()
        f2.locale = Locale(identifier: "en_US_POSIX")
        f2.dateFormat = "MMM d, yyyy"      // "Jan 6, 2026"
        if let d = f2.date(from: startDate) { return d }

        let f3 = DateFormatter()
        f3.locale = Locale(identifier: "en_US_POSIX")
        f3.dateStyle = .short
        if let d = f3.date(from: startDate) { return d }

        // fallback
        return Date()
    }

    // ✅ Helper to build from Firestore doc WITHOUT changing your Firestore structure
    static func fromDoc(_ doc: QueryDocumentSnapshot, schoolId: String) -> SchoolEvent {
        let data = doc.data()

        // supports either:
        // 1) "date": Timestamp
        // 2) "startDate": String
        let start: String = {
            if let ts = data["date"] as? Timestamp {
                return ISO8601DateFormatter().string(from: ts.dateValue())
            }
            if let s = data["startDate"] as? String {
                return s
            }
            return ""
        }()

        let end: String = {
            if let ts = data["endDate"] as? Timestamp {
                return ISO8601DateFormatter().string(from: ts.dateValue())
            }
            if let s = data["endDate"] as? String {
                return s
            }
            return ""
        }()

        return SchoolEvent(
            id: doc.documentID,
            schoolId: schoolId,
            title: data["title"] as? String ?? "",
            startDate: start,
            endDate: end,
            type: data["type"] as? String ?? "event",
            teachersOnly: data["teachersOnly"] as? Bool ?? false
        )
    }
}
