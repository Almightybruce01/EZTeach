//
//  DefaultPasswordReportView.swift
//  EZTeach
//
//  Lists students still using default password. Default is Student ID + ! (e.g. ABC12345!)
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DefaultPasswordReportView: View {
    @State private var students: [Student] = []
    @State private var isLoading = true
    @State private var schoolIds: [String] = []
    @State private var selectedSchoolId: String = ""
    @State private var schoolNames: [String: String] = [:]
    @State private var isDistrict = false
    
    private let db = Firestore.firestore()
    
    private var defaultPasswordStudents: [Student] {
        students.filter { $0.usesDefaultPassword }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isDistrict && schoolIds.count > 1 {
                Picker("School", selection: $selectedSchoolId) {
                    Text("All Schools").tag("")
                    ForEach(schoolIds, id: \.self) { sid in
                        Text(schoolNames[sid] ?? "School").tag(sid)
                    }
                }
                .pickerStyle(.menu)
                .padding()
            }
            
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(EZTeachColors.warning)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Default Password Warning")
                                    .font(.headline)
                                Text("Students below have not changed their password. Default is Student ID + ! (e.g. ABC12345!)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(EZTeachColors.warning.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        if defaultPasswordStudents.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(EZTeachColors.success)
                                Text("All students have changed their password")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        } else {
                            Text("\(defaultPasswordStudents.count) student(s) with default password")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(defaultPasswordStudents) { student in
                                NavigationLink {
                                    StudentProfileView(student: student)
                                } label: {
                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(EZTeachColors.warning.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Text(student.firstName.prefix(1) + student.lastName.prefix(1))
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(EZTeachColors.warning)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(student.fullName)
                                                .font(.subheadline.weight(.medium))
                                            Text("Student ID: \(student.studentCode) • Password: \(student.studentCode)!")
                                                .font(.caption.monospaced())
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(EZTeachColors.secondaryBackground)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(EZTeachColors.background)
        .navigationTitle("Default Password Report")
        .onAppear(perform: loadData)
        .onChange(of: selectedSchoolId) { _, _ in loadStudents() }
    }
    
    private func loadData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            let role = data["role"] as? String ?? ""
            isDistrict = (role == "district")
            
            if isDistrict, let districtId = data["districtId"] as? String {
                db.collection("districts").document(districtId).getDocument { dSnap, _ in
                    schoolIds = dSnap?.data()?["schoolIds"] as? [String] ?? []
                    selectedSchoolId = schoolIds.first ?? ""
                    for sid in schoolIds {
                        db.collection("schools").document(sid).getDocument { sSnap, _ in
                            schoolNames[sid] = sSnap?.data()?["name"] as? String ?? "School"
                        }
                    }
                    loadStudents()
                }
            } else if let schoolId = data["activeSchoolId"] as? String {
                schoolIds = [schoolId]
                selectedSchoolId = schoolId
                db.collection("schools").document(schoolId).getDocument { sSnap, _ in
                    schoolNames[schoolId] = sSnap?.data()?["name"] as? String ?? "School"
                }
                loadStudents()
            } else {
                isLoading = false
            }
        }
    }
    
    private func loadStudents() {
        isLoading = true
        let idsToLoad = selectedSchoolId.isEmpty ? schoolIds : [selectedSchoolId]
        
        guard !idsToLoad.isEmpty else {
            students = []
            isLoading = false
            return
        }
        
        if idsToLoad.count == 1 {
            db.collection("students")
                .whereField("schoolId", isEqualTo: idsToLoad[0])
                .order(by: "lastName")
                .getDocuments { snap, _ in
                    students = snap?.documents.compactMap { Student.fromDocument($0) } ?? []
                    isLoading = false
                }
        } else {
            var all: [Student] = []
            let group = DispatchGroup()
            for sid in idsToLoad {
                group.enter()
                db.collection("students")
                    .whereField("schoolId", isEqualTo: sid)
                    .order(by: "lastName")
                    .getDocuments { snap, _ in
                        all.append(contentsOf: snap?.documents.compactMap { Student.fromDocument($0) } ?? [])
                        group.leave()
                    }
            }
            group.notify(queue: .main) {
                students = all.sorted { $0.lastName < $1.lastName }
                isLoading = false
            }
        }
    }
}
