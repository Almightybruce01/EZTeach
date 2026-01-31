//
//  GradeDetailView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI

struct GradeDetailView: View {
    let grade: Int

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle.bold())

            Text("Classes, teachers, students.")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle(title)
    }

    private var title: String {
        switch grade {
        case 0: return "Pre‑K / Kindergarten"
        case 1: return "1st Grade"
        case 2: return "2nd Grade"
        case 3: return "3rd Grade"
        default: return "Grade \(grade)"
        }
    }
}
