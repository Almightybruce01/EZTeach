//
//  ElectivesHubView.swift
//  EZTeach
//
//  Hub for elective offerings: Art, Music, Dance, Band, P.E. / Gym.
//

import SwiftUI

enum ElectiveCategory: String, CaseIterable {
    case art = "Art"
    case music = "Music"
    case dance = "Dance"
    case band = "Band"
    case pe = "P.E. / Gym"

    var icon: String {
        switch self {
        case .art: return "paintpalette.fill"
        case .music: return "music.note"
        case .dance: return "figure.dance"
        case .band: return "music.mic"
        case .pe: return "figure.run"
        }
    }

    var description: String {
        switch self {
        case .art: return "Creative arts & visual expression"
        case .music: return "Music theory & appreciation"
        case .dance: return "Movement & dance"
        case .band: return "Band & instrumental music"
        case .pe: return "Physical education & fitness"
        }
    }

    var accentColor: Color {
        switch self {
        case .art: return EZTeachColors.tronOrange
        case .music: return EZTeachColors.brightTeal
        case .dance: return EZTeachColors.tronPink
        case .band: return EZTeachColors.softBlue
        case .pe: return .green
        }
    }
}

struct ElectivesHubView: View {
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("ELECTIVES")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(EZTeachColors.textMutedLight)

                    Text("Explore Art, Music, Dance, Band & P.E.")
                        .font(.subheadline)
                        .foregroundColor(EZTeachColors.textMutedLight)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(ElectiveCategory.allCases, id: \.rawValue) { category in
                            ElectiveCard(category: category)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ElectiveCard: View {
    let category: ElectiveCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [category.accentColor.opacity(0.8), category.accentColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                Image(systemName: category.icon)
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }

            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(EZTeachColors.textDark)

            Text(category.description)
                .font(.caption)
                .foregroundColor(EZTeachColors.textMutedLight)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(category.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}
