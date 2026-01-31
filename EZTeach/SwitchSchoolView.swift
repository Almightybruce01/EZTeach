//
//  SwitchSchoolView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SwitchSchoolView: View {

    @State private var schools: [SchoolItem] = []
    @State private var activeSchoolId: String = ""
    @State private var showAddSchool = false
    @State private var isLoading = true

    private let db = Firestore.firestore()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header card
                            headerCard

                            // Schools list
                            if schools.isEmpty {
                                emptyStateView
                            } else {
                                schoolsListView
                            }

                            // Add school button
                            addSchoolButton
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Schools")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddSchool) {
                AddSchoolByCodeView {
                    loadSchools()
                }
            }
            .onAppear(perform: loadSchools)
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(EZTeachColors.accentGradient)

            Text("Switch Schools")
                .font(.title2.bold())

            Text("Select a school to view its content, or add a new school using a school code.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(20)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Schools Yet")
                .font(.title3.bold())
                .foregroundColor(.secondary)

            Text("Add a school using a 6-digit school code to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }

    // MARK: - Schools List
    private var schoolsListView: some View {
        VStack(spacing: 12) {
            ForEach(schools) { school in
                schoolCard(school)
            }
        }
    }

    private func schoolCard(_ school: SchoolItem) -> some View {
        Button {
            switchTo(school)
        } label: {
            HStack(spacing: 16) {
                // School icon
                ZStack {
                    Circle()
                        .fill(school.id == activeSchoolId
                              ? EZTeachColors.accent.opacity(0.15)
                              : EZTeachColors.cardFill)
                        .frame(width: 56, height: 56)

                    Text(school.name.prefix(2).uppercased())
                        .font(.headline.bold())
                        .foregroundColor(school.id == activeSchoolId
                                        ? EZTeachColors.accent
                                        : EZTeachColors.navy)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(school.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if school.id == activeSchoolId {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundColor(EZTeachColors.success)
                    } else {
                        Text("Tap to switch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if school.id == activeSchoolId {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(EZTeachColors.success)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EZTeachColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(school.id == activeSchoolId
                                   ? EZTeachColors.success.opacity(0.5)
                                   : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add School Button
    private var addSchoolButton: some View {
        Button {
            showAddSchool = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Add School")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(EZTeachColors.accentGradient)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .padding(.top, 8)
    }

    // MARK: - Data Methods
    private func loadSchools() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else {
                isLoading = false
                return
            }

            activeSchoolId = data["activeSchoolId"] as? String ?? ""

            let joinedSchools = data["joinedSchools"] as? [[String: String]] ?? []
            schools = joinedSchools.compactMap { dict in
                guard let id = dict["id"], let name = dict["name"] else { return nil }
                return SchoolItem(id: id, name: name)
            }

            isLoading = false
        }
    }

    private func switchTo(_ school: SchoolItem) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Update active school
        db.collection("users").document(uid).updateData([
            "activeSchoolId": school.id,
            "schoolId": school.id,
            "schoolName": school.name
        ]) { _ in
            // Notify app to refresh data
            NotificationCenter.default.post(name: .schoolDataDidChange, object: nil)
            dismiss()
        }
    }
}

// MARK: - School Item Model
struct SchoolItem: Identifiable {
    let id: String
    let name: String
}
