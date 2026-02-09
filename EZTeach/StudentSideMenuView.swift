//
//  StudentSideMenuView.swift
//  EZTeach
//

import SwiftUI
import FirebaseAuth

struct StudentSideMenuView: View {
    @Binding var showMenu: Bool
    @Binding var selectedPage: StudentPortalView.StudentPage
    let student: Student
    let schoolName: String

    @Environment(\.colorScheme) private var colorScheme

    private func go(_ page: StudentPortalView.StudentPage) {
        selectedPage = page
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showMenu = false
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.leading, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func menuItem(_ title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .frame(width: 24)
                    .foregroundColor(isSelected ? EZTeachColors.brightTeal : (colorScheme == .dark ? .white.opacity(0.8) : EZTeachColors.navy.opacity(0.8)))
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? EZTeachColors.brightTeal : (colorScheme == .dark ? .white : EZTeachColors.navy))
                Spacer()
                if isSelected {
                    Circle()
                        .fill(EZTeachColors.tronCyan)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(isSelected ? EZTeachColors.brightTeal.opacity(0.15) : Color.clear)
            .cornerRadius(10)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
                .padding(.vertical, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    sectionLabel("NAVIGATION")
                    menuItem("Home", icon: "house.fill", isSelected: selectedPage == .home) { go(.home) }
                    menuItem("Homework", icon: "book.fill", isSelected: selectedPage == .homework) { go(.homework) }
                    menuItem("Grades", icon: "chart.bar.fill", isSelected: selectedPage == .grades) { go(.grades) }
                    menuItem("Classes", icon: "person.3.fill", isSelected: selectedPage == .classes) { go(.classes) }
                    menuItem("School Info", icon: "building.2.fill", isSelected: selectedPage == .schoolInfo) { go(.schoolInfo) }
                    menuItem("School Library", icon: "books.vertical.fill", isSelected: selectedPage == .schoolLibrary) { go(.schoolLibrary) }
                    menuItem("EZLearning", icon: "gamecontroller.fill", isSelected: selectedPage == .games) { go(.games) }
                    menuItem("Free Books", icon: "books.vertical.fill", isSelected: selectedPage == .freeBooks) { go(.freeBooks) }
                    menuItem("Leaderboard", icon: "trophy.fill", isSelected: selectedPage == .leaderboard) { go(.leaderboard) }
                    Divider()
                        .padding(.vertical, 12)
                    sectionLabel("TOOLS")
                    menuItem("Talker Board", icon: "bubble.left.and.text.bubble.right.fill", isSelected: selectedPage == .talkerBoard) { go(.talkerBoard) }
                    Divider()
                        .padding(.vertical, 12)
                    sectionLabel("ELECTIVES")
                    menuItem("Art", icon: "paintpalette.fill", isSelected: selectedPage == .electives) { go(.electives) }
                    menuItem("Music", icon: "music.note", isSelected: selectedPage == .electives) { go(.electives) }
                    menuItem("Dance", icon: "figure.dance", isSelected: selectedPage == .electives) { go(.electives) }
                    menuItem("Band", icon: "music.mic", isSelected: selectedPage == .electives) { go(.electives) }
                    menuItem("P.E. / Gym", icon: "figure.run", isSelected: selectedPage == .electives) { go(.electives) }
                    Divider()
                        .padding(.vertical, 12)
                    sectionLabel("ACCOUNT")
                    menuItem("My Account", icon: "person.circle.fill", isSelected: selectedPage == .account) { go(.account) }
                }
                .padding(.horizontal, 16)
            }
            Spacer()
            Text("EZTeach v1.0")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            Divider()
            Button {
                try? Auth.auth().signOut()
                withAnimation { showMenu = false }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(EZTeachColors.error)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .frame(width: 280)
        .background(menuBackground)
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            HStack(spacing: 8) {
                Circle()
                    .fill(EZTeachColors.tronCyan.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(student.firstName.prefix(1).uppercased())
                            .font(.caption.bold())
                            .foregroundColor(EZTeachColors.tronCyan)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(student.fullName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(menuTextColor)
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text("Student")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(EZTeachColors.brightTeal.opacity(0.08))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

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
}
