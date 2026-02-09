//
//  SearchableSchoolPicker.swift
//  EZTeach
//
//  Searchable, scrollable school picker with code verification
//

import SwiftUI
import FirebaseFirestore

// MARK: - School Info Model
struct SchoolInfo: Identifiable {
    let id: String
    let name: String
    let code: String
    let district: String
    let address: String
    let logoUrl: String?
    
    static func fromDocument(_ doc: DocumentSnapshot) -> SchoolInfo? {
        guard let data = doc.data() else { return nil }
        return SchoolInfo(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            code: data["schoolCode"] as? String ?? "",
            district: data["districtName"] as? String ?? "",
            address: data["address"] as? String ?? "",
            logoUrl: data["logoUrl"] as? String
        )
    }
}

// MARK: - Searchable School Picker
struct SearchableSchoolPicker: View {
    @Binding var selectedSchoolId: String
    @Binding var isPresented: Bool
    let requireCodeVerification: Bool
    let onSchoolSelected: ((SchoolInfo) -> Void)?
    
    @State private var searchText = ""
    @State private var schools: [SchoolInfo] = []
    @State private var isLoading = true
    @State private var selectedSchool: SchoolInfo?
    @State private var enteredCode = ""
    @State private var codeError: String?
    @State private var showCodeEntry = false
    
    private let db = Firestore.firestore()
    
    init(
        selectedSchoolId: Binding<String>,
        isPresented: Binding<Bool>,
        requireCodeVerification: Bool = true,
        onSchoolSelected: ((SchoolInfo) -> Void)? = nil
    ) {
        self._selectedSchoolId = selectedSchoolId
        self._isPresented = isPresented
        self.requireCodeVerification = requireCodeVerification
        self.onSchoolSelected = onSchoolSelected
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showCodeEntry, let school = selectedSchool {
                    // Code verification step
                    codeVerificationView(school)
                } else {
                    // School search and selection
                    schoolSelectionView
                }
            }
            .navigationTitle(showCodeEntry ? "Verify School Code" : "Select School")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(showCodeEntry ? "Back" : "Cancel") {
                        if showCodeEntry {
                            withAnimation {
                                showCodeEntry = false
                                selectedSchool = nil
                                enteredCode = ""
                                codeError = nil
                            }
                        } else {
                            isPresented = false
                        }
                    }
                }
            }
            .onAppear {
                loadSchools()
            }
        }
    }
    
    // MARK: - School Selection View
    private var schoolSelectionView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search schools by name...", text: $searchText)
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
            
            // Results count
            HStack {
                Text("\(filteredSchools.count) schools found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if isLoading {
                Spacer()
                ProgressView("Loading schools...")
                Spacer()
            } else if filteredSchools.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "building.2")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No schools found")
                        .font(.headline)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                // Scrollable list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredSchools) { school in
                            SchoolRowView(school: school) {
                                selectSchool(school)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Code Verification View
    private func codeVerificationView(_ school: SchoolInfo) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // School info card
            VStack(spacing: 12) {
                if let logoUrl = school.logoUrl, !logoUrl.isEmpty {
                    AsyncImage(url: URL(string: logoUrl)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(EZTeachColors.brightTeal)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(EZTeachColors.brightTeal.opacity(0.2))
                            .frame(width: 80, height: 80)
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 32))
                            .foregroundColor(EZTeachColors.brightTeal)
                    }
                }
                
                Text(school.name)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                
                if !school.district.isEmpty {
                    Text(school.district)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            .padding(.horizontal)
            
            // Code entry
            VStack(spacing: 12) {
                Text("Enter School Code to Verify")
                    .font(.headline)
                
                Text("Ask your school administrator for the school code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("School Code", text: $enteredCode)
                    .font(.title2.monospaced())
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(codeError != nil ? Color.red : Color.clear, lineWidth: 2)
                    )
                    .padding(.horizontal)
                
                if let error = codeError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Verify button
            Button {
                verifyCode(school)
            } label: {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Verify & Select School")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    enteredCode.isEmpty
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(EZTeachColors.accentGradient)
                )
                .cornerRadius(12)
            }
            .disabled(enteredCode.isEmpty)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Filtered Schools
    private var filteredSchools: [SchoolInfo] {
        if searchText.isEmpty {
            return schools
        }
        return schools.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.district.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Load Schools
    private func loadSchools() {
        isLoading = true
        
        db.collection("schools")
            .order(by: "name")
            .getDocuments { snap, _ in
                schools = snap?.documents.compactMap { SchoolInfo.fromDocument($0) } ?? []
                isLoading = false
            }
    }
    
    // MARK: - Select School
    private func selectSchool(_ school: SchoolInfo) {
        if requireCodeVerification {
            selectedSchool = school
            withAnimation {
                showCodeEntry = true
            }
        } else {
            selectedSchoolId = school.id
            onSchoolSelected?(school)
            isPresented = false
        }
    }
    
    // MARK: - Verify Code
    private func verifyCode(_ school: SchoolInfo) {
        let trimmedCode = enteredCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if trimmedCode == school.code.uppercased() {
            // Code matches!
            selectedSchoolId = school.id
            onSchoolSelected?(school)
            isPresented = false
        } else {
            withAnimation {
                codeError = "Invalid school code. Please try again."
            }
        }
    }
}

// MARK: - School Row View
struct SchoolRowView: View {
    let school: SchoolInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Logo
                if let logoUrl = school.logoUrl, !logoUrl.isEmpty {
                    AsyncImage(url: URL(string: logoUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        schoolPlaceholder
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    schoolPlaceholder
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(school.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if !school.district.isEmpty {
                        Text(school.district)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !school.address.isEmpty {
                        Text(school.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var schoolPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(EZTeachColors.brightTeal.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Text(school.name.prefix(1).uppercased())
                .font(.title2.weight(.bold))
                .foregroundColor(EZTeachColors.brightTeal)
        }
    }
}

// MARK: - School Picker Button (Reusable Component)
struct SchoolPickerButton: View {
    @Binding var selectedSchoolId: String
    @State private var selectedSchoolName = "Select School"
    @State private var showPicker = false
    let requireCodeVerification: Bool
    let onSchoolSelected: ((SchoolInfo) -> Void)?
    
    private let db = Firestore.firestore()
    
    init(
        selectedSchoolId: Binding<String>,
        requireCodeVerification: Bool = true,
        onSchoolSelected: ((SchoolInfo) -> Void)? = nil
    ) {
        self._selectedSchoolId = selectedSchoolId
        self.requireCodeVerification = requireCodeVerification
        self.onSchoolSelected = onSchoolSelected
    }
    
    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(EZTeachColors.brightTeal)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("School")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selectedSchoolName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            SearchableSchoolPicker(
                selectedSchoolId: $selectedSchoolId,
                isPresented: $showPicker,
                requireCodeVerification: requireCodeVerification,
                onSchoolSelected: { school in
                    selectedSchoolName = school.name
                    onSchoolSelected?(school)
                }
            )
        }
        .onAppear {
            loadSchoolName()
        }
        .onChange(of: selectedSchoolId) { _, newValue in
            if !newValue.isEmpty {
                loadSchoolName()
            }
        }
    }
    
    private func loadSchoolName() {
        guard !selectedSchoolId.isEmpty else {
            selectedSchoolName = "Select School"
            return
        }
        
        db.collection("schools").document(selectedSchoolId).getDocument { snap, _ in
            if let data = snap?.data() {
                selectedSchoolName = data["name"] as? String ?? "Select School"
            }
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var schoolId = ""
        @State private var showPicker = true
        
        var body: some View {
            VStack {
                SchoolPickerButton(selectedSchoolId: $schoolId)
                    .padding()
                
                Button("Show Picker") {
                    showPicker = true
                }
            }
            .sheet(isPresented: $showPicker) {
                SearchableSchoolPicker(
                    selectedSchoolId: $schoolId,
                    isPresented: $showPicker
                )
            }
        }
    }
    
    return PreviewWrapper()
}
