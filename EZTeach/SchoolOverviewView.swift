//
//  SchoolOverviewView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI

struct SchoolOverviewView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("School Overview")
                .font(.title.bold())

            Text("School name, address, and district info go here.")
            Spacer()
        }
        .padding()
        .navigationTitle("Overview")
    }
}
