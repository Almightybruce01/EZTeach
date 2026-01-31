//
//  ActivitiesView.swift
//  EZTeach
//
//  Teacher-recommended activities and links (e.g. things to buy).
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ActivitiesView: View {
    let schoolId: String
    let classId: String?

    @State private var items: [RecommendedActivity] = []
    @State private var filterType: RecommendedActivity.ActivityType?
    @State private var showAdd = false
    @State private var isLoading = true

    private let db = Firestore.firestore()

    private var filtered: [RecommendedActivity] {
        guard let t = filterType else { return items }
        return items.filter { $0.type == t }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("Type", selection: $filterType) {
                        Text("All").tag(nil as RecommendedActivity.ActivityType?)
                        ForEach(RecommendedActivity.ActivityType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t as RecommendedActivity.ActivityType?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filtered.isEmpty {
                        ContentUnavailableView(
                            "No activities yet",
                            systemImage: "link",
                            description: Text("Add recommended activities or purchases for students.")
                        )
                        Spacer()
                    } else {
                        List {
                            ForEach(filtered) { item in
                                ActivityRow(item: item)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Activities & Links")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .onAppear(perform: load)
            .sheet(isPresented: $showAdd) {
                AddActivityView(schoolId: schoolId, classId: classId) {
                    load()
                    showAdd = false
                }
            }
        }
    }

    private func load() {
        isLoading = true
        guard let uid = Auth.auth().currentUser?.uid else { isLoading = false; return }
        db.collection("recommendedActivities")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                var list = snap?.documents.compactMap { RecommendedActivity.fromDocument($0) } ?? []
                if let cid = classId, !cid.isEmpty {
                    list = list.filter { $0.classId == cid }
                }
                items = list
                isLoading = false
            }
    }
}

struct ActivityRow: View {
    let item: RecommendedActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.type == .recommendedPurchase ? "cart.fill" : "link")
                    .foregroundColor(EZTeachColors.accent)
                Text(item.title)
                    .font(.headline)
                Spacer()
                Text(item.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if !item.description.isEmpty {
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let url = item.linkUrl, !url.isEmpty {
                Link(destination: URL(string: url) ?? URL(string: "https://example.com")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text("Open link")
                            .font(.caption)
                    }
                    .foregroundColor(EZTeachColors.accent)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddActivityView: View {
    let schoolId: String
    let classId: String?
    let onDone: () -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var linkUrl = ""
    @State private var type: RecommendedActivity.ActivityType = .activity
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("", selection: $type) {
                        ForEach(RecommendedActivity.ActivityType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description)
                    TextField("Link URL (optional)", text: $linkUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Add \(type.displayName)")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        let data: [String: Any] = [
            "teacherId": uid,
            "schoolId": schoolId,
            "classId": classId ?? NSNull(),
            "title": title.trimmingCharacters(in: .whitespaces),
            "description": description.trimmingCharacters(in: .whitespaces),
            "linkUrl": linkUrl.trimmingCharacters(in: .whitespaces),
            "type": type.rawValue,
            "createdAt": Timestamp()
        ]
        db.collection("recommendedActivities").addDocument(data: data) { _ in
            isSaving = false
            onDone()
        }
    }
}
