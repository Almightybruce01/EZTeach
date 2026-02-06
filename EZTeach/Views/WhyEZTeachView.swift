//
//  WhyEZTeachView.swift
//  EZTeach
//
//  Sales pitch page: three paragraphs + features.
//

import SwiftUI

struct WhyEZTeachView: View {
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("Why EZTeach")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [EZTeachColors.brightTeal, EZTeachColors.softBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 20) {
                        paragraph(
                            "EZTeach brings schools, teachers, students, and parents into one seamless platform. From attendance to grades, calendars to homework, everything you need is in one place. Schools save time and reduce paperwork while teachers focus on teaching, not admin."
                        )
                        paragraph(
                            "Students get a dedicated learning hub with EZLearning—games and books tailored to their grade and level. Interactive stories, sentence builders, run-and-quiz games, and free classics from Project Gutenberg keep kids engaged and growing. Leaderboards celebrate progress across all-time, monthly, and weekly scores."
                        )
                        paragraph(
                            "For parents, EZTeach offers clear visibility into grades, homework, and school events. Districts can manage multiple schools from a single dashboard. With EZTeach, learning is simpler, communication is clearer, and everyone stays connected."
                        )
                    }
                    
                    Text("Features")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(EZTeachColors.textDark)
                    
                    featureGrid
                }
                .padding(24)
            }
        }
        .navigationTitle("Why EZTeach")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(EZTeachColors.textDark)
            .lineSpacing(8)
    }
    
    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            FeatureChip(icon: "person.3.fill", title: "School Management")
            FeatureChip(icon: "calendar", title: "Calendar & Events")
            FeatureChip(icon: "chart.bar.fill", title: "Grades & Reporting")
            FeatureChip(icon: "gamecontroller.fill", title: "EZLearning Games")
            FeatureChip(icon: "book.fill", title: "Readings & Free Books")
            FeatureChip(icon: "trophy.fill", title: "Leaderboards")
            FeatureChip(icon: "bell.fill", title: "Announcements")
            FeatureChip(icon: "building.2.fill", title: "District Dashboard")
        }
    }
}

struct FeatureChip: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(EZTeachColors.brightTeal)
                .frame(width: 40, height: 40)
                .background(EZTeachColors.brightTeal.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(EZTeachColors.textDark)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(EZTeachColors.brightTeal.opacity(0.2), lineWidth: 1)
        )
    }
}
