//
//  MainContainerView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainContainerView: View {

    // UI
    @State private var showMenu = false
    @State private var showInfo = false

    // Navigation
    @State private var selectedPage: Page = .home
    @State private var activeSheet: ActiveSheet?

    // User & School data
    @State private var role: String = ""
    @State private var schoolId: String?
    @State private var schoolName: String = ""
    @State private var schoolLogoUrl: String = ""
    @State private var welcomeMessage: String = ""
    @State private var subscriptionActive: Bool = false

    // Edit sheets
    @State private var showEditHomepage = false
    @State private var showEditCalendar = false
    @State private var showAddAnnouncement = false

    private let db = Firestore.firestore()

    enum Page {
        case home
        case schoolInfo
        case officeInfo
        case grades
    }

    enum ActiveSheet: Identifiable {
        case switchSchool
        var id: Int { 1 }
    }

    enum MenuSheet: String, Identifiable, CaseIterable {
        case account
        case messaging
        case documents
        case analytics
        case bellSchedule
        case subRequests
        case availability
        case parentPortal
        case lessonPlans
        case homework
        case behavior
        case busTracking
        case lunchMenu
        case emergencyAlerts
        case videoMeetings
        case attendanceAnalytics
        case subRanking
        case activities
        case students
        case defaultPasswordReport
        case schoolLibrary
        case studentWriteUps
        case subNotes
        // New features
        case aiLessonPlans
        case aiStudyPlan
        case activeTime
        case gymGames
        case talkerBoard
        case movies
        case addBookByPhoto
        case plansBilling
        case standardsExplorer
        var id: String { rawValue }
    }

    @State private var menuSheet: MenuSheet?
    @State private var districtSchoolIds: [String] = []

    var body: some View {
        ZStack(alignment: .leading) {

            NavigationStack {
                currentPage
                    .background(EZTeachColors.background)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showMenu.toggle()
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3.weight(.medium))
                            }
                        }

                        // School edit menu (only on home page for school accounts)
                        if selectedPage == .home && role == "school" && schoolId != nil {
                            ToolbarItem(placement: .topBarTrailing) {
                                Menu {
                                    Button {
                                        showEditHomepage = true
                                    } label: {
                                        Label("Edit Homepage", systemImage: "house")
                                    }

                                    Button {
                                        showEditCalendar = true
                                    } label: {
                                        Label("Add Calendar Event", systemImage: "calendar.badge.plus")
                                    }

                                    Button {
                                        showAddAnnouncement = true
                                    } label: {
                                        Label("Add Announcement", systemImage: "megaphone")
                                    }
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(EZTeachColors.accentGradient)
                                }
                            }
                        }

                        // Teacher announcement button (on home page)
                        if selectedPage == .home && role == "teacher" && schoolId != nil {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showAddAnnouncement = true
                                } label: {
                                    Image(systemName: "megaphone")
                                        .font(.title3)
                                        .foregroundColor(EZTeachColors.accent)
                                }
                            }
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showInfo = true } label: {
                                Image(systemName: "questionmark.circle")
                                    .font(.title3)
                            }
                        }
                    }
            }

            // Menu overlay
            if showMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }
                    .transition(.opacity)

                SideMenuView(
                    showMenu: $showMenu,
                    selectedPage: $selectedPage,
                    activeSheet: $activeSheet,
                    menuSheet: $menuSheet,
                    role: role,
                    schoolId: schoolId ?? "",
                    districtSchoolIds: districtSchoolIds
                )
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            if sheet == .switchSchool {
                SwitchSchoolView()
                    .onDisappear {
                        // Refresh data when returning from switch school
                        loadUserData()
                        notifyDataChanged()
                    }
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoView()
        }
        .sheet(isPresented: $showEditHomepage, onDismiss: notifyDataChanged) {
            if let sid = schoolId {
                EditHomepageView(
                    schoolId: sid,
                    currentLogoUrl: schoolLogoUrl,
                    currentWelcomeMessage: welcomeMessage
                )
            }
        }
        .sheet(isPresented: $showEditCalendar, onDismiss: notifyDataChanged) {
            if let schoolId {
                EditCalendarView(schoolId: schoolId)
            }
        }
        .sheet(isPresented: $showAddAnnouncement, onDismiss: notifyDataChanged) {
            if let schoolId {
                AddAnnouncementView(
                    schoolId: schoolId,
                    userRole: role,
                    userName: Auth.auth().currentUser?.displayName ?? ""
                )
            }
        }
        .sheet(item: $menuSheet) { sheet in
            menuSheetContent(sheet)
        }
        .onAppear(perform: loadUserData)
        .onChange(of: selectedPage) { _, _ in
            loadUserData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .schoolDataDidChange)) { _ in
            loadUserData()
        }
    }

    @ViewBuilder
    var currentPage: some View {
        switch selectedPage {
        case .home:
            ContentView()
        case .schoolInfo:
            SchoolInfoView()
        case .officeInfo:
            OfficeInfoView()
        case .grades:
            GradesListView()
        }
    }

    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            role = data["role"] as? String ?? ""
            schoolId = data["activeSchoolId"] as? String
            schoolName = data["schoolName"] as? String ?? ""

            if role == "district", let did = data["districtId"] as? String, !did.isEmpty {
                db.collection("districts").document(did).getDocument { dSnap, _ in
                    districtSchoolIds = dSnap?.data()?["schoolIds"] as? [String] ?? []
                }
            } else {
                districtSchoolIds = []
            }

            // Security: Verify user has access to the school
            if let activeSchool = schoolId {
                verifySchoolAccess(schoolId: activeSchool, userRole: role)
                loadSchoolCustomization(schoolId: activeSchool)
            } else {
                schoolLogoUrl = ""
                welcomeMessage = ""
            }
        }
    }

    private func loadSchoolCustomization(schoolId: String) {
        db.collection("schools").document(schoolId).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            schoolLogoUrl = data["logoUrl"] as? String ?? ""
            welcomeMessage = data["welcomeMessage"] as? String ?? ""
            subscriptionActive = data["subscriptionActive"] as? Bool ?? false
        }
    }

    /// Verify user has legitimate access to the school
    private func verifySchoolAccess(schoolId: String, userRole: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // For school accounts, verify they own the school
        if userRole == "school" {
            db.collection("schools").document(schoolId).getDocument { snap, _ in
                guard let data = snap?.data(),
                      let ownerUid = data["ownerUid"] as? String else { return }

                if ownerUid != uid {
                    // User doesn't own this school - clear access
                    clearSchoolAccess()
                }
            }
        } else {
            // For teachers/subs, verify they're in joinedSchools
            db.collection("users").document(uid).getDocument { snap, _ in
                guard let data = snap?.data() else { return }
                let joinedSchools = data["joinedSchools"] as? [[String: String]] ?? []

                let hasAccess = joinedSchools.contains { $0["id"] == schoolId }
                if !hasAccess {
                    clearSchoolAccess()
                }
            }
        }
    }

    /// Clear school access if user doesn't have permission
    private func clearSchoolAccess() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).updateData([
            "activeSchoolId": NSNull(),
            "schoolId": NSNull(),
            "schoolName": NSNull()
        ])

        schoolId = nil
        schoolName = ""
        notifyDataChanged()
    }

    private func notifyDataChanged() {
        NotificationCenter.default.post(name: .schoolDataDidChange, object: nil)
    }

    @ViewBuilder
    private func menuSheetContent(_ sheet: MenuSheet) -> some View {
        AnyView(menuSheetContentInner(sheet))
            .onDisappear { menuSheet = nil }
    }

    /// Features that are always free (no subscription required)
    private var freeSheets: Set<MenuSheet> {
        [.account, .plansBilling, .parentPortal]
    }

    @ViewBuilder
    private func menuSheetContentInner(_ sheet: MenuSheet) -> some View {
        let sid = schoolId ?? (role == "district" ? (districtSchoolIds.first ?? "") : "")
        let hasSchool = !sid.isEmpty

        // --- Subscription gate ---
        // Free features bypass the gate; everything else requires active subscription
        if !freeSheets.contains(sheet) && hasSchool && !subscriptionActive {
            SubscriptionRequiredView {
                menuSheet = nil
                menuSheet = .plansBilling
            }
        } else {

        switch sheet {
            case .account:
                NavigationStack { AccountView() }
            case .messaging:
                if hasSchool { NavigationStack { MessagingView(schoolId: sid) } }
                else { NeedSchoolSheetView(feature: "Messages") { menuSheet = nil; activeSheet = .switchSchool } }
            case .documents:
                if hasSchool { NavigationStack { DocumentsView(schoolId: sid, userRole: role) } }
                else { NeedSchoolSheetView(feature: "Documents") { menuSheet = nil; activeSheet = .switchSchool } }
            case .analytics:
                if hasSchool { NavigationStack { AnalyticsDashboardView(schoolId: sid) } }
                else { NeedSchoolSheetView(feature: "Analytics") { menuSheet = nil; activeSheet = .switchSchool } }
            case .bellSchedule:
                if hasSchool { NavigationStack { BellScheduleView(schoolId: sid, userRole: role) } }
                else { NeedSchoolSheetView(feature: "Bell Schedule") { menuSheet = nil; activeSheet = .switchSchool } }
            case .subRequests:
                if hasSchool { NavigationStack { SubRequestsListView(schoolId: sid, userRole: role) } }
                else { NeedSchoolSheetView(feature: "Sub Requests") { menuSheet = nil; activeSheet = .switchSchool } }
            case .availability:
                if hasSchool, let uid = Auth.auth().currentUser?.uid {
                    NavigationStack { TeacherAvailabilityView(teacherId: uid, schoolId: sid) }
                } else { NeedSchoolSheetView(feature: "My Availability") { menuSheet = nil; activeSheet = .switchSchool } }
            case .parentPortal:
                NavigationStack { ParentPortalView() }
            case .lessonPlans:
                if hasSchool { NavigationStack { LessonPlanningView(schoolId: sid) } }
                else { NeedSchoolSheetView(feature: "Lesson Plans") { menuSheet = nil; activeSheet = .switchSchool } }
            case .homework:
                if hasSchool { HomeworkView(schoolId: sid, classId: nil, userRole: role) }
                else { NeedSchoolSheetView(feature: "Homework") { menuSheet = nil; activeSheet = .switchSchool } }
            case .behavior:
                if hasSchool { BehaviorTrackingView(schoolId: sid, studentId: nil, userRole: role) }
                else { NeedSchoolSheetView(feature: "Behavior") { menuSheet = nil; activeSheet = .switchSchool } }
            case .busTracking:
                if hasSchool { NavigationStack { BusTrackingView(schoolId: sid, isAdmin: role == "school") } }
                else { NeedSchoolSheetView(feature: "Bus Tracking") { menuSheet = nil; activeSheet = .switchSchool } }
            case .lunchMenu:
                if hasSchool { NavigationStack { LunchMenuView(schoolId: sid, userRole: role) } }
                else { NeedSchoolSheetView(feature: "Lunch Menu") { menuSheet = nil; activeSheet = .switchSchool } }
            case .emergencyAlerts:
                if hasSchool { NavigationStack { EmergencyAlertsView(schoolId: sid, isAdmin: role == "school") } }
                else { NeedSchoolSheetView(feature: "Emergency Alerts") { menuSheet = nil; activeSheet = .switchSchool } }
            case .videoMeetings:
                if hasSchool { NavigationStack { VideoMeetingView(schoolId: sid, userRole: role) } }
                else { NeedSchoolSheetView(feature: "Video Meetings") { menuSheet = nil; activeSheet = .switchSchool } }
            case .attendanceAnalytics:
                if hasSchool { NavigationStack { AttendanceAnalyticsView(schoolId: sid) } }
                else { NeedSchoolSheetView(feature: "Attendance Analytics") { menuSheet = nil; activeSheet = .switchSchool } }
            case .subRanking:
                if role == "district", !districtSchoolIds.isEmpty {
                    NavigationStack { SubRankingView(schoolId: districtSchoolIds.first ?? "", districtSchoolIds: districtSchoolIds, isDistrict: true) }
                } else if hasSchool {
                    NavigationStack { SubRankingView(schoolId: sid, districtSchoolIds: [], isDistrict: false) }
                } else {
                    NeedSchoolSheetView(feature: "Sub Ranking") { menuSheet = nil; activeSheet = .switchSchool }
                }
            case .activities:
                if hasSchool { NavigationStack { ActivitiesView(schoolId: sid, classId: nil) } }
                else { NeedSchoolSheetView(feature: "Activities & Links") { menuSheet = nil; activeSheet = .switchSchool } }
            case .students:
                if hasSchool { NavigationStack { StudentsListView() } }
                else { NeedSchoolSheetView(feature: "Students") { menuSheet = nil; activeSheet = .switchSchool } }
            case .defaultPasswordReport:
                if hasSchool || role == "district" {
                    NavigationStack { DefaultPasswordReportView() }
                } else {
                    NeedSchoolSheetView(feature: "Default Password Report") { menuSheet = nil; activeSheet = .switchSchool }
                }
            case .schoolLibrary:
                if hasSchool {
                    NavigationStack {
                        if role == "school" || role == "librarian" || role == "teacher" {
                            LibraryManagementView(schoolId: sid, canEdit: role == "school" || role == "librarian" || role == "teacher")
                        } else {
                            SchoolLibraryView(schoolId: sid, canEdit: false)
                        }
                    }
                } else {
                    NeedSchoolSheetView(feature: "School Library") { menuSheet = nil; activeSheet = .switchSchool }
                }
            case .studentWriteUps:
                if hasSchool {
                    let userName = Auth.auth().currentUser?.displayName ?? "Staff"
                    NavigationStack { StudentWriteUpView(schoolId: sid, userRole: role, userName: userName) }
                } else {
                    NeedSchoolSheetView(feature: "Student Write-Ups") { menuSheet = nil; activeSheet = .switchSchool }
                }
            case .subNotes:
                if hasSchool {
                    let subName = Auth.auth().currentUser?.displayName ?? "Substitute"
                    NavigationStack {
                        SubNotesView(
                            schoolId: sid,
                            classId: "",
                            className: "",
                            teacherId: "",
                            teacherName: "",
                            subName: subName
                        )
                    }
                } else {
                    NeedSchoolSheetView(feature: "Sub Notes") { menuSheet = nil; activeSheet = .switchSchool }
                }
                
            // MARK: - New Features
            case .aiLessonPlans:
                if hasSchool {
                    AILessonPlanView(schoolId: sid, userRole: role)
                } else {
                    NeedSchoolSheetView(feature: "AI Lesson Plans") { menuSheet = nil; activeSheet = .switchSchool }
                }
                
            case .aiStudyPlan:
                if hasSchool {
                    AIStudyPlanView(schoolId: sid, studentId: "", studentName: "My Child")
                } else {
                    NeedSchoolSheetView(feature: "AI Study Plans") { menuSheet = nil; activeSheet = .switchSchool }
                }
                
            case .activeTime:
                if hasSchool {
                    ActiveTimeView(schoolId: sid, userRole: role)
                } else {
                    NeedSchoolSheetView(feature: "Active Time") { menuSheet = nil; activeSheet = .switchSchool }
                }
                
            case .gymGames:
                GymActiveGamesView()
                
            case .talkerBoard:
                if hasSchool {
                    TalkerBoardView(schoolId: sid, userRole: role, studentId: nil, studentName: nil)
                } else {
                    NeedSchoolSheetView(feature: "Talker Board") { menuSheet = nil; activeSheet = .switchSchool }
                }
                
            case .movies:
                MoviesView()
                
            case .addBookByPhoto:
                if hasSchool {
                    AddBookByPhotoView(schoolId: sid)
                } else {
                    NeedSchoolSheetView(feature: "Add Book by Photo") { menuSheet = nil; activeSheet = .switchSchool }
                }

            case .plansBilling:
                if hasSchool {
                    PlansBillingView(schoolId: sid)
                } else {
                    NeedSchoolSheetView(feature: "Plans & Billing") { menuSheet = nil; activeSheet = .switchSchool }
                }

            case .standardsExplorer:
                if hasSchool {
                    StandardsExplorerView(userRole: role, schoolId: sid, districtId: nil)
                } else {
                    NeedSchoolSheetView(feature: "Standards Explorer") { menuSheet = nil; activeSheet = .switchSchool }
                }
        }
        } // end subscription gate else
    }
}
