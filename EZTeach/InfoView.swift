//
//  InfoView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import SwiftUI

struct InfoView: View {

    @State private var showSupport = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image("EZTeachLogoPolished.jpg")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 10)

                        VStack(spacing: 4) {
                            Text("EZTeach")
                                .font(.title.bold())
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    // Quick Actions
                    VStack(spacing: 12) {
                        helpButton(
                            icon: "message.fill",
                            title: "Get Support",
                            subtitle: "Chat, claims, and FAQs",
                            color: EZTeachColors.success
                        ) {
                            showSupport = true
                        }

                        helpButton(
                            icon: "book.fill",
                            title: "User Guide",
                            subtitle: "Learn how to use EZTeach",
                            color: EZTeachColors.accent
                        ) {
                            // TODO: Open user guide
                        }

                        helpButton(
                            icon: "envelope.fill",
                            title: "Contact Us",
                            subtitle: "Submit a claim or use live chat",
                            color: EZTeachColors.navy
                        ) {
                            showSupport = true
                        }
                    }
                    .padding(.horizontal)

                    // Quick tips
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Tips")
                            .font(.headline)

                        tipRow(icon: "key.fill", text: "School codes are 6 digits and found in School Settings")
                        tipRow(icon: "person.2.fill", text: "Teachers join schools using the school code")
                        tipRow(icon: "bell.fill", text: "Announcements are visible to all school members")
                        tipRow(icon: "calendar", text: "Events can be marked as teacher-only")
                    }
                    .padding()
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Legal
                    VStack(spacing: 8) {
                        Button("Terms of Service") {}
                            .font(.caption)
                        Button("Privacy Policy") {}
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 20)

                    Text("© 2026 EZTeach. All rights reserved.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .background(EZTeachColors.background)
            .navigationTitle("Help & Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSupport) {
                SupportView()
            }
        }
    }

    private func helpButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(EZTeachColors.accent)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
