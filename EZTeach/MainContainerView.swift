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
                    activeSheet: $activeSheet
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
            if let schoolId {
                EditHomepageView(
                    schoolId: schoolId,
                    currentLogoUrl: "",
                    currentWelcomeMessage: ""
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
                AddAnnouncementView(schoolId: schoolId)
            }
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

            // Security: Verify user has access to the school
            if let activeSchool = schoolId {
                verifySchoolAccess(schoolId: activeSchool, userRole: role)
            }
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
}
