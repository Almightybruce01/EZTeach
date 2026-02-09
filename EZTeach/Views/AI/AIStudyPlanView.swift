//
//  AIStudyPlanView.swift
//  EZTeach
//
//  AI Study Plan generator for parents to create personalized study plans
//  Plans appear in student's study section
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Study Plan Model
struct AIStudyPlan: Identifiable, Codable {
    let id: String
    let creatorId: String
    let studentId: String
    let studentName: String
    let schoolId: String
    var title: String
    var subject: String
    var goal: String
    var startDate: Date
    var endDate: Date
    var weeklyHours: Int
    var sessions: [StudySession]
    var milestones: [Milestone]
    var resources: [StudyResource]
    var isActive: Bool
    var progress: Int  // 0-100
    var createdAt: Date
    var updatedAt: Date
    
    struct StudySession: Identifiable, Codable {
        let id: String
        var dayOfWeek: String
        var startTime: String
        var duration: Int  // minutes
        var focus: String
        var isCompleted: Bool
    }
    
    struct Milestone: Identifiable, Codable {
        let id: String
        var title: String
        var targetDate: Date
        var isCompleted: Bool
    }
    
    struct StudyResource: Identifiable, Codable {
        let id: String
        var title: String
        var type: String  // video, book, game, worksheet
        var url: String?
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> AIStudyPlan? {
        guard let data = doc.data() else { return nil }
        
        let sessionsData = data["sessions"] as? [[String: Any]] ?? []
        let sessions = sessionsData.map { s -> StudySession in
            StudySession(
                id: s["id"] as? String ?? UUID().uuidString,
                dayOfWeek: s["dayOfWeek"] as? String ?? "",
                startTime: s["startTime"] as? String ?? "",
                duration: s["duration"] as? Int ?? 30,
                focus: s["focus"] as? String ?? "",
                isCompleted: s["isCompleted"] as? Bool ?? false
            )
        }
        
        let milestonesData = data["milestones"] as? [[String: Any]] ?? []
        let milestones = milestonesData.map { m -> Milestone in
            Milestone(
                id: m["id"] as? String ?? UUID().uuidString,
                title: m["title"] as? String ?? "",
                targetDate: (m["targetDate"] as? Timestamp)?.dateValue() ?? Date(),
                isCompleted: m["isCompleted"] as? Bool ?? false
            )
        }
        
        let resourcesData = data["resources"] as? [[String: Any]] ?? []
        let resources = resourcesData.map { r -> StudyResource in
            StudyResource(
                id: r["id"] as? String ?? UUID().uuidString,
                title: r["title"] as? String ?? "",
                type: r["type"] as? String ?? "",
                url: r["url"] as? String
            )
        }
        
        return AIStudyPlan(
            id: doc.documentID,
            creatorId: data["creatorId"] as? String ?? "",
            studentId: data["studentId"] as? String ?? "",
            studentName: data["studentName"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            subject: data["subject"] as? String ?? "",
            goal: data["goal"] as? String ?? "",
            startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
            endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
            weeklyHours: data["weeklyHours"] as? Int ?? 5,
            sessions: sessions,
            milestones: milestones,
            resources: resources,
            isActive: data["isActive"] as? Bool ?? true,
            progress: data["progress"] as? Int ?? 0,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Parent Study Plan View
struct AIStudyPlanView: View {
    let schoolId: String
    let studentId: String
    let studentName: String
    
    @Environment(\.dismiss) var dismiss
    @State private var studyPlans: [AIStudyPlan] = []
    @State private var isLoading = true
    @State private var showingGenerator = false
    @State private var selectedPlan: AIStudyPlan?
    
    private let db = Firestore.firestore()
    
    var activePlans: [AIStudyPlan] {
        studyPlans.filter { $0.isActive }
    }
    
    var completedPlans: [AIStudyPlan] {
        studyPlans.filter { !$0.isActive }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Feature Highlight
                    aiHighlight
                    
                    // Active Plans
                    if !activePlans.isEmpty {
                        activePlansSection
                    }
                    
                    // Completed Plans
                    if !completedPlans.isEmpty {
                        completedPlansSection
                    }
                    
                    if studyPlans.isEmpty && !isLoading {
                        emptyState
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.green.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Study Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGenerator = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Create")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.gradient)
                        .cornerRadius(20)
                    }
                }
            }
            .sheet(isPresented: $showingGenerator) {
                StudyPlanGeneratorView(
                    schoolId: schoolId,
                    studentId: studentId,
                    studentName: studentName
                ) { newPlan in
                    studyPlans.insert(newPlan, at: 0)
                }
            }
            .sheet(item: $selectedPlan) { plan in
                StudyPlanDetailView(plan: plan)
            }
            .onAppear { loadStudyPlans() }
        }
    }
    
    // MARK: - AI Highlight
    private var aiHighlight: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("AI Study Planner")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
                Text("Create personalized study schedules for \(studentName)")
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Active Plans
    private var activePlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Study Plans")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(activePlans) { plan in
                StudyPlanCard(plan: plan) {
                    selectedPlan = plan
                }
            }
        }
    }
    
    // MARK: - Completed Plans
    private var completedPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Plans")
                .font(.headline)
                .foregroundColor(EZTeachColors.textSecondary)
            
            ForEach(completedPlans) { plan in
                StudyPlanCard(plan: plan, isCompleted: true) {
                    selectedPlan = plan
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Study Plans Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create a personalized AI study plan for \(studentName)")
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingGenerator = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Create Study Plan")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.green.gradient)
                .cornerRadius(25)
            }
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Load Data
    private func loadStudyPlans() {
        isLoading = true
        
        db.collection("studyPlans")
            .whereField("studentId", isEqualTo: studentId)
            .order(by: "createdAt", descending: true)
            .getDocuments(source: .default) { snap, _ in
                studyPlans = snap?.documents.compactMap { AIStudyPlan.fromDocument($0) } ?? []
                isLoading = false
            }
    }
}

// MARK: - Study Plan Card
struct StudyPlanCard: View {
    let plan: AIStudyPlan
    var isCompleted: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(plan.subject)
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(plan.progress) / 100)
                            .stroke(
                                isCompleted ? Color.green : Color.blue,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(plan.progress)%")
                            .font(.caption2.bold())
                            .foregroundColor(.primary)
                    }
                }
                
                // Goal
                Text(plan.goal)
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textSecondary)
                    .lineLimit(2)
                
                // Stats
                HStack(spacing: 16) {
                    Label("\(plan.weeklyHours)h/week", systemImage: "clock.fill")
                    Label("\(plan.sessions.count) sessions", systemImage: "calendar")
                    Label("\(plan.milestones.filter { $0.isCompleted }.count)/\(plan.milestones.count) milestones", systemImage: "flag.fill")
                }
                .font(.caption2)
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5)
            .opacity(isCompleted ? 0.7 : 1)
        }
    }
}

// MARK: - Study Plan Generator
struct StudyPlanGeneratorView: View {
    let schoolId: String
    let studentId: String
    let studentName: String
    let onSave: (AIStudyPlan) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var subject = "Math"
    @State private var goal = ""
    @State private var weeks = 4
    @State private var hoursPerWeek = 5
    @State private var focusAreas: [String] = []
    @State private var newFocusArea = ""
    @State private var preferredDays: Set<String> = []
    @State private var preferredTime = "Afternoon"
    @State private var isGenerating = false
    @State private var generatedPlan: AIStudyPlan?
    @State private var step = 1
    
    private let db = Firestore.firestore()
    
    let subjects = ["Math", "Reading", "Science", "Social Studies", "Writing", "Foreign Language", "Test Prep", "Other"]
    let times = ["Morning", "Afternoon", "Evening", "Flexible"]
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        NavigationStack {
            VStack {
                if step == 1 {
                    inputForm
                } else if step == 2 {
                    generatingView
                } else {
                    resultView
                }
            }
            .navigationTitle("Create Study Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Input Form
    private var inputForm: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Study Plan for \(studentName)")
                            .font(.headline)
                        Text("Tell us the learning goal and AI will create a plan")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .listRowBackground(Color.green.opacity(0.1))
            }
            
            Section("Subject & Goal") {
                Picker("Subject", selection: $subject) {
                    ForEach(subjects, id: \.self) { Text($0).tag($0) }
                }
                
                TextField("Goal (e.g., 'Master multiplication tables')", text: $goal, axis: .vertical)
                    .lineLimit(2...4)
            }
            
            Section("Focus Areas") {
                ForEach(focusAreas, id: \.self) { area in
                    HStack {
                        Text(area)
                        Spacer()
                        Button {
                            focusAreas.removeAll { $0 == area }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("Add focus area", text: $newFocusArea)
                    Button {
                        if !newFocusArea.isEmpty {
                            focusAreas.append(newFocusArea)
                            newFocusArea = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            
            Section("Schedule") {
                Stepper("Duration: \(weeks) weeks", value: $weeks, in: 1...12)
                Stepper("Hours per week: \(hoursPerWeek)", value: $hoursPerWeek, in: 1...20)
                
                Picker("Preferred Time", selection: $preferredTime) {
                    ForEach(times, id: \.self) { Text($0).tag($0) }
                }
            }
            
            Section("Available Days") {
                ForEach(days, id: \.self) { day in
                    Button {
                        if preferredDays.contains(day) {
                            preferredDays.remove(day)
                        } else {
                            preferredDays.insert(day)
                        }
                    } label: {
                        HStack {
                            Text(day)
                                .foregroundColor(.primary)
                            Spacer()
                            if preferredDays.contains(day) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            
            Section {
                Button {
                    generatePlan()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                        Text("Generate Study Plan")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(goal.isEmpty || preferredDays.isEmpty)
                .foregroundColor(.white)
                .listRowBackground(
                    (goal.isEmpty || preferredDays.isEmpty) 
                        ? AnyView(Color.gray) 
                        : AnyView(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing))
                )
            }
        }
    }
    
    // MARK: - Generating View
    private var generatingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.green.gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("Creating Study Plan")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("AI is designing the perfect study schedule for \(studentName)...")
                    .font(.subheadline)
                    .foregroundColor(EZTeachColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Result View
    private var resultView: some View {
        ScrollView {
            if let plan = generatedPlan {
                VStack(spacing: 20) {
                    // Success
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Study Plan Ready!")
                            .font(.title2.bold())
                    }
                    .padding()
                    
                    // Preview
                    StudyPlanPreviewCard(plan: plan)
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            step = 1
                            generatedPlan = nil
                        } label: {
                            Text("Regenerate")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            savePlan(plan)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Save Plan")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.gradient)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Generate
    private func generatePlan() {
        step = 2
        isGenerating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            generatedPlan = createPlan()
            isGenerating = false
            step = 3
        }
    }
    
    private func createPlan() -> AIStudyPlan {
        let engine = StudyPlanEngine(
            subject: subject, goal: goal, studentName: studentName,
            focusAreas: focusAreas, weeks: weeks, hoursPerWeek: hoursPerWeek,
            preferredDays: Array(preferredDays), preferredTime: preferredTime,
            studentId: studentId, schoolId: schoolId
        )
        return engine.generate(creatorId: Auth.auth().currentUser?.uid ?? "")
    }
    
    private func savePlan(_ plan: AIStudyPlan) {
        let planData: [String: Any] = [
            "creatorId": plan.creatorId,
            "studentId": plan.studentId,
            "studentName": plan.studentName,
            "schoolId": plan.schoolId,
            "title": plan.title,
            "subject": plan.subject,
            "goal": plan.goal,
            "startDate": Timestamp(date: plan.startDate),
            "endDate": Timestamp(date: plan.endDate),
            "weeklyHours": plan.weeklyHours,
            "sessions": plan.sessions.map { s -> [String: Any] in
                ["id": s.id, "dayOfWeek": s.dayOfWeek, "startTime": s.startTime, "duration": s.duration, "focus": s.focus, "isCompleted": s.isCompleted]
            },
            "milestones": plan.milestones.map { m -> [String: Any] in
                ["id": m.id, "title": m.title, "targetDate": Timestamp(date: m.targetDate), "isCompleted": m.isCompleted]
            },
            "resources": plan.resources.map { r -> [String: Any] in
                ["id": r.id, "title": r.title, "type": r.type, "url": r.url ?? ""]
            },
            "isActive": plan.isActive,
            "progress": plan.progress,
            "createdAt": Timestamp(date: plan.createdAt),
            "updatedAt": Timestamp(date: plan.updatedAt)
        ]
        
        db.collection("studyPlans").document(plan.id).setData(planData) { _ in
            onSave(plan)
            dismiss()
        }
    }
}

// MARK: - Study Plan Preview Card
struct StudyPlanPreviewCard: View {
    let plan: AIStudyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(plan.title)
                .font(.headline)
            
            Text(plan.goal)
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textSecondary)
            
            Divider()
            
            // Schedule summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Schedule")
                    .font(.subheadline.weight(.semibold))
                
                ForEach(plan.sessions) { session in
                    HStack {
                        Text(session.dayOfWeek)
                            .font(.caption)
                        Spacer()
                        Text(session.startTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(session.duration) min")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Milestones
            VStack(alignment: .leading, spacing: 8) {
                Text("Milestones")
                    .font(.subheadline.weight(.semibold))
                
                ForEach(plan.milestones.prefix(3)) { milestone in
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(milestone.title)
                            .font(.caption)
                        Spacer()
                        Text(milestone.targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
    }
}

// MARK: - Study Plan Detail View
struct StudyPlanDetailView: View {
    let plan: AIStudyPlan
    @Environment(\.dismiss) var dismiss
    @State private var copiedSection: String?
    
    private var fullPlanText: String {
        var t = "STUDY PLAN: \(plan.title)\n"
        t += "Student: \(plan.studentName) | Subject: \(plan.subject)\n"
        t += "Duration: \(plan.startDate.formatted(date: .abbreviated, time: .omitted)) — \(plan.endDate.formatted(date: .abbreviated, time: .omitted))\n"
        t += "\nGOAL: \(plan.goal)\n"
        t += "\n--- WEEKLY SCHEDULE ---\n"
        for s in plan.sessions { t += "• \(s.dayOfWeek) at \(s.startTime) — \(s.duration) min — Focus: \(s.focus)\n" }
        t += "\n--- MILESTONES ---\n"
        for m in plan.milestones { t += "• \(m.title) (target: \(m.targetDate.formatted(date: .abbreviated, time: .omitted)))\n" }
        t += "\n--- RESOURCES ---\n"
        for r in plan.resources { t += "• [\(r.type)] \(r.title)\n" }
        t += "\n--- EZTEACH FEATURES TO USE ---\n"
        t += featureSuggestions.map { "• \($0.feature): \($0.tip)" }.joined(separator: "\n")
        t += "\n\nGenerated by EZTeach AI"
        return t
    }
    
    private var featureSuggestions: [(icon: String, feature: String, tip: String)] {
        var suggestions: [(String, String, String)] = []
        switch plan.subject.lowercased() {
        case "math":
            suggestions.append(("gamecontroller.fill", "Math Games", "Play EZTeach Math Games daily to reinforce \(plan.goal). The leaderboard tracks progress over time."))
            suggestions.append(("chart.bar.fill", "Grades Section", "Check \(plan.studentName)'s Math grades in the Gradebook to see which areas need more focus."))
        case "reading":
            suggestions.append(("book.fill", "Picture Books Library", "Read 2-3 books per week from the 100+ Picture Books to build fluency and comprehension."))
            suggestions.append(("person.2.fill", "Reading Together", "Join or create Reading Together sessions with classmates for shared reading practice."))
            suggestions.append(("speaker.wave.2.fill", "Read Aloud", "Use the Read Aloud feature to hear proper pronunciation and improve listening skills."))
        case "science":
            suggestions.append(("atom", "Science Games", "Explore the Science section in EZTeach Games for hands-on virtual experiments."))
        case "writing":
            suggestions.append(("doc.text.fill", "Homework Submission", "Submit writing assignments as photos through the Homework feature for teacher review."))
        default: break
        }
        suggestions.append(("books.vertical.fill", "Free Books Library", "Browse the Free Books section for thousands of classic texts related to \(plan.subject)."))
        suggestions.append(("trophy.fill", "Leaderboards", "Check the Leaderboards to see how \(plan.studentName) ranks in \(plan.subject)-related games."))
        suggestions.append(("chart.line.uptrend.xyaxis", "Improvement Tracking", "EZTeach tracks improvement automatically and sends notifications when milestones are hit."))
        suggestions.append(("paintpalette.fill", "Electives Hub", "Take study breaks with the Electives Hub — Art, Music, and Dance activities refresh the mind."))
        return suggestions
    }
    
    private func iconFor(_ type: String) -> String {
        switch type {
        case "game": return "gamecontroller.fill"
        case "video": return "play.rectangle.fill"
        case "worksheet": return "doc.text.fill"
        case "book": return "book.fill"
        case "ezteach": return "star.fill"
        default: return "link"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with copy all
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(plan.title)
                                .font(.title2.bold())
                                .textSelection(.enabled)
                            Spacer()
                            Image(systemName: "sparkles")
                                .foregroundColor(.green)
                        }
                        
                        Text("For \(plan.studentName)")
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textSecondary)
                        
                        // Progress
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Progress")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(plan.progress)%")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2))
                                    RoundedRectangle(cornerRadius: 4).fill(Color.green.gradient)
                                        .frame(width: geo.size.width * CGFloat(plan.progress) / 100)
                                }
                            }
                            .frame(height: 8)
                        }
                        
                        Button {
                            UIPasteboard.general.string = fullPlanText
                            withAnimation { copiedSection = "all" }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { copiedSection = nil } }
                        } label: {
                            Label(copiedSection == "all" ? "Copied!" : "Copy Entire Plan", systemImage: copiedSection == "all" ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(copiedSection == "all" ? .green : .blue)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background((copiedSection == "all" ? Color.green : Color.blue).opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Goal
                    studyCopyableSection(title: "Goal", icon: "target", text: plan.goal)
                    
                    // Schedule
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar").foregroundColor(.green)
                            Text("Weekly Schedule").font(.headline)
                            Spacer()
                            copyBtn("schedule", text: plan.sessions.map { "\($0.dayOfWeek) \($0.startTime) — \($0.duration)min — \($0.focus)" }.joined(separator: "\n"))
                        }
                        ForEach(plan.sessions) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.dayOfWeek).font(.subheadline.weight(.medium))
                                    Text(session.focus).font(.caption).foregroundColor(EZTeachColors.textSecondary)
                                        .textSelection(.enabled)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(session.startTime).font(.caption)
                                    Text("\(session.duration) min").font(.caption).foregroundColor(.green)
                                }
                                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(session.isCompleted ? .green : .gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Milestones
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "flag.fill").foregroundColor(.orange)
                            Text("Milestones").font(.headline)
                            Spacer()
                            copyBtn("milestones", text: plan.milestones.map { "• \($0.title) (\($0.targetDate.formatted(date: .abbreviated, time: .omitted)))" }.joined(separator: "\n"))
                        }
                        ForEach(plan.milestones) { milestone in
                            HStack {
                                Image(systemName: milestone.isCompleted ? "flag.checkered" : "flag.fill")
                                    .foregroundColor(milestone.isCompleted ? .green : .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(milestone.title).font(.subheadline).strikethrough(milestone.isCompleted)
                                        .textSelection(.enabled)
                                    Text(milestone.targetDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                if milestone.isCompleted {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(milestone.isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Resources
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.fill").foregroundColor(.blue)
                            Text("Resources & Suggestions").font(.headline)
                            Spacer()
                            copyBtn("resources", text: plan.resources.map { "[\($0.type)] \($0.title)" }.joined(separator: "\n"))
                        }
                        ForEach(plan.resources) { resource in
                            HStack {
                                Image(systemName: iconFor(resource.type)).foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resource.title).font(.subheadline)
                                        .textSelection(.enabled)
                                    Text(resource.type.capitalized).font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // EZTeach Feature Suggestions
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "star.circle.fill").foregroundColor(.orange)
                            Text("EZTeach Features to Use").font(.headline)
                            Spacer()
                            copyBtn("features", text: featureSuggestions.map { "• \($0.feature): \($0.tip)" }.joined(separator: "\n"))
                        }
                        
                        ForEach(Array(featureSuggestions.enumerated()), id: \.offset) { _, s in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: s.icon)
                                    .font(.body)
                                    .foregroundColor(.green)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(s.feature)
                                        .font(.subheadline.weight(.semibold))
                                    Text(s.tip)
                                        .font(.caption)
                                        .foregroundColor(EZTeachColors.textSecondary)
                                        .textSelection(.enabled)
                                }
                            }
                            .padding(10)
                            .background(Color.orange.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                }
                .padding()
            }
            .background(EZTeachColors.backgroundColor)
            .navigationTitle("Study Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = fullPlanText
                            withAnimation { copiedSection = "all" }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { copiedSection = nil } }
                        } label: {
                            Label("Copy All to Clipboard", systemImage: "doc.on.doc")
                        }
                        ShareLink(item: fullPlanText) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func studyCopyableSection(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(.green)
                Text(title).font(.headline)
                Spacer()
                copyBtn(title, text: text)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textSecondary)
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func copyBtn(_ key: String, text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            withAnimation { copiedSection = key }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copiedSection = nil } }
        } label: {
            Image(systemName: copiedSection == key ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.caption)
                .foregroundColor(copiedSection == key ? .green : .gray)
        }
    }
}

// MARK: - Study Plan Generation Engine
struct StudyPlanEngine {
    let subject: String
    let goal: String
    let studentName: String
    let focusAreas: [String]
    let weeks: Int
    let hoursPerWeek: Int
    let preferredDays: [String]
    let preferredTime: String
    let studentId: String
    let schoolId: String
    
    func generate(creatorId: String) -> AIStudyPlan {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: startDate) ?? Date()
        
        return AIStudyPlan(
            id: UUID().uuidString,
            creatorId: creatorId,
            studentId: studentId,
            studentName: studentName,
            schoolId: schoolId,
            title: buildTitle(),
            subject: subject,
            goal: goal,
            startDate: startDate,
            endDate: endDate,
            weeklyHours: hoursPerWeek,
            sessions: buildSessions(),
            milestones: buildMilestones(start: startDate),
            resources: buildResources(),
            isActive: true,
            progress: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func buildTitle() -> String {
        let verbs = ["Mastering", "Conquering", "Excelling at", "Building Skills in", "Accelerating"]
        let verb = verbs[abs(goal.hashValue) % verbs.count]
        return "\(verb) \(subject) — \(weeks)-Week Plan"
    }
    
    private func buildSessions() -> [AIStudyPlan.StudySession] {
        let totalMinutes = hoursPerWeek * 60
        let days = preferredDays.isEmpty ? ["Monday", "Wednesday", "Friday"] : preferredDays
        let perSession = totalMinutes / max(days.count, 1)
        
        let timeStr: String
        switch preferredTime {
        case "Morning": timeStr = "8:30 AM"
        case "Afternoon": timeStr = "3:30 PM"
        case "Evening": timeStr = "6:00 PM"
        default: timeStr = "3:30 PM"
        }
        
        // Rotate focus areas across sessions
        let focuses = buildSessionFocuses()
        
        return days.enumerated().map { idx, day in
            AIStudyPlan.StudySession(
                id: UUID().uuidString,
                dayOfWeek: day,
                startTime: timeStr,
                duration: perSession,
                focus: focuses[idx % focuses.count],
                isCompleted: false
            )
        }
    }
    
    private func buildSessionFocuses() -> [String] {
        if !focusAreas.isEmpty { return focusAreas }
        switch subject.lowercased() {
        case "math":
            return ["Number Sense & Operations", "Problem Solving Practice", "Word Problems & Application", "Review & Speed Drills", "Concept Extension"]
        case "reading":
            return ["Guided Reading (fluency)", "Vocabulary Building", "Comprehension Strategies", "Independent Silent Reading", "Discussion & Response Writing"]
        case "science":
            return ["Key Concepts Review", "Hands-On Experiments", "Data & Observation", "Scientific Vocabulary", "Real-World Connections"]
        case "writing":
            return ["Brainstorming & Planning", "Drafting Practice", "Grammar & Mechanics", "Revision & Editing", "Publishing & Sharing"]
        case "social studies":
            return ["Reading Primary Sources", "Timeline & Mapping", "Discussion & Debate", "Research & Note-Taking", "Project Work"]
        case "foreign language":
            return ["Vocabulary Drills", "Grammar Practice", "Listening Comprehension", "Speaking Practice", "Reading in Target Language"]
        case "test prep":
            return ["Practice Questions", "Timed Drills", "Weak Area Review", "Strategy & Test-Taking Tips", "Full Practice Test"]
        default:
            return ["Core Concept Review", "Practice & Application", "Extension Activities", "Review & Self-Assessment"]
        }
    }
    
    private func buildMilestones(start: Date) -> [AIStudyPlan.Milestone] {
        var milestones: [AIStudyPlan.Milestone] = []
        let cal = Calendar.current
        
        let titles: [String]
        switch subject.lowercased() {
        case "math":
            titles = [
                "Master foundational concepts for \(goal)",
                "Complete 50 practice problems with 80%+ accuracy",
                "Apply skills to 10 real-world word problems",
                "Score 85%+ on practice quiz",
                "Teach the concept to someone else (peer tutoring)",
                "Complete timed challenge under target time",
                "Final mastery assessment — 90%+ target"
            ]
        case "reading":
            titles = [
                "Read 3 books at current level independently",
                "Learn 20 new vocabulary words in context",
                "Write 3 reading responses with text evidence",
                "Increase reading speed by 10 words per minute",
                "Complete a book report or presentation",
                "Read aloud fluently for 5 minutes without error",
                "Final comprehension assessment — 90%+ target"
            ]
        default:
            titles = [
                "Build foundational understanding of \(goal)",
                "Complete initial practice exercises with support",
                "Apply concepts independently with 80%+ accuracy",
                "Review and strengthen weak areas",
                "Demonstrate mastery through a project or test",
                "Extend learning to new contexts",
                "Final assessment — demonstrate full competency"
            ]
        }
        
        let count = min(titles.count, weeks)
        let spacing = max(weeks / count, 1)
        
        for i in 0..<count {
            let date = cal.date(byAdding: .weekOfYear, value: (i + 1) * spacing, to: start) ?? start
            milestones.append(AIStudyPlan.Milestone(
                id: UUID().uuidString,
                title: titles[i],
                targetDate: min(date, cal.date(byAdding: .weekOfYear, value: weeks, to: start) ?? date),
                isCompleted: false
            ))
        }
        
        return milestones
    }
    
    private func buildResources() -> [AIStudyPlan.StudyResource] {
        var resources: [AIStudyPlan.StudyResource] = []
        
        // Always include EZTeach in-app resources
        switch subject.lowercased() {
        case "math":
            resources += [
                .init(id: UUID().uuidString, title: "EZTeach Math Games — daily practice", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "EZTeach Leaderboard — track weekly progress", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "Khan Academy — \(goal) video lessons", type: "video", url: "https://www.khanacademy.org"),
                .init(id: UUID().uuidString, title: "IXL Math — adaptive practice problems", type: "worksheet", url: "https://www.ixl.com/math"),
                .init(id: UUID().uuidString, title: "Prodigy Math Game — gamified practice", type: "game", url: "https://www.prodigygame.com"),
                .init(id: UUID().uuidString, title: "Math worksheets — printable practice sheets", type: "worksheet", url: nil)
            ]
        case "reading":
            resources += [
                .init(id: UUID().uuidString, title: "EZTeach Picture Books — 100+ books with illustrations", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "EZTeach Reading Together — shared reading sessions", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "EZTeach Read Aloud — text-to-speech narration", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "EZTeach Free Books — thousands of classic texts", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "ReadWorks — reading comprehension passages", type: "worksheet", url: "https://www.readworks.org"),
                .init(id: UUID().uuidString, title: "Epic! — digital library for kids", type: "book", url: "https://www.getepic.com"),
                .init(id: UUID().uuidString, title: "Storyline Online — read-aloud videos", type: "video", url: "https://storylineonline.net")
            ]
        case "science":
            resources += [
                .init(id: UUID().uuidString, title: "EZTeach Science Games — virtual experiments", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "BrainPOP — animated science lessons", type: "video", url: "https://www.brainpop.com"),
                .init(id: UUID().uuidString, title: "Mystery Science — free science lessons", type: "video", url: "https://mysteryscience.com"),
                .init(id: UUID().uuidString, title: "National Geographic Kids — articles & videos", type: "book", url: "https://kids.nationalgeographic.com")
            ]
        case "writing":
            resources += [
                .init(id: UUID().uuidString, title: "EZTeach Homework Submission — submit writing drafts", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "NoRedInk — grammar practice", type: "worksheet", url: "https://www.noredink.com"),
                .init(id: UUID().uuidString, title: "Writing prompts collection — daily writing starters", type: "worksheet", url: nil)
            ]
        default:
            resources += [
                .init(id: UUID().uuidString, title: "EZTeach Games — subject-specific practice", type: "ezteach", url: nil),
                .init(id: UUID().uuidString, title: "Khan Academy — free video lessons", type: "video", url: "https://www.khanacademy.org"),
                .init(id: UUID().uuidString, title: "Practice worksheets — printable exercises", type: "worksheet", url: nil)
            ]
        }
        
        // Always add these
        resources.append(.init(id: UUID().uuidString, title: "EZTeach Electives Hub — study break activities", type: "ezteach", url: nil))
        resources.append(.init(id: UUID().uuidString, title: "EZTeach Analytics — track improvement over time", type: "ezteach", url: nil))
        
        return resources
    }
}

// MARK: - Student Study Section View (what student sees)
struct StudentStudySectionView: View {
    let studentId: String
    
    @State private var studyPlans: [AIStudyPlan] = []
    @State private var todaySessions: [AIStudyPlan.StudySession] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "book.and.wrench.fill")
                        .font(.system(size: 40))
                        .foregroundColor(EZTeachColors.softBlue)
                    
                    Text("My Study Plan")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                .padding()
                
                // Today's Sessions
                if !todaySessions.isEmpty {
                    todaysSessionsSection
                }
                
                // Active Plans
                ForEach(studyPlans.filter { $0.isActive }) { plan in
                    StudentPlanCard(plan: plan)
                }
                
                if studyPlans.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No study plans yet")
                            .font(.headline)
                            .foregroundColor(EZTeachColors.textSecondary)
                        Text("Ask your parent to create a study plan for you!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
        .background(EZTeachColors.backgroundColor)
        .onAppear { loadPlans() }
    }
    
    private var todaysSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Study Sessions")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(todaySessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.focus)
                            .font(.subheadline.weight(.medium))
                        Text(session.startTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("\(session.duration) min")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    
                    Button {
                        // Mark complete
                    } label: {
                        Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(session.isCompleted ? .green : .gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func loadPlans() {
        isLoading = true
        
        db.collection("studyPlans")
            .whereField("studentId", isEqualTo: studentId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments(source: .default) { snap, _ in
                studyPlans = snap?.documents.compactMap { AIStudyPlan.fromDocument($0) } ?? []
                
                // Get today's sessions
                let today = Calendar.current.component(.weekday, from: Date())
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                let todayName = dayNames[today - 1]
                
                todaySessions = studyPlans.flatMap { $0.sessions.filter { $0.dayOfWeek == todayName } }
                
                isLoading = false
            }
    }
}

struct StudentPlanCard: View {
    let plan: AIStudyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(plan.progress)%")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
            
            Text(plan.goal)
                .font(.caption)
                .foregroundColor(EZTeachColors.textSecondary)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.gradient)
                        .frame(width: geo.size.width * CGFloat(plan.progress) / 100)
                }
            }
            .frame(height: 8)
            
            // Next milestone
            if let nextMilestone = plan.milestones.first(where: { !$0.isCompleted }) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                    Text("Next: \(nextMilestone.title)")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
