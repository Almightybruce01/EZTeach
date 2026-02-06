//
//  PatternGameView.swift
//  EZTeach
//

import SwiftUI

struct PatternGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    private let shapes = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill"]
    @State private var pattern: [String] = []
    @State private var options: [String] = []
    @State private var score = 0
    @State private var round = 0
    @State private var selected: String? = nil
    @State private var showResult = false
    @State private var gameOver = false
    
    var body: some View {
        ZStack {
            UnderwaterBackground()
            
            VStack(spacing: 32) {
                HStack {
                    Image(systemName: "fish.fill")
                        .foregroundColor(.cyan)
                    Text("Ocean Patterns")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("Score: \(score)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Text("What comes next?")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(color: .cyan, radius: 8)
                
                if !gameOver {
                    HStack(spacing: 16) {
                        ForEach(Array(pattern.enumerated()), id: \.offset) { _, s in
                            Image(systemName: s)
                                .font(.system(size: 36))
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.8), radius: 6)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(16)
                    
                    HStack(spacing: 16) {
                        ForEach(options, id: \.self) { opt in
                            Button {
                                if selected == nil {
                                    selected = opt
                                    showResult = true
                                    let nextCorrect = getNextInPattern() == opt
                                    if nextCorrect {
                                        score += 15
                                        GameAudioService.shared.playCorrect()
                                    } else {
                                        GameAudioService.shared.playWrong()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        nextRound()
                                    }
                                }
                            } label: {
                                Image(systemName: opt)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.3)))
                                    )
                                    .shadow(color: .cyan.opacity(0.4), radius: 6)
                            }
                            .disabled(showResult)
                        }
                    }
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.cyan)
                        Text("OCEAN EXPLORER!")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.cyan)
                        Text("Score: \(score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Button {
                            resetGame()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Dive Again")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                        }
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cyan, lineWidth: 3))
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle(gameTitle)
        .onAppear { nextRound() }
    }
    
    private func getNextInPattern() -> String {
        guard pattern.count >= 2 else { return shapes[0] }
        let last = pattern[pattern.count - 1]
        let prev = pattern[pattern.count - 2]
        let idx = shapes.firstIndex(of: last) ?? 0
        let prevIdx = shapes.firstIndex(of: prev) ?? 0
        let nextIdx = (idx + (idx - prevIdx) + shapes.count) % shapes.count
        return shapes[nextIdx]
    }
    
    private func nextRound() {
        round += 1
        selected = nil
        showResult = false
        if round > 8 {
            gameOver = true
            GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
        } else {
            let len = Int.random(in: 3...4)
            let start = Int.random(in: 0..<shapes.count)
            var p: [String] = []
            for i in 0..<len {
                p.append(shapes[(start + i) % shapes.count])
            }
            pattern = p
            let next = getNextInPattern()
            options = [next] + shapes.filter { $0 != next }.shuffled().prefix(2).map { String($0) }
            options = Array(Set(options))
            while options.count < 3 {
                options.append(shapes.randomElement()!)
            }
            options.shuffle()
        }
    }
    
    private func resetGame() {
        score = 0
        round = 0
        gameOver = false
        nextRound()
    }
}
