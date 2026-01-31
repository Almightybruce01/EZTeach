//
//  SideMenuView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SideMenuView: View {

    @Binding var showMenu: Bool
    @Binding var selectedPage: MainContainerView.Page
    @Binding var activeSheet: MainContainerView.ActiveSheet?

    @State private var role: String = ""
    @State private var userName: String = ""
    @State private var schoolName: String = ""
    @State private var schoolId: String = ""
    @State private var districtId: String = ""
    @State private var districtSchoolIds: [String] = []
    
    // Sheet states
    @State private var showAccount = false
    @State private var showMessaging = false
    @State private var showDocuments = false
    @State private var showAnalytics = false
    @State private var showBellSchedule = false
    @State private var showSubRequests = false
    @State private var showAvailability = false
    @State private var showParentPortal = false
    
    // New feature sheets
    @State private var showLessonPlans = false
    @State private var showHomework = false
    @State private var showBehavior = false
    @State private var showBusTracking = false
    @State private var showLunchMenu = false
    @State private var showEmergencyAlerts = false
    @State private var showVideoMeetings = false
    @State private var showAttendanceAnalytics = false
    @State private var showSubRanking = false
    @State private var showActivities = false

    @Environment(\.colorScheme) private var colorScheme
    private let db = Firestore.firestore()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header with branding
            headerSection

            Divider()
                .padding(.vertical, 8)

            // Navigation items
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // Main navigation
                    sectionLabel("NAVIGATION")

                    menuItem("Home", icon: "house.fill", isSelected: selectedPage == .home) {
                        go(.home)
                    }

                    menuItem("School Info", icon: "building.columns.fill", isSelected: selectedPage == .schoolInfo) {
                        go(.schoolInfo)
                    }

                    menuItem("Office Info", icon: "info.circle.fill", isSelected: selectedPage == .officeInfo) {
                        go(.officeInfo)
                    }

                    menuItem("Grades", icon: "list.clipboard.fill", isSelected: selectedPage == .grades) {
                        go(.grades)
                    }

                    // Parent-specific section
                    if role == "parent" {
                        Divider()
                            .padding(.vertical, 12)

                        sectionLabel("MY CHILDREN")

                        menuItem("My Children", icon: "figure.2.and.child.holdinghands") {
                            showMenu = false
                            showParentPortal = true
                        }
                        
                        menuItem("Bus Tracking", icon: "bus.fill") {
                            showMenu = false
                            showBusTracking = true
                        }
                        
                        menuItem("Lunch Menu", icon: "fork.knife") {
                            showMenu = false
                            showLunchMenu = true
                        }
                        
                        menuItem("Video Meetings", icon: "video.fill") {
                            showMenu = false
                            showVideoMeetings = true
                        }
                    }

                    // School/Teacher features
                    if role == "school" || role == "teacher" {
                        Divider()
                            .padding(.vertical, 12)

                        sectionLabel("CLASSROOM")
                        
                        if role == "teacher" {
                            menuItem("Lesson Plans", icon: "doc.text.fill") {
                                showMenu = false
                                showLessonPlans = true
                            }
                        }
                        
                        menuItem("Homework", icon: "book.fill") {
                            showMenu = false
                            showHomework = true
                        }
                        
                        menuItem("Behavior", icon: "star.fill") {
                            showMenu = false
                            showBehavior = true
                        }
                        
                        menuItem("Activities & Links", icon: "link") {
                            showMenu = false
                            showActivities = true
                        }

                        Divider()
                            .padding(.vertical, 12)

                        sectionLabel("MANAGEMENT")

                        menuItem("Sub Requests", icon: "calendar.badge.clock") {
                            showMenu = false
                            showSubRequests = true
                        }

                        if role == "teacher" {
                            menuItem("My Availability", icon: "calendar.badge.checkmark") {
                                showMenu = false
                                showAvailability = true
                            }
                        }

                        menuItem("Documents", icon: "doc.fill") {
                            showMenu = false
                            showDocuments = true
                        }

                        menuItem("Bell Schedule", icon: "bell.fill") {
                            showMenu = false
                            showBellSchedule = true
                        }
                        
                        menuItem("Video Meetings", icon: "video.fill") {
                            showMenu = false
                            showVideoMeetings = true
                        }

                        if role == "school" {
                            Divider()
                                .padding(.vertical, 12)
                            
                            sectionLabel("SCHOOL ADMIN")
                            
                            menuItem("Analytics", icon: "chart.bar.fill") {
                                showMenu = false
                                showAnalytics = true
                            }
                            
                            menuItem("Attendance Stats", icon: "chart.pie.fill") {
                                showMenu = false
                                showAttendanceAnalytics = true
                            }
                            
                            menuItem("Bus Routes", icon: "bus.fill") {
                                showMenu = false
                                showBusTracking = true
                            }
                            
                            menuItem("Lunch Menu", icon: "fork.knife") {
                                showMenu = false
                                showLunchMenu = true
                            }
                            
                            menuItem("Emergency Alerts", icon: "exclamationmark.triangle.fill", badgeColor: .red) {
                                showMenu = false
                                showEmergencyAlerts = true
                            }
                            
                            menuItem("Sub Ranking", icon: "list.number") {
                                showMenu = false
                                showSubRanking = true
                            }
                        }
                        
                        // District admin: same management features including Sub Ranking
                        if role == "district" {
                            Divider()
                                .padding(.vertical, 12)
                            
                            sectionLabel("DISTRICT ADMIN")
                            
                            menuItem("Analytics", icon: "chart.bar.fill") {
                                showMenu = false
                                showAnalytics = true
                            }
                            
                            menuItem("Sub Ranking", icon: "list.number") {
                                showMenu = false
                                showSubRanking = true
                            }
                        }
                    }

                    // Communication
                    Divider()
                        .padding(.vertical, 12)

                    sectionLabel("COMMUNICATION")

                    menuItem("Messages", icon: "bubble.left.and.bubble.right.fill") {
                        showMenu = false
                        showMessaging = true
                    }

                    // Schools section (teachers and subs only)
                    if role == "teacher" || role == "sub" || role == "parent" {
                        Divider()
                            .padding(.vertical, 12)

                        sectionLabel("SCHOOLS")

                        menuItem("Switch Schools", icon: "arrow.triangle.swap") {
                            showMenu = false
                            activeSheet = .switchSchool
                        }
                    }

                    Divider()
                        .padding(.vertical, 12)

                    // Account section
                    sectionLabel("ACCOUNT")

                    menuItem("My Account", icon: "person.circle.fill") {
                        showMenu = false
                        showAccount = true
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            // App version
            Text("EZTeach v1.0")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            Divider()

            // Footer with sign out
            footerSection
        }
        .frame(width: 280)
        .background(menuBackground)
        .ignoresSafeArea()
        .onAppear(perform: loadUserData)
        
        // Original sheets
        .sheet(isPresented: $showAccount) {
            AccountView()
        }
        .sheet(isPresented: $showMessaging) {
            if !schoolId.isEmpty {
                NavigationStack {
                    MessagingView(schoolId: schoolId)
                }
            }
        }
        .sheet(isPresented: $showDocuments) {
            if !schoolId.isEmpty {
                NavigationStack {
                    DocumentsView(schoolId: schoolId, userRole: role)
                }
            }
        }
        .sheet(isPresented: $showAnalytics) {
            if !schoolId.isEmpty {
                NavigationStack {
                    AnalyticsDashboardView(schoolId: schoolId)
                }
            }
        }
        .sheet(isPresented: $showBellSchedule) {
            if !schoolId.isEmpty {
                NavigationStack {
                    BellScheduleView(schoolId: schoolId, userRole: role)
                }
            }
        }
        .sheet(isPresented: $showSubRequests) {
            if !schoolId.isEmpty {
                NavigationStack {
                    SubRequestsListView(schoolId: schoolId, userRole: role)
                }
            }
        }
        .sheet(isPresented: $showAvailability) {
            if !schoolId.isEmpty, let uid = Auth.auth().currentUser?.uid {
                NavigationStack {
                    TeacherAvailabilityView(teacherId: uid, schoolId: schoolId)
                }
            }
        }
        .sheet(isPresented: $showParentPortal) {
            NavigationStack {
                ParentPortalView()
            }
        }
        
        // New feature sheets
        .sheet(isPresented: $showLessonPlans) {
            if !schoolId.isEmpty {
                LessonPlanningView(schoolId: schoolId)
            }
        }
        .sheet(isPresented: $showHomework) {
            if !schoolId.isEmpty {
                HomeworkView(schoolId: schoolId, classId: nil)
            }
        }
        .sheet(isPresented: $showBehavior) {
            if !schoolId.isEmpty {
                BehaviorTrackingView(schoolId: schoolId, studentId: nil)
            }
        }
        .sheet(isPresented: $showBusTracking) {
            if !schoolId.isEmpty {
                BusTrackingView(schoolId: schoolId, isAdmin: role == "school")
            }
        }
        .sheet(isPresented: $showLunchMenu) {
            if !schoolId.isEmpty {
                LunchMenuView(schoolId: schoolId, isAdmin: role == "school")
            }
        }
        .sheet(isPresented: $showEmergencyAlerts) {
            if !schoolId.isEmpty {
                EmergencyAlertsView(schoolId: schoolId, isAdmin: role == "school")
            }
        }
        .sheet(isPresented: $showVideoMeetings) {
            if !schoolId.isEmpty {
                VideoMeetingView(schoolId: schoolId, userRole: role)
            }
        }
        .sheet(isPresented: $showAttendanceAnalytics) {
            if !schoolId.isEmpty {
                AttendanceAnalyticsView(schoolId: schoolId)
            }
        }
        .sheet(isPresented: $showSubRanking) {
            if role == "district" {
                SubRankingView(schoolId: districtSchoolIds.first ?? "", districtSchoolIds: districtSchoolIds, isDistrict: true)
            } else if !schoolId.isEmpty {
                SubRankingView(schoolId: schoolId, districtSchoolIds: [], isDistrict: false)
            }
        }
        .sheet(isPresented: $showActivities) {
            if !schoolId.isEmpty {
                ActivitiesView(schoolId: schoolId, classId: nil)
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Logo
            HStack(spacing: 12) {
                Image("EZTeachLogoPolished.jpg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text("EZTeach")
                        .font(.title3.bold())
                        .foregroundColor(menuTextColor)

                    if !schoolName.isEmpty {
                        Text(schoolName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            // User info chip
            if !userName.isEmpty {
                HStack(spacing: 8) {
                    Circle()
                        .fill(EZTeachColors.accent.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(userName.prefix(1).uppercased())
                                .font(.caption.bold())
                                .foregroundColor(EZTeachColors.accent)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(userName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(menuTextColor)
                        HStack(spacing: 4) {
                            Image(systemName: roleIcon)
                                .font(.caption2)
                            Text(role.capitalized)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(EZTeachColors.cardFill)
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        Button {
            try? Auth.auth().signOut()
            withAnimation { showMenu = false }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.body.weight(.medium))
                Text("Sign Out")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(EZTeachColors.error)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 30)
    }

    // MARK: - Helper Views
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.leading, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func menuItem(_ title: String, icon: String, isSelected: Bool = false, badgeColor: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.body.weight(.medium))
                        .frame(width: 24)
                        .foregroundColor(isSelected ? EZTeachColors.accent : menuTextColor.opacity(0.8))
                    
                    if let badge = badgeColor {
                        Circle()
                            .fill(badge)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }

                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? EZTeachColors.accent : menuTextColor)

                Spacer()

                if isSelected {
                    Circle()
                        .fill(EZTeachColors.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(isSelected ? EZTeachColors.accent.opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
    }

    private func go(_ page: MainContainerView.Page) {
        selectedPage = page
        withAnimation { showMenu = false }
    }

    // MARK: - Styling
    private var menuTextColor: Color {
        colorScheme == .dark ? .white : EZTeachColors.navy
    }

    private var menuBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(.systemBackground)
            } else {
                LinearGradient(
                    colors: [Color.white, Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var roleIcon: String {
        switch role {
        case "school": return "building.columns.fill"
        case "teacher": return "person.fill"
        case "sub": return "person.badge.clock.fill"
        case "parent": return "figure.2.and.child.holdinghands"
        case "district": return "building.2.crop.circle.fill"
        default: return "person.fill"
        }
    }

    // MARK: - Load Data
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else { return }

            role = data["role"] as? String ?? ""
            schoolName = data["schoolName"] as? String ?? ""
            schoolId = data["activeSchoolId"] as? String ?? ""
            districtId = data["districtId"] as? String ?? ""

            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""

            if !firstName.isEmpty || !lastName.isEmpty {
                userName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            } else if !schoolName.isEmpty {
                userName = schoolName
            } else if role == "district" {
                userName = data["districtName"] as? String ?? "District Admin"
            }

            // Load district school IDs for district admins
            if role == "district", !districtId.isEmpty {
                db.collection("districts").document(districtId).getDocument { dSnap, _ in
                    districtSchoolIds = dSnap?.data()?["schoolIds"] as? [String] ?? []
                }
            } else {
                districtSchoolIds = []
            }
        }
    }
}
