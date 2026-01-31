//
//  SubPlanDetailView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI

struct SubPlanDetailView: View {

    let title: String

    @State private var instructions = "Enter sub instructions here…"

    var body: some View {
        Form {
            Section("Instructions") {
                TextEditor(text: $instructions)
                    .frame(height: 200)
            }
        }
        .navigationTitle(title)
    }
}
