//
//  AILessonPlanView.swift
//  EZTeach
//
//  AI-powered lesson plan generator for teachers
//  Not available for students or parents
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

// MARK: - Lesson Plan Model
struct AILessonPlan: Identifiable, Codable {
    let id: String
    let creatorId: String
    let schoolId: String
    var title: String
    var subject: String
    var gradeLevel: Int
    var duration: String
    var objectives: [String]
    var materials: [String]
    var warmUp: String
    var mainActivity: [LessonActivity]
    var assessment: String
    var closure: String
    var differentiation: String
    var homework: String
    var standards: [String]
    var notes: String
    var isAIGenerated: Bool
    var createdAt: Date
    var updatedAt: Date
    
    struct LessonActivity: Identifiable, Codable {
        let id: String
        var title: String
        var description: String
        var duration: String
        var type: String
    }
    
    static func fromDocument(_ doc: DocumentSnapshot) -> AILessonPlan? {
        guard let data = doc.data() else { return nil }
        
        let activitiesData = data["mainActivity"] as? [[String: Any]] ?? []
        let activities = activitiesData.map { act -> LessonActivity in
            LessonActivity(
                id: act["id"] as? String ?? UUID().uuidString,
                title: act["title"] as? String ?? "",
                description: act["description"] as? String ?? "",
                duration: act["duration"] as? String ?? "",
                type: act["type"] as? String ?? ""
            )
        }
        
        return AILessonPlan(
            id: doc.documentID,
            creatorId: data["creatorId"] as? String ?? "",
            schoolId: data["schoolId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            subject: data["subject"] as? String ?? "",
            gradeLevel: data["gradeLevel"] as? Int ?? 1,
            duration: data["duration"] as? String ?? "",
            objectives: data["objectives"] as? [String] ?? [],
            materials: data["materials"] as? [String] ?? [],
            warmUp: data["warmUp"] as? String ?? "",
            mainActivity: activities,
            assessment: data["assessment"] as? String ?? "",
            closure: data["closure"] as? String ?? "",
            differentiation: data["differentiation"] as? String ?? "",
            homework: data["homework"] as? String ?? "",
            standards: data["standards"] as? [String] ?? [],
            notes: data["notes"] as? String ?? "",
            isAIGenerated: data["isAIGenerated"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - AI Lesson Plan View
struct AILessonPlanView: View {
    let schoolId: String
    let userRole: String
    
    @Environment(\.dismiss) var dismiss
    @State private var lessonPlans: [AILessonPlan] = []
    @State private var isLoading = true
    @State private var showingGenerator = false
    @State private var showingDetail: AILessonPlan?
    @State private var searchText = ""
    @State private var selectedSubject: String?
    
    private let db = Firestore.firestore()
    
    let subjects = ["Math", "Reading", "Science", "Social Studies", "Writing", "Art", "Music", "PE", "Other"]
    
    var filteredPlans: [AILessonPlan] {
        var plans = lessonPlans
        
        if !searchText.isEmpty {
            plans = plans.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subject.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let subject = selectedSubject {
            plans = plans.filter { $0.subject == subject }
        }
        
        return plans.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Feature Highlight
                    aiFeatureHighlight
                    
                    // Search & Filter
                    searchAndFilter
                    
                    // Lesson Plans List
                    lessonPlansList
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("AI Lesson Plans")
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
                            Text("Generate")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .sheet(isPresented: $showingGenerator) {
                AILessonGeneratorView(schoolId: schoolId) { newPlan in
                    lessonPlans.insert(newPlan, at: 0)
                }
            }
            .sheet(item: $showingDetail) { plan in
                LessonPlanDetailView(plan: plan)
            }
            .onAppear { loadLessonPlans() }
        }
    }
    
    // MARK: - AI Feature Highlight
    private var aiFeatureHighlight: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("AI-Powered")
                        .font(.title3.bold())
                        .foregroundColor(EZTeachColors.textPrimary)
                    
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
                Text("Generate complete lesson plans with AI in seconds")
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Search & Filter
    private var searchAndFilter: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search lesson plans...", text: $searchText)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedSubject = nil
                    } label: {
                        Text("All")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedSubject == nil ? Color.purple : Color.gray.opacity(0.2))
                            .foregroundColor(selectedSubject == nil ? .white : EZTeachColors.textPrimary)
                            .cornerRadius(20)
                    }
                    
                    ForEach(subjects, id: \.self) { subject in
                        Button {
                            selectedSubject = subject
                        } label: {
                            Text(subject)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedSubject == subject ? Color.purple : Color.gray.opacity(0.2))
                                .foregroundColor(selectedSubject == subject ? .white : EZTeachColors.textPrimary)
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Lesson Plans List
    private var lessonPlansList: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if filteredPlans.isEmpty {
                emptyState
            } else {
                ForEach(filteredPlans) { plan in
                    LessonPlanCard(plan: plan) {
                        showingDetail = plan
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Lesson Plans Yet")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            Text("Tap 'Generate' to create your first AI lesson plan")
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingGenerator = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Lesson Plan")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Load Data
    private func loadLessonPlans() {
        isLoading = true
        
        db.collection("lessonPlans")
            .whereField("schoolId", isEqualTo: schoolId)
            .order(by: "updatedAt", descending: true)
            .getDocuments(source: .default) { snap, _ in
                lessonPlans = snap?.documents.compactMap { AILessonPlan.fromDocument($0) } ?? []
                isLoading = false
            }
    }
}

// MARK: - Lesson Plan Card
struct LessonPlanCard: View {
    let plan: AILessonPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(plan.title)
                                .font(.headline)
                                .foregroundColor(EZTeachColors.textPrimary)
                                .lineLimit(1)
                            
                            if plan.isAIGenerated {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Label(plan.subject, systemImage: "book.fill")
                            Label("Grade \(plan.gradeLevel)", systemImage: "graduationcap.fill")
                            Label(plan.duration, systemImage: "clock.fill")
                        }
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                if !plan.objectives.isEmpty {
                    Text("Objectives: \(plan.objectives.prefix(2).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(plan.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(plan.mainActivity.count) activities")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

// MARK: - AI Lesson Generator View
struct AILessonGeneratorView: View {
    let schoolId: String
    let onSave: (AILessonPlan) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var step = 1
    @State private var subject = "Math"
    @State private var gradeLevel = 3
    @State private var topic = ""
    @State private var duration = "45 minutes"
    @State private var learningStyle = "Visual"
    @State private var additionalNotes = ""
    @State private var isGenerating = false
    @State private var generatedPlan: AILessonPlan?
    @State private var error: String?
    
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    let subjects = ["Math", "Reading", "Science", "Social Studies", "Writing", "Art", "Music", "PE", "Other"]
    let durations = ["30 minutes", "45 minutes", "60 minutes", "90 minutes", "Full Day"]
    let styles = ["Visual", "Auditory", "Kinesthetic", "Mixed", "Differentiated"]
    
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
            .navigationTitle("Generate Lesson Plan")
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
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Lesson Generator")
                            .font(.headline)
                        Text("Tell us about your lesson and AI will create a complete plan")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .listRowBackground(Color.purple.opacity(0.1))
            }
            
            Section("Lesson Details") {
                Picker("Subject", selection: $subject) {
                    ForEach(subjects, id: \.self) { Text($0).tag($0) }
                }
                
                Picker("Grade Level", selection: $gradeLevel) {
                    ForEach(1...12, id: \.self) { Text("Grade \($0)").tag($0) }
                }
                
                TextField("Topic (e.g., 'Fractions', 'Photosynthesis')", text: $topic)
                
                Picker("Duration", selection: $duration) {
                    ForEach(durations, id: \.self) { Text($0).tag($0) }
                }
            }
            
            Section("Learning Style Focus") {
                Picker("Primary Style", selection: $learningStyle) {
                    ForEach(styles, id: \.self) { Text($0).tag($0) }
                }
            }
            
            Section("Additional Notes (Optional)") {
                TextEditor(text: $additionalNotes)
                    .frame(height: 100)
            }
            
            Section {
                Button {
                    generateLessonPlan()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                        Text("Generate Lesson Plan")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(topic.isEmpty)
                .foregroundColor(.white)
                .listRowBackground(
                    topic.isEmpty ? AnyView(Color.gray) : AnyView(LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
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
                    .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isGenerating)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 8) {
                Text("Generating Your Lesson Plan")
                    .font(.title2.bold())
                    .foregroundColor(EZTeachColors.textPrimary)
                
                Text("AI is creating objectives, activities, and assessments...")
                    .font(.subheadline)
                    .foregroundColor(EZTeachColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 4) {
                GeneratingStep(icon: "checkmark.circle.fill", text: "Analyzing requirements", isComplete: true)
                GeneratingStep(icon: "arrow.triangle.2.circlepath", text: "Generating objectives", isComplete: false)
                GeneratingStep(icon: "circle", text: "Creating activities", isComplete: false)
                GeneratingStep(icon: "circle", text: "Finalizing plan", isComplete: false)
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Result View
    private var resultView: some View {
        ScrollView {
            if let plan = generatedPlan {
                VStack(spacing: 20) {
                    // Success Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Lesson Plan Generated!")
                            .font(.title2.bold())
                            .foregroundColor(EZTeachColors.textPrimary)
                    }
                    .padding()
                    
                    // Preview
                    LessonPlanPreview(plan: plan)
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            step = 1
                            generatedPlan = nil
                        } label: {
                            Text("Regenerate")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
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
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Generation Failed")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        step = 1
                        self.error = nil
                    }
                    .foregroundColor(.purple)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Generate
    private func generateLessonPlan() {
        step = 2
        isGenerating = true
        
        // Simulate AI generation (replace with actual AI call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let plan = createMockLessonPlan()
            generatedPlan = plan
            isGenerating = false
            step = 3
        }
    }
    
    // MARK: - Intelligent Lesson Plan Generator
    private func createMockLessonPlan() -> AILessonPlan {
        let gen = LessonPlanEngine(subject: subject, grade: gradeLevel, topic: topic, duration: duration, style: learningStyle, notes: additionalNotes)
        return gen.generate(schoolId: schoolId, creatorId: Auth.auth().currentUser?.uid ?? "")
    }
    
    private func savePlan(_ plan: AILessonPlan) {
        let planData: [String: Any] = [
            "creatorId": plan.creatorId,
            "schoolId": plan.schoolId,
            "title": plan.title,
            "subject": plan.subject,
            "gradeLevel": plan.gradeLevel,
            "duration": plan.duration,
            "objectives": plan.objectives,
            "materials": plan.materials,
            "warmUp": plan.warmUp,
            "mainActivity": plan.mainActivity.map { act -> [String: Any] in
                [
                    "id": act.id,
                    "title": act.title,
                    "description": act.description,
                    "duration": act.duration,
                    "type": act.type
                ]
            },
            "assessment": plan.assessment,
            "closure": plan.closure,
            "differentiation": plan.differentiation,
            "homework": plan.homework,
            "standards": plan.standards,
            "notes": plan.notes,
            "isAIGenerated": plan.isAIGenerated,
            "createdAt": Timestamp(date: plan.createdAt),
            "updatedAt": Timestamp(date: plan.updatedAt)
        ]
        
        db.collection("lessonPlans").document(plan.id).setData(planData) { _ in
            onSave(plan)
            dismiss()
        }
    }
}

// MARK: - Supporting Views
struct GeneratingStep: View {
    let icon: String
    let text: String
    let isComplete: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isComplete ? .green : .gray)
            Text(text)
                .foregroundColor(isComplete ? EZTeachColors.textPrimary : .gray)
            Spacer()
        }
    }
}

struct LessonPlanPreview: View {
    let plan: AILessonPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.headline)
                    .foregroundColor(EZTeachColors.textPrimary)
                
                HStack {
                    Label(plan.subject, systemImage: "book.fill")
                    Label("Grade \(plan.gradeLevel)", systemImage: "graduationcap.fill")
                    Label(plan.duration, systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundColor(EZTeachColors.textSecondary)
            }
            
            Divider()
            
            // Objectives
            VStack(alignment: .leading, spacing: 8) {
                Text("Objectives")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(EZTeachColors.textPrimary)
                
                ForEach(plan.objectives, id: \.self) { obj in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(obj)
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textSecondary)
                    }
                }
            }
            
            // Activities Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Activities (\(plan.mainActivity.count))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(EZTeachColors.textPrimary)
                
                ForEach(plan.mainActivity) { activity in
                    HStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 8, height: 8)
                        Text(activity.title)
                            .font(.caption)
                            .foregroundColor(EZTeachColors.textSecondary)
                        Spacer()
                        Text(activity.duration)
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

// MARK: - Lesson Plan Detail View
struct LessonPlanDetailView: View {
    let plan: AILessonPlan
    @Environment(\.dismiss) var dismiss
    @State private var copiedSection: String?
    
    // Build full plan as copiable text
    private var fullPlanText: String {
        var t = "LESSON PLAN: \(plan.title)\n"
        t += "Subject: \(plan.subject) | Grade: \(plan.gradeLevel) | Duration: \(plan.duration)\n"
        t += "\n--- LEARNING OBJECTIVES ---\n"
        for (i, obj) in plan.objectives.enumerated() { t += "\(i+1). \(obj)\n" }
        t += "\n--- MATERIALS NEEDED ---\n"
        for m in plan.materials { t += "• \(m)\n" }
        t += "\n--- WARM-UP ACTIVITY ---\n\(plan.warmUp)\n"
        t += "\n--- MAIN ACTIVITIES ---\n"
        for a in plan.mainActivity { t += "\n[\(a.type)] \(a.title) (\(a.duration))\n\(a.description)\n" }
        t += "\n--- ASSESSMENT ---\n\(plan.assessment)\n"
        t += "\n--- CLOSURE ---\n\(plan.closure)\n"
        t += "\n--- DIFFERENTIATION ---\n\(plan.differentiation)\n"
        if !plan.homework.isEmpty { t += "\n--- HOMEWORK ---\n\(plan.homework)\n" }
        if !plan.standards.isEmpty { t += "\n--- STANDARDS ---\n" + plan.standards.joined(separator: "\n") + "\n" }
        if !plan.notes.isEmpty { t += "\n--- NOTES & RESOURCES ---\n\(plan.notes)\n" }
        t += "\n--- EZTEACH FEATURES TO USE ---\n"
        t += ezTeachSuggestions.map { "• \($0.feature): \($0.tip)" }.joined(separator: "\n")
        t += "\n\nGenerated by EZTeach AI"
        return t
    }
    
    // EZTeach in-app feature suggestions based on the plan
    private var ezTeachSuggestions: [(icon: String, feature: String, tip: String)] {
        var suggestions: [(String, String, String)] = []
        suggestions.append(("doc.text.fill", "Homework Submission", "Assign homework through EZTeach so students can submit photos or files directly from the app"))
        suggestions.append(("chart.bar.fill", "Gradebook", "Record assessment scores in the EZTeach Gradebook under \(plan.subject) for Grade \(plan.gradeLevel)"))
        suggestions.append(("checkmark.circle.fill", "Attendance", "Take attendance at the start of this lesson using the one-tap Attendance feature"))
        
        switch plan.subject.lowercased() {
        case "math":
            suggestions.append(("gamecontroller.fill", "Math Games", "Send students to the EZTeach Math Games section for reinforcement practice after the lesson"))
            suggestions.append(("trophy.fill", "Leaderboards", "Use the game leaderboard to motivate competitive practice on \(plan.objectives.first ?? "this topic")"))
        case "reading":
            suggestions.append(("book.fill", "Picture Books", "Assign a book from the 100+ Picture Books library as guided or independent reading"))
            suggestions.append(("person.2.fill", "Reading Together", "Create a Reading Together session so students can read the assigned text in sync"))
            suggestions.append(("speaker.wave.2.fill", "Read Aloud", "Use the Read Aloud feature for students who need auditory support"))
        case "science":
            suggestions.append(("atom", "Science Games", "Send students to Science Explorations in the Games section for interactive follow-up"))
        case "writing":
            suggestions.append(("doc.richtext.fill", "Documents", "Share writing rubrics and mentor texts through the Documents feature"))
        default: break
        }
        
        suggestions.append(("bell.fill", "Announcements", "Post today's lesson topic as an announcement so parents can discuss it at home"))
        suggestions.append(("person.crop.circle.badge.checkmark", "Behavior Tracking", "Log participation and engagement during the lesson with Behavior Tracking"))
        suggestions.append(("chart.line.uptrend.xyaxis", "Analytics", "Review the Analytics Dashboard after assessment to identify students who need reteaching"))
        suggestions.append(("calendar", "Calendar", "Add this lesson to the Calendar with the due date for any homework assignments"))
        return suggestions
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(plan.title)
                                .font(.title2.bold())
                                .foregroundColor(EZTeachColors.textPrimary)
                                .textSelection(.enabled)
                            
                            if plan.isAIGenerated {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            Label(plan.subject, systemImage: "book.fill")
                            Label("Grade \(plan.gradeLevel)", systemImage: "graduationcap.fill")
                            Label(plan.duration, systemImage: "clock.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(EZTeachColors.textSecondary)
                        
                        // Copy entire plan button
                        Button {
                            UIPasteboard.general.string = fullPlanText
                            withAnimation { copiedSection = "all" }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { copiedSection = nil } }
                        } label: {
                            Label(copiedSection == "all" ? "Copied!" : "Copy Entire Plan", systemImage: copiedSection == "all" ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(copiedSection == "all" ? .green : .purple)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background((copiedSection == "all" ? Color.green : Color.purple).opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Objectives
                    CopyableSection(title: "Learning Objectives", icon: "target", copyText: plan.objectives.enumerated().map { "\($0.offset+1). \($0.element)" }.joined(separator: "\n"), copiedSection: $copiedSection) {
                        ForEach(plan.objectives, id: \.self) { obj in
                            BulletPoint(text: obj)
                        }
                    }
                    
                    // Materials
                    CopyableSection(title: "Materials Needed", icon: "bag.fill", copyText: plan.materials.map { "• \($0)" }.joined(separator: "\n"), copiedSection: $copiedSection) {
                        ForEach(plan.materials, id: \.self) { material in
                            BulletPoint(text: material, icon: "checkmark.square.fill")
                        }
                    }
                    
                    // Warm Up
                    CopyableSection(title: "Warm-Up Activity", icon: "flame.fill", copyText: plan.warmUp, copiedSection: $copiedSection) {
                        Text(plan.warmUp)
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textSecondary)
                            .textSelection(.enabled)
                    }
                    
                    // Main Activities
                    CopyableSection(title: "Main Activities", icon: "list.bullet.clipboard.fill", copyText: plan.mainActivity.map { "[\($0.type)] \($0.title) (\($0.duration))\n\($0.description)" }.joined(separator: "\n\n"), copiedSection: $copiedSection) {
                        ForEach(plan.mainActivity) { activity in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(activity.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(EZTeachColors.textPrimary)
                                    Spacer()
                                    Text(activity.duration)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(8)
                                }
                                
                                Text(activity.description)
                                    .font(.caption)
                                    .foregroundColor(EZTeachColors.textSecondary)
                                    .textSelection(.enabled)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Assessment
                    CopyableSection(title: "Assessment", icon: "checkmark.seal.fill", copyText: plan.assessment, copiedSection: $copiedSection) {
                        Text(plan.assessment)
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textSecondary)
                            .textSelection(.enabled)
                    }
                    
                    // Closure
                    CopyableSection(title: "Closure", icon: "flag.checkered", copyText: plan.closure, copiedSection: $copiedSection) {
                        Text(plan.closure)
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textSecondary)
                            .textSelection(.enabled)
                    }
                    
                    // Differentiation
                    CopyableSection(title: "Differentiation", icon: "person.2.fill", copyText: plan.differentiation, copiedSection: $copiedSection) {
                        Text(plan.differentiation)
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.textSecondary)
                            .textSelection(.enabled)
                    }
                    
                    // Homework
                    if !plan.homework.isEmpty {
                        CopyableSection(title: "Homework", icon: "house.fill", copyText: plan.homework, copiedSection: $copiedSection) {
                            Text(plan.homework)
                                .font(.subheadline)
                                .foregroundColor(EZTeachColors.textSecondary)
                                .textSelection(.enabled)
                        }
                    }
                    
                    // Standards
                    if !plan.standards.isEmpty {
                        CopyableSection(title: "Standards", icon: "doc.badge.gearshape.fill", copyText: plan.standards.joined(separator: "\n"), copiedSection: $copiedSection) {
                            ForEach(plan.standards, id: \.self) { standard in
                                Text(standard)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    
                    // Notes & Resources
                    if !plan.notes.isEmpty {
                        CopyableSection(title: "Notes & Resources", icon: "lightbulb.fill", copyText: plan.notes, copiedSection: $copiedSection) {
                            Text(plan.notes)
                                .font(.subheadline)
                                .foregroundColor(EZTeachColors.textSecondary)
                                .textSelection(.enabled)
                        }
                    }
                    
                    // EZTeach Feature Suggestions
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.orange)
                            Text("EZTeach Features to Use")
                                .font(.headline)
                                .foregroundColor(EZTeachColors.textPrimary)
                            Spacer()
                            Button {
                                let text = ezTeachSuggestions.map { "• \($0.feature): \($0.tip)" }.joined(separator: "\n")
                                UIPasteboard.general.string = text
                                withAnimation { copiedSection = "features" }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { copiedSection = nil } }
                            } label: {
                                Image(systemName: copiedSection == "features" ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.caption)
                                    .foregroundColor(copiedSection == "features" ? .green : .gray)
                            }
                        }
                        
                        ForEach(Array(ezTeachSuggestions.enumerated()), id: \.offset) { _, suggestion in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: suggestion.icon)
                                    .font(.body)
                                    .foregroundColor(.purple)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(suggestion.feature)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(EZTeachColors.textPrimary)
                                    Text(suggestion.tip)
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
            .navigationTitle("Lesson Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
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
}

// MARK: - Copyable Section (with copy button on each section)
private struct CopyableSection<Content: View>: View {
    let title: String
    let icon: String
    let copyText: String
    @Binding var copiedSection: String?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                Text(title)
                    .font(.headline)
                    .foregroundColor(EZTeachColors.textPrimary)
                Spacer()
                Button {
                    UIPasteboard.general.string = copyText
                    withAnimation { copiedSection = title }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copiedSection = nil } }
                } label: {
                    Image(systemName: copiedSection == title ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(copiedSection == title ? .green : .gray)
                }
            }
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct BulletPoint: View {
    let text: String
    var icon: String = "circle.fill"
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.purple)
            Text(text)
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textSecondary)
        }
    }
}

// MARK: - Lesson Plan Generation Engine
// Produces detailed, subject-specific, grade-appropriate lesson plans
// with differentiation strategies, real standards, and varied activities.

struct LessonPlanEngine {
    let subject: String
    let grade: Int
    let topic: String
    let duration: String
    let style: String
    let notes: String
    var stateCode: String = "DEFAULT"
    
    private var gradeLabel: String { GradeUtils.label(grade) }
    private var isElem: Bool { grade <= 6 }
    private var isMiddle: Bool { grade >= 7 && grade <= 9 }
    
    func generate(schoolId: String, creatorId: String) -> AILessonPlan {
        AILessonPlan(
            id: UUID().uuidString,
            creatorId: creatorId,
            schoolId: schoolId,
            title: buildTitle(),
            subject: subject,
            gradeLevel: grade,
            duration: duration,
            objectives: buildObjectives(),
            materials: buildMaterials(),
            warmUp: buildWarmUp(),
            mainActivity: buildActivities(),
            assessment: buildAssessment(),
            closure: buildClosure(),
            differentiation: buildDifferentiation(),
            homework: buildHomework(),
            standards: buildStandards(),
            notes: buildNotes(),
            isAIGenerated: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Title
    private func buildTitle() -> String {
        let verbs = ["Exploring", "Discovering", "Mastering", "Understanding", "Investigating"]
        let verb = verbs[abs(topic.hashValue) % verbs.count]
        return "\(verb) \(topic) — \(subject) (\(gradeLabel))"
    }
    
    // MARK: - Objectives (5 detailed, Bloom's Taxonomy aligned)
    private func buildObjectives() -> [String] {
        var objs: [String] = []
        objs.append("Students will be able to define and explain the key concepts of \(topic) in their own words (Remember/Understand).")
        
        switch subject {
        case "Math":
            objs.append("Students will solve \(isElem ? "basic" : "multi-step") problems involving \(topic) with \(isElem ? "80" : "85")% accuracy (Apply).")
            objs.append("Students will use mathematical reasoning to compare different approaches to \(topic) (Analyze).")
            objs.append("Students will create real-world word problems that apply \(topic) concepts (Create).")
            objs.append("Students will evaluate peer solutions and identify common errors in \(topic) (Evaluate).")
        case "Reading":
            objs.append("Students will identify the main idea, supporting details, and vocabulary within a text about \(topic) (Understand).")
            objs.append("Students will make text-to-self and text-to-world connections related to \(topic) (Apply).")
            objs.append("Students will analyze author's purpose, tone, and structure in the selected reading (Analyze).")
            objs.append("Students will compose a written response synthesizing what they learned about \(topic) (Create).")
        case "Science":
            objs.append("Students will form a hypothesis and design a simple investigation related to \(topic) (Apply).")
            objs.append("Students will collect, record, and interpret data from their \(topic) experiment (Analyze).")
            objs.append("Students will explain cause-and-effect relationships within \(topic) using evidence (Evaluate).")
            objs.append("Students will create a diagram or model that illustrates the concept of \(topic) (Create).")
        case "Social Studies":
            objs.append("Students will compare and contrast different perspectives related to \(topic) (Analyze).")
            objs.append("Students will use primary and secondary sources to research \(topic) (Apply).")
            objs.append("Students will present findings about \(topic) in a structured format (Create).")
            objs.append("Students will evaluate the impact of \(topic) on modern society (Evaluate).")
        case "Writing":
            objs.append("Students will plan and draft a \(isElem ? "paragraph" : "multi-paragraph essay") about \(topic) using a graphic organizer (Apply).")
            objs.append("Students will incorporate descriptive language, transitions, and \(isElem ? "basic" : "varied") sentence structure (Apply).")
            objs.append("Students will revise their writing for clarity, grammar, and organization (Evaluate).")
            objs.append("Students will publish a final version of their \(topic) writing piece (Create).")
        default:
            objs.append("Students will apply key principles of \(topic) through hands-on activities (Apply).")
            objs.append("Students will analyze and discuss the significance of \(topic) (Analyze).")
            objs.append("Students will create a project demonstrating their understanding of \(topic) (Create).")
            objs.append("Students will reflect on their learning and set personal goals related to \(topic) (Evaluate).")
        }
        return objs
    }
    
    // MARK: - Materials
    private func buildMaterials() -> [String] {
        var mats = [
            "Interactive whiteboard or projector",
            "Student notebooks/journals",
            "Colored pencils/markers for visual activities"
        ]
        switch subject {
        case "Math":
            mats += ["Printed practice worksheets (differentiated: 3 levels)", "Manipulatives (base-ten blocks, fraction tiles, number lines)", "Calculator (for checking, grades 4+)", "Graph paper"]
        case "Reading":
            mats += ["Anchor text copies (class set or digital)", "Graphic organizer handouts (story map / KWL chart)", "Vocabulary word wall cards for \(topic)", "Sticky notes for annotation"]
        case "Science":
            mats += ["Lab materials (safety goggles, gloves as needed)", "Observation recording sheets", "Science journals", "Digital resource: related video (5 min)"]
        case "Social Studies":
            mats += ["Primary source documents (copies or digital)", "World/US map or globe", "Timeline template handout", "Chromebooks/tablets for research"]
        case "Writing":
            mats += ["Writing rubric (posted and printed)", "Graphic organizer (web, outline, or T-chart)", "Mentor text examples", "Peer editing checklist"]
        default:
            mats += ["Project supplies as needed", "Digital device for research", "Handouts and worksheets"]
        }
        if style == "Visual" { mats.append("Anchor charts and infographics for visual support") }
        if style == "Kinesthetic" { mats.append("Movement-based activity cards and manipulatives") }
        if style == "Auditory" { mats.append("Audio recordings and discussion prompts") }
        return mats
    }
    
    // MARK: - Warm-Up
    private func buildWarmUp() -> String {
        switch style {
        case "Visual":
            return "Display a visual prompt (image, chart, or short video clip) related to \(topic) on the board. Students spend 3 minutes observing and writing 3 things they notice and 1 question they have. Pair-share observations before brief whole-class discussion. This activates prior knowledge and sets the visual learning tone."
        case "Kinesthetic":
            return "Begin with a 3-minute 'Stand Up, Hand Up, Pair Up' activity: students walk around and find a partner, then share one thing they already know about \(topic). After 2 rotations, gather as a class and chart responses on the board. This gets bodies moving and minds activated."
        case "Auditory":
            return "Play a 2-minute audio clip or read aloud a short passage related to \(topic). Students listen actively and jot down key words they hear. Discuss as a class: 'What did you notice? What patterns did you hear?' Use this to bridge into the day's learning goals."
        default:
            return "Think-Pair-Share: Display the essential question about \(topic) on the board. Students think silently for 1 minute, discuss with a shoulder partner for 2 minutes, then share out with the class. Record student responses on the board as an anchor for the lesson. Review any prerequisite vocabulary needed for today's content."
        }
    }
    
    // MARK: - Activities
    private func buildActivities() -> [AILessonPlan.LessonActivity] {
        let durationMins = parseDuration()
        let warmClosure = 12 // warm-up + closure time
        let available = max(durationMins - warmClosure, 20)
        
        var activities: [AILessonPlan.LessonActivity] = []
        
        // Activity 1: Direct instruction (mini-lesson)
        let miniLen = max(available / 4, 8)
        activities.append(AILessonPlan.LessonActivity(
            id: UUID().uuidString,
            title: "Mini-Lesson: Introduction to \(topic)",
            description: buildMiniLesson(),
            duration: "\(miniLen) minutes",
            type: "Direct Instruction"
        ))
        
        // Activity 2: Guided practice
        let guidedLen = max(available / 3, 10)
        activities.append(AILessonPlan.LessonActivity(
            id: UUID().uuidString,
            title: "Guided Practice: \(topic) Together",
            description: buildGuidedPractice(),
            duration: "\(guidedLen) minutes",
            type: "Guided Practice"
        ))
        
        // Activity 3: Group/collaborative
        let groupLen = max(available / 4, 8)
        activities.append(AILessonPlan.LessonActivity(
            id: UUID().uuidString,
            title: "Collaborative Activity: \(topic) Exploration",
            description: buildGroupActivity(),
            duration: "\(groupLen) minutes",
            type: "Group Work"
        ))
        
        // Activity 4: Independent practice
        let indLen = available - miniLen - guidedLen - groupLen
        activities.append(AILessonPlan.LessonActivity(
            id: UUID().uuidString,
            title: "Independent Practice & Application",
            description: buildIndependentPractice(),
            duration: "\(max(indLen, 5)) minutes",
            type: "Independent Practice"
        ))
        
        return activities
    }
    
    private func buildMiniLesson() -> String {
        switch subject {
        case "Math":
            return "Present \(topic) using the 'I Do' model. Walk through 2-3 example problems step-by-step on the board. Use color coding to highlight key operations. Pause after each example to check understanding with thumbs up/down. Introduce vocabulary: define key terms and add them to the word wall. Show the concept visually with a diagram or number line."
        case "Reading":
            return "Introduce the text and pre-teach 3-5 vocabulary words related to \(topic) using pictures and context clues. Model the reading strategy for today (e.g., making inferences, identifying main idea). Read the first section aloud using a think-aloud approach — verbalize your thinking process so students see how skilled readers process text."
        case "Science":
            return "Present the scientific concept of \(topic) using a brief demonstration or video clip (3-4 min). Introduce key vocabulary and have students predict what will happen in today's investigation. Explain the scientific method steps they will follow. Draw a diagram on the board showing the concept and label key parts together."
        case "Writing":
            return "Display a mentor text example related to \(topic). Analyze the structure together — point out how the author organized ideas, used transitions, and supported their points. Co-create a success criteria chart: 'What makes good writing about \(topic)?' Students copy the criteria into their notebooks as a reference."
        default:
            return "Present the core concepts of \(topic) through a brief, engaging presentation. Use visuals, real-world examples, and questioning to keep students engaged. Introduce and define key vocabulary. Model the expected skill or process step-by-step using the 'I Do, We Do, You Do' framework."
        }
    }
    
    private func buildGuidedPractice() -> String {
        switch subject {
        case "Math":
            return "'We Do' phase: Work through 3-4 problems as a class, progressively releasing responsibility. Use whiteboards — students hold up answers after each problem so you can quickly assess. Address common misconceptions immediately. For each problem, ask: 'What do we know? What are we solving for? What strategy should we use?'"
        case "Reading":
            return "Read the next section of the text together (choral reading or partner reading). Stop at key points to model comprehension strategies: 'What is the author saying here? What evidence supports this?' Students annotate their text with sticky notes marking important ideas, questions, and connections."
        case "Science":
            return "Guide students through the first part of the investigation together. Demonstrate proper procedures, safety protocols, and data collection methods. Students follow along, completing each step as you model it. Check that all groups have accurate observations before allowing them to continue independently."
        default:
            return "Work through examples together as a class using the 'We Do' approach. Gradually release responsibility — start by leading, then have students contribute ideas, then have them attempt with minimal guidance. Use questioning strategies to check for understanding throughout."
        }
    }
    
    private func buildGroupActivity() -> String {
        switch style {
        case "Kinesthetic":
            return "Station Rotation: Set up 3-4 stations around the room, each with a hands-on activity related to \(topic). Groups rotate every 5-6 minutes. Station 1: Manipulative practice. Station 2: Real-world problem solving. Station 3: Creative challenge. Station 4: Technology-based practice. Teacher circulates and supports."
        case "Visual":
            return "Gallery Walk: Groups create visual representations of \(topic) — posters, diagrams, or infographics. Post around the room. Groups rotate to view each poster, leaving sticky note feedback (one compliment, one question). Regroup to discuss patterns and key takeaways from the gallery."
        default:
            return "Small Group Discussion & Practice: Organize students into groups of 3-4. Each group receives a challenge related to \(topic) at their level. Groups collaborate, discuss strategies, and document their thinking. One member serves as recorder, one as presenter. Groups share their approach with the class. Teacher circulates to facilitate and ask probing questions."
        }
    }
    
    private func buildIndependentPractice() -> String {
        switch subject {
        case "Math":
            return "Students work independently on a tiered practice sheet (3 levels: approaching, meeting, exceeding). \(isElem ? "8-10" : "10-15") problems that progress from basic to application. Early finishers work on challenge problems or create their own word problems. Teacher pulls a small group for targeted reteaching."
        case "Reading":
            return "Students independently read the final section and complete a written response: \(isElem ? "3-5 sentences" : "1-2 paragraphs") answering the essential question using text evidence. Use the graphic organizer to plan before writing. Teacher confers with individual students."
        case "Science":
            return "Students complete their investigation independently/in pairs. Record all observations and data in their science journals. Answer analysis questions: What happened? Why? What would you change? Draw a labeled diagram of the results."
        default:
            return "Students work independently to apply what they learned about \(topic). Complete the practice activity at their level. Teacher circulates for one-on-one support. Early finishers extend their learning through a choice board activity."
        }
    }
    
    // MARK: - Assessment
    private func buildAssessment() -> String {
        "Formative Assessment — Exit Ticket (3-5 minutes): Students complete a quick check on an index card or digital form.\n\n" +
        "• Question 1 (Knowledge): Define or explain a key concept from today's lesson on \(topic).\n" +
        "• Question 2 (Application): Solve a problem or provide an example demonstrating \(topic).\n" +
        "• Question 3 (Reflection): Rate your confidence (1-5) and explain: 'What part of \(topic) do you want more practice with?'\n\n" +
        "Sort exit tickets into 3 piles (Got It / Getting There / Needs Support) to inform tomorrow's instruction. Also use observational notes from group work and independent practice for holistic assessment."
    }
    
    // MARK: - Closure
    private func buildClosure() -> String {
        "Bring students back together for a 3-minute closing circle.\n\n" +
        "1. Review the essential question and have 2-3 students share their answers.\n" +
        "2. '3-2-1' Reflection: Students share 3 things they learned, 2 things they found interesting, and 1 question they still have about \(topic).\n" +
        "3. Preview tomorrow's lesson: 'Tomorrow we will build on \(topic) by...'\n" +
        "4. Positive reinforcement: Highlight specific student efforts and growth observed during the lesson."
    }
    
    // MARK: - Differentiation
    private func buildDifferentiation() -> String {
        "Struggling Learners (Approaching Grade Level):\n" +
        "• Provide sentence starters, word banks, and visual vocabulary cards\n" +
        "• Use simplified problems with fewer steps; allow use of manipulatives\n" +
        "• Pair with a supportive peer; offer additional teacher check-ins\n" +
        "• Allow extra time and reduce quantity (quality over quantity)\n\n" +
        "On-Level Learners (Meeting Grade Level):\n" +
        "• Standard lesson activities as planned\n" +
        "• Encourage peer discussion to deepen understanding\n" +
        "• Provide choice in how they demonstrate learning\n\n" +
        "Advanced Learners (Exceeding Grade Level):\n" +
        "• Extension problems with higher complexity or real-world application\n" +
        "• Leadership role: serve as group facilitator or peer tutor\n" +
        "• Independent research project or creative extension related to \(topic)\n" +
        "• Open-ended challenge: 'How else could you apply \(topic)?'\n\n" +
        "English Language Learners:\n" +
        "• Bilingual glossary, visual supports, and graphic organizers\n" +
        "• Partner with a fluent peer for language support\n" +
        "• Allow verbal responses as alternative to written when appropriate\n\n" +
        "Students with IEPs/504s:\n" +
        "• Follow individual accommodations as documented\n" +
        "• Preferential seating, extended time, modified assignments as needed"
    }
    
    // MARK: - Homework
    private func buildHomework() -> String {
        if isElem {
            return "Practice Activity (15-20 minutes): Complete the take-home worksheet reviewing today's \(topic) concepts. Parents are encouraged to ask their child to explain their thinking.\n\nOptional Extension: Draw a picture or create a short presentation showing how \(topic) appears in everyday life."
        } else {
            return "Independent Review (20-30 minutes): Complete problems/questions 1-10 from the \(topic) practice set. Show all work and explain your reasoning for at least 2 problems.\n\nReflection Journal: Write a brief paragraph explaining the most important thing you learned about \(topic) and one area where you need more practice.\n\nOptional Extension: Research a real-world application of \(topic) and prepare a 1-minute presentation for the class."
        }
    }
    
    // MARK: - Standards (powered by StandardsService)
    private func buildStandards() -> [String] {
        // Use the StandardsService to get resolved standards based on
        // the school's state, district, and school-level overrides.
        let service = StandardsService.shared
        let resolved = service.baseStandards(subject: subject, grade: grade, stateCode: stateCode)
        if !resolved.isEmpty {
            return resolved.map { "\($0.standardId) — \($0.description)" }
        }

        // Fallback for subjects without specific standards
        return [
            "Aligned to \(subject) Grade \(grade) State Standards",
            "21st Century Skills: Critical Thinking and Collaboration",
            "SEL Competency: Self-Management and Responsible Decision-Making"
        ]
    }
    
    // MARK: - Notes
    private func buildNotes() -> String {
        var n = "Suggested Resources:\n"
        n += "• Video: Search YouTube for '\(topic) for \(gradeLabel) students' (preview before showing)\n"
        n += "• Website: Khan Academy, BrainPOP, or ReadWorks for supplemental content\n"
        n += "• Book: Check school library for grade-level texts on \(topic)\n\n"
        n += "Teacher Tips:\n"
        n += "• Prepare materials the day before; have extra copies ready\n"
        n += "• Anticipate common misconceptions about \(topic) and plan how to address them\n"
        n += "• Keep flexible — if students need more guided practice, shorten independent time\n"
        n += "• Photograph student work for portfolio assessment\n"
        if !notes.isEmpty {
            n += "\nAdditional Teacher Notes: \(notes)"
        }
        return n
    }
    
    // MARK: - Helpers
    private func parseDuration() -> Int {
        if duration.contains("30") { return 30 }
        if duration.contains("45") { return 45 }
        if duration.contains("60") { return 60 }
        if duration.contains("90") { return 90 }
        return 45
    }
}
