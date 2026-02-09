//
//  DistrictSubscriptionView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
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

    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var currentStep = 1
    @State private var districtId: String?
    @State private var selectedSchoolsForBilling: Set<String> = []
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    private let fs = FirestoreService.shared
    
    private var numberOfSchools: Int { selectedSchoolsForBilling.count }
    
    // Pricing from selected schools only (for billing)
    private var pricing: (tier: District.SubscriptionTier, pricePerSchool: Double, total: Double) {
        District.calculatePrice(schoolCount: max(1, numberOfSchools))
    }
    
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
                            case 3: step3_Payment
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
            .alert("Subscription Activated!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your district subscription is now active. All \(numberOfSchools) schools are covered!")
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
                        // Total students across all schools
                let totalStudents = districtSchools.reduce(0) { $0 + $1.studentCount }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Students").font(.caption).foregroundColor(.secondary)
                        Text("\(totalStudents)").font(.title2.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Per-Student Rate").font(.caption).foregroundColor(.secondary)
                        let rate = District.calculateStudentPrice(totalStudents: max(totalStudents, 3000))
                        Text("$\(Int(rate.pricePerStudent))/student/yr").font(.headline).foregroundColor(EZTeachColors.accent)
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
                                        Text("(cap: \(school.studentCap))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Button {
                                    removeSchoolFromDistrict(school.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
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

    private func removeSchoolFromDistrict(_ schoolId: String) {
        let functions = Functions.functions()
        functions.httpsCallable("districtRemoveSchool").call(["schoolId": schoolId]) { _, _ in
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
            // Header
            VStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(EZTeachColors.premiumGradient)
                
                Text("District Account")
                    .font(.title2.bold())
                
                Text("Manage multiple schools under one account. Exclusive features on our website.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // District name
            VStack(alignment: .leading, spacing: 8) {
                Text("District Name")
                    .font(.subheadline.weight(.medium))
                
                TextField("Enter district name", text: $districtName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(12)
            }
            
            Text("Next, you’ll add schools (link existing or create new), then pay for your subscription.")
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
    
    // MARK: - Step 2: Add Schools First (link or create)
    private var step2_SchoolSelection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 48))
                    .foregroundColor(EZTeachColors.accent)
                
                Text("Add Your Schools")
                    .font(.title2.bold())
                
                Text("Link existing schools by code, or create new ones. Complete setup on our website.")
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
                            ProgressView()
                                .scaleEffect(0.9)
                                .frame(width: 44, height: 44)
                        } else {
                            Text("Add")
                                .fontWeight(.semibold)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .disabled(linkCode.count != 6 || isAddingByCode)
                    .background(EZTeachColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                if !linkError.isEmpty {
                    Text(linkError)
                        .font(.caption)
                        .foregroundColor(EZTeachColors.error)
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
                                Text(school.name)
                                    .font(.subheadline.weight(.medium))
                                Text(school.exists ? "Linked" : "Created")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                validatedSchools.removeAll { $0.id == school.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
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
                    // Pre-select all schools for billing when moving to payment
                    selectedSchoolsForBilling = Set(validatedSchools.map { $0.id })
                    currentStep = 3
                } label: {
                    Text("Continue to payment")
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
    
    // MARK: - Step 3: Payment & School Selection
    private var step3_Payment: some View {
        VStack(spacing: 24) {
            // Important billing notice
            billingNoticeCard
            
            // School selection for billing
            schoolBillingSelection
            
            // Summary card
            VStack(spacing: 16) {
                HStack {
                    Text("Billing Summary")
                        .font(.headline)
                    Spacer()
                    if numberOfSchools > 0 {
                        Text("\(numberOfSchools) school\(numberOfSchools == 1 ? "" : "s") selected")
                            .font(.caption)
                            .foregroundColor(EZTeachColors.success)
                    }
                }
                
                Divider()
                
                VStack(spacing: 12) {
                    summaryRow(label: "District", value: districtName)
                    summaryRow(label: "Schools to Bill", value: "\(numberOfSchools)")
                }

                if numberOfSchools > 0 {
                    Divider()

                    VStack(spacing: 8) {
                        Text("Option A — Per-School/Year")
                            .font(.subheadline.bold())
                        let perSchool = District.calculatePerSchoolPrice(schoolCount: numberOfSchools)
                        Text("$\(Int(perSchool.annualTotal))/year")
                            .font(.title3.bold())
                            .foregroundStyle(EZTeachColors.primaryGradient)
                        Text("$2,750/school/year (\(numberOfSchools) schools, up to 750 students each)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(spacing: 8) {
                        Text("Option B — Per-Student/Year")
                            .font(.subheadline.bold())
                        Text("$8–$12/student/year based on total district enrollment")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            priceRow("3,000–7,500 students", "$12/student")
                            priceRow("7,501–15,000 students", "$11/student")
                            priceRow("15,001–30,000 students", "$10/student")
                            priceRow("30,001–60,000 students", "$9/student")
                            priceRow("60,000+ students", "$8/student")
                        }
                        .font(.caption)
                    }

                    Text("Contact ezteach0@gmail.com to finalize district pricing.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
            
            // Website checkout info
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.orange)
                    Text("Secure Payment via Website")
                        .font(.subheadline.weight(.medium))
                }
                
                Text("For security, all payments are processed through our website using Stripe. You will NOT be charged for schools you don't select.")
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
                    proceedToStripeCheckout()
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Checkout on Website")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(numberOfSchools == 0 ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(EZTeachColors.accentGradient))
                    .foregroundColor(numberOfSchools == 0 ? .secondary : .white)
                    .cornerRadius(12)
                }
                .disabled(numberOfSchools == 0)
            }
            
            Text("You will be redirected to ezteach.org to complete payment securely via Stripe.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Billing Notice Card
    private var billingNoticeCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transparent Billing")
                        .font(.headline)
                    Text("Only pay for schools you select below")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(selectedSchoolsForBilling.count)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(validatedSchools.count)")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    // Select all
                    selectedSchoolsForBilling = Set(validatedSchools.map { $0.id })
                } label: {
                    Text("Select All")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.accent)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - School Billing Selection
    private var schoolBillingSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Schools to Include in Billing")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if !selectedSchoolsForBilling.isEmpty {
                    Button {
                        selectedSchoolsForBilling.removeAll()
                    } label: {
                        Text("Deselect All")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if validatedSchools.isEmpty {
                Text("No schools added yet. Go back to add schools.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(validatedSchools) { school in
                    Button {
                        toggleSchoolSelection(school.id)
                    } label: {
                        HStack {
                            Image(systemName: selectedSchoolsForBilling.contains(school.id) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedSchoolsForBilling.contains(school.id) ? EZTeachColors.success : .gray)
                                .font(.title3)
                            
                            Image(systemName: school.exists ? "building.2.fill" : "plus.circle.fill")
                                .foregroundColor(school.exists ? EZTeachColors.accent : EZTeachColors.success)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(school.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                                Text(school.exists ? "Existing School" : "New School")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedSchoolsForBilling.contains(school.id) {
                                Text("$2,750/yr")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedSchoolsForBilling.contains(school.id) ? Color.green.opacity(0.1) : EZTeachColors.secondaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedSchoolsForBilling.contains(school.id) ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                }
            }
            
            // Warning about unselected schools
            if !selectedSchoolsForBilling.isEmpty && selectedSchoolsForBilling.count < validatedSchools.count {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("Unselected schools will NOT have premium features until added to billing.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private func toggleSchoolSelection(_ schoolId: String) {
        if selectedSchoolsForBilling.contains(schoolId) {
            selectedSchoolsForBilling.remove(schoolId)
        } else {
            selectedSchoolsForBilling.insert(schoolId)
        }
    }
    
    private func proceedToStripeCheckout() {
        guard !selectedSchoolsForBilling.isEmpty else { return }
        
        // Build URL with selected school IDs for Stripe checkout
        let schoolIds = Array(selectedSchoolsForBilling).joined(separator: ",")
        let encodedDistrict = districtName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let checkoutUrl = "https://ezteach.org/checkout/district?name=\(encodedDistrict)&schools=\(schoolIds)&count=\(selectedSchoolsForBilling.count)"
        
        if let url = URL(string: checkoutUrl) {
            UIApplication.shared.open(url)
        }
        
        // Also save the pending subscription to Firestore for tracking
        savePendingSubscription()
    }
    
    private func savePendingSubscription() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let selectedSchoolsList = validatedSchools.filter { selectedSchoolsForBilling.contains($0.id) }
        
        let pendingData: [String: Any] = [
            "userId": uid,
            "districtName": districtName,
            "selectedSchoolIds": Array(selectedSchoolsForBilling),
            "selectedSchoolNames": selectedSchoolsList.map { $0.name },
            "numberOfSchools": selectedSchoolsForBilling.count,
            "pricingTier": pricing.tier.rawValue,
            "pricePerSchool": pricing.pricePerSchool,
            "totalMonthlyPrice": pricing.total,
            "status": "pending_payment",
            "createdAt": Timestamp(),
            "expiresAt": Timestamp(date: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date())
        ]
        
        db.collection("pendingDistrictSubscriptions").addDocument(data: pendingData)
    }
    
    private func openDistrictWebsite() {
        guard let url = URL(string: "https://ezteach.org") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Helper Views
    private var pricingCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per-School Annual")
                        .font(.caption.bold())
                        .foregroundColor(EZTeachColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(EZTeachColors.accent.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text("\(numberOfSchools) school\(numberOfSchools == 1 ? "" : "s") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("$2,750")
                            .font(.title.bold())
                        Text("/school/yr")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Text("Annual Total")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "$%,.0f/yr", 2750.0 * Double(numberOfSchools)))
                    .font(.title2.bold())
                    .foregroundStyle(EZTeachColors.primaryGradient)
            }
            
            Text("All features included • Up to 750 students per school")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(EZTeachColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(EZTeachColors.gold.opacity(0.5), lineWidth: 2)
                )
        )
    }
    
    private var volumeDiscountInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("District Annual Pricing")
                .font(.subheadline.weight(.medium))
            
            VStack(spacing: 8) {
                districtTierRow(label: "3,000–7,500 students", price: "$12/student/year")
                districtTierRow(label: "7,501–15,000 students", price: "$11/student/year")
                districtTierRow(label: "15,001–30,000 students", price: "$10/student/year")
                districtTierRow(label: "30,001–60,000 students", price: "$9/student/year")
                districtTierRow(label: "60,000+ students", price: "$8/student/year")
                
                Divider().padding(.vertical, 4)
                
                districtTierRow(label: "Per-School Option", price: "$2,750/school/year")
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func districtTierRow(label: String, price: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(price)
                .font(.caption.bold())
                .foregroundColor(EZTeachColors.accent)
        }
        .padding(.vertical, 4)
    }
    
    private func priceRow(_ range: String, _ price: String) -> some View {
        HStack {
            Text(range).foregroundColor(.secondary)
            Spacer()
            Text(price).fontWeight(.semibold).foregroundColor(EZTeachColors.accent)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
    
    // MARK: - Actions
    private func processDistrictSubscription() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isProcessing = true
        errorMessage = ""
        
        // Create district document
        let districtRef = db.collection("districts").document()
        let nextBilling = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        let schoolIds = validatedSchools.map { $0.id }
        
        let districtData: [String: Any] = [
            "name": districtName,
            "ownerUid": uid,
            "schoolIds": schoolIds,
            "subscriptionActive": true,
            "subscriptionTier": pricing.tier.rawValue,
            "maxSchools": numberOfSchools,
            "pricePerSchool": pricing.pricePerSchool,
            "totalMonthlyPrice": pricing.total,
            "subscriptionStartDate": Timestamp(),
            "subscriptionEndDate": Timestamp(date: nextBilling),
            "paymentMethod": "card",
            "createdAt": Timestamp()
        ]
        
        districtRef.setData(districtData) { error in
            isProcessing = false
            if let error = error {
                errorMessage = "Failed to create district: \(error.localizedDescription)"
                return
            }
            // Cloud Function onDistrictCreated links schools + user. No client-side batch.
            showSuccess = true
        }
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
                    adminLastName: adminLastName.trimmingCharacters(in: .whitespaces)
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
