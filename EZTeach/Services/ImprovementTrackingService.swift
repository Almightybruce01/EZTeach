//
//  ImprovementTrackingService.swift
//  EZTeach
//
//  Track student improvements and send notifications for milestones
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

// MARK: - Improvement Event Types
enum ImprovementEvent: String, Codable {
    case assignmentSubmitted = "assignment_submitted"
    case gradeImproved = "grade_improved"
    case gameHighScore = "game_high_score"
    case readingStreak = "reading_streak"
    case perfectScore = "perfect_score"
    case attendancePerfect = "attendance_perfect"
    case behaviorPositive = "behavior_positive"
    case studyGoalMet = "study_goal_met"
    case activeTimeMilestone = "active_time_milestone"
    
    var icon: String {
        switch self {
        case .assignmentSubmitted: return "checkmark.circle.fill"
        case .gradeImproved: return "arrow.up.circle.fill"
        case .gameHighScore: return "trophy.fill"
        case .readingStreak: return "book.fill"
        case .perfectScore: return "star.fill"
        case .attendancePerfect: return "calendar.badge.checkmark"
        case .behaviorPositive: return "heart.fill"
        case .studyGoalMet: return "target"
        case .activeTimeMilestone: return "timer"
        }
    }
    
    var color: String {
        switch self {
        case .assignmentSubmitted: return "green"
        case .gradeImproved: return "blue"
        case .gameHighScore: return "orange"
        case .readingStreak: return "purple"
        case .perfectScore: return "yellow"
        case .attendancePerfect: return "teal"
        case .behaviorPositive: return "pink"
        case .studyGoalMet: return "indigo"
        case .activeTimeMilestone: return "mint"
        }
    }
}

// MARK: - Improvement Record
struct ImprovementRecord: Identifiable, Codable {
    let id: String
    let studentId: String
    let schoolId: String
    let eventType: ImprovementEvent
    let title: String
    let message: String
    let details: [String: String]
    let timestamp: Date
    let isRead: Bool
    let notifiedParents: Bool
    
    static func fromDocument(_ doc: DocumentSnapshot) -> ImprovementRecord? {
        guard let data = doc.data() else { return nil }
        return ImprovementRecord(
            id: doc.documentID,
            studentId: data["studentId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            eventType: ImprovementEvent(rawValue: data["eventType"] as? String ?? "") ?? .gradeImproved,
            title: data["title"] as? String ?? "",
            message: data["message"] as? String ?? "",
            details: data["details"] as? [String: String] ?? [:],
            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
            isRead: data["isRead"] as? Bool ?? false,
            notifiedParents: data["notifiedParents"] as? Bool ?? false
        )
    }
}

// MARK: - Improvement Tracking Service
class ImprovementTrackingService: ObservableObject {
    static let shared = ImprovementTrackingService()
    
    private let db = Firestore.firestore()
    
    @Published var recentImprovements: [ImprovementRecord] = []
    @Published var unreadCount: Int = 0
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Request Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - Track Assignment Submitted
    func trackAssignmentSubmitted(studentId: String, studentName: String, schoolId: String, assignmentTitle: String, wasEarly: Bool) {
        let title = wasEarly ? "Early Submission!" : "Assignment Submitted"
        let message = "\(studentName) submitted \"\(assignmentTitle)\"\(wasEarly ? " early!" : ".")"
        
        createImprovementRecord(
            studentId: studentId,
            schoolId: schoolId,
            eventType: .assignmentSubmitted,
            title: title,
            message: message,
            details: [
                "assignmentTitle": assignmentTitle,
                "wasEarly": wasEarly ? "true" : "false"
            ],
            notifyParents: true
        )
    }
    
    // MARK: - Track Grade Improvement
    func trackGradeImproved(studentId: String, studentName: String, schoolId: String, className: String, oldGrade: Double, newGrade: Double) {
        guard newGrade > oldGrade else { return }
        
        let improvement = newGrade - oldGrade
        let title = "Grade Improved!"
        let message = "\(studentName)'s grade in \(className) improved by \(String(format: "%.1f", improvement))%!"
        
        createImprovementRecord(
            studentId: studentId,
            schoolId: schoolId,
            eventType: .gradeImproved,
            title: title,
            message: message,
            details: [
                "className": className,
                "oldGrade": String(format: "%.1f", oldGrade),
                "newGrade": String(format: "%.1f", newGrade),
                "improvement": String(format: "%.1f", improvement)
            ],
            notifyParents: true
        )
        
        // Check for perfect score
        if newGrade >= 100 {
            trackPerfectScore(studentId: studentId, studentName: studentName, schoolId: schoolId, className: className)
        }
    }
    
    // MARK: - Track Game High Score
    func trackGameHighScore(studentId: String, studentName: String, schoolId: String, gameName: String, oldScore: Int, newScore: Int) {
        guard newScore > oldScore else { return }
        
        let title = "New High Score!"
        let message = "\(studentName) beat their high score in \(gameName)! New score: \(newScore)"
        
        createImprovementRecord(
            studentId: studentId,
            schoolId: schoolId,
            eventType: .gameHighScore,
            title: title,
            message: message,
            details: [
                "gameName": gameName,
                "oldScore": "\(oldScore)",
                "newScore": "\(newScore)"
            ],
            notifyParents: false // Only notify for academic achievements
        )
        
        // Send local notification
        sendLocalNotification(title: title, body: message)
    }
    
    // MARK: - Track Reading Streak
    func trackReadingStreak(studentId: String, studentName: String, schoolId: String, streakDays: Int) {
        let milestones = [3, 7, 14, 30, 60, 100]
        guard milestones.contains(streakDays) else { return }
        
        let title = "\(streakDays)-Day Reading Streak!"
        let message = "\(studentName) has been reading for \(streakDays) days in a row!"
        
        createImprovementRecord(
            studentId: studentId,
            schoolId: schoolId,
            eventType: .readingStreak,
            title: title,
            message: message,
            details: [
                "streakDays": "\(streakDays)"
            ],
            notifyParents: true
        )
    }
    
    // MARK: - Track Perfect Score
    func trackPerfectScore(studentId: String, studentName: String, schoolId: String, className: String) {
        let title = "Perfect Score!"
        let message = "\(studentName) achieved a perfect score in \(className)!"
        
        createImprovementRecord(
            studentId: studentId,
            schoolId: schoolId,
            eventType: .perfectScore,
            title: title,
            message: message,
            details: [
                "className": className
            ],
            notifyParents: true
        )
    }
    
    // MARK: - Track Active Time Milestone
    func trackActiveTimeMilestone(studentId: String, studentName: String, schoolId: String, totalMinutes: Int) {
        let milestones = [60, 120, 300, 600, 1000, 2000, 5000]
        guard milestones.contains(totalMinutes) else { return }
        
        let hours = totalMinutes / 60
        let title = "\(hours)+ Hours of Learning!"
        let message = "\(studentName) has spent over \(hours) hours actively learning!"
        
        createImprovementRecord(
            studentId: studentId,
            schoolId: schoolId,
            eventType: .activeTimeMilestone,
            title: title,
            message: message,
            details: [
                "totalMinutes": "\(totalMinutes)"
            ],
            notifyParents: true
        )
    }
    
    // MARK: - Track Study Goal Met
    func trackStudyGoalMet(studentId: String, studentName: String, schoolId: String, goalDescription: String) {
        let title = "Study Goal Achieved!"
        let message = "\(studentName) completed their study goal: \(goalDescription)"
        
        createImprovementRecord(
            studentId: studentId,
            schoolId: schoolId,
            eventType: .studyGoalMet,
            title: title,
            message: message,
            details: [
                "goalDescription": goalDescription
            ],
            notifyParents: true
        )
    }
    
    // MARK: - Create Improvement Record
    private func createImprovementRecord(
        studentId: String,
        schoolId: String,
        eventType: ImprovementEvent,
        title: String,
        message: String,
        details: [String: String],
        notifyParents: Bool
    ) {
        let recordId = UUID().uuidString
        
        let data: [String: Any] = [
            "studentId": studentId,
            "schoolId": schoolId,
            "eventType": eventType.rawValue,
            "title": title,
            "message": message,
            "details": details,
            "timestamp": Timestamp(),
            "isRead": false,
            "notifiedParents": false
        ]
        
        db.collection("improvementRecords").document(recordId).setData(data) { error in
            if error == nil && notifyParents {
                self.notifyParents(studentId: studentId, title: title, message: message)
            }
        }
        
        // Also send local notification to the student
        sendLocalNotification(title: title, body: message)
    }
    
    // MARK: - Notify Parents
    private func notifyParents(studentId: String, title: String, message: String) {
        // Get parent IDs for this student
        db.collection("students").document(studentId).getDocument { snap, _ in
            guard let data = snap?.data(),
                  let parentIds = data["parentIds"] as? [String] else { return }
            
            for parentId in parentIds {
                // Create notification for parent
                self.db.collection("userNotifications").addDocument(data: [
                    "userId": parentId,
                    "title": title,
                    "body": message,
                    "type": "improvement",
                    "studentId": studentId,
                    "createdAt": Timestamp(),
                    "isRead": false
                ])
                
                // Send push notification via FCM topic
                // (Handled by Cloud Function that listens to userNotifications)
            }
        }
    }
    
    // MARK: - Send Local Notification
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Load Recent Improvements
    func loadRecentImprovements(for studentId: String) {
        db.collection("improvementRecords")
            .whereField("studentId", isEqualTo: studentId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snap, _ in
                self.recentImprovements = snap?.documents.compactMap { ImprovementRecord.fromDocument($0) } ?? []
                self.unreadCount = self.recentImprovements.filter { !$0.isRead }.count
            }
    }
    
    // MARK: - Load Improvements for Parent
    func loadImprovementsForParent(studentIds: [String], completion: @escaping ([ImprovementRecord]) -> Void) {
        guard !studentIds.isEmpty else {
            completion([])
            return
        }
        
        db.collection("improvementRecords")
            .whereField("studentId", in: Array(studentIds.prefix(10)))
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snap, _ in
                let records = snap?.documents.compactMap { ImprovementRecord.fromDocument($0) } ?? []
                completion(records)
            }
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ recordId: String) {
        db.collection("improvementRecords").document(recordId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - Get Student Progress Summary
    func getProgressSummary(for studentId: String, completion: @escaping (ProgressSummary) -> Void) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        db.collection("improvementRecords")
            .whereField("studentId", isEqualTo: studentId)
            .whereField("timestamp", isGreaterThan: Timestamp(date: thirtyDaysAgo))
            .getDocuments { snap, _ in
                let records = snap?.documents.compactMap { ImprovementRecord.fromDocument($0) } ?? []
                
                let summary = ProgressSummary(
                    totalImprovements: records.count,
                    assignmentsSubmitted: records.filter { $0.eventType == .assignmentSubmitted }.count,
                    gradeImprovements: records.filter { $0.eventType == .gradeImproved }.count,
                    gameHighScores: records.filter { $0.eventType == .gameHighScore }.count,
                    perfectScores: records.filter { $0.eventType == .perfectScore }.count,
                    readingStreak: records.filter { $0.eventType == .readingStreak }.count,
                    studyGoalsMet: records.filter { $0.eventType == .studyGoalMet }.count
                )
                
                completion(summary)
            }
    }
}

// MARK: - Progress Summary
struct ProgressSummary {
    let totalImprovements: Int
    let assignmentsSubmitted: Int
    let gradeImprovements: Int
    let gameHighScores: Int
    let perfectScores: Int
    let readingStreak: Int
    let studyGoalsMet: Int
}

// MARK: - Improvement Feed View
struct ImprovementFeedView: View {
    let studentId: String
    let studentName: String
    
    @StateObject private var service = ImprovementTrackingService.shared
    @State private var improvements: [ImprovementRecord] = []
    @State private var isLoading = true
    @State private var progressSummary: ProgressSummary?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Summary
                    if let summary = progressSummary {
                        progressSummaryCard(summary)
                    }
                    
                    // Improvement Feed
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Achievements")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if improvements.isEmpty {
                            emptyState
                        } else {
                            ForEach(improvements) { record in
                                ImprovementCard(record: record)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(EZTeachColors.background)
            .navigationTitle("Progress")
            .onAppear {
                loadData()
            }
        }
    }
    
    private func progressSummaryCard(_ summary: ProgressSummary) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(summary.totalImprovements)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(EZTeachColors.brightTeal)
                
                VStack(alignment: .leading) {
                    Text("Achievements")
                        .font(.headline)
                    Text("Last 30 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MiniStatView(icon: "checkmark.circle.fill", value: "\(summary.assignmentsSubmitted)", label: "Submitted", color: .green)
                MiniStatView(icon: "arrow.up.circle.fill", value: "\(summary.gradeImprovements)", label: "Grade Ups", color: .blue)
                MiniStatView(icon: "trophy.fill", value: "\(summary.gameHighScores)", label: "High Scores", color: .orange)
                MiniStatView(icon: "star.fill", value: "\(summary.perfectScores)", label: "Perfect", color: .yellow)
                MiniStatView(icon: "book.fill", value: "\(summary.readingStreak)", label: "Streaks", color: .purple)
                MiniStatView(icon: "target", value: "\(summary.studyGoalsMet)", label: "Goals Met", color: .indigo)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        .padding(.horizontal)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No achievements yet")
                .font(.headline)
            
            Text("Complete assignments, play games, and read books to earn achievements!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private func loadData() {
        isLoading = true
        
        service.loadRecentImprovements(for: studentId)
        
        service.getProgressSummary(for: studentId) { summary in
            progressSummary = summary
        }
        
        // Observe changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            improvements = service.recentImprovements
            isLoading = false
        }
    }
}

// MARK: - Mini Stat View
struct MiniStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Improvement Card
struct ImprovementCard: View {
    let record: ImprovementRecord
    
    private var eventColor: Color {
        switch record.eventType.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "teal": return .teal
        case "pink": return .pink
        case "indigo": return .indigo
        case "mint": return .mint
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: record.eventType.icon)
                    .foregroundColor(eventColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.subheadline.weight(.semibold))
                
                Text(record.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(record.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
            
            if !record.isRead {
                Circle()
                    .fill(eventColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}
