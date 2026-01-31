//
//  AnalyticsData.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import Foundation

// MARK: - School Analytics
struct SchoolAnalytics {
    let schoolId: String
    let period: AnalyticsPeriod
    let startDate: Date
    let endDate: Date
    
    // Attendance
    let totalStudents: Int
    let averageAttendanceRate: Double
    let totalAbsences: Int
    let totalTardies: Int
    
    // Staffing
    let totalTeachers: Int
    let totalSubs: Int
    let subRequestsCount: Int
    let subRequestsFilled: Int
    let subRequestsFillRate: Double
    
    // Engagement
    let announcementsPosted: Int
    let eventsCreated: Int
    let documentsUploaded: Int
    let messagesExchanged: Int
    
    enum AnalyticsPeriod: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case quarter = "This Quarter"
        case year = "This Year"
        case custom = "Custom"
    }
}

// MARK: - Attendance Analytics
struct AttendanceAnalytics {
    let period: String
    let dailyRates: [DailyRate]
    let byGrade: [GradeAttendance]
    let byClass: [ClassAttendance]
    let trends: AttendanceTrend
    
    struct DailyRate: Identifiable {
        let id = UUID()
        let date: Date
        let rate: Double
        let presentCount: Int
        let absentCount: Int
    }
    
    struct GradeAttendance: Identifiable {
        let id = UUID()
        let grade: Int
        let gradeName: String
        let rate: Double
        let studentCount: Int
    }
    
    struct ClassAttendance: Identifiable {
        let id = UUID()
        let classId: String
        let className: String
        let teacherName: String
        let rate: Double
    }
    
    struct AttendanceTrend {
        let direction: TrendDirection
        let percentageChange: Double
        let comparedTo: String
        
        enum TrendDirection {
            case up
            case down
            case stable
        }
    }
}

// MARK: - Sub Coverage Analytics
struct SubCoverageAnalytics {
    let period: String
    let totalRequests: Int
    let filledRequests: Int
    let unfilledRequests: Int
    let averageFillTime: TimeInterval  // in hours
    let fillRate: Double
    
    let byReason: [ReasonBreakdown]
    let byTeacher: [TeacherSubUsage]
    let byDay: [DayBreakdown]
    
    struct ReasonBreakdown: Identifiable {
        let id = UUID()
        let reason: String
        let count: Int
        let percentage: Double
    }
    
    struct TeacherSubUsage: Identifiable {
        let id = UUID()
        let teacherId: String
        let teacherName: String
        let requestCount: Int
        let daysOut: Int
    }
    
    struct DayBreakdown: Identifiable {
        let id = UUID()
        let dayOfWeek: Int
        let dayName: String
        let averageRequests: Double
    }
}

// MARK: - Financial Analytics (for subscriptions)
struct FinancialAnalytics {
    let period: String
    let totalRevenue: Double
    let activeSubscriptions: Int
    let newSubscriptions: Int
    let cancelledSubscriptions: Int
    let churnRate: Double
    let monthlyRecurringRevenue: Double
    
    let revenueByMonth: [MonthlyRevenue]
    
    struct MonthlyRevenue: Identifiable {
        let id = UUID()
        let month: Date
        let revenue: Double
        let subscriptionCount: Int
    }
}
