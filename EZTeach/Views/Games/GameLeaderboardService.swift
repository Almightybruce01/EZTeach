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
    let score: Int
    let timeSeconds: Double?
    let createdAt: Date
}

struct LeaderboardRank: Identifiable {
    let id: String
    let rank: Int
    let userId: String
    let displayName: String
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
    
    func saveScore(gameId: String, score: Int, timeSeconds: Double? = nil, displayName: String? = nil) {
        guard let uid = currentUserId else { return }
        
        var data: [String: Any] = [
            "gameId": gameId,
            "userId": uid,
            "score": score,
            "createdAt": Timestamp()
        ]
        if let t = timeSeconds { data["timeSeconds"] = t }
        if let n = displayName { data["displayName"] = n }
        
        db.collection("gameLeaderboards").addDocument(data: data) { _ in }
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
            let entries = snap?.documents.compactMap { doc -> GameScoreEntry? in
                let d = doc.data()
                return GameScoreEntry(
                    id: doc.documentID,
                    gameId: d["gameId"] as? String ?? "",
                    userId: d["userId"] as? String ?? "",
                    displayName: d["displayName"] as? String,
                    score: d["score"] as? Int ?? 0,
                    timeSeconds: d["timeSeconds"] as? Double,
                    createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []
            let aggregated = Self.aggregateByUserMax(entries)
            completion(Array(aggregated.prefix(limit)))
        }
    }
    
    
    private static func aggregateByUserMax(_ entries: [GameScoreEntry]) -> [LeaderboardRank] {
        var byUser: [String: (displayName: String?, best: Int)] = [:]
        for e in entries {
            let cur = byUser[e.userId] ?? (e.displayName, 0)
            byUser[e.userId] = (cur.displayName ?? e.displayName, max(cur.best, e.score))
        }
        return byUser.map { LeaderboardRank(id: $0.key, rank: 0, userId: $0.key, displayName: $0.value.displayName ?? "Player", score: $0.value.best) }
            .sorted { $0.score > $1.score }
            .enumerated()
            .map { LeaderboardRank(id: $0.element.id, rank: $0.offset + 1, userId: $0.element.userId, displayName: $0.element.displayName, score: $0.element.score) }
    }
    
    private static func aggregateByUserSum(_ entries: [GameScoreEntry]) -> [LeaderboardRank] {
        var byUser: [String: (displayName: String?, total: Int)] = [:]
        for e in entries {
            let cur = byUser[e.userId] ?? (e.displayName, 0)
            byUser[e.userId] = (cur.displayName ?? e.displayName, cur.total + e.score)
        }
        return byUser.map { LeaderboardRank(id: $0.key, rank: 0, userId: $0.key, displayName: $0.value.displayName ?? "Player", score: $0.value.total) }
            .sorted { $0.score > $1.score }
            .enumerated()
            .map { LeaderboardRank(id: $0.element.id, rank: $0.offset + 1, userId: $0.element.userId, displayName: $0.element.displayName, score: $0.element.score) }
    }
    
    func fetchGeneralLeaderboard(timeRange: LeaderboardTimeRange, limit: Int = 30, completion: @escaping ([LeaderboardRank]) -> Void) {
        var query: Query = db.collection("gameLeaderboards")
        
        switch timeRange {
        case .allTime: break
        case .monthly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth()))
        case .weekly:
            query = query.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek()))
        }
        
        query.getDocuments { snap, _ in
            let entries = snap?.documents.compactMap { doc -> GameScoreEntry? in
                let d = doc.data()
                return GameScoreEntry(
                    id: doc.documentID,
                    gameId: d["gameId"] as? String ?? "",
                    userId: d["userId"] as? String ?? "",
                    displayName: d["displayName"] as? String,
                    score: d["score"] as? Int ?? 0,
                    timeSeconds: d["timeSeconds"] as? Double,
                    createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []
            let aggregated = Self.aggregateByUserSum(entries)
            completion(Array(aggregated.prefix(limit)))
        }
    }
    
    func fetchLeaderboard(gameId: String, limit: Int = 20, completion: @escaping ([GameScoreEntry]) -> Void) {
        fetchLeaderboard(gameId: gameId, timeRange: .allTime, limit: limit) { ranks in
            completion(ranks.map { GameScoreEntry(id: $0.id, gameId: gameId, userId: $0.userId, displayName: $0.displayName, score: $0.score, timeSeconds: nil, createdAt: Date()) })
        }
    }
}
