//
//  StudentAccountView.swift
//  EZTeach
//

import SwiftUI

struct StudentAccountView: View {
    let student: Student
    let schoolName: String

    var body: some View {
        ZStack {
            EZTeachColors.tronGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(EZTeachColors.tronCyan.opacity(0.2))
                                .frame(width: 100, height: 100)
                            Text(student.firstName.prefix(1).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(EZTeachColors.tronCyan)
                        }
                        VStack(spacing: 4) {
                            Text(student.fullName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                Text("Student")
                                    .font(.subheadline)
                            }
                            .foregroundColor(EZTeachColors.tronCyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(EZTeachColors.tronCyan.opacity(0.15))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACCOUNT INFO")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(EZTeachColors.tronCyan)
                            .padding(.horizontal)

                        infoRow(icon: "number", label: "Student ID", value: student.studentCode)
                        infoRow(icon: "building.2.fill", label: "School", value: schoolName)
                        infoRow(icon: "graduationcap.fill", label: "Grade", value: GradeUtils.label(student.gradeLevel))
                        if let email = student.email, !email.isEmpty {
                            infoRow(icon: "envelope.fill", label: "Email", value: email)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(EZTeachColors.tronCyan.opacity(0.4), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                    )
                    .padding(.horizontal)

                    NavigationLink {
                        WhyEZTeachView()
                    } label: {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(EZTeachColors.tronCyan)
                            Text("Why EZTeach")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(EZTeachColors.tronCyan.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)

                    NavigationLink {
                        WhyEZTeachPamphletView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(EZTeachColors.tronCyan)
                            Text("Why EZTeach Pamphlet")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(EZTeachColors.tronCyan.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "key.fill")
                                .foregroundColor(EZTeachColors.tronCyan)
                            Text("Login Info")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        Text("Your Student ID is \(student.studentCode). If you need to reset your password, ask your teacher.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(EZTeachColors.tronCyan.opacity(0.35), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(EZTeachColors.tronCyan)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}
