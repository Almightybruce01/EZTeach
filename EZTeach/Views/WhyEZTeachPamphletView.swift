//
//  WhyEZTeachPamphletView.swift
//  EZTeach
//
//  Pamphlet: "Why EZTeach" — 6 pages with graphics.
//

import SwiftUI

struct WhyEZTeachPamphletView: View {
    @State private var page = 0
    private let pages: [PamphletPage] = [
        PamphletPage(
            icon: "graduationcap.fill",
            title: "Why EZTeach",
            subtitle: "One platform for everyone",
            body: "Schools, teachers, students, and parents—all connected in one place.",
            accent: EZTeachColors.brightTeal
        ),
        PamphletPage(
            icon: "building.2.fill",
            title: "For Schools",
            subtitle: "Manage it all",
            body: "Attendance, grades, calendars, events, and office info. Reduce paperwork and stay organized.",
            accent: EZTeachColors.softPurple
        ),
        PamphletPage(
            icon: "person.fill",
            title: "For Teachers",
            subtitle: "Focus on teaching",
            body: "Classes, rosters, grading scales, sub plans, and communication—all in one hub.",
            accent: EZTeachColors.softOrange
        ),
        PamphletPage(
            icon: "gamecontroller.fill",
            title: "EZLearning",
            subtitle: "Games & books",
            body: "Students play leveled games and read interactive stories. Leaderboards celebrate progress.",
            accent: EZTeachColors.tronGreen
        ),
        PamphletPage(
            icon: "person.2.fill",
            title: "For Parents",
            subtitle: "Stay in the loop",
            body: "View grades, homework, and announcements. Link to your child's account and never miss a beat.",
            accent: EZTeachColors.lightCoral
        ),
        PamphletPage(
            icon: "checkmark.seal.fill",
            title: "Get Started",
            subtitle: "Join EZTeach today",
            body: "Simplify your school, engage your students, and connect your community.",
            accent: EZTeachColors.brightTeal
        )
    ]
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            TabView(selection: $page) {
                ForEach(0..<pages.count, id: \.self) { i in
                    pamphletPageView(pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .navigationTitle("Why EZTeach")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func pamphletPageView(_ p: PamphletPage) -> some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(p.accent.opacity(0.2))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(p.accent, lineWidth: 3)
                    .frame(width: 120, height: 120)
                Image(systemName: p.icon)
                    .font(.system(size: 48))
                    .foregroundColor(p.accent)
            }
            .padding(.top, 40)
            
            VStack(spacing: 12) {
                Text(p.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(EZTeachColors.textDark)
                Text(p.subtitle)
                    .font(.headline)
                    .foregroundColor(p.accent)
                Text(p.body)
                    .font(.body)
                    .foregroundColor(EZTeachColors.textMutedLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct PamphletPage {
    let icon: String
    let title: String
    let subtitle: String
    let body: String
    let accent: Color
}
