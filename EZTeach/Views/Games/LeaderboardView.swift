//
//  LeaderboardView.swift
//  EZTeach
//
//  Per-game and general leaderboards with School / Worldwide scope.
//  Top 100 students shown in each view.
//

import SwiftUI
import FirebaseAuth

struct LeaderboardView: View {
    @State private var selectedTab: LeaderboardTab = .general
    @State private var scopeTab: LeaderboardScope = .worldwide
    @State private var timeRange: LeaderboardTimeRange = .allTime
    @State private var selectedGameId: String = "math_addition"
    @State private var generalRanks: [LeaderboardRank] = []
    @State private var gameRanks: [LeaderboardRank] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var userSchoolId: String?
    @State private var schoolResolved = false

    enum LeaderboardTab: String, CaseIterable, Identifiable {
        case general = "All Games"
        case perGame = "By Game"
        var id: String { rawValue }
    }

    enum LeaderboardScope: String, CaseIterable, Identifiable {
        case mySchool = "My School"
        case worldwide = "Worldwide"
        var id: String { rawValue }
    }

    private static let gameOptions: [(id: String, name: String)] = [
        ("math_addition", "Addition Blast"),
        ("math_subtraction", "Subtraction Race"),
        ("math_multiplication", "Multiplication"),
        ("math_fractions", "Fractions"),
        ("reading_sentence", "Sentence Builder"),
        ("reading_word_scramble", "Word Scramble"),
        ("reading_run_quiz", "Run & Quiz"),
        ("puzzle_memory", "Memory Match"),
        ("puzzle_pattern", "Pattern Game"),
        ("sn_calm_colors", "Calm Colors"),
        ("racing_math", "Racing Math")
    ]

    var body: some View {
        ZStack {
            EZTeachColors.lightAppealGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 6) {
                        Text("LEADERBOARD")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(EZTeachColors.textMutedLight)
                        Text("TOP 100")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(EZTeachColors.brightTeal)
                    }

                    // MARK: - Scope: My School / Worldwide
                    Picker("Scope", selection: $scopeTab) {
                        ForEach(LeaderboardScope.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: scopeTab) { _, _ in load() }

                    // MARK: - Type: All Games / By Game
                    Picker("Type", selection: $selectedTab) {
                        ForEach(LeaderboardTab.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTab) { _, _ in load() }

                    // MARK: - Time Range
                    Picker("Time", selection: $timeRange) {
                        ForEach(LeaderboardTimeRange.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: timeRange) { _, _ in load() }

                    // MARK: - Game Picker (per-game only)
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

                    // Scope info badge
                    if scopeTab == .mySchool && userSchoolId == nil && schoolResolved {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("No school found. Showing worldwide results.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // MARK: - Results
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
                .padding(.vertical)
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Resolve user's school once
            GameLeaderboardService.shared.resolveCurrentUserSchoolId { sid in
                userSchoolId = sid
                schoolResolved = true
                load()
            }
        }
    }

    // MARK: - Leaderboard List
    private var leaderboardList: some View {
        let ranks = selectedTab == .general ? generalRanks : gameRanks
        return VStack(spacing: 0) {
            // Count header
            if !ranks.isEmpty {
                HStack {
                    Text("\(ranks.count) student\(ranks.count == 1 ? "" : "s")")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(scopeTab == .mySchool ? "School Rankings" : "Worldwide Rankings")
                        .font(.caption.bold())
                        .foregroundColor(EZTeachColors.brightTeal)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            ForEach(ranks) { r in
                LeaderboardRow(rank: r, isCurrentUser: r.userId == Auth.auth().currentUser?.uid)
            }
            if ranks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(EZTeachColors.textMutedLight.opacity(0.5))
                    Text("No scores yet. Play games to climb the board!")
                        .font(.subheadline)
                        .foregroundColor(EZTeachColors.textMutedLight)
                }
                .padding(.top, 40)
            }
        }
    }

    // MARK: - Data Loading
    private func load() {
        isLoading = true
        errorMessage = nil
        let limit = 100

        let useSchool = scopeTab == .mySchool && userSchoolId != nil
        let sid = userSchoolId ?? ""

        if selectedTab == .general {
            if useSchool {
                GameLeaderboardService.shared.fetchSchoolGeneralLeaderboard(schoolId: sid, timeRange: timeRange, limit: limit) { ranks in
                    generalRanks = ranks
                    isLoading = false
                }
            } else {
                GameLeaderboardService.shared.fetchGeneralLeaderboard(timeRange: timeRange, limit: limit) { ranks in
                    generalRanks = ranks
                    isLoading = false
                }
            }
        } else {
            if useSchool {
                GameLeaderboardService.shared.fetchSchoolLeaderboard(schoolId: sid, gameId: selectedGameId, timeRange: timeRange, limit: limit) { ranks in
                    gameRanks = ranks
                    isLoading = false
                }
            } else {
                GameLeaderboardService.shared.fetchLeaderboard(gameId: selectedGameId, timeRange: timeRange, limit: limit) { ranks in
                    gameRanks = ranks
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let rank: LeaderboardRank
    let isCurrentUser: Bool

    /// Build a subtitle like "Lincoln Elementary - 5th Grade"
    private var subtitle: String {
        let parts = [rank.schoolName, rank.grade].filter { !$0.isEmpty }
        return parts.joined(separator: " \u{2022} ")
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
