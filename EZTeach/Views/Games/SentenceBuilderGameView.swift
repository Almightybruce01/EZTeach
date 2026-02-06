//
//  SentenceBuilderGameView.swift
//  EZTeach
//
//  Build correct sentences from shuffled word tiles.
//

import SwiftUI

struct SentenceBuilderGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    private static let sentencesByLevel: [[String]] = [
        ["The cat sat.", "I see a dog.", "She runs fast.", "We play ball.", "It is big.", "He has a hat.", "Mom is kind.", "The sun is hot.", "I like red.", "We go home."],
        ["The dog runs in the park.", "She reads a good book.", "We eat lunch at noon.", "The bird flew away.", "My friend likes pizza.", "The moon is bright tonight.", "Kids play in the sand.", "I have a blue bike.", "The cat sleeps on the rug.", "We saw a big rainbow."],
        ["The little dog ran across the street.", "Sarah found her lost book under the bed.", "Every morning the birds sing in the trees.", "We went to the store to buy some milk.", "The teacher read an interesting story to the class."]
    ]
    
    private var sentences: [String] {
        Self.sentencesByLevel.flatMap { $0 }
    }
    
    @State private var correctSentence = ""
    @State private var shuffledWords: [String] = []
    @State private var selectedWords: [String] = []
    @State private var usedIndices: Set<Int> = []
    @State private var score = 0
    @State private var round = 0
    @State private var showResult = false
    @State private var correct = false
    @State private var gameOver = false
    
    private let roundsPerGame = 10
    
    private var accentColor: Color { EZTeachColors.softPurple }
    
    var body: some View {
        ZStack {
            KnightsKingdomBackground()
            
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("Knight's Quest")
                        .font(.headline.bold())
                        .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                    Spacer()
                    HStack(spacing: 16) {
                        Text("Score: \(score)")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                        Text("\(round)/\(roundsPerGame)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .red.opacity(0.2), radius: 6, y: 2)
                .padding(.horizontal)
                
                if !gameOver {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "scroll.fill")
                                .foregroundColor(.brown)
                            Text("Forge the Royal Decree")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.15))
                            Image(systemName: "scroll.fill")
                                .foregroundColor(.brown)
                        }
                        
                        Text(selectedWords.joined(separator: " "))
                            .font(.title2.bold())
                            .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.05))
                            .frame(minHeight: 50)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.95, green: 0.9, blue: 0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.brown.opacity(0.6), lineWidth: 2)
                                    )
                            )
                            .padding(.horizontal, 24)
                        
                        Text("Tap words in order")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        wordPool
                        
                        if showResult {
                            HStack(spacing: 8) {
                                Image(systemName: correct ? "crown.fill" : "xmark.shield.fill")
                                    .foregroundColor(correct ? .yellow : .red)
                                Text(correct ? "Victory!" : "Try Again, Knight!")
                                    .font(.headline)
                                    .foregroundColor(correct ? Color(red: 0.4, green: 0.3, blue: 0.1) : .red)
                            }
                        }
                        
                        Button {
                            clearSelection()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Clear")
                            }
                            .font(.caption)
                            .foregroundColor(.brown)
                        }
                    }
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("NOBLE WORDSMITH!")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(Color(red: 0.4, green: 0.25, blue: 0.1))
                        Text("Score: \(score)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                        Button {
                            resetGame()
                        } label: {
                            HStack {
                                Image(systemName: "flag.fill")
                                Text("New Quest")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [.red, Color(red: 0.6, green: 0.1, blue: 0.1)], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                        }
                    }
                    .padding(40)
                    .background(Color(red: 0.95, green: 0.9, blue: 0.8))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.red, lineWidth: 3))
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle(gameTitle)
        .onAppear {
            GameAudioService.shared.playStart()
            GameAudioService.shared.speakInstructions("Tap the words in the correct order to build the sentence.")
            nextRound()
        }
    }
    
    private var wordPool: some View {
        WrappingHStack(spacing: 10) {
            ForEach(Array(shuffledWords.enumerated()), id: \.offset) { idx, word in
                if !usedIndices.contains(idx) {
                    Button {
                        trySelectWord(word, at: idx)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "seal.fill")
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.5))
                            Text(word)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.95, green: 0.9, blue: 0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.brown.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: .brown.opacity(0.15), radius: 4, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func trySelectWord(_ word: String, at idx: Int) {
        let correctOrder = correctSentence.components(separatedBy: " ").filter { !$0.isEmpty }
        let nextExpected = correctOrder[safe: selectedWords.count]
        guard word == nextExpected else {
            GameAudioService.shared.playWrong()
            return
        }
        selectedWords.append(word)
        usedIndices.insert(idx)
        if selectedWords.joined(separator: " ") == correctSentence {
            checkAnswer()
        }
    }
    
    private func clearSelection() {
        selectedWords = []
        usedIndices = []
        showResult = false
    }
    
    private func checkAnswer() {
        let built = selectedWords.joined(separator: " ")
        correct = built == correctSentence
        if correct {
            score += 15
            GameAudioService.shared.playCorrect()
            showResult = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                nextRound()
            }
        } else {
            GameAudioService.shared.playWrong()
            showResult = true
        }
    }
    
    private func nextRound() {
        round += 1
        selectedWords = []
        usedIndices = []
        showResult = false
        if round > roundsPerGame {
            gameOver = true
            GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
        } else {
            correctSentence = sentences.randomElement() ?? "The cat sat."
            shuffledWords = correctSentence.components(separatedBy: " ").filter { !$0.isEmpty }.shuffled()
        }
    }
    
    private func resetGame() {
        score = 0
        round = 0
        gameOver = false
        nextRound()
    }
}

struct WrappingHStack: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let (_, size) = arrange(proposal: proposal, subviews: subviews)
        return size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (origins, _) = arrange(proposal: proposal, subviews: subviews)
        for (i, o) in origins.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + o.x, y: bounds.minY + o.y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ([CGPoint], CGSize) {
        let maxW = proposal.width ?? 400
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        var origins: [CGPoint] = []
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxW && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            origins.append(CGPoint(x: x, y: y))
            rowH = max(rowH, s.height)
            x += s.width + spacing
        }
        return (origins, CGSize(width: maxW, height: y + rowH))
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
