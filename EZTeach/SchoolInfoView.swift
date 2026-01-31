//
//  SchoolInfoView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SchoolInfoView: View {

    @State private var schoolId: String?
    @State private var role: String = ""
    @State private var name = ""
    @State private var overview = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var isLoading = true
    @State private var showEditSchoolInfo = false

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()

            if isLoading {
                ProgressView("Loading...")
            } else if schoolId == nil {
                ContentUnavailableView(
                    "No school selected",
                    systemImage: "building.2",
                    description: Text("Join a school from Switch Schools to view school information.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // School name header card
                        VStack(spacing: 8) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(EZTeachColors.navy)
                            Text(name.isEmpty ? "School Name" : name)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(EZTeachColors.cardFill)
                        .cornerRadius(16)

                        // Overview section
                        VStack(alignment: .leading, spacing: 10) {
                            Label("About", systemImage: "text.alignleft")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)

                            if overview.isEmpty {
                                Text("No overview available.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                Text(overview)
                                    .font(.body)
                                    .lineSpacing(4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)

                        // Address section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Location", systemImage: "mappin.and.ellipse")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)

                            infoRow(icon: "house.fill", label: "Address", value: address)
                            infoRow(icon: "building.2.fill", label: "City", value: city)

                            HStack(spacing: 12) {
                                infoBox(label: "State", value: state)
                                infoBox(label: "ZIP", value: zip)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("School Info")
        .toolbar {
            if role == "school", schoolId != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showEditSchoolInfo = true }
                }
            }
        }
        .sheet(isPresented: $showEditSchoolInfo) {
            if let schoolId {
                EditSchoolInfoView(schoolId: schoolId) {
                    loadSchoolInfo(schoolId: schoolId)
                }
            }
        }
        .onAppear(perform: loadUserAndSchool)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(EZTeachColors.navy)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value.isEmpty ? "—" : value)
                    .font(.body)
            }
            Spacer()
        }
    }

    private func infoBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value.isEmpty ? "—" : value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }

    private func loadUserAndSchool() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else {
                isLoading = false
                return
            }
            role = data["role"] as? String ?? ""
            schoolId = data["activeSchoolId"] as? String
            if let sid = schoolId {
                loadSchoolInfo(schoolId: sid)
            } else {
                isLoading = false
            }
        }
    }

    private func loadSchoolInfo(schoolId: String) {
        db.collection("schools").document(schoolId).getDocument { snap, _ in
            guard let data = snap?.data() else {
                isLoading = false
                return
            }
            name = data["name"] as? String ?? ""
            overview = data["overview"] as? String ?? ""
            address = data["address"] as? String ?? ""
            city = data["city"] as? String ?? ""
            state = data["state"] as? String ?? ""
            zip = data["zip"] as? String ?? ""
            isLoading = false
        }
    }
}
