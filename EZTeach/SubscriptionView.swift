//
//  SubscriptionView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-26.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct SubscriptionView: View {

    let userData: UserAccountData

    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var promoCode = ""
    @State private var appliedPromo: PromoCodeResult?
    @State private var isValidatingPromo = false
    @State private var promoError = ""
    @State private var isProcessing = false
    @State private var showPaymentSuccess = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    // MARK: - Pricing
    private let monthlyPrice: Double = 75.0
    private let yearlyPrice: Double = 750.0  // ~17% savings vs monthly
    
    private var finalPrice: Double {
        guard selectedPlan == .yearly else { return monthlyPrice }
        
        if let promo = appliedPromo {
            let discount = yearlyPrice * promo.discountPercent
            return yearlyPrice - discount
        }
        return yearlyPrice
    }
    
    private var savingsText: String {
        let monthlyCost = monthlyPrice * 12
        let saved = monthlyCost - yearlyPrice
        return "Save $\(Int(saved))/yr"
    }

    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    enum PaymentMethod: String, CaseIterable, Identifiable {
        case applePay = "Apple Pay"
        case card = "Credit/Debit Card"
        case paypal = "PayPal"
        case venmo = "Venmo"
        case cashapp = "Cash App"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .applePay: return "apple.logo"
            case .card: return "creditcard.fill"
            case .paypal: return "p.circle.fill"
            case .venmo: return "v.circle.fill"
            case .cashapp: return "dollarsign.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .applePay: return .primary
            case .card: return EZTeachColors.accent
            case .paypal: return Color(red: 0/255, green: 112/255, blue: 201/255)
            case .venmo: return Color(red: 0/255, green: 141/255, blue: 211/255)
            case .cashapp: return Color(red: 0/255, green: 200/255, blue: 83/255)
            }
        }
    }
    
    struct PromoCodeResult {
        let code: String
        let discountPercent: Double  // 0.25 = 25%, 1.0 = 100%
        let description: String
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Plan selection
                        planSelectionSection
                        
                        // Promo code (only for yearly)
                        if selectedPlan == .yearly {
                            promoCodeSection
                        }

                        // Features list
                        featuresSection

                        // Payment methods
                        if !userData.isSubscribed {
                            paymentMethodsSection
                        }

                        // Subscribe button
                        if !userData.isSubscribed {
                            subscribeButton
                        }

                        // Manage subscription (if active)
                        if userData.isSubscribed {
                            manageSubscriptionSection
                        }

                        // Terms
                        termsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Complete Payment", isPresented: $showPaymentSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Complete your payment in the browser. Return to the app when done—your subscription will activate automatically.")
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(EZTeachColors.premiumGradient)
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("EZTeach Pro")
                    .font(.title.bold())

                if userData.isSubscribed {
                    Label("Active Subscription", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(EZTeachColors.success)
                } else {
                    Text("Unlock all features for your school")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Plan Selection
    private var planSelectionSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Monthly plan
                planCard(
                    plan: .monthly,
                    price: "$75",
                    period: "/month",
                    badge: nil
                )
                
                // Yearly plan
                planCard(
                    plan: .yearly,
                    price: "$750",
                    period: "/year",
                    badge: savingsText
                )
            }
        }
    }
    
    private func planCard(plan: SubscriptionPlan, price: String, period: String, badge: String?) -> some View {
        Button {
            withAnimation { selectedPlan = plan }
            if plan == .monthly {
                appliedPromo = nil
                promoCode = ""
                promoError = ""
            }
        } label: {
            VStack(spacing: 8) {
                if let badge = badge {
                    Text(badge)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(EZTeachColors.success)
                        .cornerRadius(8)
                }
                
                Text(plan.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title2.bold())
                        .foregroundStyle(selectedPlan == plan ? EZTeachColors.primaryGradient : LinearGradient(colors: [.primary], startPoint: .leading, endPoint: .trailing))
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if plan == .yearly && appliedPromo != nil {
                    Text("With promo: $\(Int(finalPrice))")
                        .font(.caption.bold())
                        .foregroundColor(EZTeachColors.success)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(EZTeachColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedPlan == plan ? EZTeachColors.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Promo Code Section
    private var promoCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promo Code")
                .font(.headline)
            
            HStack(spacing: 12) {
                TextField("Enter promo code", text: $promoCode)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(EZTeachColors.secondaryBackground)
                    .cornerRadius(10)
                    .autocapitalization(.allCharacters)
                    .disabled(appliedPromo != nil)
                
                Button {
                    if appliedPromo != nil {
                        // Remove promo
                        appliedPromo = nil
                        promoCode = ""
                        promoError = ""
                    } else {
                        validatePromoCode()
                    }
                } label: {
                    if isValidatingPromo {
                        ProgressView()
                            .frame(width: 80)
                    } else {
                        Text(appliedPromo != nil ? "Remove" : "Apply")
                            .fontWeight(.semibold)
                            .frame(width: 80)
                    }
                }
                .padding(.vertical, 14)
                .background(appliedPromo != nil ? EZTeachColors.error.opacity(0.1) : EZTeachColors.accent.opacity(0.1))
                .foregroundColor(appliedPromo != nil ? EZTeachColors.error : EZTeachColors.accent)
                .cornerRadius(10)
                .disabled(promoCode.isEmpty || isValidatingPromo)
            }
            
            if let promo = appliedPromo {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(EZTeachColors.success)
                    Text(promo.description)
                        .font(.caption)
                        .foregroundColor(EZTeachColors.success)
                }
            }
            
            if !promoError.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(EZTeachColors.error)
                    Text(promoError)
                        .font(.caption)
                        .foregroundColor(EZTeachColors.error)
                }
            }
            
            Text("Promo codes only apply to yearly subscriptions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(EZTeachColors.cardFill)
        .cornerRadius(16)
    }

    // MARK: - Features Section
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

    // MARK: - Payment Methods Section
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(PaymentMethod.allCases) { method in
                    paymentMethodButton(method)
                }
            }
        }
    }

    private func paymentMethodButton(_ method: PaymentMethod) -> some View {
        Button {
            selectedPaymentMethod = method
        } label: {
            HStack(spacing: 14) {
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(method.color)
                    .frame(width: 32)

                Text(method.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

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
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(EZTeachColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedPaymentMethod == method ? EZTeachColors.accent : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        VStack(spacing: 12) {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(EZTeachColors.error)
            }

            Button {
                processPayment()
            } label: {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                    
                    let priceText = selectedPlan == .monthly ? "$75/month" : "$\(Int(finalPrice))/yr"
                    Text(isProcessing ? "Processing..." : "Subscribe Now - \(priceText)")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    selectedPaymentMethod != nil && !isProcessing
                        ? EZTeachColors.accentGradient
                        : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(selectedPaymentMethod != nil && !isProcessing ? .white : .secondary)
                .cornerRadius(14)
            }
            .disabled(selectedPaymentMethod == nil || isProcessing)
        }
    }

    // MARK: - Manage Subscription Section
    private var manageSubscriptionSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Billing Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(userData.nextBillingDate)
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$75.00")
                        .font(.headline)
                }
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(12)

            Button {
                // Cancel subscription action
            } label: {
                Text("Cancel Subscription")
                    .font(.subheadline.bold())
                    .foregroundColor(EZTeachColors.error)
            }
        }
    }

    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("By subscribing, you agree to our Terms of Service and Privacy Policy.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Subscription automatically renews unless cancelled.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Validate Promo Code
    private func validatePromoCode() {
        let code = promoCode.uppercased().trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }
        
        isValidatingPromo = true
        promoError = ""
        
        guard let uid = Auth.auth().currentUser?.uid else {
            promoError = "Please sign in to use promo codes"
            isValidatingPromo = false
            return
        }
        
        // Check if promo code exists
        db.collection("promoCodes").document(code).getDocument { snap, error in
            guard let data = snap?.data(), snap?.exists == true else {
                promoError = "Invalid promo code"
                isValidatingPromo = false
                return
            }
            
            // Check if code is active
            guard data["isActive"] as? Bool == true else {
                promoError = "This promo code has expired"
                isValidatingPromo = false
                return
            }
            
            // Check if yearly only
            if data["yearlyOnly"] as? Bool == true && selectedPlan != .yearly {
                promoError = "This code only applies to yearly subscriptions"
                isValidatingPromo = false
                return
            }
            
            // Check if user/school already used this code
            db.collection("promoCodeUsage")
                .whereField("code", isEqualTo: code)
                .whereField("userId", isEqualTo: uid)
                .getDocuments { usageSnap, _ in
                    if let docs = usageSnap?.documents, !docs.isEmpty {
                        promoError = "You've already used this promo code"
                        isValidatingPromo = false
                        return
                    }
                    
                    // Also check if school already used it
                    if let schoolId = userData.activeSchoolId {
                        db.collection("promoCodeUsage")
                            .whereField("code", isEqualTo: code)
                            .whereField("schoolId", isEqualTo: schoolId)
                            .getDocuments { schoolUsageSnap, _ in
                                if let schoolDocs = schoolUsageSnap?.documents, !schoolDocs.isEmpty {
                                    promoError = "This code has already been used for this school"
                                    isValidatingPromo = false
                                    return
                                }
                                
                                // Code is valid!
                                let discount = data["discountPercent"] as? Double ?? 0
                                let description = data["description"] as? String ?? "\(Int(discount * 100))% off"
                                
                                appliedPromo = PromoCodeResult(
                                    code: code,
                                    discountPercent: discount,
                                    description: description
                                )
                                isValidatingPromo = false
                            }
                    } else {
                        // No school ID, just validate for user
                        let discount = data["discountPercent"] as? Double ?? 0
                        let description = data["description"] as? String ?? "\(Int(discount * 100))% off"
                        
                        appliedPromo = PromoCodeResult(
                            code: code,
                            discountPercent: discount,
                            description: description
                        )
                        isValidatingPromo = false
                    }
                }
        }
    }

    // MARK: - Process Payment
    private func processPayment() {
        guard selectedPaymentMethod != nil else { return }

        isProcessing = true
        errorMessage = ""

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Authentication error. Please try again."
            isProcessing = false
            return
        }

        guard let schoolId = userData.activeSchoolId else {
            errorMessage = "No school selected. Please select a school first."
            isProcessing = false
            return
        }

        let successUrl = "https://ezteach.org/subscription-success.html"
        let cancelUrl = "https://ezteach.org/subscription-cancel.html"

        var params: [String: Any] = [
            "schoolId": schoolId,
            "plan": selectedPlan == .yearly ? "yearly" : "monthly",
            "successUrl": successUrl,
            "cancelUrl": cancelUrl
        ]
        if let promo = appliedPromo {
            params["promoCode"] = promo.code
        }

        let functions = Functions.functions()
        functions.httpsCallable("createCheckoutSession").call(params) { result, error in
            DispatchQueue.main.async {
                isProcessing = false

                if let error = error as NSError? {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data = result?.data as? [String: Any],
                      let urlString = data["url"] as? String,
                      let url = URL(string: urlString) else {
                    errorMessage = "Could not start checkout."
                    return
                }

                // Open Stripe Checkout in Safari
                UIApplication.shared.open(url) { opened in
                    if opened {
                        // Webhook will update Firestore when payment completes
                        showPaymentSuccess = true
                    } else {
                        errorMessage = "Could not open payment page."
                    }
                }
            }
        }
    }
}
