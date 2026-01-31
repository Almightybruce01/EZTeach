//
//  NotificationService.swift
//  EZTeach
//
//  Push notification handling using native iOS APIs
//

import Foundation
import Combine
import UserNotifications
import UIKit
import FirebaseAuth
import FirebaseFirestore

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var deviceToken: String?
    @Published var hasPermission = false
    
    private let db = Firestore.firestore()
    
    override init() {
        super.init()
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.hasPermission = granted
            }
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Handle Device Token
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        saveTokenToFirestore()
    }
    
    // MARK: - Save Token to Firestore
    func saveTokenToFirestore() {
        guard let token = deviceToken,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "deviceToken": token,
            "tokenUpdatedAt": Timestamp(),
            "platform": "iOS"
        ]) { error in
            if let error = error {
                print("Failed to save device token: \(error)")
            }
        }
    }
    
    // MARK: - Send Local Notification
    func sendLocalNotification(title: String, body: String, category: String = "general") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Reminder
    func scheduleReminder(title: String, body: String, date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Daily Reminder
    func scheduleDailyReminder(title: String, body: String, hour: Int, minute: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Notification
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Cancel All Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Update User Preferences
    func updateNotificationPreferences(_ prefs: NotificationPreferences) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).updateData([
            "notificationPrefs": [
                "announcements": prefs.announcements,
                "grades": prefs.grades,
                "attendance": prefs.attendance,
                "subRequests": prefs.subRequests,
                "emergencyAlerts": prefs.emergencyAlerts,
                "messages": prefs.messages,
                "homework": prefs.homework,
                "events": prefs.events
            ]
        ])
    }
    
    // MARK: - Get User Preferences
    func getNotificationPreferences(completion: @escaping (NotificationPreferences) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.defaultPrefs)
            return
        }
        
        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data(),
                  let prefs = data["notificationPrefs"] as? [String: Bool] else {
                completion(.defaultPrefs)
                return
            }
            
            completion(NotificationPreferences(
                announcements: prefs["announcements"] ?? true,
                grades: prefs["grades"] ?? true,
                attendance: prefs["attendance"] ?? true,
                subRequests: prefs["subRequests"] ?? true,
                emergencyAlerts: prefs["emergencyAlerts"] ?? true,
                messages: prefs["messages"] ?? true,
                homework: prefs["homework"] ?? true,
                events: prefs["events"] ?? true
            ))
        }
    }
    
    // MARK: - Update Badge Count
    func updateBadgeCount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Count unread messages
        db.collection("messages")
            .whereField("recipientId", isEqualTo: uid)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snap, _ in
                let count = snap?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.setBadgeCount(count)
                }
            }
    }
    
    // MARK: - Clear Badge
    func clearBadge() {
        setBadgeCount(0)
    }
    
    // MARK: - Set Badge Count (iOS 17+ compatible)
    private func setBadgeCount(_ count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - Notification Categories Setup
extension NotificationService {
    func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive
        )
        
        // Announcement category
        let announcementCategory = UNNotificationCategory(
            identifier: "ANNOUNCEMENT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )
        
        // Grade category
        let gradeCategory = UNNotificationCategory(
            identifier: "GRADE",
            actions: [viewAction],
            intentIdentifiers: []
        )
        
        // Emergency category
        let emergencyCategory = UNNotificationCategory(
            identifier: "EMERGENCY",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Message category
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: .authenticationRequired,
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your reply..."
        )
        
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE",
            actions: [replyAction, viewAction],
            intentIdentifiers: []
        )
        
        // Homework reminder category
        let homeworkCategory = UNNotificationCategory(
            identifier: "HOMEWORK",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )
        
        // Event reminder category
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT",
            actions: [viewAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            announcementCategory,
            gradeCategory,
            emergencyCategory,
            messageCategory,
            homeworkCategory,
            eventCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Handle different actions
        switch actionIdentifier {
        case "VIEW_ACTION":
            // Navigate to relevant screen based on category
            handleViewAction(userInfo: userInfo)
            
        case "REPLY_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                handleReplyAction(text: textResponse.userText, userInfo: userInfo)
            }
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleViewAction(userInfo: [AnyHashable: Any]) {
        // Post notification to navigate to appropriate screen
        if let type = userInfo["type"] as? String {
            NotificationCenter.default.post(
                name: Notification.Name("NavigateToNotification"),
                object: nil,
                userInfo: ["type": type, "data": userInfo]
            )
        }
    }
    
    private func handleReplyAction(text: String, userInfo: [AnyHashable: Any]) {
        // Handle quick reply to message
        guard let conversationId = userInfo["conversationId"] as? String,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("messages").addDocument(data: [
            "conversationId": conversationId,
            "senderId": uid,
            "content": text,
            "sentAt": Timestamp(),
            "isRead": false
        ])
    }
}
