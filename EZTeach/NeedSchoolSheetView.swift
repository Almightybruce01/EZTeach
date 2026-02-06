//
//  NeedSchoolSheetView.swift
//  EZTeach
//

import SwiftUI

struct NeedSchoolSheetView: View {
    let feature: String
    let onSwitchSchool: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "building.2")
                    .font(.system(size: 56))
                    .foregroundColor(EZTeachColors.accent.opacity(0.7))

                Text("Join a school first")
                    .font(.title2.bold())

                Text("To use \(feature), switch to or join a school from the menu.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSwitchSchool()
                    }
                } label: {
                    Label("Switch Schools", systemImage: "arrow.triangle.swap")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(EZTeachColors.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(EZTeachColors.background)
            .navigationTitle(feature)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
