//
//  AcademicsHubView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI

struct AcademicsHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink("Grades") {
                    GradesListView()
                }
            }
            .padding()
        }
        .navigationTitle("Academics")
    }
}
