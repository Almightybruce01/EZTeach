//
//  SchoolAccountManagementView.swift
//  EZTeach
//
//  Manage school accounts - add, remove, and manage users
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

// MARK: - Account Management View for Schools/Districts
struct SchoolAccountManagementView: View {
    let schoolId: String
    let userRole: String // "school" or "district"
    
    @State private var selectedTab: AccountTab = .students
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var students: [Student] = []
    @State private var teachers: [TeacherAccount] = []
    @State private var staff: [StaffAccount] = []
    @State private var showAddAccount = false
    @State private var accountToDelete: AccountInfo?
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var selectedGradeFilter: Int? = nil
    
    private let db = Firestore.firestore()
    
    enum AccountTab: String, CaseIterable {
        case students = "Students"
        case teachers = "Teachers"
        case staff = "Staff"
        
        var icon: String {
            switch self {
            case .students: return "graduationcap.fill"
            case .teachers: return "person.fill"
            case .staff: return "person.2.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    ForEach(AccountTab.allCases, id: \.rawValue) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = tab
                                loadAccounts()
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.title3)
                                Text(tab.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(selectedTab == tab ? EZTeachColors.brightTeal : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == tab
                                    ? EZTeachColors.brightTeal.opacity(0.1)
                                    : Color.clear
                            )
                        }
                    }
                }
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search \(selectedTab.rawValue.lowercased())...", text: $searchText)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding()
                
                // Grade filter (only for Students tab)
                if selectedTab == .students {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                withAnimation { selectedGradeFilter = nil }
                            } label: {
                                Text("All Grades")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(selectedGradeFilter == nil ? .white : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedGradeFilter == nil ? Color.blue : Color.gray.opacity(0.15))
                                    .cornerRadius(16)
                            }
                            
                            ForEach(GradeUtils.allGrades, id: \.self) { grade in
                                Button {
                                    withAnimation { selectedGradeFilter = grade }
                                } label: {
                                    Text(GradeUtils.label(grade))
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(selectedGradeFilter == grade ? .white : .secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedGradeFilter == grade ? Color.blue : Color.gray.opacity(0.15))
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 4)
                }
                
                // Stats bar
                statsBar
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Loading accounts...")
                    Spacer()
                } else {
                    accountsList
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Account Management")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(EZTeachColors.brightTeal)
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountView(schoolId: schoolId, accountType: selectedTab) {
                    loadAccounts()
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let account = accountToDelete {
                        deleteAccount(account)
                    }
                }
            } message: {
                if let account = accountToDelete {
                    Text("Are you sure you want to delete \(account.name)? This action cannot be undone.")
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay {
                if let success = successMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(success)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                successMessage = nil
                            }
                        }
                    }
                }
            }
            .onAppear { loadAccounts() }
        }
    }
    
    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 16) {
            StatBox(
                value: "\(filteredStudents.count)",
                label: "Students",
                color: .blue,
                isSelected: selectedTab == .students
            )
            
            StatBox(
                value: "\(filteredTeachers.count)",
                label: "Teachers",
                color: .green,
                isSelected: selectedTab == .teachers
            )
            
            StatBox(
                value: "\(filteredStaff.count)",
                label: "Staff",
                color: .purple,
                isSelected: selectedTab == .staff
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Accounts List
    private var accountsList: some View {
        Group {
            switch selectedTab {
            case .students:
                if filteredStudents.isEmpty {
                    EmptyAccountsView(type: "students", onAdd: { showAddAccount = true })
                } else {
                    List {
                        ForEach(filteredStudents) { student in
                            StudentAccountRow(student: student, onDelete: {
                                accountToDelete = AccountInfo(id: student.id, name: student.fullName, type: .student)
                                showDeleteConfirmation = true
                            })
                        }
                    }
                    .listStyle(.plain)
                }
                
            case .teachers:
                if filteredTeachers.isEmpty {
                    EmptyAccountsView(type: "teachers", onAdd: { showAddAccount = true })
                } else {
                    List {
                        ForEach(filteredTeachers) { teacher in
                            TeacherAccountRow(teacher: teacher, onDelete: {
                                accountToDelete = AccountInfo(id: teacher.id, name: teacher.name, type: .teacher)
                                showDeleteConfirmation = true
                            })
                        }
                    }
                    .listStyle(.plain)
                }
                
            case .staff:
                if filteredStaff.isEmpty {
                    EmptyAccountsView(type: "staff", onAdd: { showAddAccount = true })
                } else {
                    List {
                        ForEach(filteredStaff) { staffMember in
                            StaffAccountRow(staff: staffMember, onDelete: {
                                accountToDelete = AccountInfo(id: staffMember.id, name: staffMember.name, type: .staff)
                                showDeleteConfirmation = true
                            })
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Filtered Data
    private var filteredStudents: [Student] {
        var result = students
        
        // Filter by grade level if selected
        if let grade = selectedGradeFilter {
            result = result.filter { $0.gradeLevel == grade }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.studentCode.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private var filteredTeachers: [TeacherAccount] {
        if searchText.isEmpty {
            return teachers
        }
        return teachers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredStaff: [StaffAccount] {
        if searchText.isEmpty {
            return staff
        }
        return staff.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Load Accounts
    private func loadAccounts() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // Load students
        group.enter()
        db.collection("students")
            .whereField("schoolId", isEqualTo: schoolId)
            .order(by: "lastName")
            .getDocuments { snap, _ in
                students = snap?.documents.compactMap { Student.fromDocument($0) } ?? []
                group.leave()
            }
        
        // Load teachers
        group.enter()
        db.collection("users")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("role", isEqualTo: "teacher")
            .getDocuments { snap, _ in
                teachers = snap?.documents.compactMap { doc -> TeacherAccount? in
                    let d = doc.data()
                    return TeacherAccount(
                        id: doc.documentID,
                        name: "\(d["firstName"] as? String ?? "") \(d["lastName"] as? String ?? "")",
                        email: d["email"] as? String ?? "",
                        subjects: d["subjects"] as? [String] ?? [],
                        isActive: d["isActive"] as? Bool ?? true
                    )
                } ?? []
                group.leave()
            }
        
        // Load staff
        group.enter()
        db.collection("users")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("role", in: ["librarian", "substitute", "counselor", "admin"])
            .getDocuments { snap, _ in
                staff = snap?.documents.compactMap { doc -> StaffAccount? in
                    let d = doc.data()
                    return StaffAccount(
                        id: doc.documentID,
                        name: "\(d["firstName"] as? String ?? "") \(d["lastName"] as? String ?? "")",
                        email: d["email"] as? String ?? "",
                        role: d["role"] as? String ?? "",
                        isActive: d["isActive"] as? Bool ?? true
                    )
                } ?? []
                group.leave()
            }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
    
    // MARK: - Delete Account
    private func deleteAccount(_ account: AccountInfo) {
        let functions = Functions.functions()
        
        functions.httpsCallable("deleteSchoolAccount").call([
            "accountId": account.id,
            "accountType": account.type.rawValue,
            "schoolId": schoolId
        ]) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                withAnimation {
                    successMessage = "\(account.name) has been removed"
                }
                loadAccounts()
            }
        }
    }
}

// MARK: - Supporting Types
struct TeacherAccount: Identifiable {
    let id: String
    let name: String
    let email: String
    let subjects: [String]
    let isActive: Bool
}

struct StaffAccount: Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let isActive: Bool
}

struct AccountInfo {
    let id: String
    let name: String
    let type: AccountType
    
    enum AccountType: String {
        case student, teacher, staff
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(isSelected ? color : .secondary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Account Rows
struct StudentAccountRow: View {
    let student: Student
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(EZTeachColors.brightTeal.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(student.firstName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(EZTeachColors.brightTeal)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(student.fullName)
                    .font(.subheadline.weight(.semibold))
                
                HStack(spacing: 8) {
                    Text("ID: \(student.studentCode)")
                        .font(.caption.monospaced())
                    Text("•")
                    Text("Grade \(student.gradeLevel)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button("View Details", systemImage: "person.crop.circle") { }
                Button("Edit", systemImage: "pencil") { }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TeacherAccountRow: View {
    let teacher: TeacherAccount
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.green)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(teacher.name)
                        .font(.subheadline.weight(.semibold))
                    
                    if !teacher.isActive {
                        Text("INACTIVE")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                
                Text(teacher.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !teacher.subjects.isEmpty {
                    Text(teacher.subjects.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Menu {
                Button("View Profile", systemImage: "person.crop.circle") { }
                Button("Edit", systemImage: "pencil") { }
                Button(teacher.isActive ? "Deactivate" : "Activate", systemImage: teacher.isActive ? "xmark.circle" : "checkmark.circle") { }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StaffAccountRow: View {
    let staff: StaffAccount
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: roleIcon)
                        .foregroundColor(.purple)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.name)
                    .font(.subheadline.weight(.semibold))
                
                HStack(spacing: 8) {
                    Text(staff.role.capitalized)
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(staff.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Menu {
                Button("View Profile", systemImage: "person.crop.circle") { }
                Button("Edit", systemImage: "pencil") { }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var roleIcon: String {
        switch staff.role.lowercased() {
        case "librarian": return "books.vertical.fill"
        case "substitute": return "person.badge.clock.fill"
        case "counselor": return "heart.text.square.fill"
        case "admin": return "gearshape.fill"
        default: return "person.fill"
        }
    }
}

// MARK: - Empty Accounts View
struct EmptyAccountsView: View {
    let type: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No \(type) found")
                .font(.title3.weight(.semibold))
            
            Text("Add \(type) to your school database to manage their accounts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onAdd) {
                Label("Add \(type.capitalized)", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(EZTeachColors.accentGradient)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
    }
}

// MARK: - Add Account View
struct AddAccountView: View {
    let schoolId: String
    let accountType: SchoolAccountManagementView.AccountTab
    let onSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var gradeLevel = 1
    @State private var role = "teacher"
    @State private var subjects: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var generatedCode: String?
    
    private let staffRoles = ["librarian", "substitute", "counselor", "admin"]
    private let subjectOptions = ["Math", "English", "Science", "History", "Art", "Music", "PE", "Foreign Language"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                    
                    if accountType != .students {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                if accountType == .students {
                    Section("Student Details") {
                        Picker("Grade Level", selection: $gradeLevel) {
                            ForEach(-1..<13) { grade in
                                Text(GradeUtils.label(grade)).tag(grade)
                            }
                        }
                    }
                }
                
                if accountType == .teachers {
                    Section("Subjects") {
                        ForEach(subjectOptions, id: \.self) { subject in
                            Button {
                                if subjects.contains(subject) {
                                    subjects.removeAll { $0 == subject }
                                } else {
                                    subjects.append(subject)
                                }
                            } label: {
                                HStack {
                                    Text(subject)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if subjects.contains(subject) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(EZTeachColors.brightTeal)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if accountType == .staff {
                    Section("Role") {
                        Picker("Staff Role", selection: $role) {
                            ForEach(staffRoles, id: \.self) { r in
                                Text(r.capitalized).tag(r)
                            }
                        }
                    }
                }
                
                if let code = generatedCode {
                    Section("Account Created") {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            
                            if accountType == .students {
                                Text("Student ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(code)
                                    .font(.title.monospaced().bold())
                                    .foregroundColor(EZTeachColors.brightTeal)
                                
                                Text("Default password: \(code)!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Account created successfully!")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            .navigationTitle("Add \(accountType.rawValue.dropLast())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if generatedCode != nil {
                        Button("Done") {
                            onSuccess()
                            dismiss()
                        }
                    } else {
                        Button("Create") {
                            createAccount()
                        }
                        .disabled(!canCreate || isLoading)
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var canCreate: Bool {
        !firstName.isEmpty && !lastName.isEmpty && (accountType == .students || !email.isEmpty)
    }
    
    private func createAccount() {
        isLoading = true
        
        let functions = Functions.functions()
        var data: [String: Any] = [
            "schoolId": schoolId,
            "firstName": firstName,
            "lastName": lastName,
            "accountType": accountType.rawValue.dropLast().lowercased() // "student", "teacher", "staf"
        ]
        
        if accountType == .students {
            data["gradeLevel"] = gradeLevel
        } else {
            data["email"] = email
        }
        
        if accountType == .teachers {
            data["subjects"] = subjects
        }
        
        if accountType == .staff {
            data["role"] = role
        }
        
        functions.httpsCallable("createSchoolAccount").call(data) { result, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let resultData = result?.data as? [String: Any] {
                generatedCode = resultData["studentCode"] as? String ?? resultData["userId"] as? String
            }
        }
    }
}
