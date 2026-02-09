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
    @Binding var menuSheet: MainContainerView.MenuSheet?
    let role: String
    let schoolId: String
    let districtSchoolIds: [String]

    @State private var userName: String = ""
    @State private var schoolName: String = ""
    @State private var districtId: String = ""

    @Environment(\.colorScheme) private var colorScheme
    private let db = Firestore.firestore()

    private func open(_ sheet: MainContainerView.MenuSheet) {
        menuSheet = sheet
        showMenu = false
    }

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

                    menuItem("School Library", icon: "books.vertical.fill", isSelected: false) {
                        open(.schoolLibrary)
                    }
                    
                    menuItem("Movies", icon: "play.rectangle.fill") {
                        open(.movies)
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
                            open(.parentPortal)
                        }
                        menuItem("AI Study Plans", icon: "sparkles", badgeColor: .green) { open(.aiStudyPlan) }
                        menuItem("Active Time", icon: "timer") { open(.activeTime) }
                        menuItem("Bus Tracking", icon: "bus.fill") { open(.busTracking) }
                        menuItem("Lunch Menu", icon: "fork.knife") { open(.lunchMenu) }
                        menuItem("Video Meetings", icon: "video.fill") { open(.videoMeetings) }
                    }

                    // School, district, teacher, sub: reports & classroom (parents excluded)
                    if role == "school" || role == "teacher" || role == "librarian" || role == "sub" || role == "district" {
                        Divider()
                            .padding(.vertical, 12)

                        sectionLabel("CLASSROOM")
                        
                        if role == "teacher" || role == "school" {
                            menuItem("AI Lesson Plans", icon: "sparkles", badgeColor: .purple) { open(.aiLessonPlans) }
                        }
                        menuItem("Standards Explorer", icon: "list.clipboard.fill") { open(.standardsExplorer) }
                        menuItem("Homework", icon: "book.fill") { open(.homework) }
                        menuItem("Behavior", icon: "star.fill") { open(.behavior) }
                        menuItem("Activities & Links", icon: "link") { open(.activities) }
                        menuItem("Gym Games", icon: "figure.run") { open(.gymGames) }
                        menuItem("Talker Board", icon: "bubble.left.and.text.bubble.right.fill") { open(.talkerBoard) }

                        Divider()
                            .padding(.vertical, 12)

                        sectionLabel("MANAGEMENT")

                        menuItem("Students", icon: "person.3.fill") { open(.students) }
                        menuItem("Student Write-Ups", icon: "doc.text.fill") { open(.studentWriteUps) }
                        if role == "sub" {
                            menuItem("Sub Notes", icon: "note.text") { open(.subNotes) }
                        }
                        menuItem("Sub Requests", icon: "calendar.badge.clock") { open(.subRequests) }
                        if role == "teacher" {
                            menuItem("My Availability", icon: "calendar.badge.checkmark") { open(.availability) }
                        }
                        menuItem("Documents", icon: "doc.fill") { open(.documents) }
                        menuItem("Bell Schedule", icon: "bell.fill") { open(.bellSchedule) }
                        menuItem("Video Meetings", icon: "video.fill") { open(.videoMeetings) }

                        if role == "school" {
                            Divider()
                                .padding(.vertical, 12)
                            sectionLabel("SCHOOL ADMIN")
                            menuItem("Plans & Billing", icon: "creditcard.fill", badgeColor: .green) { open(.plansBilling) }
                            menuItem("Default Password Report", icon: "exclamationmark.shield.fill", badgeColor: .orange) { open(.defaultPasswordReport) }
                            menuItem("Active Time", icon: "timer", badgeColor: .teal) { open(.activeTime) }
                            menuItem("Analytics", icon: "chart.bar.fill") { open(.analytics) }
                            menuItem("Attendance Stats", icon: "chart.pie.fill") { open(.attendanceAnalytics) }
                            menuItem("Bus Routes", icon: "bus.fill") { open(.busTracking) }
                            menuItem("Lunch Menu", icon: "fork.knife") { open(.lunchMenu) }
                            menuItem("Add Book by Photo", icon: "camera.fill") { open(.addBookByPhoto) }
                            menuItem("Emergency Alerts", icon: "exclamationmark.triangle.fill", badgeColor: .red) { open(.emergencyAlerts) }
                            menuItem("Sub Ranking", icon: "list.number") { open(.subRanking) }
                        }
                        if role == "district" {
                            Divider()
                                .padding(.vertical, 12)
                            sectionLabel("DISTRICT ADMIN")
                            menuItem("Default Password Report", icon: "exclamationmark.shield.fill", badgeColor: .orange) { open(.defaultPasswordReport) }
                            menuItem("Analytics", icon: "chart.bar.fill") { open(.analytics) }
                            menuItem("Attendance Stats", icon: "chart.pie.fill") { open(.attendanceAnalytics) }
                            menuItem("Sub Ranking", icon: "list.number") { open(.subRanking) }
                        }
                    }

                    // Communication
                    Divider()
                        .padding(.vertical, 12)

                    sectionLabel("COMMUNICATION")

                    menuItem("Messages", icon: "bubble.left.and.bubble.right.fill") { open(.messaging) }

                    if role == "teacher" || role == "sub" || role == "parent" || role == "district" {
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
                    sectionLabel("ACCOUNT")
                    menuItem("My Account", icon: "person.circle.fill") { open(.account) }
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
        case "librarian": return "books.vertical.fill"
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

            schoolName = data["schoolName"] as? String ?? ""
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
        }
    }
}
