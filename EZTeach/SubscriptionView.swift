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

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        featuresSection
                        manageAccountSection
                        termsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Account")
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
                Text("Account Management")
                    .font(.title.bold())

                if userData.isSubscribed {
                    Label("Active Account", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(EZTeachColors.success)
                } else {
                    Text("Exclusive features available on our website")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                featureRow("Unlimited teacher accounts")
                featureRow("Unlimited substitute management")
                featureRow("Full calendar & announcements")
                featureRow("Student roster & grades")
                featureRow("Parent portal access")
                featureRow("Sub plans & scheduling")
                featureRow("Document storage")
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
            Text(text)
                .font(.subheadline)
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
                    Text(userData.isSubscribed ? "Manage Account" : "View Plans")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(EZTeachColors.accentGradient)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)

            Text("Exclusive features and billing are managed on our website.")
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
