//
//  SubscriptionView.swift
//  EZTeach
//
//  App Store compliant: No prices or payment in app. All subscription management
//  happens on the website. This view provides neutral links only.
//

import SwiftUI

/// URL for account/plans management. All payment flows happen on the website.
private let accountManagementURL = "https://ezteach.org"

struct SubscriptionView: View {

    let userData: UserAccountData

    @Environment(\.dismiss) private var dismiss

    private let tiers = FirestoreService.schoolTiers

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        tierSection
                        featuresSection
                        districtSection
                        manageAccountSection
                        termsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Plans & Pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(EZTeachColors.premiumGradient)
                    .frame(width: 80, height: 80)
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("EZTeach Plans")
                    .font(.title.bold())

                if userData.isSubscribed {
                    Label("Active Account", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(EZTeachColors.success)
                } else {
                    Text("All plans include every feature. Tiers only differ by student cap.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - School Tier Pricing
    private var tierSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("School Monthly Plans")
                .font(.headline)

            Text("No add-ons. No per-module upsells. Every tier includes all features.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(tiers, id: \.tier) { t in
                HStack {
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
                }
                .padding(12)
                .background(EZTeachColors.secondaryBackground.opacity(0.6))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included in Every Plan")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                featureRow("Learning games & leaderboards")
                featureRow("Free books & Reading Together")
                featureRow("AI Lesson Plans & AI Study Plans")
                featureRow("Student roster, grades & GPA")
                featureRow("Homework with photo/file submissions")
                featureRow("Parent portal access")
                featureRow("Sub plans, requests & availability")
                featureRow("Attendance tracking & analytics")
                featureRow("Behavior tracking & write-ups")
                featureRow("School library management")
                featureRow("Bell schedules & lunch menus")
                featureRow("Bus route tracking")
                featureRow("Document storage")
                featureRow("Video meetings")
                featureRow("Emergency alerts")
                featureRow("Electives hub & Gym games")
                featureRow("Active time tracking")
                featureRow("District-wide management")
                featureRow("Priority customer support")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(EZTeachColors.success)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - District Pricing
    private var districtSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("District Annual Pricing")
                .font(.headline)

            Text("Per-student/year (all features included):")
                .font(.subheadline.bold())

            VStack(spacing: 6) {
                districtRow("3,000–7,500 students", "$12/student/yr")
                districtRow("7,501–15,000 students", "$11/student/yr")
                districtRow("15,001–30,000 students", "$10/student/yr")
                districtRow("30,001–60,000 students", "$9/student/yr")
                districtRow("60,000+ students", "$8/student/yr")
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Per-school option:")
                    .font(.subheadline.bold())
                Text("$2,750/school/year (up to 750 students)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Contact ezteach0@gmail.com for district pricing.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    private func districtRow(_ range: String, _ price: String) -> some View {
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

    // MARK: - Manage Account (opens website)
    private var manageAccountSection: some View {
        VStack(spacing: 16) {
            if userData.isSubscribed {
                VStack(spacing: 8) {
                    HStack {
                        Text("Next billing")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(userData.nextBillingDate)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(12)
            }

            Button {
                openAccountWebsite()
            } label: {
                HStack {
                    Image(systemName: "safari")
                    Text(userData.isSubscribed ? "Manage Account" : "Get Started")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(EZTeachColors.accentGradient)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)

            Text("Billing is managed on our website at ezteach.org.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Terms
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("By using EZTeach, you agree to our Terms of Service and Privacy Policy.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func openAccountWebsite() {
        guard let url = URL(string: accountManagementURL) else { return }
        UIApplication.shared.open(url)
    }
}
