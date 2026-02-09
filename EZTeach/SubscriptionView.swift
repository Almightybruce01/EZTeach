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
                        autoPaymentBanner
                        tierSection
                        discountCodesSection
                        featuresSection
                        districtSection
                        manageAccountSection
                        restorePurchasesSection
                        subscriptionTermsSection
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

    // MARK: - Auto-Payment Banner
    private var autoPaymentBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("Enable Automatic Payments")
                    .font(.subheadline.bold())
                Text("We recommend automatic renewal so your school never loses access to features. Set it up during checkout or in your account settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.green.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Discount Codes
    private var discountCodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discount Codes")
                .font(.headline)

            VStack(spacing: 8) {
                Text("Monthly")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                discountRow(code: "EZT-M25-7KP9X4", description: "25% off monthly")
                discountRow(code: "EZT-M100-R5J6T8", description: "100% off monthly")

                Divider()

                Text("Yearly")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                discountRow(code: "EZT-Y25-3NQ8W2", description: "25% off yearly")
                discountRow(code: "EZT-Y100-V2L4M9", description: "100% off yearly")
            }

            Text("Enter a code during checkout on our website.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    private func discountRow(code: String, description: String) -> some View {
        HStack(spacing: 12) {
            Text(code)
                .font(.caption.bold().monospaced())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(EZTeachColors.accent.opacity(0.1))
                .foregroundColor(EZTeachColors.accent)
                .cornerRadius(6)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                UIPasteboard.general.string = code
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - District Pricing
    private var districtSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("District Plans")
                .font(.headline)

            Text("Districts pick a plan tier for each school — same tiers as above.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(EZTeachColors.success)
                        .font(.caption)
                    Text("Choose a tier per school based on school size")
                        .font(.caption)
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(EZTeachColors.success)
                        .font(.caption)
                    Text("All features included at every tier")
                        .font(.caption)
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(EZTeachColors.success)
                        .font(.caption)
                    Text("Change tiers anytime as schools grow")
                        .font(.caption)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Over 7,500 Students?")
                    .font(.subheadline.bold())

                Text("Schools or districts that exceed the max tier cap (7,500) pay a per-student/year overage rate:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(spacing: 4) {
                    overageRow("7,501–15,000 students", "$12/student/yr")
                    overageRow("15,001–30,000 students", "$11/student/yr")
                    overageRow("30,001–60,000 students", "$10/student/yr")
                    overageRow("60,001–100,000 students", "$9/student/yr")
                    overageRow("100,000+ students", "$8/student/yr")
                }
            }

            Text("Contact ezteach0@gmail.com for district setup.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }

    private func overageRow(_ range: String, _ price: String) -> some View {
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

    // MARK: - Restore Purchases (Apple requirement)
    private var restorePurchasesSection: some View {
        Button {
            openURL("https://apps.apple.com/account/subscriptions")
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title3)
                    .foregroundColor(EZTeachColors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore Purchases")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text("Already subscribed? Manage your subscription in your Apple ID settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subscription Terms (Apple compliance — Section 3.1.2)
    private var subscriptionTermsSection: some View {
        VStack(spacing: 12) {
            Text("Subscription Information")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Text("EZTeach subscriptions are billed through our website at ezteach.org. All plans auto-renew at the end of each billing period (monthly or yearly) unless canceled before the renewal date. You can manage or cancel your subscription at any time from your account settings on our website or by contacting support.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Prices shown are in USD. Subscriptions provide access to all features for the duration of the active billing period. If your subscription lapses, access to premium features will be restricted until renewed.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
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

            Button("Manage Subscriptions") {
                openURL("https://apps.apple.com/account/subscriptions")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private func openAccountWebsite() {
        openURL(accountManagementURL)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}
