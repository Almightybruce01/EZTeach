//
//  CalmGameView.swift
//  EZTeach
//
//  Learning Support - calming, accessible activities (inclusive design)
//

import SwiftUI

struct CalmGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var matchedPairs: Set<Int> = []
    @State private var cards: [(String, Color, Int)] = []
    @State private var flipped: Set<Int> = []
    @State private var lastFlipped: Int?
    @State private var colors: [Color] = [.blue, .green, .purple, .orange, .pink, .cyan]
    
    private var accentColor: Color { EZTeachColors.tronGreen }
    
    var body: some View {
        ZStack {
            PeacefulMeadowBackground()
            
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.title2)
                        .foregroundColor(.pink)
                    Text("Peaceful Meadow")
                        .font(.headline.bold())
                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.3))
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
                .padding(.horizontal)
                
                Text("Breathe & Match")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 4)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                        Button {
                            flipCard(i)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(flipped.contains(i) || matchedPairs.contains(card.2) ? card.1.opacity(0.4) : Color.white.opacity(0.7))
                                    .frame(height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                    )
                                    .shadow(color: .green.opacity(0.2), radius: 4)
                                if flipped.contains(i) || matchedPairs.contains(card.2) {
                                    Image(systemName: "flower.fill")
                                        .font(.title)
                                        .foregroundColor(card.1)
                                } else {
                                    Image(systemName: "leaf.fill")
                                        .font(.title2)
                                        .foregroundColor(.green.opacity(0.4))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.3))
                .cornerRadius(20)
                .padding(.horizontal)
            }
            .onAppear {
                GameAudioService.shared.playStart()
                GameAudioService.shared.speakInstructions("Match the flowers. Take your time and breathe.")
                setupGame()
            }
        }
        .navigationTitle(gameTitle)
    }
    
    private func setupGame() {
        var all: [(String, Color, Int)] = []
        for (idx, c) in Array(colors.prefix(4)).enumerated() {
            all.append(("", c, idx))
            all.append(("", c, idx))
        }
        cards = all.shuffled()
        flipped = []
        lastFlipped = nil
        matchedPairs = []
    }
    
    private func flipCard(_ i: Int) {
        guard flipped.count < 2, i >= 0, i < cards.count else { return }
        flipped.insert(i)
        if let first = lastFlipped, first >= 0, first < cards.count {
            if cards[first].1 == cards[i].1 {
                matchedPairs.insert(cards[first].2)
                flipped = []
                lastFlipped = nil
                GameAudioService.shared.playCorrect()
                if matchedPairs.count == 4 {
                    GameLeaderboardService.shared.saveScore(gameId: gameId, score: 50)
                }
            } else {
                GameAudioService.shared.playWrong()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    flipped.remove(first)
                    flipped.remove(i)
                    lastFlipped = nil
                }
            }
        } else {
            lastFlipped = i
        }
    }
}
