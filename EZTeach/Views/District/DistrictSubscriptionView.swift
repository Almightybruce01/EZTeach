//
//  DistrictSubscriptionView.swift
//  EZTeach
//
//  Districts add schools, pick a plan tier (S/M1/M2/L/XL/ENT) for each,
//  and pay the sum of all school tiers. Same pricing as individual schools.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct DistrictSubscriptionView: View {

    @State private var existingDistrictId: String?
    @State private var existingDistrictName = ""
    @State private var districtSchools: [DistrictSchoolItem] = []
    @State private var isLoadingExisting = true

    @State private var districtName = ""
    @State private var validatedSchools: [ValidatedSchool] = []
    @State private var linkCode = ""
    @State private var linkError = ""
    @State private var isAddingByCode = false
    @State private var showCreateSchool = false

    // Per-school tier selection
    @State private var schoolTierSelections: [String: String] = [:]  // schoolId → tier key
    @State private var billingInterval = "monthly"  // "monthly" or "yearly"

    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var currentStep = 1
    @State private var districtId: String?

    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    private let fs = FirestoreService.shared
    private let tiers = FirestoreService.schoolTiers

    // Computed totals
    private var monthlyTotal: Double {
        schoolTierSelections.values.compactMap { key in
            tiers.first(where: { $0.tier == key })
        }.reduce(0.0) { $0 + Double($1.price) }
    }

    private var yearlyTotal: Double { monthlyTotal * 10 }  // save ~17%

    private var hasExistingDistrict: Bool { existingDistrictId != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                if isLoadingExisting {
                    ProgressView("Loading...")
                } else if hasExistingDistrict {
                    districtManageSchoolsView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            progressIndicator
                            switch currentStep {
                            case 1: step1_DistrictInfo
                            case 2: step2_SchoolSelection
                            case 3: step3_TierSelection
                            default: EmptyView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(hasExistingDistrict ? "Manage Schools" : "District Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("District Created!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your district account is set up with \(validatedSchools.count) school(s). Contact ezteach0@gmail.com to activate all schools.")
            }
        }
        .onAppear { loadExistingDistrict() }
    }

    // MARK: - Existing District: Manage Schools
    private var districtManageSchoolsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(EZTeachColors.premiumGradient)
                    Text(existingDistrictName)
                        .font(.title2.bold())
                    Text("Add or remove schools in your district.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                Button {
                    if let url = URL(string: "https://ezteach.org") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Manage Account", systemImage: "safari")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(EZTeachColors.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Link existing by code
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link existing school")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 12) {
                        TextField("6-digit code", text: $linkCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(EZTeachColors.secondaryBackground)
                            .cornerRadius(10)
                            .onChange(of: linkCode) { _, v in
                                linkCode = String(v.prefix(6).filter { $0.isNumber })
                                linkError = ""
                            }
                        Button {
                            addSchoolToExistingDistrict()
                        } label: {
                            if isAddingByCode {
                                ProgressView().scaleEffect(0.9).frame(width: 44, height: 44)
                            } else {
                                Text("Add").fontWeight(.semibold).frame(width: 44, height: 44)
                            }
                        }
                        .disabled(linkCode.count != 6 || isAddingByCode)
                        .background(EZTeachColors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    if !linkError.isEmpty {
                        Text(linkError).font(.caption).foregroundColor(EZTeachColors.error)
                    }
                }

                Button {
                    showCreateSchool = true
                } label: {
                    Label("Create new school", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(12)
                }

                if !districtSchools.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schools (\(districtSchools.count))")
                            .font(.subheadline.weight(.medium))

                        // Totals
                        let totalMonthly = districtSchools.compactMap { s in
                            tiers.first(where: { $0.tier == s.planTier })
                        }.reduce(0) { $0 + $1.price }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Monthly Total").font(.caption).foregroundColor(.secondary)
                                Text("$\(totalMonthly)/mo").font(.title2.bold())
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Yearly Total").font(.caption).foregroundColor(.secondary)
                                Text("$\(totalMonthly * 10)/yr").font(.headline).foregroundColor(EZTeachColors.accent)
                            }
                        }
                        .padding(12)
                        .background(EZTeachColors.accent.opacity(0.08))
                        .cornerRadius(10)

                        ForEach(districtSchools) { school in
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(EZTeachColors.success)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(school.name).font(.subheadline.weight(.medium))
                                    HStack(spacing: 8) {
                                        if !school.city.isEmpty {
                                            Text(school.city).font(.caption).foregroundColor(.secondary)
                                        }
                                        Text("\(school.studentCount) students")
                                            .font(.caption.bold())
                                            .foregroundColor(EZTeachColors.accent)
                                        if let tier = tiers.first(where: { $0.tier == school.planTier }) {
                                            Text(tier.label)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                                if let tier = tiers.first(where: { $0.tier == school.planTier }) {
                                    Text(tier.label)
                                        .font(.caption.bold())
                                        .foregroundColor(EZTeachColors.accent)
                                }
                            }
                            .padding(12)
                            .background(EZTeachColors.secondaryBackground)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showCreateSchool) {
            CreateSchoolForDistrictSheet(districtId: districtId) { school in
                Functions.functions().httpsCallable("districtAddSchoolById").call(["schoolId": school.id]) { _, _ in
                    loadExistingDistrict()
                }
            }
        }
    }

    private func loadExistingDistrict() {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoadingExisting = false
            return
        }
        db.collection("users").document(uid).getDocument { snap, _ in
            let did = snap?.data()?["districtId"] as? String
            guard let districtId = did, !districtId.isEmpty else {
                isLoadingExisting = false
                return
            }
            self.districtId = districtId
            existingDistrictId = districtId
            db.collection("districts").document(districtId).getDocument { dSnap, _ in
                existingDistrictName = dSnap?.data()?["name"] as? String ?? "District"
                let ids = dSnap?.data()?["schoolIds"] as? [String] ?? []
                guard !ids.isEmpty else {
                    districtSchools = []
                    isLoadingExisting = false
                    return
                }
                var results = [String: DistrictSchoolItem]()
                let total = ids.count
                for id in ids {
                    db.collection("schools").document(id).getDocument { sSnap, _ in
                        let d = sSnap?.data()
                        let item = DistrictSchoolItem(
                            id: id,
                            name: d?["name"] as? String ?? "School",
                            city: d?["city"] as? String ?? "",
                            studentCount: d?["studentCount"] as? Int ?? 0,
                            studentCap: d?["studentCap"] as? Int ?? 200,
                            planTier: d?["planTier"] as? String ?? "S"
                        )
                        DispatchQueue.main.async {
                            results[id] = item
                            if results.count == total {
                                districtSchools = ids.compactMap { results[$0] }
                                isLoadingExisting = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func addSchoolToExistingDistrict() {
        guard existingDistrictId != nil, linkCode.count == 6 else { return }
        isAddingByCode = true
        linkError = ""
        let functions = Functions.functions()
        functions.httpsCallable("districtAddSchool").call(["schoolCode": linkCode]) { result, error in
            isAddingByCode = false
            if let err = error as NSError? {
                linkError = (err.userInfo["NSLocalizedDescription"] as? String) ?? err.localizedDescription
                return
            }
            linkCode = ""
            loadExistingDistrict()
        }
    }

    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 0) {
            ForEach(1...3, id: \.self) { step in
                HStack(spacing: 0) {
                    Circle()
                        .fill(step <= currentStep ? EZTeachColors.accent : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(.caption.bold())
                                .foregroundColor(step <= currentStep ? .white : .gray)
                        )

                    if step < 3 {
                        Rectangle()
                            .fill(step < currentStep ? EZTeachColors.accent : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 1: District Info
    private var step1_DistrictInfo: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(EZTeachColors.premiumGradient)

                Text("District Account")
                    .font(.title2.bold())

                Text("Manage multiple schools under one account.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("District Name")
                    .font(.subheadline.weight(.medium))

                TextField("Enter district name", text: $districtName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(12)
            }

            Text("Next, you'll add schools and pick a plan tier for each.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                currentStep = 2
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(districtName.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(EZTeachColors.accentGradient))
                    .foregroundColor(districtName.isEmpty ? .secondary : .white)
                    .cornerRadius(14)
            }
            .disabled(districtName.isEmpty)
        }
    }

    // MARK: - Step 2: Add Schools
    private var step2_SchoolSelection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 48))
                    .foregroundColor(EZTeachColors.accent)

                Text("Add Your Schools")
                    .font(.title2.bold())

                Text("Link existing schools by code, or create new ones.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Link existing by code
            VStack(alignment: .leading, spacing: 8) {
                Text("Link existing school")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 12) {
                    TextField("6-digit code", text: $linkCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(10)
                        .onChange(of: linkCode) { _, v in
                            linkCode = String(v.prefix(6).filter { $0.isNumber })
                            linkError = ""
                        }
                    Button {
                        addSchoolByCode()
                    } label: {
                        if isAddingByCode {
                            ProgressView().scaleEffect(0.9).frame(width: 44, height: 44)
                        } else {
                            Text("Add").fontWeight(.semibold).frame(width: 44, height: 44)
                        }
                    }
                    .disabled(linkCode.count != 6 || isAddingByCode)
                    .background(EZTeachColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                if !linkError.isEmpty {
                    Text(linkError).font(.caption).foregroundColor(EZTeachColors.error)
                }
            }

            Button {
                showCreateSchool = true
            } label: {
                Label("Create new school", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(12)
            }

            if !validatedSchools.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schools (\(validatedSchools.count))")
                        .font(.subheadline.weight(.medium))
                    ForEach(validatedSchools) { school in
                        HStack {
                            Image(systemName: school.exists ? "building.2.fill" : "plus.circle.fill")
                                .foregroundColor(school.exists ? EZTeachColors.success : EZTeachColors.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(school.name).font(.subheadline.weight(.medium))
                                Text(school.exists ? "Linked" : "Created")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                validatedSchools.removeAll { $0.id == school.id }
                                schoolTierSelections.removeValue(forKey: school.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(EZTeachColors.secondaryBackground)
                        .cornerRadius(10)
                    }
                }
            }

            HStack(spacing: 16) {
                Button {
                    currentStep = 1
                    linkError = ""
                } label: {
                    Text("Back")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }

                Button {
                    // Default all schools to "S" tier if not yet selected
                    for school in validatedSchools {
                        if schoolTierSelections[school.id] == nil {
                            schoolTierSelections[school.id] = "S"
                        }
                    }
                    currentStep = 3
                } label: {
                    Text("Choose Plans")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(validatedSchools.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(EZTeachColors.accentGradient))
                        .foregroundColor(validatedSchools.isEmpty ? .secondary : .white)
                        .cornerRadius(12)
                }
                .disabled(validatedSchools.isEmpty)
            }
        }
        .sheet(isPresented: $showCreateSchool) {
            CreateSchoolForDistrictSheet(districtId: districtId) { school in
                validatedSchools.append(school)
            }
        }
        .onAppear { loadDistrictId() }
    }

    private func loadDistrictId() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snap, _ in
            if let did = snap?.data()?["districtId"] as? String {
                districtId = did
            }
        }
    }

    private func addSchoolByCode() {
        let code = linkCode.trimmingCharacters(in: .whitespaces)
        guard code.count == 6 else { return }
        isAddingByCode = true
        linkError = ""
        Task {
            do {
                guard let result = try await fs.lookupSchoolByCode(code) else {
                    await MainActor.run {
                        linkError = "No school with this code. Create new instead?"
                        isAddingByCode = false
                    }
                    return
                }
                if let did = result.districtId, !did.isEmpty {
                    await MainActor.run {
                        linkError = "School is already in another district."
                        isAddingByCode = false
                    }
                    return
                }
                if validatedSchools.contains(where: { $0.id == result.id }) {
                    await MainActor.run {
                        linkError = "Already added."
                        isAddingByCode = false
                    }
                    return
                }
                let v = ValidatedSchool(id: result.id, code: code, name: result.name, exists: true)
                await MainActor.run {
                    validatedSchools.append(v)
                    linkCode = ""
                    linkError = ""
                    isAddingByCode = false
                }
            } catch {
                await MainActor.run {
                    linkError = "Lookup failed. Try again."
                    isAddingByCode = false
                }
            }
        }
    }

    // MARK: - Step 3: Tier Selection + Checkout
    private var step3_TierSelection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 48))
                    .foregroundColor(EZTeachColors.accent)

                Text("Choose a Plan for Each School")
                    .font(.title2.bold())

                Text("Pick a tier based on each school's size. All features included in every tier — tiers only differ by student cap.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Billing toggle
            Picker("Billing", selection: $billingInterval) {
                Text("Monthly").tag("monthly")
                Text("Yearly (save ~17%)").tag("yearly")
            }
            .pickerStyle(.segmented)

            // Per-school tier picker
            ForEach(validatedSchools) { school in
                VStack(alignment: .leading, spacing: 8) {
                    Text(school.name)
                        .font(.subheadline.bold())

                    Picker("Tier for \(school.name)", selection: Binding(
                        get: { schoolTierSelections[school.id] ?? "S" },
                        set: { schoolTierSelections[school.id] = $0 }
                    )) {
                        ForEach(tiers, id: \.tier) { t in
                            HStack {
                                Text("\(t.label)")
                                Spacer()
                                Text("Up to \(t.cap) students")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(t.tier)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(10)

                    // Show selected tier details
                    if let key = schoolTierSelections[school.id],
                       let tier = tiers.first(where: { $0.tier == key }) {
                        HStack {
                            Text("Up to \(tier.cap) students")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(tier.label)
                                .font(.caption.bold())
                                .foregroundColor(EZTeachColors.accent)
                        }
                    }
                }
                .padding()
                .background(EZTeachColors.secondaryBackground.opacity(0.5))
                .cornerRadius(12)
            }

            // Summary
            VStack(spacing: 12) {
                Divider()

                HStack {
                    Text("District Summary")
                        .font(.headline)
                    Spacer()
                }

                Text("\(validatedSchools.count) school\(validatedSchools.count == 1 ? "" : "s") • All features included")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Setup notice
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(EZTeachColors.accent)
                    Text("District Setup")
                        .font(.subheadline.weight(.medium))
                }

                Text("Your district account will be set up with the selected schools and tiers. Contact us at ezteach0@gmail.com to finalize your district plan.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)

            // Navigation
            HStack(spacing: 16) {
                Button {
                    currentStep = 2
                } label: {
                    Text("Back")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }

                Button {
                    completeSetup()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Setup")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(EZTeachColors.accentGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func completeSetup() {

        savePendingSubscription()
    }

    private func savePendingSubscription() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let schoolEntries: [[String: Any]] = validatedSchools.compactMap { school in
            guard let tier = schoolTierSelections[school.id] else { return nil }
            let tierInfo = tiers.first(where: { $0.tier == tier })
            return [
                "schoolId": school.id,
                "schoolName": school.name,
                "tier": tier,
                "monthlyPrice": tierInfo?.price ?? 129,
                "studentCap": tierInfo?.cap ?? 200
            ]
        }

        let pendingData: [String: Any] = [
            "userId": uid,
            "districtName": districtName,
            "schools": schoolEntries,
            "billingInterval": billingInterval,
            "monthlyTotal": monthlyTotal,
            "yearlyTotal": yearlyTotal,
            "status": "pending_activation",
            "createdAt": Timestamp(),
            "expiresAt": Timestamp(date: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date())
        ]

        db.collection("pendingDistrictSubscriptions").addDocument(data: pendingData)
    }
}

// MARK: - District School Item (for manage view)
struct DistrictSchoolItem: Identifiable {
    let id: String
    let name: String
    let city: String
    var studentCount: Int = 0
    var studentCap: Int = 200
    var planTier: String = "S"
}

// MARK: - Helper Model
struct ValidatedSchool: Identifiable {
    let id: String
    let code: String
    let name: String
    let exists: Bool
}

// MARK: - Create School for District Sheet
struct CreateSchoolForDistrictSheet: View {
    let districtId: String?
    let onDone: (ValidatedSchool) -> Void

    @State private var name = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var adminFirstName = ""
    @State private var adminLastName = ""
    @State private var adminEmail = ""
    @State private var adminPassword = ""
    @State private var adminConfirmPassword = ""
    @State private var schoolCode = ""
    @State private var approximateStudents = ""
    @State private var isSaving = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    private let fs = FirestoreService.shared

    private func finish(_ v: ValidatedSchool) {
        onDone(v)
        dismiss()
    }

    private var canCreate: Bool {
        !name.isEmpty && !address.isEmpty && !city.isEmpty && !state.isEmpty &&
        zip.count >= 5 && !adminFirstName.isEmpty && !adminLastName.isEmpty &&
        !adminEmail.isEmpty && adminPassword.count >= 6 && adminPassword == adminConfirmPassword &&
        schoolCode.count == 6
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("School details") {
                    TextField("School Name", text: $name)
                    TextField("Street Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zip)
                        .keyboardType(.numberPad)
                        .onChange(of: zip) { _, v in zip = String(v.prefix(5).filter { $0.isNumber }) }
                    TextField("6-Digit School Code", text: $schoolCode)
                        .keyboardType(.numberPad)
                        .onChange(of: schoolCode) { _, v in schoolCode = String(v.prefix(6).filter { $0.isNumber }) }
                    // Student count tracked automatically as students are added
                }
                Section("School admin (login for this school)") {
                    TextField("First Name", text: $adminFirstName)
                    TextField("Last Name", text: $adminLastName)
                    TextField("Email", text: $adminEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $adminPassword)
                    SecureField("Confirm Password", text: $adminConfirmPassword)
                }
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(EZTeachColors.error)
                    }
                }
            }
            .navigationTitle("Create school")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { save() }
                        .disabled(!canCreate || isSaving)
                }
            }
        }
    }

    private func save() {
        guard canCreate else { return }
        isSaving = true
        errorMessage = ""
        Task {
            do {
                let (id, code, createdName) = try await fs.createSchoolForDistrict(
                    name: name.trimmingCharacters(in: .whitespaces),
                    address: address.trimmingCharacters(in: .whitespaces),
                    city: city.trimmingCharacters(in: .whitespaces),
                    state: state.trimmingCharacters(in: .whitespaces),
                    zip: zip.trimmingCharacters(in: .whitespaces),
                    schoolCode: schoolCode,
                    adminEmail: adminEmail.trimmingCharacters(in: .whitespaces),
                    adminPassword: adminPassword,
                    adminFirstName: adminFirstName.trimmingCharacters(in: .whitespaces),
                    adminLastName: adminLastName.trimmingCharacters(in: .whitespaces),
                    approximateStudents: Int(approximateStudents) ?? 0
                )
                await MainActor.run {
                    isSaving = false
                    finish(ValidatedSchool(id: id, code: code, name: createdName, exists: false))
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
