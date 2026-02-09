//
//  ClassDetailView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Class Detail View (Homeroom / Roster / Lesson Plan tabs)
struct ClassDetailView: View {
    let schoolClass: SchoolClass
    var userRole: String = ""

    /// Legacy convenience init for callers that use `classModel:`
    init(classModel: SchoolClass) {
        self.schoolClass = classModel
        self.userRole = ""
    }

    init(schoolClass: SchoolClass, userRole: String) {
        self.schoolClass = schoolClass
        self.userRole = userRole
    }

    enum ClassTab: String, CaseIterable {
        case homeroom = "Homeroom"
        case roster = "Roster"
        case lessonPlans = "Lesson Plans"
    }

    @State private var selectedTab: ClassTab = .homeroom
    @State private var students: [Student] = []
    @State private var isLoading = true
    @State private var showEditClass = false
    @State private var resolvedRole = ""

    private let db = Firestore.firestore()

    private var effectiveRole: String {
        !userRole.isEmpty ? userRole : resolvedRole
    }

    private var canEdit: Bool {
        let r = effectiveRole
        return r == "school" || r == "district" || r == "teacher"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            Picker("", selection: $selectedTab) {
                ForEach(ClassTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case .homeroom:
                homeroomTab
            case .roster:
                rosterTab
            case .lessonPlans:
                lessonPlanTab
            }
        }
        .background(EZTeachColors.background)
        .navigationTitle(schoolClass.name.isEmpty ? "Classroom" : schoolClass.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditClass = true
                    } label: {
                        Image(systemName: "pencil.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showEditClass) {
            EditClassView(classModel: schoolClass, editorRole: effectiveRole)
        }
        .onAppear {
            loadRoster()
            if userRole.isEmpty { resolveRole() }
        }
    }

    // MARK: - Resolve role if not provided
    private func resolveRole() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snap, _ in
            resolvedRole = snap?.data()?["role"] as? String ?? ""
        }
    }

    // MARK: - Homeroom Tab
    private var homeroomTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        Image(systemName: schoolClass.subjectType.icon)
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(EZTeachColors.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(schoolClass.name)
                                .font(.title3.bold())
                            Text("\(GradeUtils.label(schoolClass.grade)) • \(schoolClass.subjectType.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    Divider()

                    HStack(spacing: 24) {
                        statItem(value: "\(students.count)", label: "Students")
                        statItem(value: schoolClass.classType.displayName, label: "Type")
                        if let period = schoolClass.period {
                            statItem(value: "P\(period)", label: "Period")
                        }
                    }
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(16)

                if canEdit {
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            quickAction(icon: "person.badge.plus", title: "Add Student", color: .blue)
                            quickAction(icon: "checkmark.circle", title: "Take Attendance", color: .green)
                            quickAction(icon: "doc.text", title: "Assign Homework", color: .orange)
                            quickAction(icon: "megaphone", title: "Announce", color: .purple)
                        }
                    }
                }

                // Legacy links for callers using old ClassDetailView
                NavigationLink("Roster (Full View)") {
                    ClassRosterView(classModel: schoolClass)
                }
                .font(.subheadline)
                .foregroundColor(EZTeachColors.accent)

                NavigationLink("Student Grades") {
                    StudentGradesView(classModel: schoolClass)
                }
                .font(.subheadline)
                .foregroundColor(EZTeachColors.accent)
            }
            .padding()
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(EZTeachColors.accent)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func quickAction(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Roster Tab
    private var rosterTab: some View {
        Group {
            if isLoading {
                VStack { Spacer(); ProgressView(); Spacer() }
            } else if students.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No students in this class")
                        .font(.headline)
                    Text("Add students from the school roster to this classroom.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                List {
                    ForEach(students) { student in
                        NavigationLink {
                            StudentProfileView(student: student)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(EZTeachColors.accent.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(student.firstName.prefix(1).uppercased())
                                            .font(.headline)
                                            .foregroundColor(EZTeachColors.accent)
                                    )

                                VStack(alignment: .leading) {
                                    Text(student.name)
                                        .font(.subheadline.weight(.medium))
                                    Text(GradeUtils.label(student.gradeLevel))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Lesson Plans Tab
    private var lessonPlanTab: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Lesson Plans")
                .font(.headline)
            Text("Create and manage lesson plans for this classroom. Use AI Lesson Plans from the menu for smart, standards-aligned plans.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Data
    private func loadRoster() {
        db.collection("class_rosters")
            .whereField("classId", isEqualTo: schoolClass.id)
            .getDocuments { snap, _ in
                let studentIds = snap?.documents.compactMap { $0["studentId"] as? String } ?? []
                guard !studentIds.isEmpty else {
                    isLoading = false
                    return
                }

                let batches = stride(from: 0, to: studentIds.count, by: 30).map {
                    Array(studentIds[$0..<min($0 + 30, studentIds.count)])
                }

                var all: [Student] = []
                let group = DispatchGroup()

                for batch in batches {
                    group.enter()
                    db.collection("students")
                        .whereField(FieldPath.documentID(), in: batch)
                        .getDocuments { sSnap, _ in
                            all.append(contentsOf: sSnap?.documents.compactMap { Student.fromDocument($0) } ?? [])
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    students = all.sorted { $0.lastName < $1.lastName }
                    isLoading = false
                }
            }
    }
}
