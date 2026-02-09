//
//  StandardsExplorerView.swift
//  EZTeach
//
//  Searchable, filterable Standards Explorer with permission-based editing.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct StandardsExplorerView: View {

    let userRole: String       // "student", "teacher", "school", "district"
    let schoolId: String
    let districtId: String?

    @StateObject private var service = StandardsService.shared
    @State private var standards: [ResolvedStandard] = []
    @State private var isLoading = true

    // Filters
    @State private var selectedSubject = "Math"
    @State private var selectedGrade = 5
    @State private var selectedState = "DEFAULT"
    @State private var selectedFramework: String? = nil
    @State private var selectedSource: String? = nil
    @State private var searchText = ""

    // Actions
    @State private var showAddCustom = false
    @State private var showOverrideSheet = false
    @State private var overrideTarget: ResolvedStandard?

    private var canEdit: Bool {
        userRole == "school" || userRole == "district"
    }

    var filteredStandards: [ResolvedStandard] {
        var result = standards

        if let fw = selectedFramework {
            result = result.filter { $0.framework == fw }
        }
        if let src = selectedSource {
            result = result.filter { $0.resolvedFrom == src }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.standardId.lowercased().contains(q) ||
                $0.description.lowercased().contains(q) ||
                $0.framework.lowercased().contains(q)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Filters Bar
                filtersBar

                Divider()

                if isLoading {
                    Spacer()
                    ProgressView("Loading standards...")
                    Spacer()
                } else if filteredStandards.isEmpty {
                    emptyState
                } else {
                    // MARK: - Standards List
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredStandards) { standard in
                                standardCard(standard)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Standards Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canEdit {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            if userRole == "district" {
                                Button {
                                    showAddCustom = true
                                } label: {
                                    Label("Add District Standard", systemImage: "plus.circle")
                                }
                            }
                            if userRole == "school" {
                                Button {
                                    showAddCustom = true
                                } label: {
                                    Label("Add School Override", systemImage: "pencil.circle")
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(EZTeachColors.accentGradient)
                        }
                    }
                }
            }
            .task { await loadStandards() }
            .onChange(of: selectedSubject) { _, _ in Task { await loadStandards() } }
            .onChange(of: selectedGrade) { _, _ in Task { await loadStandards() } }
            .onChange(of: selectedState) { _, _ in Task { await loadStandards() } }
            .sheet(isPresented: $showAddCustom) {
                AddCustomStandardSheet(
                    userRole: userRole,
                    districtId: districtId,
                    schoolId: schoolId,
                    subject: selectedSubject,
                    grade: selectedGrade
                ) {
                    Task { await loadStandards() }
                }
            }
            .sheet(item: $overrideTarget) { target in
                OverrideStandardSheet(
                    standard: target,
                    schoolId: schoolId
                ) {
                    Task { await loadStandards() }
                }
            }
        }
    }

    // MARK: - Filters Bar
    private var filtersBar: some View {
        VStack(spacing: 10) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search by keyword or standard ID...", text: $searchText)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Subject
                    Menu {
                        ForEach(StandardsService.supportedSubjects, id: \.self) { subj in
                            Button(subj) { selectedSubject = subj }
                        }
                    } label: {
                        filterChip(label: selectedSubject, icon: "book.fill", active: true)
                    }

                    // Grade
                    Menu {
                        ForEach(GradeUtils.allGrades, id: \.self) { g in
                            Button(GradeUtils.label(g)) { selectedGrade = g }
                        }
                    } label: {
                        filterChip(label: GradeUtils.label(selectedGrade), icon: "graduationcap", active: true)
                    }

                    // State
                    Menu {
                        ForEach(StateStandardMapping.allStates, id: \.stateCode) { state in
                            Button(state.stateName) { selectedState = state.stateCode }
                        }
                    } label: {
                        let stateName = StateStandardMapping.mapping(for: selectedState).stateName
                        filterChip(label: stateName, icon: "map", active: selectedState != "DEFAULT")
                    }

                    // Source filter
                    Menu {
                        Button("All Sources") { selectedSource = nil }
                        Button("National") { selectedSource = "national" }
                        Button("State") { selectedSource = "state" }
                        Button("District") { selectedSource = "district" }
                        Button("School") { selectedSource = "school" }
                    } label: {
                        filterChip(label: selectedSource?.capitalized ?? "All Sources", icon: "line.3.horizontal.decrease", active: selectedSource != nil)
                    }

                    // Framework filter
                    Menu {
                        Button("All Frameworks") { selectedFramework = nil }
                        ForEach(StandardFramework.allCases, id: \.self) { fw in
                            Button(fw.displayName) { selectedFramework = fw.rawValue }
                        }
                    } label: {
                        filterChip(label: selectedFramework ?? "All Frameworks", icon: "square.stack.3d.up", active: selectedFramework != nil)
                    }
                }
            }

            // Results count
            HStack {
                Text("\(filteredStandards.count) standards")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func filterChip(label: String, icon: String, active: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(active ? EZTeachColors.accent.opacity(0.12) : Color.gray.opacity(0.08))
        .foregroundColor(active ? EZTeachColors.accent : .secondary)
        .cornerRadius(8)
    }

    // MARK: - Standard Card
    private func standardCard(_ standard: ResolvedStandard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Source badge
                Text(standard.resolvedFrom.capitalized)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(sourceColor(standard.resolvedFrom))
                    .cornerRadius(4)

                if standard.isOverridden {
                    Text("OVERRIDDEN")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                Text(standard.framework)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(standard.standardId)
                .font(.subheadline.monospaced().bold())
                .foregroundColor(EZTeachColors.accent)

            Text(standard.description)
                .font(.subheadline)
                .foregroundColor(.primary)

            HStack {
                Label(standard.source, systemImage: "info.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if canEdit {
                    Button {
                        overrideTarget = standard
                    } label: {
                        Label("Override", systemImage: "pencil")
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(14)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(standard.isOverridden ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func sourceColor(_ source: String) -> Color {
        switch source {
        case "national": return .blue
        case "state": return .purple
        case "district": return .green
        case "school": return .orange
        default: return .gray
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No standards found")
                .font(.title3.bold())
            Text("Try adjusting your filters or search term.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Load Standards
    private func loadStandards() async {
        isLoading = true
        standards = await service.resolveStandards(
            stateCode: selectedState,
            subject: selectedSubject,
            grade: selectedGrade,
            districtId: districtId,
            schoolId: schoolId
        )
        isLoading = false
    }
}

// MARK: - Add Custom Standard Sheet
struct AddCustomStandardSheet: View {
    let userRole: String
    let districtId: String?
    let schoolId: String
    let subject: String
    let grade: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var overridesStandardId = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section(userRole == "district" ? "New District Standard" : "New School Override") {
                    Text("Subject: \(subject) • \(GradeUtils.label(grade))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if userRole == "school" {
                        TextField("Standard ID to override (e.g. CCSS.MATH.5.OA.1)", text: $overridesStandardId)
                            .font(.subheadline.monospaced())
                    }

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(userRole == "district" ? "Add Standard" : "Add Override")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(description.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                if userRole == "district", let districtId {
                    try await StandardsService.shared.addDistrictStandard(
                        districtId: districtId,
                        subject: subject,
                        grade: grade,
                        description: description
                    )
                } else if userRole == "school" {
                    try await StandardsService.shared.addSchoolOverride(
                        schoolId: schoolId,
                        standardId: overridesStandardId,
                        customDescription: description
                    )
                }
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run { isSaving = false }
            }
        }
    }
}

// MARK: - Override Standard Sheet
struct OverrideStandardSheet: View {
    let standard: ResolvedStandard
    let schoolId: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var customDescription: String
    @State private var isSaving = false

    init(standard: ResolvedStandard, schoolId: String, onSave: @escaping () -> Void) {
        self.standard = standard
        self.schoolId = schoolId
        self.onSave = onSave
        _customDescription = State(initialValue: standard.description)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Original Standard") {
                    Text(standard.standardId)
                        .font(.subheadline.monospaced().bold())
                        .foregroundColor(EZTeachColors.accent)
                    Text(standard.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Your Override") {
                    TextField("Custom description", text: $customDescription, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Override Standard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Override") { save() }
                        .disabled(customDescription.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await StandardsService.shared.addSchoolOverride(
                    schoolId: schoolId,
                    standardId: standard.standardId,
                    customDescription: customDescription
                )
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run { isSaving = false }
            }
        }
    }
}
