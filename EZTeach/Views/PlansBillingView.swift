//
//  PlansBillingView.swift
//  EZTeach
//
//  Plans & Billing screen (school-role only).
//  Shows current tier, student usage vs cap, and upgrade options.
//  Payment happens on the website via Stripe checkout — no IAP.
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
    @State private var priceMonthly   = 129
    @State private var studentCap     = 200
    @State private var studentCount   = 0
    @State private var isActive       = true
    @State private var schoolName     = ""
    @State private var districtId: String?
    @State private var subscriptionActive = false

    @State private var isLoading      = true
    @State private var upgradeError: String?
    @State private var showUpgradeSuccess = false
    @State private var upgradedTierLabel  = ""

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
                            } else {
                                tiersSection
                                districtPricingNote
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Plans & Billing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadPlan)
            .alert("Upgrade Successful", isPresented: $showUpgradeSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your plan has been upgraded to \(upgradedTierLabel). Your new student cap is now active.")
            }
            .alert("Error", isPresented: .constant(upgradeError != nil)) {
                Button("OK") { upgradeError = nil }
            } message: {
                Text(upgradeError ?? "")
            }
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

            HStack(spacing: 8) {
                Label(subscriptionActive ? "Active" : "Inactive",
                      systemImage: subscriptionActive ? "checkmark.seal.fill" : "xmark.seal")
                    .font(.subheadline.bold())
                    .foregroundColor(subscriptionActive ? EZTeachColors.success : .orange)

                Text("•")
                    .foregroundColor(.secondary)

                Text("$\(priceMonthly)/mo")
                    .font(.subheadline.bold())
                    .foregroundColor(EZTeachColors.accent)
            }

            Text("All plans include every feature — games, books, AI lesson plans, rosters, classes, sub plans, and admin controls.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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
                    Text("Student limit reached — upgrade to add more students.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    // MARK: - Tiers
    private var tiersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("School Monthly Plans")
                .font(.headline)

            ForEach(tiers, id: \.tier) { t in
                tierRow(t)
            }
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    private func tierRow(_ t: (tier: String, label: String, cap: Int, price: Int)) -> some View {
        let isCurrent = t.tier == planTier
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(t.label)
                    .font(.subheadline.bold())
                Text("Up to \(t.cap) students")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("$\(t.price)/mo")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundColor(EZTeachColors.accent)

            if isCurrent {
                Text("Current")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(EZTeachColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            } else if tierIndex(t.tier) > tierIndex(planTier) {
                Button("Upgrade") {
                    openWebsiteForUpgrade()
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(EZTeachColors.accentGradient)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(isCurrent ? EZTeachColors.accent.opacity(0.08) : Color.clear)
        .cornerRadius(10)
    }

    // MARK: - District pricing note
    private var districtPricingNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("District Annual Pricing")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Per-student/year (all features):")
                    .font(.subheadline.bold())
                pricingRow("3,000–7,500 students", "$12/student/yr")
                pricingRow("7,501–15,000 students", "$11/student/yr")
                pricingRow("15,001–30,000 students", "$10/student/yr")
                pricingRow("30,001–60,000 students", "$9/student/yr")
                pricingRow("60,000+ students", "$8/student/yr")
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Alternative per-school option:")
                    .font(.subheadline.bold())
                Text("$2,750 per school/year (up to 750 students/school)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Contact us at ezteach0@gmail.com or visit ezteach.org for district pricing.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    private func pricingRow(_ range: String, _ price: String) -> some View {
        HStack {
            Text(range)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(price)
                .font(.caption.bold())
                .foregroundColor(EZTeachColors.accent)
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
            Text("This school's plan is managed by your district. Contact your district administrator for billing details.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    // MARK: - Helpers
    private func tierIndex(_ tier: String) -> Int {
        tiers.firstIndex(where: { $0.tier == tier }) ?? 0
    }

    private func loadPlan() {
        guard !schoolId.isEmpty else { isLoading = false; return }
        db.collection("schools").document(schoolId).getDocument { snap, _ in
            guard let data = snap?.data() else { isLoading = false; return }
            planType            = data["planType"]            as? String ?? "school"
            planTier            = data["planTier"]            as? String ?? "S"
            priceMonthly        = data["priceMonthly"]        as? Int    ?? 129
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

    /// Opens the EZTeach website for subscription management.
    /// Apple requires that payments happen outside the app, on the web.
    private func openWebsiteForUpgrade() {
        guard let url = URL(string: "https://ezteach.org/#pricing") else { return }
        UIApplication.shared.open(url)
    }
}
