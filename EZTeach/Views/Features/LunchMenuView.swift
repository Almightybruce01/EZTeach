//
//  LunchMenuView.swift
//  EZTeach
//
//  Weekly lunch menu display
//

import SwiftUI
import FirebaseFirestore

struct LunchMenuView: View {
    let schoolId: String
    let isAdmin: Bool
    
    @State private var menu: LunchMenu?
    @State private var isLoading = true
    @State private var selectedDay = Calendar.current.component(.weekday, from: Date()) - 2 // 0-4 for Mon-Fri
    @State private var showEditMenu = false
    
    private let db = Firestore.firestore()
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    
    var currentDayMenu: DailyMenu? {
        guard selectedDay >= 0 && selectedDay < 5 else { return nil }
        return menu?.days.first { $0.dayOfWeek == selectedDay + 1 }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week navigation
                HStack {
                    ForEach(0..<5, id: \.self) { index in
                        Button {
                            withAnimation { selectedDay = index }
                        } label: {
                            VStack(spacing: 4) {
                                Text(String(weekdays[index].prefix(3)))
                                    .font(.caption.bold())
                                
                                Circle()
                                    .fill(selectedDay == index ? EZTeachColors.accent : Color.clear)
                                    .frame(width: 8, height: 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedDay == index ? EZTeachColors.accent.opacity(0.1) : Color.clear)
                            .cornerRadius(12)
                        }
                        .foregroundColor(selectedDay == index ? EZTeachColors.accent : .secondary)
                    }
                }
                .padding()
                .background(EZTeachColors.secondaryBackground)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let dayMenu = currentDayMenu {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Main course
                            menuCard(
                                icon: "fork.knife",
                                title: "Main Course",
                                content: dayMenu.mainCourse,
                                color: EZTeachColors.accent
                            )
                            
                            // Sides
                            menuCard(
                                icon: "leaf.fill",
                                title: "Sides",
                                content: dayMenu.sides.joined(separator: ", "),
                                color: .green
                            )
                            
                            // Vegetarian option
                            menuCard(
                                icon: "carrot.fill",
                                title: "Vegetarian Option",
                                content: dayMenu.vegetarianOption,
                                color: .orange
                            )
                            
                            // Nutrition info
                            HStack(spacing: 16) {
                                nutritionBadge(value: dayMenu.calories, label: "Calories", icon: "flame.fill")
                                
                                if !dayMenu.allergens.isEmpty {
                                    allergenBadge(allergens: dayMenu.allergens)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Menu Available")
                            .font(.headline)
                        Text(isAdmin ? "Tap + to add this week's menu" : "Check back later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Lunch Menu")
            .toolbar {
                if isAdmin {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showEditMenu = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditMenu) {
                EditLunchMenuView(schoolId: schoolId, existingMenu: menu) {
                    loadMenu()
                }
            }
            .onAppear(perform: loadMenu)
        }
    }
    
    private func menuCard(icon: String, title: String, content: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(content)
                    .font(.subheadline.weight(.medium))
            }
            
            Spacer()
        }
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(14)
    }
    
    private func nutritionBadge(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.orange)
            Text("\(value)")
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func allergenBadge(allergens: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Allergens")
                    .font(.caption.bold())
            }
            
            Text(allergens.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func loadMenu() {
        isLoading = true
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        db.collection("lunchMenus")
            .whereField("schoolId", isEqualTo: schoolId)
            .whereField("weekStartDate", isGreaterThanOrEqualTo: Timestamp(date: weekStart.addingTimeInterval(-86400)))
            .limit(to: 1)
            .getDocuments { snap, _ in
                menu = snap?.documents.first.flatMap { LunchMenu.fromDocument($0) }
                isLoading = false
            }
    }
}

struct EditLunchMenuView: View {
    let schoolId: String
    let existingMenu: LunchMenu?
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var days: [(mainCourse: String, sides: String, vegetarian: String, allergens: String, calories: String)] = Array(repeating: ("", "", "", "", ""), count: 5)
    
    private let db = Firestore.firestore()
    private let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<5, id: \.self) { index in
                    Section(weekdays[index]) {
                        TextField("Main Course", text: $days[index].mainCourse)
                        TextField("Sides (comma-separated)", text: $days[index].sides)
                        TextField("Vegetarian Option", text: $days[index].vegetarian)
                        TextField("Allergens (comma-separated)", text: $days[index].allergens)
                        TextField("Calories", text: $days[index].calories)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Edit Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveMenu()
                    }
                }
            }
            .onAppear {
                if let menu = existingMenu {
                    for day in menu.days {
                        let index = day.dayOfWeek - 1
                        if index >= 0 && index < 5 {
                            days[index] = (
                                day.mainCourse,
                                day.sides.joined(separator: ", "),
                                day.vegetarianOption,
                                day.allergens.joined(separator: ", "),
                                "\(day.calories)"
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func saveMenu() {
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        let menuDays: [[String: Any]] = days.enumerated().map { index, day in
            [
                "dayOfWeek": index + 1,
                "mainCourse": day.mainCourse,
                "sides": day.sides.components(separatedBy: ", ").filter { !$0.isEmpty },
                "vegetarianOption": day.vegetarian,
                "allergens": day.allergens.components(separatedBy: ", ").filter { !$0.isEmpty },
                "calories": Int(day.calories) ?? 0
            ]
        }
        
        let data: [String: Any] = [
            "schoolId": schoolId,
            "weekStartDate": Timestamp(date: weekStart),
            "days": menuDays
        ]
        
        if let existing = existingMenu {
            db.collection("lunchMenus").document(existing.id).updateData(data) { _ in
                onSave()
                dismiss()
            }
        } else {
            db.collection("lunchMenus").addDocument(data: data) { _ in
                onSave()
                dismiss()
            }
        }
    }
}
