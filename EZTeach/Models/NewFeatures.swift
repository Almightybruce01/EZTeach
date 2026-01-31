//
//  NewFeatures.swift
//  EZTeach
//
//  Models for all new features
//

import Foundation
import FirebaseFirestore

// MARK: - Lesson Plan
struct LessonPlan: Identifiable, Codable {
    let id: String
    let teacherId: String
    let schoolId: String
    let classId: String?
    let title: String
    let subject: String
    let gradeLevel: Int
    let objectives: [String]
    let materials: [String]
    let activities: [LessonActivity]
    let assessment: String
    let notes: String
    let duration: Int // minutes
    let date: Date
    let isShared: Bool
    let createdAt: Date
    
    static func fromDocument(_ doc: DocumentSnapshot) -> LessonPlan? {
        guard let data = doc.data() else { return nil }
        return LessonPlan(
            id: doc.documentID,
            teacherId: data["teacherId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            classId: data["classId"] as? String,
            title: data["title"] as? String ?? "",
            subject: data["subject"] as? String ?? "",
            gradeLevel: data["gradeLevel"] as? Int ?? 1,
            objectives: data["objectives"] as? [String] ?? [],
            materials: data["materials"] as? [String] ?? [],
            activities: (data["activities"] as? [[String: Any]] ?? []).compactMap { LessonActivity.fromDict($0) },
            assessment: data["assessment"] as? String ?? "",
            notes: data["notes"] as? String ?? "",
            duration: data["duration"] as? Int ?? 45,
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            isShared: data["isShared"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

struct LessonActivity: Codable {
    let name: String
    let duration: Int
    let description: String
    
    static func fromDict(_ dict: [String: Any]) -> LessonActivity {
        LessonActivity(
            name: dict["name"] as? String ?? "",
            duration: dict["duration"] as? Int ?? 10,
            description: dict["description"] as? String ?? ""
        )
    }
    
    func toDict() -> [String: Any] {
        ["name": name, "duration": duration, "description": description]
    }
}

// MARK: - Homework Assignment
struct HomeworkAssignment: Identifiable, Codable {
    let id: String
    let classId: String
    let teacherId: String
    let schoolId: String
    let title: String
    let description: String
    let dueDate: Date
    let pointsWorth: Int
    let attachmentUrls: [String]
    let createdAt: Date
    
    static func fromDocument(_ doc: DocumentSnapshot) -> HomeworkAssignment? {
        guard let data = doc.data() else { return nil }
        return HomeworkAssignment(
            id: doc.documentID,
            classId: data["classId"] as? String ?? "",
            teacherId: data["teacherId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            dueDate: (data["dueDate"] as? Timestamp)?.dateValue() ?? Date(),
            pointsWorth: data["pointsWorth"] as? Int ?? 10,
            attachmentUrls: data["attachmentUrls"] as? [String] ?? [],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

struct HomeworkSubmission: Identifiable, Codable {
    let id: String
    let homeworkId: String
    let studentId: String
    let submittedAt: Date
    let attachmentUrls: [String]
    let grade: Int?
    let feedback: String
    let status: SubmissionStatus
    
    enum SubmissionStatus: String, Codable {
        case pending = "pending"
        case submitted = "submitted"
        case graded = "graded"
        case late = "late"
        case missing = "missing"
    }
}

// MARK: - Behavior Incident
struct BehaviorIncident: Identifiable, Codable {
    let id: String
    let studentId: String
    let schoolId: String
    let reportedBy: String // teacherId
    let type: BehaviorType
    let severity: Severity
    let description: String
    let actionTaken: String
    let parentNotified: Bool
    let date: Date
    let createdAt: Date
    
    enum BehaviorType: String, Codable, CaseIterable {
        case positive = "Positive"
        case tardiness = "Tardiness"
        case disruptive = "Disruptive Behavior"
        case disrespect = "Disrespect"
        case bullying = "Bullying"
        case fighting = "Fighting"
        case cheating = "Academic Dishonesty"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .positive: return "star.fill"
            case .tardiness: return "clock.fill"
            case .disruptive: return "speaker.wave.3.fill"
            case .disrespect: return "hand.raised.slash.fill"
            case .bullying: return "exclamationmark.triangle.fill"
            case .fighting: return "figure.boxing"
            case .cheating: return "doc.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
    
    enum Severity: String, Codable, CaseIterable {
        case minor = "Minor"
        case moderate = "Moderate"
        case major = "Major"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .minor: return "green"
            case .moderate: return "yellow"
            case .major: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> BehaviorIncident? {
        guard let data = doc.data() else { return nil }
        return BehaviorIncident(
            id: doc.documentID,
            studentId: data["studentId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            reportedBy: data["reportedBy"] as? String ?? "",
            type: BehaviorType(rawValue: data["type"] as? String ?? "") ?? .other,
            severity: Severity(rawValue: data["severity"] as? String ?? "") ?? .minor,
            description: data["description"] as? String ?? "",
            actionTaken: data["actionTaken"] as? String ?? "",
            parentNotified: data["parentNotified"] as? Bool ?? false,
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Grading Scale
struct GradingScale: Identifiable, Codable {
    let id: String
    let schoolId: String
    let name: String
    let isDefault: Bool
    let ranges: [GradeRange]
    
    struct GradeRange: Codable {
        let letter: String
        let minPercent: Double
        let maxPercent: Double
        let gpaValue: Double
    }
    
    static let standard = GradingScale(
        id: "standard",
        schoolId: "",
        name: "Standard A-F",
        isDefault: true,
        ranges: [
            GradeRange(letter: "A", minPercent: 90, maxPercent: 100, gpaValue: 4.0),
            GradeRange(letter: "B", minPercent: 80, maxPercent: 89.99, gpaValue: 3.0),
            GradeRange(letter: "C", minPercent: 70, maxPercent: 79.99, gpaValue: 2.0),
            GradeRange(letter: "D", minPercent: 60, maxPercent: 69.99, gpaValue: 1.0),
            GradeRange(letter: "F", minPercent: 0, maxPercent: 59.99, gpaValue: 0.0)
        ]
    )
    
    func letterGrade(for percent: Double) -> String {
        for range in ranges {
            if percent >= range.minPercent && percent <= range.maxPercent {
                return range.letter
            }
        }
        return "N/A"
    }
}

// MARK: - Bus Tracking
struct BusRoute: Identifiable, Codable {
    let id: String
    let schoolId: String
    let routeNumber: String
    let driverName: String
    let driverPhone: String
    let stops: [BusStop]
    let assignedStudentIds: [String]
    
    static func fromDocument(_ doc: DocumentSnapshot) -> BusRoute? {
        guard let data = doc.data() else { return nil }
        return BusRoute(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            routeNumber: data["routeNumber"] as? String ?? "",
            driverName: data["driverName"] as? String ?? "",
            driverPhone: data["driverPhone"] as? String ?? "",
            stops: (data["stops"] as? [[String: Any]] ?? []).compactMap { BusStop.fromDict($0) },
            assignedStudentIds: data["assignedStudentIds"] as? [String] ?? []
        )
    }
}

struct BusStop: Codable, Identifiable {
    var id: String { "\(name)_\(latitude)_\(longitude)" }
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let estimatedTime: String
    
    static func fromDict(_ dict: [String: Any]) -> BusStop {
        BusStop(
            name: dict["name"] as? String ?? "",
            address: dict["address"] as? String ?? "",
            latitude: dict["latitude"] as? Double ?? 0,
            longitude: dict["longitude"] as? Double ?? 0,
            estimatedTime: dict["estimatedTime"] as? String ?? ""
        )
    }
}

struct BusLocation: Codable {
    let routeId: String
    let latitude: Double
    let longitude: Double
    let speed: Double
    let heading: Double
    let updatedAt: Date
}

// MARK: - Lunch Menu
struct LunchMenu: Identifiable, Codable {
    let id: String
    let schoolId: String
    let weekStartDate: Date
    let days: [DailyMenu]
    
    static func fromDocument(_ doc: DocumentSnapshot) -> LunchMenu? {
        guard let data = doc.data() else { return nil }
        return LunchMenu(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            weekStartDate: (data["weekStartDate"] as? Timestamp)?.dateValue() ?? Date(),
            days: (data["days"] as? [[String: Any]] ?? []).compactMap { DailyMenu.fromDict($0) }
        )
    }
}

struct DailyMenu: Codable {
    let dayOfWeek: Int // 1-5 (Mon-Fri)
    let mainCourse: String
    let sides: [String]
    let vegetarianOption: String
    let allergens: [String]
    let calories: Int
    
    static func fromDict(_ dict: [String: Any]) -> DailyMenu {
        DailyMenu(
            dayOfWeek: dict["dayOfWeek"] as? Int ?? 1,
            mainCourse: dict["mainCourse"] as? String ?? "",
            sides: dict["sides"] as? [String] ?? [],
            vegetarianOption: dict["vegetarianOption"] as? String ?? "",
            allergens: dict["allergens"] as? [String] ?? [],
            calories: dict["calories"] as? Int ?? 0
        )
    }
}

// MARK: - Emergency Alert
struct EmergencyAlert: Identifiable, Codable {
    let id: String
    let schoolId: String
    let type: AlertType
    let title: String
    let message: String
    let isActive: Bool
    let createdBy: String
    let createdAt: Date
    let resolvedAt: Date?
    
    enum AlertType: String, Codable, CaseIterable {
        case lockdown = "Lockdown"
        case weather = "Weather"
        case medical = "Medical Emergency"
        case fire = "Fire Drill"
        case evacuation = "Evacuation"
        case shelter = "Shelter in Place"
        case other = "General Alert"
        
        var icon: String {
            switch self {
            case .lockdown: return "lock.shield.fill"
            case .weather: return "cloud.bolt.rain.fill"
            case .medical: return "cross.fill"
            case .fire: return "flame.fill"
            case .evacuation: return "figure.walk"
            case .shelter: return "house.fill"
            case .other: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .lockdown: return "red"
            case .weather: return "blue"
            case .medical: return "red"
            case .fire: return "orange"
            case .evacuation: return "yellow"
            case .shelter: return "purple"
            case .other: return "gray"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> EmergencyAlert? {
        guard let data = doc.data() else { return nil }
        return EmergencyAlert(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            type: AlertType(rawValue: data["type"] as? String ?? "") ?? .other,
            title: data["title"] as? String ?? "",
            message: data["message"] as? String ?? "",
            isActive: data["isActive"] as? Bool ?? true,
            createdBy: data["createdBy"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            resolvedAt: (data["resolvedAt"] as? Timestamp)?.dateValue()
        )
    }
}

// MARK: - Student Portfolio
struct PortfolioItem: Identifiable, Codable {
    let id: String
    let studentId: String
    let schoolId: String
    let title: String
    let description: String
    let type: PortfolioType
    let fileUrl: String
    let thumbnailUrl: String?
    let subject: String
    let grade: String?
    let teacherComment: String?
    let createdAt: Date
    
    enum PortfolioType: String, Codable, CaseIterable {
        case artwork = "Artwork"
        case writing = "Writing"
        case project = "Project"
        case presentation = "Presentation"
        case video = "Video"
        case photo = "Photo"
        case achievement = "Achievement"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .artwork: return "paintbrush.fill"
            case .writing: return "doc.text.fill"
            case .project: return "folder.fill"
            case .presentation: return "play.rectangle.fill"
            case .video: return "video.fill"
            case .photo: return "photo.fill"
            case .achievement: return "trophy.fill"
            case .other: return "square.fill"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> PortfolioItem? {
        guard let data = doc.data() else { return nil }
        return PortfolioItem(
            id: doc.documentID,
            studentId: data["studentId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            type: PortfolioType(rawValue: data["type"] as? String ?? "") ?? .other,
            fileUrl: data["fileUrl"] as? String ?? "",
            thumbnailUrl: data["thumbnailUrl"] as? String,
            subject: data["subject"] as? String ?? "",
            grade: data["grade"] as? String,
            teacherComment: data["teacherComment"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Notification Settings
struct NotificationPreferences: Codable {
    var announcements: Bool
    var grades: Bool
    var attendance: Bool
    var subRequests: Bool
    var emergencyAlerts: Bool
    var messages: Bool
    var homework: Bool
    var events: Bool
    
    static let defaultPrefs = NotificationPreferences(
        announcements: true,
        grades: true,
        attendance: true,
        subRequests: true,
        emergencyAlerts: true,
        messages: true,
        homework: true,
        events: true
    )
}

// MARK: - Video Meeting
struct VideoMeeting: Identifiable, Codable {
    let id: String
    let schoolId: String
    let hostId: String
    let title: String
    let scheduledAt: Date
    let duration: Int // minutes
    let meetingUrl: String
    let meetingCode: String
    let participantIds: [String]
    let isRecorded: Bool
    let recordingUrl: String?
    let status: MeetingStatus
    
    enum MeetingStatus: String, Codable {
        case scheduled = "scheduled"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> VideoMeeting? {
        guard let data = doc.data() else { return nil }
        return VideoMeeting(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            hostId: data["hostId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            scheduledAt: (data["scheduledAt"] as? Timestamp)?.dateValue() ?? Date(),
            duration: data["duration"] as? Int ?? 30,
            meetingUrl: data["meetingUrl"] as? String ?? "",
            meetingCode: data["meetingCode"] as? String ?? "",
            participantIds: data["participantIds"] as? [String] ?? [],
            isRecorded: data["isRecorded"] as? Bool ?? false,
            recordingUrl: data["recordingUrl"] as? String,
            status: MeetingStatus(rawValue: data["status"] as? String ?? "") ?? .scheduled
        )
    }
}

// MARK: - Sub Review (complaints / compliments)
struct SubReview: Identifiable, Codable {
    let id: String
    let subId: String
    let subUserId: String
    let subName: String
    let schoolId: String
    let schoolName: String
    let schoolCity: String
    let type: ReviewType
    let category: ReviewCategory
    let valueScore: Double  // 1...5
    let comment: String?
    let createdByUserId: String
    let createdAt: Date
    
    enum ReviewType: String, Codable, CaseIterable {
        case complaint = "complaint"
        case compliment = "compliment"
    }
    
    enum ReviewCategory: String, Codable, CaseIterable {
        case attendance = "attendance"
        case helpfulness = "helpfulness"
        case punctuality = "punctuality"
        case classroomManagement = "classroom_management"
        case communication = "communication"
        case flexibility = "flexibility"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .attendance: return "Attendance"
            case .helpfulness: return "Helpfulness"
            case .punctuality: return "Punctuality"
            case .classroomManagement: return "Classroom Management"
            case .communication: return "Communication"
            case .flexibility: return "Flexibility"
            case .other: return "Other"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> SubReview? {
        guard let data = doc.data() else { return nil }
        return SubReview(
            id: doc.documentID,
            subId: data["subId"] as? String ?? "",
            subUserId: data["subUserId"] as? String ?? "",
            subName: data["subName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            schoolName: data["schoolName"] as? String ?? "",
            schoolCity: data["schoolCity"] as? String ?? "",
            type: ReviewType(rawValue: data["type"] as? String ?? "compliment") ?? .compliment,
            category: ReviewCategory(rawValue: data["category"] as? String ?? "other") ?? .other,
            valueScore: data["valueScore"] as? Double ?? 0,
            comment: data["comment"] as? String,
            createdByUserId: data["createdByUserId"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Sub Ranking (aggregate for top 100)
struct SubRankingItem: Identifiable {
    let subId: String
    let subUserId: String
    let subName: String
    let city: String
    let overallValue: Double
    let categoryBreakdown: [String: Double]  // category -> avg score
    let complaintCount: Int
    let complimentCount: Int
    let reviewCount: Int
    var id: String { subId }
}

// MARK: - Activity / Recommended Purchase
struct RecommendedActivity: Identifiable, Codable {
    let id: String
    let teacherId: String
    let schoolId: String
    let classId: String?
    let title: String
    let description: String
    let linkUrl: String?
    let type: ActivityType
    let createdAt: Date
    
    enum ActivityType: String, Codable, CaseIterable {
        case activity = "activity"
        case recommendedPurchase = "recommended_purchase"
        
        var displayName: String {
            switch self {
            case .activity: return "Activity"
            case .recommendedPurchase: return "Recommended Purchase"
            }
        }
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> RecommendedActivity? {
        guard let data = doc.data() else { return nil }
        return RecommendedActivity(
            id: doc.documentID,
            teacherId: data["teacherId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            classId: data["classId"] as? String,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            linkUrl: data["linkUrl"] as? String,
            type: ActivityType(rawValue: data["type"] as? String ?? "activity") ?? .activity,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
