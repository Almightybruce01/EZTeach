//
//  LeaderboardView.swift
//  EZTeach
//
//  Per-game and general leaderboards: All-time, Monthly, Weekly.
//

import SwiftUI
import FirebaseAuth

struct LeaderboardView: View {
    @State private var selectedTab: LeaderboardTab = .general
    @State private var timeRange: LeaderboardTimeRange = .allTime
    @State private var selectedGameId: String = "math_addition"
    @State private var generalRanks: [LeaderboardRank] = []
    @State private var gameRanks: [LeaderboardRank] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    enum LeaderboardTab: String, CaseIterable, Identifiable {
        case general = "All Games"
        case perGame = "By Game"
        var id: String { rawValue }
    }
    
    private static let gameOptions: [(id: String, name: String)] = [
        ("math_addition", "Addition Blast"),
        ("math_subtraction", "Subtraction Race"),
        ("reading_sentence", "Sentence Builder"),
        ("reading_word_scramble", "Word Scramble"),
        ("reading_run_quiz", "Run & Quiz"),
        ("puzzle_memory", "Memory Match"),
        ("sn_calm_colors", "Calm Colors")
    ]
    
    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("LEADERBOARD")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(EZTeachColors.textMutedLight)
                    
                    Picker("Scope", selection: $selectedTab) {
                        ForEach(LeaderboardTab.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTab) { _, _ in load() }
                    
                    Picker("Time", selection: $timeRange) {
                        ForEach(LeaderboardTimeRange.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: timeRange) { _, _ in load() }
                    
                    if selectedTab == .perGame {
                        Picker("Game", selection: $selectedGameId) {
                            ForEach(Self.gameOptions, id: \.id) { g in
                                Text(g.name).tag(g.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)
                        .onChange(of: selectedGameId) { _, _ in load() }
                    }
                    
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if let err = errorMessage {
                        Text(err)
                            .font(.subheadline)
                            .foregroundColor(EZTeachColors.lightCoral)
                            .padding()
                    } else {
                        leaderboardList
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }
    
    private var leaderboardList: some View {
        let ranks = selectedTab == .general ? generalRanks : gameRanks
        return VStack(spacing: 0) {
            ForEach(ranks) { r in
                LeaderboardRow(rank: r, isCurrentUser: r.userId == Auth.auth().currentUser?.uid)
            }
            if ranks.isEmpty {
                Text("No scores yet. Play games to climb the board!")
                    .font(.subheadline)
                    .foregroundColor(EZTeachColors.textMutedLight)
                    .padding(.top, 40)
            }
        }
    }
    
    private func load() {
        isLoading = true
        errorMessage = nil
        if selectedTab == .general {
            GameLeaderboardService.shared.fetchGeneralLeaderboard(timeRange: timeRange, limit: 30) { ranks in
                generalRanks = ranks
                isLoading = false
            }
        } else {
            GameLeaderboardService.shared.fetchLeaderboard(gameId: selectedGameId, timeRange: timeRange, limit: 30) { ranks in
                gameRanks = ranks
                isLoading = false
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: LeaderboardRank
    let isCurrentUser: Bool
    
    /// Build a subtitle like "Lincoln Elementary • 5th Grade"
    private var subtitle: String {
        let parts = [rank.schoolName, rank.grade].filter { !$0.isEmpty }
        return parts.joined(separator: " • ")
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                if rank.rank <= 3 {
                    rankIcon
                } else {
                    Text("#\(rank.rank)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(rankColor)
                }
            }
            .frame(width: 46, height: 46)
            .background(rankColor.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Name + school/grade
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(rank.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(EZTeachColors.textDark)
                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(EZTeachColors.brightTeal)
                            .clipShape(Capsule())
                    }
                }
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(rank.score)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(EZTeachColors.textDark)
                Text("pts")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentUser ? EZTeachColors.brightTeal.opacity(0.10) : Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrentUser ? EZTeachColors.brightTeal.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var rankIcon: some View {
        switch rank.rank {
        case 1:
            Image(systemName: "crown.fill")
                .font(.system(size: 20))
                .foregroundColor(EZTeachColors.warmYellow)
        case 2:
            Image(systemName: "medal.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.gray)
        case 3:
            Image(systemName: "medal.fill")
                .font(.system(size: 18))
                .foregroundColor(EZTeachColors.softOrange)
        default:
            Text("#\(rank.rank)")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundColor(rankColor)
        }
    }
    
    private var rankColor: Color {
        switch rank.rank {
        case 1: return EZTeachColors.warmYellow
        case 2: return Color.gray
        case 3: return EZTeachColors.softOrange
        default: return EZTeachColors.brightTeal
        }
    }
}
