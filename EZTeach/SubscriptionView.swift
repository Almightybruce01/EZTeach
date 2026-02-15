//
//  SubscriptionView.swift
//  EZTeach
//
//  App Store compliant: No prices, payment links, or external purchase references.
//  Subscription management happens entirely outside the app on ezteach.org.
//  This view shows plan status and included features only.
//

import SwiftUI

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
                        statusSection
                        featuresSection
                        supportSection
                        termsSection
                    }
                    .padding()
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
                Text("EZTeach")
                    .font(.title.bold())

                if userData.isSubscribed {
                    Label("Active Account", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(EZTeachColors.success)
                } else {
                    Text("Contact your school administrator to activate your account.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Status
    private var statusSection: some View {
        VStack(spacing: 12) {
            if userData.isSubscribed {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(EZTeachColors.success)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("All Features Active")
                            .font(.subheadline.bold())
                        Text("Your school has full access to every EZTeach feature.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.green.opacity(0.08))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Setup Required")
                            .font(.subheadline.bold())
                        Text("Your school administrator manages account activation. Contact them for access to all features.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
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

    // MARK: - Support
    private var supportSection: some View {
        VStack(spacing: 12) {
            Text("Need Help?")
                .font(.headline)

            Text("If you have questions about your account or need assistance, contact your school administrator or reach out to our support team.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("ezteach0@gmail.com")
                .font(.caption.bold())
                .foregroundColor(EZTeachColors.accent)
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    // MARK: - Terms & Privacy (Apple requirement — clickable links)
    private var termsSection: some View {
        VStack(spacing: 10) {
            Text("By using EZTeach, you agree to our:")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Terms of Use") {
                    openURL("https://ezteach.org/terms")
                }
                .font(.caption.bold())
                .foregroundColor(EZTeachColors.accent)

                Text("|")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Privacy Policy") {
                    openURL("https://ezteach.org/privacy")
                }
                .font(.caption.bold())
                .foregroundColor(EZTeachColors.accent)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}
