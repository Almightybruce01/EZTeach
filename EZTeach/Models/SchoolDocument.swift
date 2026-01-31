//
//  SchoolDocument.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation
import FirebaseFirestore

struct SchoolDocument: Identifiable, Codable {
    let id: String
    let schoolId: String
    let uploadedByUserId: String
    let uploadedByName: String
    let name: String
    let description: String?
    let fileUrl: String
    let storagePath: String?  // Firebase Storage path for deletion
    let fileType: FileType
    let fileSize: Int64  // bytes
    let category: DocumentCategory
    let isPublic: Bool  // visible to all school members
    let teachersOnly: Bool
    let tags: [String]
    let downloadCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum FileType: String, Codable {
        case pdf = "pdf"
        case doc = "doc"
        case docx = "docx"
        case xls = "xls"
        case xlsx = "xlsx"
        case ppt = "ppt"
        case pptx = "pptx"
        case image = "image"
        case video = "video"
        case other = "other"
        
        var iconName: String {
            switch self {
            case .pdf: return "doc.fill"
            case .doc, .docx: return "doc.text.fill"
            case .xls, .xlsx: return "tablecells.fill"
            case .ppt, .pptx: return "rectangle.stack.fill"
            case .image: return "photo.fill"
            case .video: return "video.fill"
            case .other: return "doc.fill"
            }
        }
    }
    
    enum DocumentCategory: String, Codable, CaseIterable {
        case subPlan = "sub_plan"
        case lessonPlan = "lesson_plan"
        case policy = "policy"
        case form = "form"
        case curriculum = "curriculum"
        case resource = "resource"
        case report = "report"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .subPlan: return "Sub Plans"
            case .lessonPlan: return "Lesson Plans"
            case .policy: return "Policies"
            case .form: return "Forms"
            case .curriculum: return "Curriculum"
            case .resource: return "Resources"
            case .report: return "Reports"
            case .other: return "Other"
            }
        }
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> SchoolDocument? {
        guard let data = doc.data() else { return nil }
        
        return SchoolDocument(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            uploadedByUserId: data["uploadedByUserId"] as? String ?? "",
            uploadedByName: data["uploadedByName"] as? String ?? "",
            name: data["name"] as? String ?? "",
            description: data["description"] as? String,
            fileUrl: data["fileUrl"] as? String ?? "",
            storagePath: data["storagePath"] as? String,
            fileType: FileType(rawValue: data["fileType"] as? String ?? "other") ?? .other,
            fileSize: data["fileSize"] as? Int64 ?? 0,
            category: DocumentCategory(rawValue: data["category"] as? String ?? "other") ?? .other,
            isPublic: data["isPublic"] as? Bool ?? true,
            teachersOnly: data["teachersOnly"] as? Bool ?? false,
            tags: data["tags"] as? [String] ?? [],
            downloadCount: data["downloadCount"] as? Int ?? 0,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
