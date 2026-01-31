//
//  ContentView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

extension Notification.Name {
    static let schoolDataDidChange = Notification.Name("schoolDataDidChange")
}

struct ContentView: View {

    @State private var events: [SchoolEvent] = []
    @State private var announcements: [Announcement] = []
    @State private var role: String = ""
    @State private var schoolId: String?

    // School customization
    @State private var schoolName: String = ""
    @State private var schoolLogoUrl: String = ""
    @State private var welcomeMessage: String = ""

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()

            if schoolId == nil {
                noSchoolView
            } else {
                GeometryReader { geo in
                    let isWide = geo.size.width > 600

                    if isWide {
                        // iPad / landscape: side-by-side layout
                        HStack(spacing: 0) {
                            mainContent
                                .frame(maxWidth: .infinity)
                            announcementsSidebar
                                .frame(width: 320)
                        }
                    } else {
                        // iPhone / portrait: stacked layout
                        ScrollView {
                            VStack(spacing: 20) {
                                headerSection
                                welcomeSection
                                announcementsVertical
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 200)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if schoolId != nil {
                CalendarBottomSheetView(events: events, viewerRole: role)
            }
        }
        .onAppear(perform: loadData)
        .onReceive(NotificationCenter.default.publisher(for: .schoolDataDidChange)) { _ in
            loadData()
        }
    }

    // MARK: - No School View
    private var noSchoolView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Join a school to get started")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Use 'Switch Schools' from the menu to join with a school code.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Main Content (for wide layout)
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                welcomeSection
            }
            .padding()
            .padding(.bottom, 200)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // School logo
            schoolLogoView
                .frame(width: 100, height: 100)

            // School name
            Text(schoolName.isEmpty ? "Your School" : schoolName)
                .font(.title.bold())
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - School Logo View
    private var schoolLogoView: some View {
        Group {
            if let url = URL(string: schoolLogoUrl), !schoolLogoUrl.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        defaultLogoPlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        defaultLogoPlaceholder
                    }
                }
            } else {
                defaultLogoPlaceholder
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(EZTeachColors.navy.opacity(0.3), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private var defaultLogoPlaceholder: some View {
        ZStack {
            Circle()
                .fill(EZTeachColors.cardFill)
            Image(systemName: "building.columns.fill")
                .font(.system(size: 36))
                .foregroundColor(EZTeachColors.navy)
        }
    }

    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Text(welcomeMessage.isEmpty ? "Welcome!" : welcomeMessage)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text(currentDateString())
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Announcements Sidebar (iPad)
    private var announcementsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "megaphone.fill")
                    .foregroundColor(EZTeachColors.navy)
                Text("Announcements")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(.tertiarySystemBackground))

            Divider()

            // Scrollable list
            ScrollView {
                LazyVStack(spacing: 12) {
                    if announcements.isEmpty {
                        emptyAnnouncementsView
                    } else {
                        ForEach(announcements) { ann in
                            announcementCard(ann)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Announcements Vertical (iPhone)
    private var announcementsVertical: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "megaphone.fill")
                    .foregroundColor(EZTeachColors.navy)
                Text("Announcements")
                    .font(.headline)
                Spacer()
            }

            if announcements.isEmpty {
                emptyAnnouncementsView
            } else {
                ForEach(announcements.prefix(5)) { ann in
                    announcementCard(ann)
                }

                if announcements.count > 5 {
                    Text("\(announcements.count - 5) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
        }
    }

    // MARK: - Announcement Card
    private func announcementCard(_ ann: Announcement) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                // Icon
                Circle()
                    .fill(EZTeachColors.navy.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundColor(EZTeachColors.navy)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(ann.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)

                    Text(ann.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                if role == "school" {
                    Button {
                        takeDownAnnouncement(ann)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var emptyAnnouncementsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No announcements")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Helpers
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - LOAD DATA
    private func loadData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else { return }

            role = data["role"] as? String ?? ""
            schoolId = data["activeSchoolId"] as? String

            if let sid = schoolId {
                loadSchoolData(sid)
                loadEvents(sid, role: role)
                loadAnnouncements(sid)
            } else {
                events = []
                announcements = []
            }
        }
    }

    private func loadSchoolData(_ schoolId: String) {
        db.collection("schools").document(schoolId).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            schoolName = data["name"] as? String ?? ""
            schoolLogoUrl = data["logoUrl"] as? String ?? ""
            welcomeMessage = data["welcomeMessage"] as? String ?? ""
        }
    }

    private func loadEvents(_ schoolId: String, role: String) {
        db.collection("events")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                let docs = snap?.documents ?? []
                let startOfToday = Calendar.current.startOfDay(for: Date())
                var list = docs.map { SchoolEvent.fromDoc($0, schoolId: schoolId) }
                    .filter { $0.date >= startOfToday }
                    .sorted { $0.date < $1.date }
                if role != "school" && role != "teacher" {
                    list = list.filter { !$0.teachersOnly }
                }
                events = list
            }
    }

    private func loadAnnouncements(_ schoolId: String) {
        db.collection("announcements")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                let docs = snap?.documents ?? []
                let activeDocs = docs.filter { ($0.data()["isActive"] as? Bool ?? true) }
                let sortedDocs = activeDocs.sorted { d1, d2 in
                    let t1 = (d1.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let t2 = (d2.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return t1 > t2
                }
                announcements = sortedDocs.map { doc in
                    Announcement(
                        id: doc.documentID,
                        schoolId: schoolId,
                        title: doc["title"] as? String ?? "",
                        body: doc["body"] as? String ?? "",
                        isActive: true
                    )
                }
            }
    }

    private func takeDownAnnouncement(_ ann: Announcement) {
        db.collection("announcements").document(ann.id).updateData(["isActive": false]) { _ in
            guard let sid = schoolId else { return }
            loadAnnouncements(sid)
        }
    }
}
