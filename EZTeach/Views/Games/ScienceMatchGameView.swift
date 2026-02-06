//
//  ScienceMatchGameView.swift
//  EZTeach
//

import SwiftUI

struct ScienceMatchGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    private var pairs: [(String, String)] {
        switch gameId {
        case "science_atoms": return [("Proton", "+"), ("Neutron", "Neutral"), ("Electron", "-"), ("Nucleus", "Center"), ("Atom", "Smallest")]
        case "science_solar": return [("Sun", "Star"), ("Earth", "Planet"), ("Moon", "Satellite"), ("Mars", "Red Planet"), ("Jupiter", "Giant")]
        case "science_life_cycle": return [("Egg", "First"), ("Caterpillar", "Larva"), ("Chrysalis", "Pupa"), ("Butterfly", "Adult")]
        case "science_weather": return [("Rain", "Water"), ("Snow", "Ice"), ("Cloud", "Vapor"), ("Sun", "Clear"), ("Wind", "Air")]
        case "science_matter": return [("Solid", "Fixed shape"), ("Liquid", "Flows"), ("Gas", "Spreads"), ("Water", "H2O")]
        case "science_food_chain": return [("Plant", "Producer"), ("Herbivore", "Eats plants"), ("Carnivore", "Eats meat"), ("Sun", "Energy")]
        case "science_magnets": return [("North", "South attracts"), ("Poles", "Ends"), ("Iron", "Magnetic"), ("Repel", "Push away")]
        case "science_ecosystem": return [("Habitat", "Home"), ("Predator", "Hunter"), ("Prey", "Hunted"), ("Producer", "Makes food")]
        case "science_simple_machines": return [("Lever", "Lift"), ("Pulley", "Rope"), ("Wheel", "Axle"), ("Incline", "Ramp"), ("Screw", "Spiral")]
        case "science_sound": return [("Vibrate", "Sound"), ("Echo", "Bounce"), ("Loud", "Decibels"), ("Pitch", "High or low"), ("Wave", "Travels")]
        default: return [("Sun", "Star"), ("Water", "H2O"), ("Plant", "Photosynthesis"), ("Atom", "Nucleus"), ("Earth", "Planet"), ("Moon", "Satellite")]
        }
    }
    @State private var cards: [(String, String, Int)] = []
    @State private var flipped: Set<Int> = []
    @State private var matched: Set<Int> = []
    @State private var lastFlipped: Int?
    @State private var moves = 0
    @State private var gameWon = false
    
    var body: some View {
        ZStack {
            SpaceBackground()
            
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("Space Science")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("Moves: \(moves)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.purple)
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                        Button {
                            flipCard(i)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(flipped.contains(i) || matched.contains(i) ? Color.purple.opacity(0.4) : Color.indigo.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.purple.opacity(0.8), lineWidth: 2)
                                    )
                                    .shadow(color: .purple.opacity(0.4), radius: 4)
                                if flipped.contains(i) || matched.contains(i) {
                                    Text(card.0)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "star.fill")
                                        .font(.title3)
                                        .foregroundColor(.purple.opacity(0.5))
                                }
                            }
                            .frame(height: 70)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .onAppear {
                GameAudioService.shared.playStart()
                GameAudioService.shared.speakInstructions("Match the science terms. Tap two cards to find pairs.")
                setupGame()
            }
            .overlay {
                if gameWon {
                    VStack(spacing: 20) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        Text("SPACE EXPLORER!")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.purple)
                        Text("\(moves) moves")
                            .foregroundColor(.white)
                        Button {
                            setupGame()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Launch Again")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                        }
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.purple, lineWidth: 3))
                }
            }
        }
        .navigationTitle(gameTitle)
    }
    
    private func setupGame() {
        gameWon = false
        moves = 0
        flipped = []
        matched = []
        lastFlipped = nil
        var all: [(String, String, Int)] = []
        for (i, p) in pairs.enumerated() {
            all.append((p.0, p.1, i))
            all.append((p.1, p.0, i))
        }
        cards = all.shuffled()
    }
    
    private func flipCard(_ i: Int) {
        guard !flipped.contains(i), !matched.contains(i), flipped.count < 2, i >= 0, i < cards.count else { return }
        flipped.insert(i)
        if let first = lastFlipped, first >= 0, first < cards.count {
            moves += 1
            if cards[first].2 == cards[i].2 {
                matched.insert(first)
                matched.insert(i)
                flipped = []
                lastFlipped = nil
                if matched.count == cards.count {
                    gameWon = true
                    GameLeaderboardService.shared.saveScore(gameId: gameId, score: max(0, 100 - moves))
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
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
