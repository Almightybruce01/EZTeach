//
//  ActiveTimeService.swift
//  EZTeach
//
//  Tracks active time spent in games, studying, reading - not just screen time
//  Pauses when user is inactive, tracks actual engagement
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Activity Type
enum ActivityType: String, Codable, CaseIterable {
    case game = "game"
    case reading = "reading"
    case studying = "studying"
    case elective = "elective"
    case homework = "homework"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .game: return "Games"
        case .reading: return "Reading"
        case .studying: return "Studying"
        case .elective: return "Electives"
        case .homework: return "Homework"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .game: return "gamecontroller.fill"
        case .reading: return "book.fill"
        case .studying: return "brain.head.profile"
        case .elective: return "paintpalette.fill"
        case .homework: return "doc.text.fill"
        case .other: return "clock.fill"
        }
    }
    
    var color: String {
        switch self {
        case .game: return "teal"
        case .reading: return "purple"
        case .studying: return "blue"
        case .elective: return "orange"
        case .homework: return "green"
        case .other: return "gray"
        }
    }
}

// MARK: - Activity Session
struct ActivitySession: Identifiable, Codable {
    let id: String
    let userId: String
    let userRole: String
    let schoolId: String
    let activityType: ActivityType
    let activityName: String
    let activityId: String?
    let startTime: Date
    var endTime: Date?
    var activeSeconds: Int  // Actual active time (pauses when inactive)
    var totalSeconds: Int   // Total session time (including inactive)
    var interactions: Int   // Number of taps, answers, etc.
    let date: Date          // Calendar date for grouping
    
    var isActive: Bool { endTime == nil }
    
    var activeMinutes: Int { activeSeconds / 60 }
    var totalMinutes: Int { totalSeconds / 60 }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> ActivitySession? {
        guard let data = doc.data() else { return nil }
        return ActivitySession(
            id: doc.documentID,
            userId: data["userId"] as? String ?? "",
            userRole: data["userRole"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            activityType: ActivityType(rawValue: data["activityType"] as? String ?? "") ?? .other,
            activityName: data["activityName"] as? String ?? "",
            activityId: data["activityId"] as? String,
            startTime: (data["startTime"] as? Timestamp)?.dateValue() ?? Date(),
            endTime: (data["endTime"] as? Timestamp)?.dateValue(),
            activeSeconds: data["activeSeconds"] as? Int ?? 0,
            totalSeconds: data["totalSeconds"] as? Int ?? 0,
            interactions: data["interactions"] as? Int ?? 0,
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "userRole": userRole,
            "schoolId": schoolId,
            "activityType": activityType.rawValue,
            "activityName": activityName,
            "startTime": Timestamp(date: startTime),
            "activeSeconds": activeSeconds,
            "totalSeconds": totalSeconds,
            "interactions": interactions,
            "date": Timestamp(date: Calendar.current.startOfDay(for: startTime))
        ]
        if let activityId = activityId {
            dict["activityId"] = activityId
        }
        if let endTime = endTime {
            dict["endTime"] = Timestamp(date: endTime)
        }
        return dict
    }
}

// MARK: - Daily Summary
struct DailyActivitySummary: Identifiable {
    let id: String
    let date: Date
    let userId: String
    var totalActiveMinutes: Int
    var totalScreenMinutes: Int
    var gameMinutes: Int
    var readingMinutes: Int
    var studyingMinutes: Int
    var electiveMinutes: Int
    var homeworkMinutes: Int
    var totalInteractions: Int
    var sessionsCount: Int
}

// MARK: - Active Time Service
class ActiveTimeService: ObservableObject {
    static let shared = ActiveTimeService()
    
    private let db = Firestore.firestore()
    private var currentSession: ActivitySession?
    private var sessionTimer: Timer?
    private var lastInteractionTime: Date = Date()
    private var inactivityThreshold: TimeInterval = 30 // Pause after 30 seconds of no interaction
    private var isUserActive = true
    
    @Published var todayActiveMinutes: Int = 0
    @Published var todayScreenMinutes: Int = 0
    @Published var isTracking = false
    
    private init() {}
    
    // MARK: - Start Session
    func startSession(
        activityType: ActivityType,
        activityName: String,
        activityId: String? = nil,
        schoolId: String
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // End any existing session first
        endCurrentSession()
        
        let session = ActivitySession(
            id: UUID().uuidString,
            userId: uid,
            userRole: getUserRole(),
            schoolId: schoolId,
            activityType: activityType,
            activityName: activityName,
            activityId: activityId,
            startTime: Date(),
            endTime: nil,
            activeSeconds: 0,
            totalSeconds: 0,
            interactions: 0,
            date: Calendar.current.startOfDay(for: Date())
        )
        
        currentSession = session
        isTracking = true
        lastInteractionTime = Date()
        isUserActive = true
        
        // Start timer to track time
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionTime()
        }
        
        // Save to Firestore
        saveSession(session)
    }
    
    // MARK: - Record Interaction
    func recordInteraction() {
        lastInteractionTime = Date()
        isUserActive = true
        currentSession?.interactions += 1
    }
    
    // MARK: - Update Session Time
    private func updateSessionTime() {
        guard var session = currentSession else { return }
        
        let now = Date()
        let timeSinceLastInteraction = now.timeIntervalSince(lastInteractionTime)
        
        // Check if user is still active
        if timeSinceLastInteraction > inactivityThreshold {
            isUserActive = false
        }
        
        // Always increment total time
        session.totalSeconds += 1
        
        // Only increment active time if user is active
        if isUserActive {
            session.activeSeconds += 1
        }
        
        currentSession = session
        
        // Update published values
        todayActiveMinutes = session.activeSeconds / 60
        todayScreenMinutes = session.totalSeconds / 60
    }
    
    // MARK: - End Session
    func endCurrentSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        currentSession = nil
        isTracking = false
        
        // Save final session to Firestore
        saveSession(session)
        
        // Update daily summary
        updateDailySummary(session)
    }
    
    // MARK: - Save Session
    private func saveSession(_ session: ActivitySession) {
        db.collection("activitySessions")
            .document(session.id)
            .setData(session.toDict())
    }
    
    // MARK: - Update Daily Summary
    private func updateDailySummary(_ session: ActivitySession) {
        let dateKey = formatDateKey(session.date)
        let summaryRef = db.collection("dailyActivitySummaries")
            .document("\(session.userId)_\(dateKey)")
        
        summaryRef.getDocument { doc, _ in
            var gameMin = 0, readingMin = 0, studyingMin = 0, electiveMin = 0, homeworkMin = 0
            
            switch session.activityType {
            case .game: gameMin = session.activeMinutes
            case .reading: readingMin = session.activeMinutes
            case .studying: studyingMin = session.activeMinutes
            case .elective: electiveMin = session.activeMinutes
            case .homework: homeworkMin = session.activeMinutes
            case .other: break
            }
            
            if doc?.data() != nil {
                // Update existing summary
                summaryRef.updateData([
                    "totalActiveMinutes": FieldValue.increment(Int64(session.activeMinutes)),
                    "totalScreenMinutes": FieldValue.increment(Int64(session.totalMinutes)),
                    "gameMinutes": FieldValue.increment(Int64(gameMin)),
                    "readingMinutes": FieldValue.increment(Int64(readingMin)),
                    "studyingMinutes": FieldValue.increment(Int64(studyingMin)),
                    "electiveMinutes": FieldValue.increment(Int64(electiveMin)),
                    "homeworkMinutes": FieldValue.increment(Int64(homeworkMin)),
                    "totalInteractions": FieldValue.increment(Int64(session.interactions)),
                    "sessionsCount": FieldValue.increment(Int64(1))
                ])
            } else {
                // Create new summary
                summaryRef.setData([
                    "userId": session.userId,
                    "schoolId": session.schoolId,
                    "date": Timestamp(date: session.date),
                    "totalActiveMinutes": session.activeMinutes,
                    "totalScreenMinutes": session.totalMinutes,
                    "gameMinutes": gameMin,
                    "readingMinutes": readingMin,
                    "studyingMinutes": studyingMin,
                    "electiveMinutes": electiveMin,
                    "homeworkMinutes": homeworkMin,
                    "totalInteractions": session.interactions,
                    "sessionsCount": 1
                ])
            }
        }
    }
    
    // MARK: - Get User's Activity Data
    func getActivitySummary(
        userId: String,
        startDate: Date,
        endDate: Date,
        completion: @escaping ([DailyActivitySummary]) -> Void
    ) {
        db.collection("dailyActivitySummaries")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments(source: .default) { snap, _ in
                let summaries = snap?.documents.compactMap { doc -> DailyActivitySummary? in
                    let data = doc.data()
                    return DailyActivitySummary(
                        id: doc.documentID,
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        userId: data["userId"] as? String ?? "",
                        totalActiveMinutes: data["totalActiveMinutes"] as? Int ?? 0,
                        totalScreenMinutes: data["totalScreenMinutes"] as? Int ?? 0,
                        gameMinutes: data["gameMinutes"] as? Int ?? 0,
                        readingMinutes: data["readingMinutes"] as? Int ?? 0,
                        studyingMinutes: data["studyingMinutes"] as? Int ?? 0,
                        electiveMinutes: data["electiveMinutes"] as? Int ?? 0,
                        homeworkMinutes: data["homeworkMinutes"] as? Int ?? 0,
                        totalInteractions: data["totalInteractions"] as? Int ?? 0,
                        sessionsCount: data["sessionsCount"] as? Int ?? 0
                    )
                } ?? []
                completion(summaries)
            }
    }
    
    // MARK: - Get School Activity Data (for teachers/admins)
    func getSchoolActivitySummary(
        schoolId: String,
        startDate: Date,
        endDate: Date,
        completion: @escaping ([DailyActivitySummary]) -> Void
    ) {
        db.collection("dailyActivitySummaries")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .getDocuments(source: .default) { snap, _ in
                let summaries = snap?.documents.compactMap { doc -> DailyActivitySummary? in
                    let data = doc.data()
                    return DailyActivitySummary(
                        id: doc.documentID,
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        userId: data["userId"] as? String ?? "",
                        totalActiveMinutes: data["totalActiveMinutes"] as? Int ?? 0,
                        totalScreenMinutes: data["totalScreenMinutes"] as? Int ?? 0,
                        gameMinutes: data["gameMinutes"] as? Int ?? 0,
                        readingMinutes: data["readingMinutes"] as? Int ?? 0,
                        studyingMinutes: data["studyingMinutes"] as? Int ?? 0,
                        electiveMinutes: data["electiveMinutes"] as? Int ?? 0,
                        homeworkMinutes: data["homeworkMinutes"] as? Int ?? 0,
                        totalInteractions: data["totalInteractions"] as? Int ?? 0,
                        sessionsCount: data["sessionsCount"] as? Int ?? 0
                    )
                } ?? []
                completion(summaries)
            }
    }
    
    // MARK: - Helpers
    private func getUserRole() -> String {
        // This would be fetched from user defaults or auth claims
        return UserDefaults.standard.string(forKey: "userRole") ?? "student"
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
