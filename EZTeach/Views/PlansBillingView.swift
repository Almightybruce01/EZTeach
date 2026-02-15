//
//  PlansBillingView.swift
//  EZTeach
//
//  Plans & Billing screen (school-role only).
//  Shows current plan status, student usage vs cap, and features.
//  No pricing, payment links, or external purchase references.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PlansBillingView: View {

    let schoolId: String

    @Environment(\.dismiss) private var dismiss

    // School plan state
    @State private var planType       = "school"
    @State private var planTier       = "S"
    @State private var studentCap     = 200
    @State private var studentCount   = 0
    @State private var isActive       = true
    @State private var schoolName     = ""
    @State private var districtId: String?
    @State private var subscriptionActive = false

    @State private var isLoading      = true

    private let db = Firestore.firestore()
    private let tiers = FirestoreService.schoolTiers

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading plan…")
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerCard
                            usageCard
                            if planType == "district" {
                                districtBanner
                            }
                            featuresCard
                            supportCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Your Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadPlan)
        }
    }

    // MARK: - Header
    private var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(EZTeachColors.premiumGradient)
                    .frame(width: 64, height: 64)
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Text(schoolName.isEmpty ? "Your School" : schoolName)
                .font(.title2.bold())

            Label(subscriptionActive ? "Active" : "Inactive",
                  systemImage: subscriptionActive ? "checkmark.seal.fill" : "xmark.seal")
                .font(.subheadline.bold())
                .foregroundColor(subscriptionActive ? EZTeachColors.success : .orange)

            if !subscriptionActive {
                Text("Contact your school administrator to activate your account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }

    // MARK: - Usage
    private var usageCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Student Usage", systemImage: "person.2.fill")
                    .font(.headline)
                Spacer()
                Text("\(studentCount) / \(studentCap)")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(studentCount >= studentCap ? .red : EZTeachColors.accent)
            }

            ProgressView(value: Double(studentCount), total: Double(max(studentCap, 1)))
                .tint(studentCount >= studentCap ? .red : EZTeachColors.accent)

            if studentCount >= studentCap {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Student limit reached. Contact your school administrator to increase capacity.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    // MARK: - Features
    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Included Features")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                featureRow("AI Lesson Plans & Standards")
                featureRow("Student roster, grades & GPA")
                featureRow("Learning games & leaderboards")
                featureRow("Free books & Reading Together")
                featureRow("Homework with photo submissions")
                featureRow("Parent portal access")
                featureRow("Attendance & analytics")
                featureRow("Sub management & requests")
                featureRow("Video meetings")
                featureRow("School library management")
                featureRow("Bell schedules & lunch menus")
                featureRow("Emergency alerts")
                featureRow("Behavior tracking")
                featureRow("Document storage")
                featureRow("Electives hub")
            }
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(EZTeachColors.success)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - District banner
    private var districtBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "building.columns.fill")
                .font(.largeTitle)
                .foregroundColor(EZTeachColors.accent)
            Text("District-Managed Plan")
                .font(.headline)
            Text("This school's plan is managed by your district. Contact your district administrator for details.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    // MARK: - Support
    private var supportCard: some View {
        VStack(spacing: 8) {
            Text("Need Help?")
                .font(.subheadline.bold())
            Text("Contact your school administrator or email ezteach0@gmail.com for support.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    // MARK: - Load
    private func loadPlan() {
        guard !schoolId.isEmpty else { isLoading = false; return }
        db.collection("schools").document(schoolId).getDocument { snap, _ in
            guard let data = snap?.data() else { isLoading = false; return }
            planType            = data["planType"]            as? String ?? "school"
            planTier            = data["planTier"]            as? String ?? "S"
            studentCap          = data["studentCap"]          as? Int    ?? 200
            studentCount        = data["studentCount"]        as? Int    ?? 0
            isActive            = data["isActive"]            as? Bool   ?? true
            schoolName          = data["name"]                as? String ?? ""
            districtId          = data["districtId"]          as? String
            subscriptionActive  = data["subscriptionActive"]  as? Bool   ?? false
            if districtId != nil && !(districtId ?? "").isEmpty {
                planType = "district"
            }
            isLoading = false
        }
    }
}
