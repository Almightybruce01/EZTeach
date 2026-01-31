//
//  OfficeInfoView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OfficeInfoView: View {

    @State private var info = ""
    @State private var schoolId: String?
    @State private var role: String = ""
    @State private var isLoading = true

    private let db = Firestore.firestore()

    private var isSchool: Bool { role == "school" }

    var body: some View {
        ZStack {
            EZTeachColors.background.ignoresSafeArea()

            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if schoolId == nil {
                ContentUnavailableView(
                    "No school selected",
                    systemImage: "building.2",
                    description: Text("Join a school from Switch Schools to view office information.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header card
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(EZTeachColors.navy)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Office Information")
                                    .font(.headline)
                                Text(isSchool ? "Tap below to edit" : "Contact & hours")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(EZTeachColors.cardFill)
                        .cornerRadius(14)

                        // Content area
                        VStack(alignment: .leading, spacing: 12) {
                            if isSchool {
                                TextEditor(text: $info)
                                    .frame(minHeight: 200)
                                    .padding(8)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )

                                Text("Add office hours, phone numbers, contact info, etc.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                if info.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 36))
                                            .foregroundColor(.secondary)
                                        Text("No office information available.")
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    Text(info)
                                        .font(.body)
                                        .lineSpacing(6)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Office Info")
        .toolbar {
            if isSchool, schoolId != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
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
            guard let sid = data["activeSchoolId"] as? String else {
                isLoading = false
                return
            }
            schoolId = sid

            db.collection("schools").document(sid).getDocument { s, _ in
                info = s?.data()?["officeInfo"] as? String ?? ""
                isLoading = false
            }
        }
    }

    private func save() {
        guard let sid = schoolId else { return }

        db.collection("schools").document(sid).updateData([
            "officeInfo": info
        ]) { _ in }
    }
}
