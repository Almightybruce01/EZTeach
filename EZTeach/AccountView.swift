//
//  AccountView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountView: View {

    @State private var userData: UserAccountData?
    @State private var isLoading = true
    @State private var showSubscription = false
    @State private var showDistrictSubscription = false
    @State private var showSupport = false
    @State private var showEditProfile = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if let user = userData {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile header
                            profileHeader(user)

                            // Account info card
                            accountInfoCard(user)

                            // Account card (schools and districts)
                            if user.role == "school" {
                                subscriptionCard(user)
                            }
                            if user.role == "district" {
                                districtSubscriptionCard(user)
                            }

                            // Quick actions
                            quickActionsSection(user)

                            // Support section
                            supportSection

                            // Sign out
                            signOutButton
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "Unable to Load",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("Could not load account information.")
                    )
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showSubscription) {
                if let user = userData {
                    SubscriptionView(userData: user)
                }
            }
            .sheet(isPresented: $showDistrictSubscription) {
                DistrictSubscriptionView()
            }
            .sheet(isPresented: $showSupport) {
                SupportView()
            }
            .onAppear(perform: loadUserData)
        }
    }

    // MARK: - Profile Header
    private func profileHeader(_ user: UserAccountData) -> some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(EZTeachColors.primaryGradient)
                    .frame(width: 100, height: 100)

                Text(user.initials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.title2.bold())

                HStack(spacing: 6) {
                    Image(systemName: roleIcon(user.role))
                        .font(.caption)
                    Text(user.role.capitalized)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(EZTeachColors.cardFill)
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Account Info Card
    private func accountInfoCard(_ user: UserAccountData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Account Details", systemImage: "person.text.rectangle")
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            infoRow(icon: "envelope", label: "Email", value: user.email)

            if !user.schoolName.isEmpty {
                infoRow(icon: "building.2", label: "Active School", value: user.schoolName)
            }

            infoRow(icon: "calendar", label: "Member Since", value: user.memberSince)
        }
        .padding(20)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(16)
    }

    // MARK: - Account Card (App Store compliant: no prices, neutral language)
    private func subscriptionCard(_ user: UserAccountData) -> some View {
        Button {
            showSubscription = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundStyle(EZTeachColors.premiumGradient)
                            Text("Account")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        Text(user.subscriptionStatus)
                            .font(.subheadline)
                            .foregroundColor(user.isSubscribed ? EZTeachColors.success : .secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }

                if user.isSubscribed {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(EZTeachColors.success)
                        Text("Next billing: \(user.nextBillingDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    Text("Exclusive features available on our website")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Spacer()
                    Text("Manage Account")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(EZTeachColors.accentGradient)
                        .cornerRadius(10)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EZTeachColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EZTeachColors.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions
    private func quickActionsSection(_ user: UserAccountData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .padding(.leading, 4)

            VStack(spacing: 2) {
                actionButton(icon: "bell", title: "Notifications", subtitle: "Manage alerts") {
                    // TODO: Notifications settings
                }

                actionButton(icon: "lock", title: "Privacy & Security", subtitle: "Password & data") {
                    // TODO: Privacy settings
                }

                if user.role != "school" {
                    actionButton(icon: "building.2", title: "My Schools", subtitle: "\(user.joinedSchoolsCount) school(s)") {
                        // TODO: Navigate to schools
                    }
                }
            }
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Help & Support")
                .font(.headline)
                .padding(.leading, 4)

            VStack(spacing: 2) {
                actionButton(icon: "questionmark.circle", title: "Help Center", subtitle: "FAQs and guides") {
                    showSupport = true
                }

                actionButton(icon: "message", title: "Contact Support", subtitle: "Get help from our team") {
                    showSupport = true
                }

                actionButton(icon: "exclamationmark.bubble", title: "Report an Issue", subtitle: "Submit a claim") {
                    showSupport = true
                }
            }
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button {
            try? Auth.auth().signOut()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.headline)
            .foregroundColor(EZTeachColors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(EZTeachColors.error.opacity(0.1))
            .cornerRadius(14)
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Views
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(EZTeachColors.accent)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    private func actionButton(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 32)
                    .foregroundColor(EZTeachColors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
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
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func roleIcon(_ role: String) -> String {
        switch role {
        case "school": return "building.columns.fill"
        case "district": return "building.2.fill"
        case "teacher": return "person.fill"
        case "sub": return "person.badge.clock.fill"
        default: return "person.fill"
        }
    }

    // MARK: - District Account Card (App Store compliant)
    private func districtSubscriptionCard(_ user: UserAccountData) -> some View {
        Button {
            showDistrictSubscription = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "building.2.crop.circle.fill")
                                .foregroundStyle(EZTeachColors.premiumGradient)
                            Text("District Account")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Text(user.subscriptionStatus)
                            .font(.subheadline)
                            .foregroundColor(user.isSubscribed ? EZTeachColors.success : .secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
                HStack {
                    Spacer()
                    Text("Manage Account")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(EZTeachColors.accentGradient)
                        .cornerRadius(10)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EZTeachColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EZTeachColors.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Load Data
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else {
            isLoading = false
            return
        }

        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else {
                isLoading = false
                return
            }

            let role = data["role"] as? String ?? ""
            let firstName = data["firstName"] as? String ?? ""
            let lastName = data["lastName"] as? String ?? ""
            let schoolName = data["schoolName"] as? String ?? ""
            let joinedSchools = data["joinedSchools"] as? [[String: String]] ?? []
            let activeSchoolId = data["activeSchoolId"] as? String
            let districtId = data["districtId"] as? String

            // Get creation date
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            let memberSince = formatter.string(from: createdAt)

            // Subscription: for school role read from school doc; for district from district doc
            let isSubscribed = data["subscriptionActive"] as? Bool ?? false
            var subscriptionEnd: Date?

            if role == "school", let sid = activeSchoolId {
                db.collection("schools").document(sid).getDocument { schoolSnap, _ in
                    let schoolData = schoolSnap?.data()
                    let subActive = schoolData?["subscriptionActive"] as? Bool ?? false
                    let subEnd = (schoolData?["subscriptionEndDate"] as? Timestamp)?.dateValue()
                    finishLoadUserData(email: email, role: role, firstName: firstName, lastName: lastName, schoolName: schoolName, joinedSchools: joinedSchools, activeSchoolId: activeSchoolId, memberSince: memberSince, isSubscribed: subActive, subscriptionEnd: subEnd)
                }
            } else if role == "district", let did = districtId {
                db.collection("districts").document(did).getDocument { districtSnap, _ in
                    let districtData = districtSnap?.data()
                    let subActive = districtData?["subscriptionActive"] as? Bool ?? false
                    let subEnd = (districtData?["subscriptionEndDate"] as? Timestamp)?.dateValue()
                    finishLoadUserData(email: email, role: role, firstName: firstName, lastName: lastName, schoolName: schoolName, joinedSchools: joinedSchools, activeSchoolId: activeSchoolId, memberSince: memberSince, isSubscribed: subActive, subscriptionEnd: subEnd)
                }
            } else {
                subscriptionEnd = (data["subscriptionEndDate"] as? Timestamp)?.dateValue()
                finishLoadUserData(email: email, role: role, firstName: firstName, lastName: lastName, schoolName: schoolName, joinedSchools: joinedSchools, activeSchoolId: activeSchoolId, memberSince: memberSince, isSubscribed: isSubscribed, subscriptionEnd: subscriptionEnd)
            }
        }
    }

    private func finishLoadUserData(email: String, role: String, firstName: String, lastName: String, schoolName: String, joinedSchools: [[String: String]], activeSchoolId: String?, memberSince: String, isSubscribed: Bool, subscriptionEnd: Date?) {
        let nextBillingFormatter = DateFormatter()
        nextBillingFormatter.dateFormat = "MMM d, yyyy"
        let nextBilling = subscriptionEnd != nil ? nextBillingFormatter.string(from: subscriptionEnd!) : "N/A"

        var displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        if displayName.isEmpty {
            displayName = schoolName.isEmpty ? "User" : schoolName
        }

        let initials: String
        if !firstName.isEmpty && !lastName.isEmpty {
            initials = "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
        } else if !schoolName.isEmpty {
            initials = String(schoolName.prefix(2)).uppercased()
        } else {
            initials = "U"
        }

        userData = UserAccountData(
            email: email,
            role: role,
            displayName: displayName,
            initials: initials,
            schoolName: schoolName,
            activeSchoolId: activeSchoolId,
            memberSince: memberSince,
            joinedSchoolsCount: joinedSchools.count,
            isSubscribed: isSubscribed,
            subscriptionStatus: isSubscribed ? "Active" : "Inactive",
            nextBillingDate: nextBilling
        )
        isLoading = false
    }
}

// MARK: - User Account Data Model
struct UserAccountData {
    let email: String
    let role: String
    let displayName: String
    let initials: String
    let schoolName: String
    let activeSchoolId: String?
    let memberSince: String
    let joinedSchoolsCount: Int
    let isSubscribed: Bool
    let subscriptionStatus: String
    let nextBillingDate: String
}
