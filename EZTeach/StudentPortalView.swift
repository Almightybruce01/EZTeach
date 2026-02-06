//
//  StudentPortalView.swift
//  EZTeach
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct StudentPortalView: View {
    @State private var student: Student?
    @State private var schoolName: String = ""
    @State private var selectedPage: StudentPage = .games
    @State private var showMenu = false
    @State private var loadFailed = false

    enum StudentPage: String, CaseIterable {
        case home, homework, grades, classes, schoolInfo, schoolLibrary, games, freeBooks, leaderboard, electives, account
        var title: String {
            switch self {
            case .home: return "Home"
            case .homework: return "Homework"
            case .grades: return "Grades"
            case .classes: return "Classes"
            case .schoolInfo: return "School Info"
            case .schoolLibrary: return "School Library"
            case .games: return "EZLearning"
            case .freeBooks: return "Free Books"
            case .leaderboard: return "Leaderboard"
            case .electives: return "Electives"
            case .account: return "My Account"
            }
        }
    }

    var body: some View {
        Group {
            if student == nil && !loadFailed {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(EZTeachColors.brightTeal)
            } else if loadFailed {
                VStack(spacing: 24) {
                    ContentUnavailableView(
                        "Unable to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Your student profile could not be loaded. Please sign out and try again.")
                    )
                    .tint(EZTeachColors.brightTeal)
                    Button("Sign Out") {
                        try? Auth.auth().signOut()
                    }
                    .font(.headline)
                    .foregroundColor(EZTeachColors.brightTeal)
                }
            } else if let s = student {
                ZStack(alignment: .leading) {
                    NavigationStack {
                        currentPage(s)
                            .background(EZTeachColors.lightSky)
                            .navigationTitle(selectedPage.title)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showMenu.toggle()
                                        }
                                    } label: {
                                        Image(systemName: "line.3.horizontal")
                                            .font(.title3.weight(.medium))
                                            .foregroundColor(EZTeachColors.brightTeal)
                                    }
                                }
                            }
                    }
                    if showMenu {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showMenu = false
                                }
                            }
                            .transition(.opacity)
                        StudentSideMenuView(
                            showMenu: $showMenu,
                            selectedPage: $selectedPage,
                            student: s,
                            schoolName: schoolName
                        )
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                    }
                }
            }
        }
        .background(EZTeachColors.lightSky)
        .onAppear { loadStudent() }
    }

    @ViewBuilder
    private func currentPage(_ s: Student) -> some View {
        switch selectedPage {
        case .home: StudentHomeTab(student: s, schoolName: schoolName, onSelectGames: { selectedPage = .games })
        case .homework: StudentHomeworkTab(studentId: s.id, schoolId: s.schoolId)
        case .grades: StudentGradesTab(studentId: s.id, schoolId: s.schoolId)
        case .classes: StudentClassesTab(studentId: s.id, schoolId: s.schoolId)
        case .schoolInfo: StudentSchoolInfoTab(schoolId: s.schoolId)
        case .schoolLibrary: SchoolLibraryView(schoolId: s.schoolId, canEdit: false)
        case .games: EZLearningGamesHubView(gradeLevel: s.gradeLevel)
        case .freeBooks: FreeBooksView()
        case .leaderboard: LeaderboardView()
        case .electives: ElectivesHubView()
        case .account: StudentAccountView(student: s, schoolName: schoolName)
        }
    }

    private func loadStudent() {
        guard Auth.auth().currentUser != nil else { return }
        loadFailed = false
        Functions.functions().httpsCallable("getMyStudentProfile").call { result, error in
            DispatchQueue.main.async {
                if error != nil {
                    loadFailed = true
                    return
                }
                guard let data = result?.data as? [String: Any],
                      let s = Student.fromCallableResponse(data) else {
                    loadFailed = true
                    return
                }
                student = s
                schoolName = data["schoolName"] as? String ?? "School"
            }
        }
    }
}

// MARK: - Student Home Tab
struct StudentHomeTab: View {
    let student: Student
    let schoolName: String
    var onSelectGames: (() -> Void)?
    @State private var announcements: [Announcement] = []
    @State private var events: [SchoolEvent] = []
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Text("Welcome, \(student.firstName)!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [EZTeachColors.brightTeal, .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text(schoolName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)

                    if let onSelectGames {
                        Button(action: onSelectGames) {
                            HStack(spacing: 16) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(EZTeachColors.brightTeal)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("EZLearning")
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(.white)
                                    Text("Play math, reading, puzzles & more")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(EZTeachColors.brightTeal)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(EZTeachColors.brightTeal.opacity(0.6), lineWidth: 2)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if !announcements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ANNOUNCEMENTS")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(EZTeachColors.brightTeal)
                            ForEach(announcements.prefix(5)) { a in
                                StudentAnnouncementRow(announcement: a)
                            }
                        }
                    }

                    if !events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("UPCOMING EVENTS")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(EZTeachColors.textMutedLight)
                            ForEach(events.prefix(5)) { e in
                                StudentEventRow(event: e)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            db.collection("announcements")
                .whereField("schoolId", isEqualTo: student.schoolId)
                .order(by: "createdAt", descending: true)
                .limit(to: 10)
                .getDocuments { snap, _ in
                    let docs = snap?.documents ?? []
                    let ann = docs
                        .filter { ($0.data()["teachersOnly"] as? Bool ?? false) == false && ($0.data()["isActive"] as? Bool ?? true) }
                        .map { doc in
                            let d = doc.data()
                            return Announcement(id: doc.documentID, schoolId: student.schoolId, title: d["title"] as? String ?? "", body: d["body"] as? String ?? "", attachmentUrl: d["attachmentUrl"] as? String, isActive: true)
                        }
                    DispatchQueue.main.async { announcements = ann }
                }
            db.collection("events")
                .whereField("schoolId", isEqualTo: student.schoolId)
                .order(by: "date")
                .limit(to: 20)
                .getDocuments { snap, _ in
                    let docs = snap?.documents ?? []
                    let ev = docs
                        .filter { ($0.data()["teachersOnly"] as? Bool ?? false) == false }
                        .map { SchoolEvent.fromDoc($0, schoolId: student.schoolId) }
                    DispatchQueue.main.async { events = ev }
                }
        }
    }
}

private struct StudentAnnouncementRow: View {
    let announcement: Announcement
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(announcement.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(EZTeachColors.textDark)
            Text(announcement.body)
                .font(.caption)
                .foregroundColor(EZTeachColors.textMutedLight)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(EZTeachColors.cardWhite)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(EZTeachColors.brightTeal.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct StudentEventRow: View {
    let event: SchoolEvent
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(EZTeachColors.brightTeal.opacity(0.4), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        )
    }
}

// MARK: - Student Homework Tab
struct StudentHomeworkTab: View {
    let studentId: String
    let schoolId: String
    @State private var assignments: [HomeworkAssignment] = []
    @State private var isLoading = true
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            Group {
                if isLoading {
                    ProgressView("Loading homework...")
                        .tint(EZTeachColors.brightTeal)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if assignments.isEmpty {
                    ContentUnavailableView("No Homework", systemImage: "book.closed", description: Text("You have no homework assignments for your classes."))
                        .tint(EZTeachColors.brightTeal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(assignments) { a in
                                StudentHomeworkRow(assignment: a)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear { loadHomework() }
    }
    
    private func loadHomework() {
        isLoading = true
        db.collection("class_rosters")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments { rosterSnap, _ in
                let classIds = Set(rosterSnap?.documents.compactMap { $0["classId"] as? String } ?? [])
                guard !classIds.isEmpty else {
                    DispatchQueue.main.async {
                        assignments = []
                        isLoading = false
                    }
                    return
                }
                db.collection("homework")
                    .whereField("schoolId", isEqualTo: schoolId)
                    .order(by: "dueDate")
                    .getDocuments { snap, _ in
                        let all = snap?.documents.compactMap { HomeworkAssignment.fromDocument($0) } ?? []
                        DispatchQueue.main.async {
                            assignments = all.filter { classIds.contains($0.classId) }
                            isLoading = false
                        }
                    }
            }
    }
}

private struct StudentHomeworkRow: View {
    let assignment: HomeworkAssignment
    var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: assignment.dueDate).day ?? 0
        return daysUntilDue <= 2 && daysUntilDue >= 0
    }
    var isOverdue: Bool { assignment.dueDate < Date() }
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(isOverdue ? EZTeachColors.tronPink.opacity(0.3) : (isDueSoon ? EZTeachColors.tronOrange.opacity(0.3) : EZTeachColors.brightTeal.opacity(0.2)))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(isOverdue ? EZTeachColors.tronPink : (isDueSoon ? EZTeachColors.tronOrange : EZTeachColors.brightTeal))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(assignment.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                HStack {
                    Text("\(assignment.pointsWorth) pts")
                    Text("•")
                    Text("Due \(assignment.dueDate, style: .date)")
                }
                .font(.caption2)
                .foregroundColor(isOverdue ? EZTeachColors.tronPink : .white.opacity(0.6))
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(EZTeachColors.brightTeal.opacity(0.35), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        )
    }
}

// MARK: - Student Grades Tab
struct StudentGradesTab: View {
    let studentId: String
    let schoolId: String
    @State private var grades: [(name: String, earned: Double, possible: Double)] = []
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            Group {
                if grades.isEmpty {
                    ContentUnavailableView("No Grades", systemImage: "chart.bar", description: Text("Your grades will appear here."))
                        .tint(EZTeachColors.brightTeal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(grades.indices, id: \.self) { idx in
                                if idx < grades.count {
                                    let g = grades[idx]
                                    let pct = g.possible > 0 ? (g.earned / g.possible) * 100 : 0
                                    HStack {
                                    Text(g.name)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(g.earned))/\(Int(g.possible)) (\(Int(pct))%)")
                                        .foregroundColor(EZTeachColors.brightTeal)
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EZTeachColors.brightTeal.opacity(0.35), lineWidth: 1)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                                )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            db.collection("studentGrades")
                .whereField("studentId", isEqualTo: studentId)
                .getDocuments { snap, _ in
                    let items: [(name: String, earned: Double, possible: Double)] = (snap?.documents ?? []).map { doc in
                        let d = doc.data()
                        let name = d["assignmentName"] as? String ?? "Assignment"
                        let earned = d["pointsEarned"] as? Double ?? 0
                        let possible = d["pointsPossible"] as? Double ?? 0
                        return (name: name, earned: earned, possible: possible)
                    }
                    DispatchQueue.main.async {
                        grades = items
                    }
                }
        }
    }
}

// MARK: - Student Classes Tab
struct StudentClassesTab: View {
    let studentId: String
    let schoolId: String
    @State private var classes: [SchoolClass] = []
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            Group {
                if classes.isEmpty {
                    ContentUnavailableView("No Classes", systemImage: "person.3", description: Text("Your classes will appear here."))
                        .tint(EZTeachColors.brightTeal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(classes) { c in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(c.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(GradeUtils.label(c.grade))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EZTeachColors.brightTeal.opacity(0.35), lineWidth: 1)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            db.collection("class_rosters")
                .whereField("studentId", isEqualTo: studentId)
                .getDocuments { rosterSnap, _ in
                    let classIds = rosterSnap?.documents.compactMap { $0["classId"] as? String } ?? []
                    guard !classIds.isEmpty else { return }
                    db.collection("classes")
                        .whereField(FieldPath.documentID(), in: Array(classIds.prefix(10)))
                        .getDocuments { classSnap, _ in
                            let cls = classSnap?.documents.compactMap { doc -> SchoolClass? in
                                let d = doc.data()
                                let ct = SchoolClass.ClassType(rawValue: d["classType"] as? String ?? "regular") ?? .regular
                                return SchoolClass(id: doc.documentID, name: d["name"] as? String ?? "", grade: d["grade"] as? Int ?? 0, schoolId: d["schoolId"] as? String ?? "", teacherIds: d["teacherIds"] as? [String] ?? [], classType: ct)
                            } ?? []
                            DispatchQueue.main.async {
                                classes = cls
                            }
                        }
                }
        }
    }
}

// MARK: - Student School Info Tab
struct StudentSchoolInfoTab: View {
    let schoolId: String
    @State private var school: School?
    @State private var isLoading = true
    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .tint(EZTeachColors.brightTeal)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let s = school {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text(s.name)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [EZTeachColors.brightTeal, .white],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            if let addr = s.address, !addr.isEmpty {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(EZTeachColors.brightTeal)
                                    Text(addr)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EZTeachColors.brightTeal.opacity(0.35), lineWidth: 1)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                                )
                            }
                            if let phone = s.phone, !phone.isEmpty {
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.circle.fill")
                                        .foregroundColor(EZTeachColors.brightTeal)
                                    Text(phone)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(EZTeachColors.brightTeal.opacity(0.35), lineWidth: 1)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "School Info",
                        systemImage: "building.2",
                        description: Text("School information could not be loaded.")
                    )
                    .tint(EZTeachColors.brightTeal)
                }
            }
        }
        .onAppear {
            db.collection("schools").document(schoolId).getDocument { snap, _ in
                DispatchQueue.main.async {
                    isLoading = false
                    guard let d = snap?.data() else { return }
                    school = School(
                        id: schoolId,
                        name: d["name"] as? String ?? "School",
                        address: d["address"] as? String,
                        phone: d["phone"] as? String,
                        logoUrl: d["logoUrl"] as? String
                    )
                }
            }
        }
    }
}

struct School {
    let id: String
    let name: String
    let address: String?
    let phone: String?
    let logoUrl: String?
}
