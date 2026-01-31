//
//  SubPlansListView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-08.
//

import SwiftUI

struct SubPlansListView: View {
    var body: some View {
        List {
            NavigationLink("Default Sub Plan Template") {
                SubPlanDetailView(title: "Default Sub Plan")
            }
        }
        .navigationTitle("Sub Plans")
    }
}
