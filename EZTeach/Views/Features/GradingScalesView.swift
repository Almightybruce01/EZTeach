//
//  GradingScalesView.swift
//  EZTeach
//
//  Custom grading scales management
//

import SwiftUI
import FirebaseFirestore

struct GradingScalesView: View {
    let schoolId: String
    
    @State private var scales: [GradingScale] = []
    @State private var selectedScale: GradingScale?
    @State private var isLoading = true
    @State private var showAddScale = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    List {
                        // Default scales
                        Section("Standard Scales") {
                            scaleRow(GradingScale.standard, isSystem: true)
                            scaleRow(plusMinusScale, isSystem: true)
                            scaleRow(passFail, isSystem: true)
                        }
                        
                        // Custom scales
                        if !scales.isEmpty {
                            Section("Custom Scales") {
                                ForEach(scales) { scale in
                                    scaleRow(scale, isSystem: false)
                                }
                                .onDelete(perform: deleteScale)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Grading Scales")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddScale = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $selectedScale) { scale in
                GradingScaleDetailView(scale: scale)
            }
            .sheet(isPresented: $showAddScale) {
                CreateGradingScaleView(schoolId: schoolId) {
                    loadScales()
                }
            }
            .onAppear(perform: loadScales)
        }
    }
    
    private func scaleRow(_ scale: GradingScale, isSystem: Bool) -> some View {
        Button {
            selectedScale = scale
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(scale.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        if scale.isDefault {
                            Text("DEFAULT")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(EZTeachColors.accent)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(scale.ranges.count) grade levels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Preview
                HStack(spacing: 4) {
                    ForEach(scale.ranges.prefix(4), id: \.letter) { range in
                        Text(range.letter)
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    if scale.ranges.count > 4 {
                        Text("...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var plusMinusScale: GradingScale {
        GradingScale(
            id: "plus_minus",
            schoolId: "",
            name: "A-F with +/-",
            isDefault: false,
            ranges: [
                GradingScale.GradeRange(letter: "A+", minPercent: 97, maxPercent: 100, gpaValue: 4.0),
                GradingScale.GradeRange(letter: "A", minPercent: 93, maxPercent: 96.99, gpaValue: 4.0),
                GradingScale.GradeRange(letter: "A-", minPercent: 90, maxPercent: 92.99, gpaValue: 3.7),
                GradingScale.GradeRange(letter: "B+", minPercent: 87, maxPercent: 89.99, gpaValue: 3.3),
                GradingScale.GradeRange(letter: "B", minPercent: 83, maxPercent: 86.99, gpaValue: 3.0),
                GradingScale.GradeRange(letter: "B-", minPercent: 80, maxPercent: 82.99, gpaValue: 2.7),
                GradingScale.GradeRange(letter: "C+", minPercent: 77, maxPercent: 79.99, gpaValue: 2.3),
                GradingScale.GradeRange(letter: "C", minPercent: 73, maxPercent: 76.99, gpaValue: 2.0),
                GradingScale.GradeRange(letter: "C-", minPercent: 70, maxPercent: 72.99, gpaValue: 1.7),
                GradingScale.GradeRange(letter: "D+", minPercent: 67, maxPercent: 69.99, gpaValue: 1.3),
                GradingScale.GradeRange(letter: "D", minPercent: 63, maxPercent: 66.99, gpaValue: 1.0),
                GradingScale.GradeRange(letter: "D-", minPercent: 60, maxPercent: 62.99, gpaValue: 0.7),
                GradingScale.GradeRange(letter: "F", minPercent: 0, maxPercent: 59.99, gpaValue: 0.0)
            ]
        )
    }
    
    private var passFail: GradingScale {
        GradingScale(
            id: "pass_fail",
            schoolId: "",
            name: "Pass/Fail",
            isDefault: false,
            ranges: [
                GradingScale.GradeRange(letter: "P", minPercent: 60, maxPercent: 100, gpaValue: 1.0),
                GradingScale.GradeRange(letter: "F", minPercent: 0, maxPercent: 59.99, gpaValue: 0.0)
            ]
        )
    }
    
    private func loadScales() {
        isLoading = true
        db.collection("gradingScales")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                scales = snap?.documents.compactMap { doc -> GradingScale? in
                    let data = doc.data()
                    let ranges = (data["ranges"] as? [[String: Any]] ?? []).map { r in
                        GradingScale.GradeRange(
                            letter: r["letter"] as? String ?? "",
                            minPercent: r["minPercent"] as? Double ?? 0,
                            maxPercent: r["maxPercent"] as? Double ?? 100,
                            gpaValue: r["gpaValue"] as? Double ?? 0
                        )
                    }
                    return GradingScale(
                        id: doc.documentID,
                        schoolId: schoolId,
                        name: data["name"] as? String ?? "",
                        isDefault: data["isDefault"] as? Bool ?? false,
                        ranges: ranges
                    )
                } ?? []
                isLoading = false
            }
    }
    
    private func deleteScale(at offsets: IndexSet) {
        for index in offsets {
            db.collection("gradingScales").document(scales[index].id).delete()
        }
        loadScales()
    }
}

struct GradingScaleDetailView: View {
    let scale: GradingScale
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(scale.ranges, id: \.letter) { range in
                    HStack {
                        Text(range.letter)
                            .font(.title2.bold())
                            .frame(width: 50)
                            .foregroundColor(colorForGrade(range.letter))
                        
                        VStack(alignment: .leading) {
                            Text("\(Int(range.minPercent))% - \(Int(range.maxPercent))%")
                                .font(.subheadline)
                            Text("GPA: \(range.gpaValue, specifier: "%.1f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Visual bar
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForGrade(range.letter).opacity(0.3))
                                .frame(width: geo.size.width * (range.maxPercent - range.minPercent) / 100)
                        }
                        .frame(width: 80, height: 20)
                    }
                }
            }
            .navigationTitle(scale.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func colorForGrade(_ letter: String) -> Color {
        if letter.hasPrefix("A") { return .green }
        if letter.hasPrefix("B") { return .blue }
        if letter.hasPrefix("C") { return .yellow }
        if letter.hasPrefix("D") { return .orange }
        if letter == "P" { return .green }
        return .red
    }
}

struct CreateGradingScaleView: View {
    let schoolId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var ranges: [(letter: String, min: String, max: String, gpa: String)] = [
        ("A", "90", "100", "4.0"),
        ("B", "80", "89.99", "3.0"),
        ("C", "70", "79.99", "2.0"),
        ("D", "60", "69.99", "1.0"),
        ("F", "0", "59.99", "0.0")
    ]
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Scale Name") {
                    TextField("e.g. My Custom Scale", text: $name)
                }
                
                Section("Grade Ranges") {
                    ForEach(0..<ranges.count, id: \.self) { index in
                        if index < ranges.count {
                        HStack {
                            TextField("Grade", text: $ranges[index].letter)
                                .frame(width: 50)
                            
                            TextField("Min %", text: $ranges[index].min)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                            
                            Text("-")
                            
                            TextField("Max %", text: $ranges[index].max)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                            
                            TextField("GPA", text: $ranges[index].gpa)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)
                        }
                        }
                    }
                    
                    Button("Add Grade Level") {
                        ranges.append(("", "", "", ""))
                    }
                }
            }
            .navigationTitle("Create Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveScale()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveScale() {
        let gradeRanges: [[String: Any]] = ranges.compactMap { r in
            guard !r.letter.isEmpty,
                  let min = Double(r.min),
                  let max = Double(r.max),
                  let gpa = Double(r.gpa) else { return nil }
            
            return [
                "letter": r.letter,
                "minPercent": min,
                "maxPercent": max,
                "gpaValue": gpa
            ]
        }
        
        db.collection("gradingScales").addDocument(data: [
            "schoolId": schoolId,
            "name": name,
            "isDefault": false,
            "ranges": gradeRanges
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}
