//
//  DistrictSubscriptionView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DistrictSubscriptionView: View {
    
    @State private var districtName = ""
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var validatedSchools: [ValidatedSchool] = []
    @State private var linkCode = ""
    @State private var linkError = ""
    @State private var isAddingByCode = false
    @State private var showCreateSchool = false
    
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var currentStep = 1
    
    @Environment(\.dismiss) private var dismiss
    private let db = Firestore.firestore()
    private let fs = FirestoreService.shared
    
    private var numberOfSchools: Int { validatedSchools.count }
    
    // Pricing from chosen schools only
    private var pricing: (tier: District.SubscriptionTier, pricePerSchool: Double, total: Double) {
        District.calculatePrice(schoolCount: max(1, numberOfSchools))
    }
    
    enum PaymentMethod: String, CaseIterable, Identifiable {
        case applePay = "Apple Pay"
        case card = "Credit/Debit Card"
        case paypal = "PayPal"
        case bankTransfer = "Bank Transfer (ACH)"
        case invoice = "Invoice (Net 30)"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .applePay: return "apple.logo"
            case .card: return "creditcard.fill"
            case .paypal: return "p.circle.fill"
            case .bankTransfer: return "building.columns.fill"
            case .invoice: return "doc.text.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress indicator
                        progressIndicator
                        
                        switch currentStep {
                        case 1:
                            step1_DistrictInfo
                        case 2:
                            step2_SchoolSelection
                        case 3:
                            step3_Payment
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("District Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Subscription Activated!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your district subscription is now active. All \(numberOfSchools) schools are covered!")
            }
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
                
                Text("District Subscription")
                    .font(.title2.bold())
                
                Text("Manage multiple schools under one subscription with volume pricing.")
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
                
                Text("Link existing schools by code, or create new ones. You must add at least one school before paying. Private schools can sign up on their own and pay separately.")
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
            CreateSchoolForDistrictSheet { school in
                validatedSchools.append(school)
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
    
    // MARK: - Step 3: Payment
    private var step3_Payment: some View {
        VStack(spacing: 24) {
            // Summary card
            VStack(spacing: 16) {
                Text("Subscription Summary")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    summaryRow(label: "District", value: districtName)
                    summaryRow(label: "Schools", value: "\(numberOfSchools)")
                    summaryRow(label: "Price per School", value: String(format: "$%.2f/mo", pricing.pricePerSchool))
                    Divider()
                    HStack {
                        Text("Total Monthly")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "$%.2f", pricing.total))
                            .font(.title2.bold())
                            .foregroundStyle(EZTeachColors.primaryGradient)
                    }
                }
            }
            .padding(20)
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
            
            // Payment methods
            VStack(alignment: .leading, spacing: 12) {
                Text("Payment Method")
                    .font(.headline)
                
                ForEach(PaymentMethod.allCases) { method in
                    paymentMethodButton(method)
                }
            }
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(EZTeachColors.error)
                    .padding()
                    .background(EZTeachColors.error.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Navigation buttons
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
                    processDistrictSubscription()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        }
                        Text(isProcessing ? "Processing..." : "Subscribe")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(selectedPaymentMethod != nil && !isProcessing ? EZTeachColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(selectedPaymentMethod != nil && !isProcessing ? .white : .secondary)
                    .cornerRadius(12)
                }
                .disabled(selectedPaymentMethod == nil || isProcessing)
            }
            
            // Terms
            Text("By subscribing, you agree to cover all listed schools. Schools covered by a district subscription cannot be charged separately.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Views
    private var pricingCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pricing.tier.rawValue.capitalized)
                        .font(.caption.bold())
                        .foregroundColor(EZTeachColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(EZTeachColors.accent.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text("\(pricing.tier.schoolRange) schools")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("$\(Int(pricing.pricePerSchool))")
                            .font(.title.bold())
                        Text("/school/mo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Text("Total Monthly")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "$%.2f", pricing.total))
                    .font(.title2.bold())
                    .foregroundStyle(EZTeachColors.primaryGradient)
            }
            
            if pricing.tier != .none {
                let savings = (75.0 - pricing.pricePerSchool) * Double(numberOfSchools)
                if savings > 0 {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(EZTeachColors.success)
                        Text("You save \(String(format: "$%.2f", savings))/month with volume pricing!")
                            .font(.caption.bold())
                            .foregroundColor(EZTeachColors.success)
                    }
                }
            }
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
            Text("Volume Pricing")
                .font(.subheadline.weight(.medium))
            
            VStack(spacing: 8) {
                pricingTierRow(tier: .small, isSelected: pricing.tier == .small)
                pricingTierRow(tier: .medium, isSelected: pricing.tier == .medium)
                pricingTierRow(tier: .large, isSelected: pricing.tier == .large)
                pricingTierRow(tier: .enterprise, isSelected: pricing.tier == .enterprise)
            }
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func pricingTierRow(tier: District.SubscriptionTier, isSelected: Bool) -> some View {
        HStack {
            Text("\(tier.schoolRange) schools")
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
            
            Text("$\(Int(tier.pricePerSchool))/school")
                .font(.caption.bold())
                .foregroundColor(isSelected ? EZTeachColors.accent : .secondary)
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(EZTeachColors.success)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
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
    
    private func paymentMethodButton(_ method: PaymentMethod) -> some View {
        Button {
            selectedPaymentMethod = method
        } label: {
            HStack(spacing: 14) {
                Image(systemName: method.icon)
                    .font(.title3)
                    .frame(width: 32)
                
                Text(method.rawValue)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                if selectedPaymentMethod == method {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(EZTeachColors.success)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .foregroundColor(.primary)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(EZTeachColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPaymentMethod == method ? EZTeachColors.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    private func processDistrictSubscription() {
        guard let uid = Auth.auth().currentUser?.uid,
              let method = selectedPaymentMethod else { return }
        
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
            "paymentMethod": method.rawValue,
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

// MARK: - Helper Model
struct ValidatedSchool: Identifiable {
    let id: String
    let code: String
    let name: String
    let exists: Bool
}

// MARK: - Create School for District Sheet
struct CreateSchoolForDistrictSheet: View {
    let onDone: (ValidatedSchool) -> Void
    
    @State private var name = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var isSaving = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private let fs = FirestoreService.shared
    
    private func finish(_ v: ValidatedSchool) {
        onDone(v)
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("School details") {
                    TextField("Name", text: $name)
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP", text: $zip)
                        .keyboardType(.numberPad)
                }
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(EZTeachColors.error)
                }
            }
            .navigationTitle("Create school")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        save()
                    }
                    .disabled(name.isEmpty || address.isEmpty || city.isEmpty || state.isEmpty || zip.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func save() {
        guard !name.isEmpty, !address.isEmpty, !city.isEmpty, !state.isEmpty, !zip.isEmpty else { return }
        isSaving = true
        errorMessage = ""
        Task {
            do {
                let (id, code, createdName) = try await fs.createSchoolForDistrict(
                    name: name.trimmingCharacters(in: .whitespaces),
                    address: address.trimmingCharacters(in: .whitespaces),
                    city: city.trimmingCharacters(in: .whitespaces),
                    state: state.trimmingCharacters(in: .whitespaces),
                    zip: zip.trimmingCharacters(in: .whitespaces)
                )
                await MainActor.run {
                    isSaving = false
                    finish(ValidatedSchool(id: id, code: code, name: createdName, exists: false))
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to create school. Try again."
                }
            }
        }
    }
}
