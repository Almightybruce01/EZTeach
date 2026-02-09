//
//  SubscriptionRequiredView.swift
//  EZTeach
//
//  Shows when a feature is accessed without an active subscription.
//

import SwiftUI

struct SubscriptionRequiredView: View {
    let onViewPlans: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(EZTeachColors.accentGradient)
                    .shadow(color: EZTeachColors.accent.opacity(0.3), radius: 12, y: 4)

                VStack(spacing: 8) {
                    Text("Subscription Required")
                        .font(.title2.bold())

                    Text("This feature is not available at this time.\nPlease subscribe or renew your plan to unlock all EZTeach features.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onViewPlans()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard.fill")
                            Text("View Plans & Billing")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(EZTeachColors.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 32)

                    Text("We recommend signing up for automatic payments so your school never loses access.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Feature highlights so they know what they're missing
                VStack(alignment: .leading, spacing: 10) {
                    Text("Unlock everything:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    featureRow(icon: "person.3.fill", text: "Student management & rosters")
                    featureRow(icon: "video.fill", text: "Video meetings")
                    featureRow(icon: "brain.head.profile", text: "AI lesson plans & tutoring")
                    featureRow(icon: "book.fill", text: "Library, books & movies")
                    featureRow(icon: "chart.bar.fill", text: "Analytics & attendance")
                    featureRow(icon: "bell.badge.fill", text: "Announcements & alerts")
                }
                .padding(16)
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(14)
                .padding(.horizontal, 24)

                // Apple-required legal links
                VStack(spacing: 6) {
                    Text("Subscriptions are managed on our website.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Button("Terms of Use") {
                            if let url = URL(string: "https://ezteach.org/terms") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption2.bold())
                        .foregroundColor(EZTeachColors.accent)

                        Button("Privacy Policy") {
                            if let url = URL(string: "https://ezteach.org/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption2.bold())
                        .foregroundColor(EZTeachColors.accent)
                    }
                }
                .padding(.bottom, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(EZTeachColors.background)
            .navigationTitle("Features Unavailable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(EZTeachColors.accent)
                .frame(width: 22)
            Text(text)
                .font(.caption)
        }
    }
}
