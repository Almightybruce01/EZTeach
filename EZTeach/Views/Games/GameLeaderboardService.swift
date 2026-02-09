//
//  GameLeaderboardService.swift
//  EZTeach
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum LeaderboardTimeRange: String, CaseIterable, Identifiable {
    case allTime = "All Time"
    case monthly = "Monthly"
    case weekly = "Weekly"
    var id: String { rawValue }
}

struct GameScoreEntry: Identifiable {
    let id: String
    let gameId: String
    let userId: String
    let displayName: String?
    let schoolId: String?
    let schoolName: String?
    let grade: String?
    let score: Int
    let timeSeconds: Double?
    let createdAt: Date
}

struct LeaderboardRank: Identifiable {
    let id: String
    let rank: Int
    let userId: String
    let displayName: String   // e.g. "Mateo V."
    let schoolName: String    // e.g. "Lincoln Elementary"
    let grade: String         // e.g. "5th Grade"
    let score: Int
}

final class GameLeaderboardService {
    static let shared = GameLeaderboardService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    var currentUserId: String? { Auth.auth().currentUser?.uid }
    
    private func startOfMonth() -> Date {
        let cal = Calendar.current
        var comp = cal.dateComponents([.year, .month], from: Date())
        comp.day = 1
        comp.hour = 0
        comp.minute = 0
        comp.second = 0
        return cal.date(from: comp) ?? Date()
    }
    
    private func startOfWeek() -> Date {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let daysToSubtract = (weekday - cal.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -daysToSubtract, to: cal.startOfDay(for: now)) ?? Date()
    }
    
    /// Format name as "Mateo V." — first name + last initial with period
    private static func formatLeaderboardName(first: String, last: String) -> String {
        let f = first.trimmingCharacters(in: .whitespaces)
        let l = last.trimmingCharacters(in: .whitespaces)
        if f.isEmpty && l.isEmpty { return "Student" }
        if l.isEmpty { return f }
        if f.isEmpty { return "\(l.prefix(1))." }
        return "\(f) \(l.prefix(1))."
    }

    func saveScore(gameId: String, score: Int, timeSeconds: Double? = nil, displayName: String? = nil) {
        guard let uid = currentUserId else { return }
        
        var data: [String: Any] = [
            "gameId": gameId,
            "userId": uid,
            "score": score,
            "createdAt": Timestamp()
        ]
        if let t = timeSeconds { data["timeSeconds"] = t }
        
        // Look up the student doc for real name, school, and grade
        db.collection("users").document(uid).getDocument { [weak self] userSnap, _ in
            guard let self = self else { return }
            let userData = userSnap?.data()
            let schoolId = userData?["schoolId"] as? String ?? ""

            // Try students collection for detailed info (firstName, lastName, gradeLevel)
            let studentsQuery = self.db.collection("students")
                .whereField("userId", isEqualTo: uid)
                .limit(to: 1)

            studentsQuery.getDocuments { studentSnap, _ in
                var firstName = ""
                var lastName = ""
                var gradeLevel: Int? = nil

                if let sDoc = studentSnap?.documents.first?.data() {
                    firstName = sDoc["firstName"] as? String ?? ""
                    lastName = sDoc["lastName"] as? String ?? ""
                    gradeLevel = sDoc["gradeLevel"] as? Int
                }

                // Fallbacks from user doc or Auth
                if firstName.isEmpty {
                    firstName = userData?["firstName"] as? String
                        ?? Auth.auth().currentUser?.displayName?.components(separatedBy: " ").first
                        ?? ""
                }
                if lastName.isEmpty {
                    lastName = userData?["lastName"] as? String
                        ?? {
                            let parts = Auth.auth().currentUser?.displayName?.components(separatedBy: " ") ?? []
                            return parts.count > 1 ? parts.last ?? "" : ""
                        }()
                        ?? ""
                }

                let formattedName = Self.formatLeaderboardName(first: firstName, last: lastName)
                data["displayName"] = formattedName

                // Grade label
                if let gl = gradeLevel {
                    data["grade"] = GradeUtils.label(gl)
                }

                // Store schoolId for school-scoped leaderboards
                if !schoolId.isEmpty {
                    data["schoolId"] = schoolId
                    self.db.collection("schools").document(schoolId).getDocument { schoolSnap, _ in
                        let schoolName = schoolSnap?.data()?["schoolName"] as? String ?? ""
                        if !schoolName.isEmpty {
                            data["schoolName"] = schoolName
                        }
                        self.db.collection("gameLeaderboards").addDocument(data: data) { _ in }
                    }
                } else {
                    self.db.collection("gameLeaderboards").addDocument(data: data) { _ in }
                }
            }
        }
    }
    
    private static func parseEntry(_ doc: QueryDocumentSnapshot) -> GameScoreEntry {
        let d = doc.data()
        return GameScoreEntry(
            id: doc.documentID,
            gameId: d["gameId"] as? String ?? "",
            userId: d["userId"] as? String ?? "",
            displayName: d["displayName"] as? String,
            schoolId: d["schoolId"] as? String,
            schoolName: d["schoolName"] as? String,
            grade: d["grade"] as? String,
            score: d["score"] as? Int ?? 0,
            timeSeconds: d["timeSeconds"] as? Double,
            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func fetchLeaderboard(gameId: String, timeRange: LeaderboardTimeRange, limit: Int = 30, completion: @escaping ([LeaderboardRank]) -> Void) {
        var query: Query = db.collection("gameLeaderboards")
            .whereField("gameId", isEqualTo: gameId)
        
        switch timeRange {
        case .allTime: break
        case .monthly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth()))
        case .weekly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek()))
        }
        
        query.getDocuments { snap, _ in
            let entries = snap?.documents.map { Self.parseEntry($0) } ?? []
            let aggregated = Self.aggregateByUserMax(entries)
            completion(Array(aggregated.prefix(limit)))
        }
    }
    
    
    // MARK: - Name helpers

    /// Resolve a display name, filtering out generic placeholders from old data.
    private static func resolveName(_ raw: String?, userId: String) -> String {
        let bad: Set<String> = ["Player", "player", "Student", "", "Unknown"]
        if let n = raw, !bad.contains(n) { return n }
        if userId == Auth.auth().currentUser?.uid {
            if let dn = Auth.auth().currentUser?.displayName, !dn.isEmpty {
                // Format auth name as "First L."
                let parts = dn.components(separatedBy: " ")
                if parts.count >= 2, let last = parts.last, !last.isEmpty {
                    return "\(parts[0]) \(last.prefix(1))."
                }
                return dn
            }
            if let em = Auth.auth().currentUser?.email {
                return em.components(separatedBy: "@").first ?? "Student"
            }
        }
        return "Student"
    }

    /// Pick the more specific value out of two optional candidates.
    private static func pickBetter(_ a: String?, _ b: String?) -> String? {
        let bad: Set<String> = ["Player", "player", "Student", "", "Unknown"]
        if let a = a, !bad.contains(a) { return a }
        if let b = b, !bad.contains(b) { return b }
        return a ?? b
    }

    // MARK: - Aggregation

    private struct UserAggregate {
        var displayName: String?
        var schoolName: String?
        var grade: String?
        var value: Int // best score or cumulative total
    }

    private static func aggregateByUserMax(_ entries: [GameScoreEntry]) -> [LeaderboardRank] {
        var byUser: [String: UserAggregate] = [:]
        for e in entries {
            var cur = byUser[e.userId] ?? UserAggregate(displayName: e.displayName, schoolName: e.schoolName, grade: e.grade, value: 0)
            cur.displayName = pickBetter(cur.displayName, e.displayName)
            cur.schoolName  = pickBetter(cur.schoolName, e.schoolName)
            cur.grade       = pickBetter(cur.grade, e.grade)
            cur.value       = max(cur.value, e.score)
            byUser[e.userId] = cur
        }
        return ranked(byUser)
    }
    
    private static func aggregateByUserSum(_ entries: [GameScoreEntry]) -> [LeaderboardRank] {
        var byUser: [String: UserAggregate] = [:]
        for e in entries {
            var cur = byUser[e.userId] ?? UserAggregate(displayName: e.displayName, schoolName: e.schoolName, grade: e.grade, value: 0)
            cur.displayName = pickBetter(cur.displayName, e.displayName)
            cur.schoolName  = pickBetter(cur.schoolName, e.schoolName)
            cur.grade       = pickBetter(cur.grade, e.grade)
            cur.value       = cur.value + e.score
            byUser[e.userId] = cur
        }
        return ranked(byUser)
    }

    private static func ranked(_ byUser: [String: UserAggregate]) -> [LeaderboardRank] {
        byUser.map { userId, agg in
            LeaderboardRank(
                id: userId,
                rank: 0,
                userId: userId,
                displayName: resolveName(agg.displayName, userId: userId),
                schoolName: agg.schoolName ?? "",
                grade: agg.grade ?? "",
                score: agg.value
            )
        }
        .sorted { $0.score > $1.score }
        .enumerated()
        .map { idx, r in
            LeaderboardRank(id: r.id, rank: idx + 1, userId: r.userId,
                            displayName: r.displayName, schoolName: r.schoolName,
                            grade: r.grade, score: r.score)
        }
    }
    
    func fetchGeneralLeaderboard(timeRange: LeaderboardTimeRange, limit: Int = 100, completion: @escaping ([LeaderboardRank]) -> Void) {
        var query: Query = db.collection("gameLeaderboards")
        
        switch timeRange {
        case .allTime: break
        case .monthly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth()))
        case .weekly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek()))
        }
        
        query.getDocuments { snap, _ in
            let entries = snap?.documents.map { Self.parseEntry($0) } ?? []
            let aggregated = Self.aggregateByUserSum(entries)
            completion(Array(aggregated.prefix(limit)))
        }
    }

    // MARK: - School-scoped leaderboards

    /// Fetch general leaderboard for a specific school (sum of all games)
    func fetchSchoolGeneralLeaderboard(schoolId: String, timeRange: LeaderboardTimeRange, limit: Int = 100, completion: @escaping ([LeaderboardRank]) -> Void) {
        var query: Query = db.collection("gameLeaderboards")
            .whereField("schoolId", isEqualTo: schoolId)

        switch timeRange {
        case .allTime: break
        case .monthly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth()))
        case .weekly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek()))
        }

        query.getDocuments { snap, _ in
            let entries = snap?.documents.map { Self.parseEntry($0) } ?? []
            let aggregated = Self.aggregateByUserSum(entries)
            completion(Array(aggregated.prefix(limit)))
        }
    }

    /// Fetch per-game leaderboard for a specific school
    func fetchSchoolLeaderboard(schoolId: String, gameId: String, timeRange: LeaderboardTimeRange, limit: Int = 100, completion: @escaping ([LeaderboardRank]) -> Void) {
        var query: Query = db.collection("gameLeaderboards")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("gameId", isEqualTo: gameId)

        switch timeRange {
        case .allTime: break
        case .monthly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth()))
        case .weekly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek()))
        }

        query.getDocuments { snap, _ in
            let entries = snap?.documents.map { Self.parseEntry($0) } ?? []
            let aggregated = Self.aggregateByUserMax(entries)
            completion(Array(aggregated.prefix(limit)))
        }
    }

    /// Resolve the current user's schoolId from Firestore
    func resolveCurrentUserSchoolId(completion: @escaping (String?) -> Void) {
        guard let uid = currentUserId else {
            completion(nil)
            return
        }
        db.collection("students").whereField("userId", isEqualTo: uid).limit(to: 1).getDocuments { snap, _ in
            if let sDoc = snap?.documents.first?.data(), let sid = sDoc["schoolId"] as? String, !sid.isEmpty {
                completion(sid)
                return
            }
            self.db.collection("users").document(uid).getDocument { uSnap, _ in
                let sid = uSnap?.data()?["activeSchoolId"] as? String
                    ?? uSnap?.data()?["schoolId"] as? String
                completion(sid)
            }
        }
    }

    func fetchLeaderboard(gameId: String, limit: Int = 20, completion: @escaping ([GameScoreEntry]) -> Void) {
        fetchLeaderboard(gameId: gameId, timeRange: .allTime, limit: limit) { ranks in
            completion(ranks.map {
                GameScoreEntry(id: $0.id, gameId: gameId, userId: $0.userId,
                               displayName: $0.displayName, schoolId: nil,
                               schoolName: $0.schoolName, grade: $0.grade,
                               score: $0.score, timeSeconds: nil,
                               createdAt: Date())
            })
        }
    }
}
