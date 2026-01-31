//
//  TeacherPortalView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TeacherPortalView: View {

    let teacher: Teacher
    let viewerRole: String

    @State private var selectedSection: TeacherSection = .home
    @State private var showEditProfile = false

    // Teacher profile data (editable)
    @State private var bio: String = ""
    @State private var roomNumber: String = ""
    @State private var officeHours: String = ""
    @State private var email: String = ""

    private let db = Firestore.firestore()

    /// Check if current user is the teacher themselves
    private var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == teacher.userId
    }

    enum TeacherSection: String, CaseIterable {
        case home = "Home"
        case homeroom = "Homeroom"
        case roster = "Class Roster"
        case grades = "Grades"
        case subPlans = "Sub Plans"
        case classes = "My Classes"
        case schedule = "Schedule"
    }

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 600

            if isWide {
                // iPad: Side-by-side layout
                HStack(spacing: 0) {
                    sidebarMenu
                        .frame(width: 220)
                    Divider()
                    mainContent
                        .frame(maxWidth: .infinity)
                }
            } else {
                // iPhone: List-based navigation
                List {
                    // Teacher header
                    teacherHeader
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                    // Navigation links
                    Section("Quick Links") {
                        ForEach(TeacherSection.allCases, id: \.self) { section in
                            NavigationLink {
                                destinationView(for: section)
                            } label: {
                                Label(section.rawValue, systemImage: iconForSection(section))
                            }
                        }
                    }

                    // Teacher info section
                    if !bio.isEmpty || !roomNumber.isEmpty || !officeHours.isEmpty {
                        Section("About") {
                            if !roomNumber.isEmpty {
                                LabeledContent("Room", value: roomNumber)
                            }
                            if !officeHours.isEmpty {
                                LabeledContent("Office Hours", value: officeHours)
                            }
                            if !bio.isEmpty {
                                Text(bio)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(teacher.formattedName)
        .toolbar {
            if isOwnProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showEditProfile = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditTeacherProfileView(
                teacherId: teacher.id,
                currentBio: bio,
                currentRoomNumber: roomNumber,
                currentOfficeHours: officeHours,
                currentEmail: email
            ) {
                loadTeacherProfile()
            }
        }
        .onAppear(perform: loadTeacherProfile)
    }

    // MARK: - Sidebar Menu (iPad)
    private var sidebarMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Teacher header in sidebar
            VStack(spacing: 12) {
                Circle()
                    .fill(EZTeachColors.navy.opacity(0.1))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text(teacher.lastName.prefix(1).uppercased() + teacher.firstName.prefix(1).uppercased())
                            .font(.title2.bold())
                            .foregroundColor(EZTeachColors.navy)
                    )

                Text(teacher.formattedName)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if !roomNumber.isEmpty {
                    Text("Room \(roomNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))

            Divider()

            // Menu items
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(TeacherSection.allCases, id: \.self) { section in
                        sidebarButton(for: section)
                    }
                }
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .background(Color(.systemBackground))
    }

    private func sidebarButton(for section: TeacherSection) -> some View {
        Button {
            selectedSection = section
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconForSection(section))
                    .frame(width: 24)
                Text(section.rawValue)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(selectedSection == section ? EZTeachColors.cardFill : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Main Content (iPad)
    private var mainContent: some View {
        destinationView(for: selectedSection)
    }

    // MARK: - Teacher Header (iPhone)
    private var teacherHeader: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(EZTeachColors.navy.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(teacher.lastName.prefix(1).uppercased() + teacher.firstName.prefix(1).uppercased())
                        .font(.title.bold())
                        .foregroundColor(EZTeachColors.navy)
                )

            VStack(spacing: 4) {
                Text(teacher.formattedName)
                    .font(.title2.bold())

                if !teacher.displayName.isEmpty && teacher.displayName != teacher.fullName {
                    Text(teacher.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if !roomNumber.isEmpty {
                    Label("Room \(roomNumber)", systemImage: "door.left.hand.closed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Destination Views
    @ViewBuilder
    private func destinationView(for section: TeacherSection) -> some View {
        switch section {
        case .home:
            TeacherHomeContentView(teacher: teacher, bio: bio, roomNumber: roomNumber, officeHours: officeHours)
        case .homeroom:
            TeacherHomeroomView(teacher: teacher)
        case .roster:
            TeacherRosterView(teacher: teacher)
        case .grades:
            TeacherGradesHubView(teacher: teacher)
        case .subPlans:
            TeacherSubPlansView(teacher: teacher)
        case .classes:
            ClassesHubView(teacherId: teacher.userId)
        case .schedule:
            TeacherScheduleView(teacher: teacher)
        }
    }

    private func iconForSection(_ section: TeacherSection) -> String {
        switch section {
        case .home: return "house.fill"
        case .homeroom: return "person.3.fill"
        case .roster: return "list.bullet.clipboard"
        case .grades: return "chart.bar.doc.horizontal"
        case .subPlans: return "doc.text.fill"
        case .classes: return "books.vertical.fill"
        case .schedule: return "calendar"
        }
    }

    // MARK: - Load Data
    private func loadTeacherProfile() {
        db.collection("teachers").document(teacher.id).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            bio = data["bio"] as? String ?? ""
            roomNumber = data["roomNumber"] as? String ?? ""
            officeHours = data["officeHours"] as? String ?? ""
            email = data["email"] as? String ?? ""
        }
    }
}

// MARK: - Teacher Home Content
struct TeacherHomeContentView: View {
    let teacher: Teacher
    let bio: String
    let roomNumber: String
    let officeHours: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Welcome card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome to \(teacher.formattedName)'s Page")
                        .font(.title2.bold())

                    if !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                // Quick info cards
                if !roomNumber.isEmpty || !officeHours.isEmpty {
                    HStack(spacing: 12) {
                        if !roomNumber.isEmpty {
                            infoCard(icon: "door.left.hand.closed", title: "Room", value: roomNumber)
                        }
                        if !officeHours.isEmpty {
                            infoCard(icon: "clock", title: "Office Hours", value: officeHours)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Home")
    }

    private func infoCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Teacher Homeroom View
struct TeacherHomeroomView: View {
    let teacher: Teacher

    var body: some View {
        List {
            Section {
                Text("Homeroom information and students will appear here.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("\(teacher.lastName)'s Homeroom")
    }
}

// MARK: - Teacher Roster View
struct TeacherRosterView: View {
    let teacher: Teacher
    @State private var students: [Student] = []
    private let db = Firestore.firestore()

    var body: some View {
        List {
            if students.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No students found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(students.sorted { $0.name < $1.name }) { student in
                    NavigationLink {
                        StudentProfileView(student: student)
                    } label: {
                        Text(student.name)
                    }
                }
            }
        }
        .navigationTitle("Student Roster")
        .onAppear(perform: loadStudents)
    }

    private func loadStudents() {
        // Load students from classes taught by this teacher
        db.collection("classes")
            .whereField("teacherIds", arrayContains: teacher.userId)
            .getDocuments { snap, _ in
                let classIds = snap?.documents.map { $0.documentID } ?? []
                guard !classIds.isEmpty else { return }

                db.collection("classEnrollments")
                    .whereField("classId", in: classIds)
                    .getDocuments { enrollSnap, _ in
                        let studentIds = enrollSnap?.documents.compactMap { $0["studentId"] as? String } ?? []
                        guard !studentIds.isEmpty else { return }

                        db.collection("students")
                            .whereField(FieldPath.documentID(), in: Array(Array(Set(studentIds)).prefix(10)))
                            .getDocuments { studentSnap, _ in
                                students = studentSnap?.documents.compactMap { doc in
                                    Student.fromDocument(doc)
                                } ?? []
                            }
                    }
            }
    }
}

// MARK: - Teacher Sub Plans View
struct TeacherSubPlansView: View {
    let teacher: Teacher

    var body: some View {
        List {
            NavigationLink("Default Sub Plan Template") {
                SubPlanDetailView(title: "Default Sub Plan")
            }

            Section {
                Text("Create sub plans so substitutes know what to do when you're absent.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Sub Plans")
    }
}

// MARK: - Teacher Schedule View
struct TeacherScheduleView: View {
    let teacher: Teacher

    var body: some View {
        List {
            Section {
                Text("Schedule information will appear here.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Schedule")
    }
}

// MARK: - Teacher Grades Hub View
struct TeacherGradesHubView: View {
    let teacher: Teacher
    
    @State private var classes: [SchoolClass] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading classes...")
            } else if classes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Classes")
                        .font(.headline)
                    Text("You need to be assigned to classes to enter grades.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    Section("Select a Class") {
                        ForEach(classes) { cls in
                            NavigationLink {
                                StudentGradesView(classModel: cls)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cls.name)
                                        .font(.headline)
                                    Text(GradeUtils.label(cls.grade))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Grades")
        .onAppear(perform: loadClasses)
    }
    
    private func loadClasses() {
        db.collection("classes")
            .whereField("teacherIds", arrayContains: teacher.userId)
            .getDocuments { snap, _ in
                classes = snap?.documents.compactMap { doc -> SchoolClass? in
                    let d = doc.data()
                    let ct = SchoolClass.ClassType(rawValue: d["classType"] as? String ?? "regular") ?? .regular
                    return SchoolClass(
                        id: doc.documentID,
                        name: d["name"] as? String ?? "",
                        grade: d["grade"] as? Int ?? 0,
                        schoolId: d["schoolId"] as? String ?? "",
                        teacherIds: d["teacherIds"] as? [String] ?? [],
                        classType: ct
                    )
                }.sorted { $0.name < $1.name } ?? []
                isLoading = false
            }
    }
}
