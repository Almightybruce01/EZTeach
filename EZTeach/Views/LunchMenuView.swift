//
//  LunchMenuView.swift
//  EZTeach
//
//  Enhanced Lunch Menu with photo upload support
//  Includes name, photo/file upload (not just links)
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// MARK: - Lunch Item Model
struct LunchMenuItem: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var imageUrl: String?
    var price: Double?
    var calories: Int?
    var allergens: [String]
    var isVegetarian: Bool
    var isGlutenFree: Bool
    var category: LunchCategory
    var dayOfWeek: String?  // For weekly menus
    
    static func fromDocument(_ doc: DocumentSnapshot) -> LunchMenuItem? {
        guard let data = doc.data() else { return nil }
        return LunchMenuItem(
            id: doc.documentID,
            name: data["name"] as? String ?? "",
            description: data["description"] as? String ?? "",
            imageUrl: data["imageUrl"] as? String,
            price: data["price"] as? Double,
            calories: data["calories"] as? Int,
            allergens: data["allergens"] as? [String] ?? [],
            isVegetarian: data["isVegetarian"] as? Bool ?? false,
            isGlutenFree: data["isGlutenFree"] as? Bool ?? false,
            category: LunchCategory(rawValue: data["category"] as? String ?? "") ?? .entree,
            dayOfWeek: data["dayOfWeek"] as? String
        )
    }
}

enum LunchCategory: String, Codable, CaseIterable {
    case entree = "Entree"
    case side = "Side"
    case drink = "Drink"
    case dessert = "Dessert"
    case snack = "Snack"
    case breakfast = "Breakfast"
    
    var icon: String {
        switch self {
        case .entree: return "fork.knife"
        case .side: return "carrot.fill"
        case .drink: return "cup.and.saucer.fill"
        case .dessert: return "birthday.cake.fill"
        case .snack: return "bag.fill"
        case .breakfast: return "sun.horizon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .entree: return .orange
        case .side: return .green
        case .drink: return .blue
        case .dessert: return .pink
        case .snack: return .purple
        case .breakfast: return .yellow
        }
    }
}

// MARK: - Daily Menu Model
struct DailyLunchMenu: Identifiable, Codable {
    let id: String
    let schoolId: String
    var date: Date
    var items: [LunchMenuItem]
    var specialNote: String?
    var createdBy: String
    var createdAt: Date
    
    static func fromDocument(_ doc: DocumentSnapshot) -> DailyLunchMenu? {
        guard let data = doc.data() else { return nil }
        
        let itemsData = data["items"] as? [[String: Any]] ?? []
        let items = itemsData.compactMap { itemData -> LunchMenuItem? in
            return LunchMenuItem(
                id: itemData["id"] as? String ?? UUID().uuidString,
                name: itemData["name"] as? String ?? "",
                description: itemData["description"] as? String ?? "",
                imageUrl: itemData["imageUrl"] as? String,
                price: itemData["price"] as? Double,
                calories: itemData["calories"] as? Int,
                allergens: itemData["allergens"] as? [String] ?? [],
                isVegetarian: itemData["isVegetarian"] as? Bool ?? false,
                isGlutenFree: itemData["isGlutenFree"] as? Bool ?? false,
                category: LunchCategory(rawValue: itemData["category"] as? String ?? "") ?? .entree,
                dayOfWeek: nil
            )
        }
        
        return DailyLunchMenu(
            id: doc.documentID,
            schoolId: data["schoolId"] as? String ?? "",
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            items: items,
            specialNote: data["specialNote"] as? String,
            createdBy: data["createdBy"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

// MARK: - Main Lunch Menu View
struct LunchMenuView: View {
    let schoolId: String
    let userRole: String
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    @State private var dailyMenu: DailyLunchMenu?
    @State private var isLoading = true
    @State private var showingAddItem = false
    @State private var showingEditMenu = false
    @State private var selectedCategory: LunchCategory?
    
    private let db = Firestore.firestore()
    
    var canEdit: Bool {
        ["school", "district", "teacher", "librarian"].contains(userRole)
    }
    
    var filteredItems: [LunchMenuItem] {
        guard let menu = dailyMenu else { return [] }
        if let cat = selectedCategory {
            return menu.items.filter { $0.category == cat }
        }
        return menu.items
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Date Picker
                    datePicker
                    
                    // Category Filter
                    categoryFilter
                    
                    // Menu Items
                    menuItemsSection
                    
                    // Special Note
                    if let note = dailyMenu?.specialNote, !note.isEmpty {
                        specialNoteSection(note)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.green.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Lunch Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                if canEdit {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingAddItem = true
                            } label: {
                                Label("Add Menu Item", systemImage: "plus.circle")
                            }
                            
                            Button {
                                showingEditMenu = true
                            } label: {
                                Label("Edit Today's Menu", systemImage: "pencil")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddLunchItemView(schoolId: schoolId, date: selectedDate) { newItem in
                    if dailyMenu != nil {
                        dailyMenu?.items.append(newItem)
                        saveMenu()
                    } else {
                        createMenu(with: [newItem])
                    }
                }
            }
            .sheet(isPresented: $showingEditMenu) {
                if let menu = dailyMenu {
                    EditLunchMenuView(menu: menu) { updatedMenu in
                        dailyMenu = updatedMenu
                        saveMenu()
                    }
                }
            }
            .onAppear { loadMenu() }
            .onChange(of: selectedDate) { _, _ in loadMenu() }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.gradient)
                    .frame(width: 60, height: 60)
                Image(systemName: "fork.knife")
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("School Lunch Menu")
                    .font(.title2.bold())
                    .foregroundColor(EZTeachColors.textPrimary)
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(EZTeachColors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Date Picker
    private var datePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(-2...5, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    DateButton(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)) {
                        selectedDate = date
                    }
                }
            }
        }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedCategory = nil
                } label: {
                    Text("All")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.orange : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == nil ? .white : EZTeachColors.textPrimary)
                        .cornerRadius(20)
                }
                
                ForEach(LunchCategory.allCases, id: \.rawValue) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? category.color : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == category ? .white : EZTeachColors.textPrimary)
                        .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // MARK: - Menu Items
    private var menuItemsSection: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if filteredItems.isEmpty {
                emptyMenuState
            } else {
                ForEach(filteredItems) { item in
                    LunchMenuItemCard(item: item, canEdit: canEdit) {
                        // Edit item
                    } onDelete: {
                        dailyMenu?.items.removeAll { $0.id == item.id }
                        saveMenu()
                    }
                }
            }
        }
    }
    
    private var emptyMenuState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Menu Items")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            Text("The menu for this day hasn't been added yet")
                .font(.caption)
                .foregroundColor(EZTeachColors.textSecondary)
            
            if canEdit {
                Button {
                    showingAddItem = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Menu Item")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange.gradient)
                    .cornerRadius(25)
                }
            }
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Special Note
    private func specialNoteSection(_ note: String) -> some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            Text(note)
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Data Operations
    private func loadMenu() {
        isLoading = true
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        db.collection("lunchMenus")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments(source: .default) { snap, _ in
                dailyMenu = snap?.documents.first.flatMap { DailyLunchMenu.fromDocument($0) }
                isLoading = false
            }
    }
    
    private func saveMenu() {
        guard let menu = dailyMenu else { return }
        
        let menuData: [String: Any] = [
            "schoolId": menu.schoolId,
            "date": Timestamp(date: menu.date),
            "items": menu.items.map { item -> [String: Any] in
                [
                    "id": item.id,
                    "name": item.name,
                    "description": item.description,
                    "imageUrl": item.imageUrl ?? "",
                    "price": item.price ?? 0,
                    "calories": item.calories ?? 0,
                    "allergens": item.allergens,
                    "isVegetarian": item.isVegetarian,
                    "isGlutenFree": item.isGlutenFree,
                    "category": item.category.rawValue
                ]
            },
            "specialNote": menu.specialNote ?? "",
            "createdBy": menu.createdBy,
            "createdAt": Timestamp(date: menu.createdAt)
        ]
        
        db.collection("lunchMenus").document(menu.id).setData(menuData)
    }
    
    private func createMenu(with items: [LunchMenuItem]) {
        let menu = DailyLunchMenu(
            id: UUID().uuidString,
            schoolId: schoolId,
            date: Calendar.current.startOfDay(for: selectedDate),
            items: items,
            specialNote: nil,
            createdBy: Auth.auth().currentUser?.uid ?? "",
            createdAt: Date()
        )
        dailyMenu = menu
        saveMenu()
    }
}

// MARK: - Date Button
struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(date.formatted(.dateTime.day()))
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : EZTeachColors.textPrimary)
            }
            .frame(width: 50, height: 60)
            .background(isSelected ? AnyShapeStyle(Color.orange.gradient) : AnyShapeStyle(isToday ? Color.orange.opacity(0.2) : Color.white))
            .cornerRadius(12)
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0), radius: 3)
        }
    }
}

// MARK: - Lunch Menu Item Card
struct LunchMenuItemCard: View {
    let item: LunchMenuItem
    let canEdit: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            if let imageUrl = item.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    itemPlaceholder
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                itemPlaceholder
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(EZTeachColors.textPrimary)
                    
                    if item.isVegetarian {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if item.isGlutenFree {
                        Text("GF")
                            .font(.caption2.bold())
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    }
                }
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    // Category
                    HStack(spacing: 4) {
                        Image(systemName: item.category.icon)
                        Text(item.category.rawValue)
                    }
                    .font(.caption2)
                    .foregroundColor(item.category.color)
                    
                    // Calories
                    if let calories = item.calories {
                        Text("\(calories) cal")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    // Price
                    if let price = item.price, price > 0 {
                        Text("$\(price, specifier: "%.2f")")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
                
                // Allergens
                if !item.allergens.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(item.allergens.joined(separator: ", "))
                            .foregroundColor(.orange)
                    }
                    .font(.caption2)
                }
            }
            
            Spacer()
            
            if canEdit {
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private var itemPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(item.category.color.opacity(0.2))
            Image(systemName: item.category.icon)
                .font(.title2)
                .foregroundColor(item.category.color)
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - Add Lunch Item View
struct AddLunchItemView: View {
    let schoolId: String
    let date: Date
    let onSave: (LunchMenuItem) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var category: LunchCategory = .entree
    @State private var price: String = ""
    @State private var calories: String = ""
    @State private var isVegetarian = false
    @State private var isGlutenFree = false
    @State private var allergens: [String] = []
    @State private var newAllergen = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    
    private let storage = Storage.storage()
    
    let commonAllergens = ["Milk", "Eggs", "Peanuts", "Tree Nuts", "Wheat", "Soy", "Fish", "Shellfish"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section("Photo") {
                    if let image = selectedImage {
                        HStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Spacer()
                            
                            VStack {
                                Button("Change") {
                                    showingImagePicker = true
                                }
                                .foregroundColor(.blue)
                                
                                Button("Remove") {
                                    selectedImage = nil
                                }
                                .foregroundColor(.red)
                            }
                        }
                    } else {
                        Button {
                            showingImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add Photo")
                                        .font(.headline)
                                        .foregroundColor(EZTeachColors.textPrimary)
                                    Text("Take a photo or upload from library")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Basic Info
                Section("Item Details") {
                    TextField("Name (required)", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Picker("Category", selection: $category) {
                        ForEach(LunchCategory.allCases, id: \.rawValue) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.rawValue)
                            }
                            .tag(cat)
                        }
                    }
                }
                
                // Nutrition
                Section("Nutrition Info (Optional)") {
                    TextField("Price (e.g., 3.50)", text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                    
                    Toggle("Vegetarian", isOn: $isVegetarian)
                    Toggle("Gluten-Free", isOn: $isGlutenFree)
                }
                
                // Allergens
                Section("Allergens") {
                    // Common allergens quick-add
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonAllergens, id: \.self) { allergen in
                                Button {
                                    if allergens.contains(allergen) {
                                        allergens.removeAll { $0 == allergen }
                                    } else {
                                        allergens.append(allergen)
                                    }
                                } label: {
                                    Text(allergen)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(allergens.contains(allergen) ? Color.orange : Color.gray.opacity(0.2))
                                        .foregroundColor(allergens.contains(allergen) ? .white : EZTeachColors.textPrimary)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    
                    // Current allergens
                    if !allergens.isEmpty {
                        ForEach(allergens, id: \.self) { allergen in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(allergen)
                                Spacer()
                                Button {
                                    allergens.removeAll { $0 == allergen }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    // Add custom
                    HStack {
                        TextField("Add custom allergen", text: $newAllergen)
                        Button {
                            if !newAllergen.isEmpty {
                                allergens.append(newAllergen)
                                newAllergen = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Add Menu Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.isEmpty || isUploading)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                LunchImagePicker(image: $selectedImage)
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Uploading photo...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func saveItem() {
        isUploading = true
        
        // Upload image if present
        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.7) {
            let imageId = UUID().uuidString
            let imageRef = storage.reference().child("lunchMenus/\(schoolId)/\(imageId).jpg")
            
            imageRef.putData(imageData) { _, _ in
                imageRef.downloadURL { url, _ in
                    createItem(imageUrl: url?.absoluteString)
                }
            }
        } else {
            createItem(imageUrl: nil)
        }
    }
    
    private func createItem(imageUrl: String?) {
        let item = LunchMenuItem(
            id: UUID().uuidString,
            name: name,
            description: description,
            imageUrl: imageUrl,
            price: Double(price),
            calories: Int(calories),
            allergens: allergens,
            isVegetarian: isVegetarian,
            isGlutenFree: isGlutenFree,
            category: category,
            dayOfWeek: nil
        )
        
        isUploading = false
        onSave(item)
        dismiss()
    }
}

// MARK: - Image Picker
struct LunchImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LunchImagePicker
        
        init(_ parent: LunchImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Edit Lunch Menu View
struct EditLunchMenuView: View {
    let menu: DailyLunchMenu
    let onSave: (DailyLunchMenu) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var specialNote: String = ""
    @State private var items: [LunchMenuItem] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Special Note") {
                    TextField("Add a note (e.g., 'Pizza Day!')", text: $specialNote, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Menu Items (\(items.count))") {
                    ForEach(items) { item in
                        HStack {
                            Image(systemName: item.category.icon)
                                .foregroundColor(item.category.color)
                            Text(item.name)
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        items.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            .navigationTitle("Edit Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        var updatedMenu = menu
                        updatedMenu.items = items
                        updatedMenu.specialNote = specialNote.isEmpty ? nil : specialNote
                        onSave(updatedMenu)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.gradient)
                            .cornerRadius(12)
                    }
                }
            }
            .onAppear {
                specialNote = menu.specialNote ?? ""
                items = menu.items
            }
        }
    }
}
