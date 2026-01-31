//
//  Message.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let senderName: String
    let senderRole: String
    let content: String
    let messageType: MessageType
    let attachmentUrl: String?
    let attachmentName: String?
    let isRead: Bool
    let readAt: Date?
    let createdAt: Date
    
    enum MessageType: String, Codable {
        case text = "text"
        case image = "image"
        case document = "document"
        case announcement = "announcement"
        case system = "system"
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> Message? {
        guard let data = doc.data() else { return nil }
        
        return Message(
            id: doc.documentID,
            conversationId: data["conversationId"] as? String ?? "",
            senderId: data["senderId"] as? String ?? "",
            senderName: data["senderName"] as? String ?? "",
            senderRole: data["senderRole"] as? String ?? "",
            content: data["content"] as? String ?? "",
            messageType: MessageType(rawValue: data["messageType"] as? String ?? "text") ?? .text,
            attachmentUrl: data["attachmentUrl"] as? String,
            attachmentName: data["attachmentName"] as? String,
            isRead: data["isRead"] as? Bool ?? false,
            readAt: (data["readAt"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

struct Conversation: Identifiable, Codable {
    let id: String
    let schoolId: String
    let participantIds: [String]
    let participantNames: [String: String]
    let conversationType: ConversationType
    let title: String?
    let lastMessage: String?
    let lastMessageAt: Date?
    let unreadCounts: [String: Int]
    let createdAt: Date
    
    enum ConversationType: String, Codable {
        case direct = "direct"           // 1-on-1
        case group = "group"             // Multiple people
        case classGroup = "class_group"  // Class-based
        case parentTeacher = "parent_teacher"
        case announcement = "announcement"
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> Conversation? {
        guard let data = doc.data() else { return nil }
        
        return Conversation(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            participantIds: data["participantIds"] as? [String] ?? [],
            participantNames: data["participantNames"] as? [String: String] ?? [:],
            conversationType: ConversationType(rawValue: data["conversationType"] as? String ?? "direct") ?? .direct,
            title: data["title"] as? String,
            lastMessage: data["lastMessage"] as? String,
            lastMessageAt: (data["lastMessageAt"] as? Timestamp)?.dateValue(),
            unreadCounts: data["unreadCounts"] as? [String: Int] ?? [:],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func unreadCount(for userId: String) -> Int {
        return unreadCounts[userId] ?? 0
    }
}
