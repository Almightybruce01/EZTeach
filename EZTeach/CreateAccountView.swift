//
//  CreateAccountView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI
import FirebaseAuth

enum UserRole: String, CaseIterable {
    case school = "School"
    case district = "District"
    case teacher = "Teacher"
    case principal = "Principal"
    case assistantPrincipal = "Assistant Principal"
    case assistantTeacher = "Assistant Teacher"
    case secretary = "Secretary"
    case sub = "Sub"
    case parent = "Parent"
    
    var description: String {
        switch self {
        case .school: return "Manage your school, teachers, and students"
        case .district: return "Manage multiple schools—exclusive features on our website"
        case .teacher: return "Access classes, attendance, and sub plans"
        case .principal, .assistantPrincipal: return "School leadership—no grade assignment required"
        case .assistantTeacher, .secretary: return "Support staff—no grade assignment required"
        case .sub: return "View assignments and accept sub requests"
        case .parent: return "View your child's grades and school info"
        }
    }

    /// Roles that create teacher-level accounts (stored as "teacher" in Firestore) without requiring grade
    var isStaffNoGradeRequired: Bool {
        switch self {
        case .principal, .assistantPrincipal, .assistantTeacher, .secretary: return true
        default: return false
        }
    }

    /// Firestore role value
    var firestoreRole: String {
        switch self {
        case .teacher, .principal, .assistantPrincipal, .assistantTeacher, .secretary: return "teacher"
        case .sub: return "sub"
        default: return rawValue.lowercased()
        }
    }

    /// Optional staff type for teacher accounts (principals, etc.)
    var staffType: String? {
        switch self {
        case .principal: return "principal"
        case .assistantPrincipal: return "assistant_principal"
        case .assistantTeacher: return "assistant_teacher"
        case .secretary: return "secretary"
        default: return nil
        }
    }
}

struct CreateAccountView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var role: UserRole = .teacher
    @State private var showAdminTypePicker = false

    // Person
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""

    // School
    @State private var schoolName = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var schoolCode = ""

    @State private var gradeFrom = 0
    @State private var gradeTo = 13
    
    // District
    @State private var districtName = ""
    @State private var districtAddress = ""
    @State private var districtCity = ""
    @State private var districtState = ""
    @State private var districtZip = ""
    @State private var numberOfSchools = 1

    // Auth
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var errorMessage = ""
    @State private var loading = false
    @State private var showSuccess = false
    @State private var showParentSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Role selector
                roleSelector
                
                // Role-specific fields
                switch role {
                case .school:
                    schoolFields
                case .district:
                    districtFields
                case .teacher, .principal, .assistantPrincipal, .assistantTeacher, .secretary, .sub:
                    personFields
                case .parent:
                    parentFields
                }
                
                // Account credentials
                accountFields
                
                // Error message
                if !errorMessage.isEmpty {
                    errorView
                }
                
                // Submit button
                submitButton
                
                // Terms
                termsText
            }
            .padding()
        }
        .background(EZTeachColors.background)
        .navigationTitle("Create Account")
        .alert("Account Created!", isPresented: $showSuccess) {
            Button("Continue") { dismiss() }
        } message: {
            Text("Your account has been created successfully. You can now sign in and customize your school. Create an account on our website to access advanced features and allow teachers, subs, and parents to join.")
        }
        .alert("Parent Account Created!", isPresented: $showParentSuccess) {
            Button("Got it!") { dismiss() }
        } message: {
            Text("Your account is ready!\n\nAfter signing in, go to 'My Children' → search and select your child's school → enter your child's Student ID (8-character code) to link and view grades.")
        }
    }
    
    // MARK: - Role Selector
    private static let mainRoles: [UserRole] = [.parent, .teacher, .sub]
    private static let adminRoles: [UserRole] = [.school, .district, .principal, .assistantPrincipal, .assistantTeacher, .secretary]

    private var roleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I am a...")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Self.mainRoles, id: \.self) { r in
                    roleCard(r)
                }
                adminCard
            }
        }
        .sheet(isPresented: $showAdminTypePicker) {
            adminTypePickerSheet
        }
    }

    private var adminCard: some View {
        Button {
            showAdminTypePicker = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.title2)
                    .foregroundColor(Self.adminRoles.contains(role) ? .white : EZTeachColors.accent)

                Text("School Administration")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Self.adminRoles.contains(role) ? .white : .primary)

                Text(Self.adminRoles.contains(role) ? role.rawValue : "School, district, principal & staff")
                    .font(.caption2)
                    .foregroundColor(Self.adminRoles.contains(role) ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Self.adminRoles.contains(role) ? EZTeachColors.accentGradient : LinearGradient(colors: [EZTeachColors.secondaryBackground], startPoint: .top, endPoint: .bottom))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Self.adminRoles.contains(role) ? Color.clear : EZTeachColors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var adminTypePickerSheet: some View {
        NavigationStack {
            List(Self.adminRoles, id: \.self) { r in
                Button {
                    withAnimation { role = r }
                    showAdminTypePicker = false
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: roleIcon(r))
                            .font(.title3)
                            .foregroundColor(EZTeachColors.accent)
                            .frame(width: 28, alignment: .center)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Text(r.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("School Administration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showAdminTypePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func roleCard(_ r: UserRole) -> some View {
        Button {
            withAnimation { role = r }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: roleIcon(r))
                    .font(.title2)
                    .foregroundColor(role == r ? .white : EZTeachColors.accent)
                
                Text(r.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(role == r ? .white : .primary)
                
                Text(r.description)
                    .font(.caption2)
                    .foregroundColor(role == r ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(role == r ? EZTeachColors.accentGradient : LinearGradient(colors: [EZTeachColors.secondaryBackground], startPoint: .top, endPoint: .bottom))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(role == r ? Color.clear : EZTeachColors.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func roleIcon(_ r: UserRole) -> String {
        switch r {
        case .school: return "building.columns.fill"
        case .district: return "building.2.crop.circle.fill"
        case .teacher: return "person.fill"
        case .principal: return "person.badge.key.fill"
        case .assistantPrincipal: return "person.crop.circle.badge.checkmark"
        case .assistantTeacher: return "person.2.fill"
        case .secretary: return "person.text.rectangle.fill"
        case .sub: return "person.badge.clock.fill"
        case .parent: return "figure.2.and.child.holdinghands"
        }
    }
    
    // MARK: - School Fields
    private var schoolFields: some View {
        VStack(spacing: 20) {
            formSection(title: "School Information") {
                formField(icon: "building.2", placeholder: "School Name", text: $schoolName)
                formField(icon: "mappin", placeholder: "Street Address", text: $address)
                
                HStack(spacing: 12) {
                    formField(icon: "building", placeholder: "City", text: $city)
                    formField(icon: "map", placeholder: "State", text: $state)
                        .frame(width: 80)
                }
                
                formField(icon: "number", placeholder: "ZIP Code", text: $zip)
                    .keyboardType(.numberPad)
            }
            
            formSection(title: "School Code") {
                formField(icon: "key", placeholder: "6-Digit Code", text: $schoolCode)
                    .keyboardType(.numberPad)
                    .onChange(of: schoolCode) { _, newValue in
                        schoolCode = String(newValue.prefix(6).filter { $0.isNumber })
                    }
                
                Text("This code will be shared with teachers and staff to join your school.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            formSection(title: "Grades Served") {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("From", selection: $gradeFrom) {
                            ForEach(GradeUtils.allGrades, id: \.self) { g in
                                Text(GradeUtils.label(g)).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("To")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("To", selection: $gradeTo) {
                            ForEach(GradeUtils.allGrades.filter { $0 >= gradeFrom }, id: \.self) { g in
                                Text(GradeUtils.label(g)).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }
    
    // MARK: - District Fields
    private var districtFields: some View {
        VStack(spacing: 20) {
            formSection(title: "District Information") {
                formField(icon: "building.2.crop.circle", placeholder: "District Name", text: $districtName)
                formField(icon: "mappin", placeholder: "Street Address", text: $districtAddress)
                HStack(spacing: 12) {
                    formField(icon: "building", placeholder: "City", text: $districtCity)
                    formField(icon: "map", placeholder: "State", text: $districtState)
                        .frame(width: 80)
                }
                formField(icon: "number", placeholder: "ZIP Code", text: $districtZip)
                    .keyboardType(.numberPad)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of Schools")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper("\(numberOfSchools) school\(numberOfSchools > 1 ? "s" : "")", value: $numberOfSchools, in: 2...100)
                }
                .padding(12)
                .background(EZTeachColors.background)
                .cornerRadius(10)
            }
            
            formSection(title: "Admin Contact") {
                HStack(spacing: 12) {
                    formField(icon: "person", placeholder: "First Name", text: $firstName)
                    formField(icon: "person", placeholder: "Last Name", text: $lastName)
                }
                
                formField(icon: "phone", placeholder: "Phone Number", text: $phone)
                    .keyboardType(.phonePad)
            }
            
            // Pricing preview
            VStack(spacing: 12) {
                Text("Volume Pricing")
                    .font(.headline)
                
                let pricing = District.calculatePrice(schoolCount: numberOfSchools)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("$\(Int(pricing.pricePerSchool))")
                            .font(.title.bold())
                            .foregroundStyle(EZTeachColors.primaryGradient)
                        Text("per school/month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(Int(pricing.total))")
                            .font(.title2.bold())
                        Text("total/month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                .cornerRadius(12)
                
                Text("You'll add your schools after creating your account.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Person Fields (Teacher/Sub)
    private var personFields: some View {
        formSection(title: "Personal Information") {
            HStack(spacing: 12) {
                formField(icon: "person", placeholder: "First Name", text: $firstName)
                formField(icon: "person", placeholder: "Last Name", text: $lastName)
            }
        }
    }
    
    // MARK: - Parent Fields
    private var parentFields: some View {
        VStack(spacing: 20) {
            formSection(title: "Personal Information") {
                HStack(spacing: 12) {
                    formField(icon: "person", placeholder: "First Name", text: $firstName)
                    formField(icon: "person", placeholder: "Last Name", text: $lastName)
                }
                
                formField(icon: "phone", placeholder: "Phone Number (optional)", text: $phone)
                    .keyboardType(.phonePad)
            }
            
            // Important info for parents
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(EZTeachColors.accent)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to View Your Child's Grades")
                            .font(.subheadline.bold())
                        Text("After creating your account:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    stepRow(number: 1, text: "Sign in to the app")
                    stepRow(number: 2, text: "Tap the menu → 'My Children'")
                    stepRow(number: 3, text: "Search and select your child's school")
                    stepRow(number: 4, text: "Enter your child's Student Code")
                    stepRow(number: 5, text: "View grades, classes & announcements")
                }
                
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(EZTeachColors.warning)
                    Text("Get the Student ID from your child's school or teacher")
                        .font(.caption.bold())
                        .foregroundColor(EZTeachColors.warning)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(EZTeachColors.warning.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(12)
        }
    }
    
    private func stepRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(EZTeachColors.accent)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                )
            
            Text(text)
                .font(.subheadline)
        }
    }
    
    // MARK: - Account Fields
    private var accountFields: some View {
        formSection(title: "Account Credentials") {
            formField(icon: "envelope", placeholder: "Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            SecureFormField(icon: "lock", placeholder: "Password", text: $password)
            
            SecureFormField(icon: "lock", placeholder: "Confirm Password", text: $confirmPassword)
            
            if password.count > 0 && password.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(.caption)
                    .foregroundColor(EZTeachColors.warning)
            }
        }
    }
    
    // MARK: - Error View
    private var errorView: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
            Text(errorMessage)
        }
        .font(.subheadline)
        .foregroundColor(EZTeachColors.error)
        .padding()
        .frame(maxWidth: .infinity)
        .background(EZTeachColors.error.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack {
                if loading {
                    ProgressView()
                        .tint(.white)
                }
                Text(loading ? "Creating Account..." : "Create Account")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? EZTeachColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(isFormValid ? .white : .secondary)
            .cornerRadius(14)
        }
        .disabled(!isFormValid || loading)
    }
    
    // MARK: - Terms Text
    private var termsText: some View {
        Text("By creating an account, you agree to our Terms of Service and Privacy Policy.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    
    // MARK: - Helper Views
    private func formSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(spacing: 12) {
                content()
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(12)
        }
    }
    
    private func formField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: text)
        }
        .padding(12)
        .background(EZTeachColors.background)
        .cornerRadius(10)
    }
    
    private var isFormValid: Bool {
        if email.isEmpty || password.isEmpty || password.count < 6 || password != confirmPassword {
            return false
        }
        
        switch role {
        case .school:
            return !schoolName.isEmpty && !address.isEmpty && !city.isEmpty && !state.isEmpty && !zip.isEmpty && schoolCode.count == 6
        case .district:
            return !districtName.isEmpty && !firstName.isEmpty && !lastName.isEmpty && !districtAddress.isEmpty && !districtCity.isEmpty && !districtState.isEmpty && districtZip.count >= 5 && numberOfSchools >= 2
        case .teacher, .principal, .assistantPrincipal, .assistantTeacher, .secretary, .sub, .parent:
            return !firstName.isEmpty && !lastName.isEmpty
        }
    }

    // MARK: - Submit
    @MainActor
    private func submit() async {
        errorMessage = ""
        loading = true

        do {
            switch role {
            case .school:
                try await FirestoreService.shared.createSchoolAccount(
                    email: email,
                    password: password,
                    name: schoolName,
                    address: address,
                    city: city,
                    state: state,
                    zip: zip,
                    gradesFrom: gradeFrom,
                    gradesTo: gradeTo,
                    schoolCode: schoolCode
                )
                showSuccess = true
                
            case .district:
                try await FirestoreService.shared.createDistrictAccount(
                    email: email,
                    password: password,
                    districtName: districtName,
                    firstName: firstName,
                    lastName: lastName,
                    phone: phone,
                    address: districtAddress,
                    city: districtCity,
                    state: districtState,
                    zip: districtZip,
                    numberOfSchools: numberOfSchools
                )
                showSuccess = true

            case .teacher, .principal, .assistantPrincipal, .assistantTeacher, .secretary, .sub:
                try await FirestoreService.shared.createStaffAccount(
                    email: email,
                    password: password,
                    role: role.firestoreRole,
                    staffType: role.staffType,
                    firstName: firstName,
                    lastName: lastName
                )
                showSuccess = true
                
            case .parent:
                try await FirestoreService.shared.createParentAccount(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    phone: phone
                )
                showParentSuccess = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        loading = false
    }
}

// MARK: - Secure Form Field
struct SecureFormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(EZTeachColors.background)
        .cornerRadius(10)
    }
}
