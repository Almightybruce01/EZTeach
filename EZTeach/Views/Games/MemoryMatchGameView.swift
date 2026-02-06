//
//  MemoryMatchGameView.swift
//  EZTeach
//
//  Enhanced with animations, difficulty levels, timer, and celebratory effects
//

import SwiftUI

struct MemoryMatchGameView: View {
    let gameId: String
    let gameTitle: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [MemoryCard] = []
    @State private var flipped: Set<Int> = []
    @State private var matched: Set<Int> = []
    @State private var lastFlipped: Int?
    @State private var moves = 0
    @State private var gameWon = false
    @State private var startTime = Date()
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var difficulty: Difficulty = .easy
    @State private var showDifficultyPicker = true
    @State private var matchStreak = 0
    @State private var showStreakBonus = false
    @State private var confettiTrigger = false
    @State private var perfectGame = true
    @State private var cardFlipAnimations: [Bool] = []
    
    enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var pairs: Int {
            switch self {
            case .easy: return 6
            case .medium: return 8
            case .hard: return 10
            }
        }
        
        var columns: Int {
            switch self {
            case .easy: return 3
            case .medium: return 4
            case .hard: return 5
            }
        }
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
    }
    
    private var symbols: [String] {
        switch gameId {
        case "puzzle_word_find": return ["textformat.abc", "character.book.closed", "textformat", "pencil", "doc.text", "books.vertical", "text.book.closed", "bookmark.fill", "book.fill", "text.quote"]
        case "puzzle_crossword": return ["square.grid.3x3", "pencil.circle", "number", "textformat.abc", "character.cursor.ibeam", "square.and.pencil", "grid", "tablecells", "rectangle.split.3x3", "checkerboard.rectangle"]
        case "puzzle_logic_grid": return ["square.grid.3x3", "checkmark.square", "xmark.square", "questionmark.square", "plus.square", "minus.square", "divide.square", "multiply.square", "equal.square", "number.square"]
        default: return ["star.fill", "heart.fill", "bolt.fill", "cloud.fill", "moon.fill", "sun.max.fill", "leaf.fill", "flame.fill", "drop.fill", "snowflake", "sparkles", "crown.fill"]
        }
    }
    
    var body: some View {
        ZStack {
            JungleBackground()
            
            if confettiTrigger {
                ConfettiView()
            }
            
            if showDifficultyPicker {
                difficultyPickerView
            } else {
                VStack(spacing: 16) {
                    // Enhanced header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.green)
                                Text("Jungle Match")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            Text(difficulty.rawValue)
                                .font(.caption)
                                .foregroundColor(difficulty.color)
                        }
                        Spacer()
                        
                        // Timer
                        HStack(spacing: 12) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatTime(elapsedTime))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                Text("Time")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(moves)")
                                    .font(.system(size: 20, weight: .black, design: .monospaced))
                                    .foregroundColor(.yellow)
                                Text("Moves")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Streak indicator
                        if matchStreak >= 2 {
                            VStack {
                                Text("🔥")
                                Text("x\(matchStreak)")
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(matchStreak >= 3 ? Color.orange : Color.green.opacity(0.5), lineWidth: matchStreak >= 3 ? 2 : 1)
                    )
                    
                    // Streak bonus popup
                    if showStreakBonus {
                        Text("🔥 \(matchStreak) MATCHES IN A ROW! 🔥")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.orange.opacity(0.8)))
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Card grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: difficulty.columns), spacing: 8) {
                        ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                            EnhancedCardView(
                                symbol: card.symbol,
                                isFlipped: flipped.contains(i) || matched.contains(i),
                                isMatched: matched.contains(i),
                                flipAnimation: i < cardFlipAnimations.count ? cardFlipAnimations[i] : false
                            ) {
                                flipCard(i)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    // Progress indicator
                    HStack {
                        Text("\(matched.count / 2) / \(difficulty.pairs) pairs found")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(LinearGradient(colors: [.green, .yellow], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * CGFloat(matched.count) / CGFloat(cards.count), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .overlay {
            if gameWon {
                gameWonView
            }
        }
    }
    
    private var difficultyPickerView: some View {
        VStack(spacing: 32) {
            Image(systemName: "puzzlepiece.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("JUNGLE MATCH")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text("Choose Difficulty")
                .font(.headline)
                .foregroundColor(.gray)
            
            VStack(spacing: 16) {
                ForEach(Difficulty.allCases, id: \.self) { diff in
                    Button {
                        difficulty = diff
                        showDifficultyPicker = false
                        setupGame()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(diff.rawValue)
                                    .font(.headline.bold())
                                Text("\(diff.pairs) pairs")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: diff == .easy ? "1.circle.fill" : diff == .medium ? "2.circle.fill" : "3.circle.fill")
                                .font(.title2)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(diff.color.opacity(0.8))
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
        .background(Color.black.opacity(0.85))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.green, lineWidth: 3))
        .padding()
    }
    
    private var gameWonView: some View {
        VStack(spacing: 20) {
            // Trophy or stars based on performance
            if perfectGame && moves <= difficulty.pairs + 2 {
                HStack {
                    Image(systemName: "star.fill")
                    Image(systemName: "crown.fill")
                        .font(.system(size: 50))
                    Image(systemName: "star.fill")
                }
                .foregroundColor(.yellow)
            } else {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
            }
            
            Text("Jungle Master!")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.green)
            
            // Stats
            HStack(spacing: 30) {
                VStack {
                    Text("\(moves)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Moves")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack {
                    Text(formatTime(elapsedTime))
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack {
                    Text(getStars())
                        .font(.title)
                    Text("Rating")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text(getPerformanceMessage())
                .font(.subheadline)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button {
                    showDifficultyPicker = true
                    gameWon = false
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Difficulty")
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button {
                    setupGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Play Again")
                    }
                    .font(.headline)
                    .padding()
                    .background(LinearGradient(colors: [.green, .yellow], startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
            }
        }
        .padding(40)
        .background(Color.black.opacity(0.9))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.green, lineWidth: 3))
        .padding()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func getStars() -> String {
        let movesPerPair = Double(moves) / Double(difficulty.pairs)
        if movesPerPair <= 1.2 { return "⭐⭐⭐" }
        if movesPerPair <= 1.8 { return "⭐⭐" }
        return "⭐"
    }
    
    private func getPerformanceMessage() -> String {
        let movesPerPair = Double(moves) / Double(difficulty.pairs)
        if perfectGame && movesPerPair <= 1.2 { return "🏆 PERFECT! Amazing memory!" }
        if movesPerPair <= 1.5 { return "🌟 Excellent! You have great memory!" }
        if movesPerPair <= 2.0 { return "👍 Good job! Keep practicing!" }
        return "💪 Nice try! You'll do better next time!"
    }
    
    private func setupGame() {
        gameWon = false
        moves = 0
        flipped = []
        matched = []
        lastFlipped = nil
        matchStreak = 0
        perfectGame = true
        elapsedTime = 0
        confettiTrigger = false
        
        let picked = Array(symbols.shuffled().prefix(difficulty.pairs))
        let pairs = (picked + picked).shuffled()
        cards = pairs.map { MemoryCard(symbol: $0) }
        cardFlipAnimations = Array(repeating: false, count: cards.count)
        
        // Start timer
        timer?.invalidate()
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime = Int(Date().timeIntervalSince(startTime))
        }
        
        GameAudioService.shared.playStart()
        GameAudioService.shared.speakInstructions("Find matching pairs. Tap two cards with the same picture.")
    }
    
    private func flipCard(_ i: Int) {
        guard !flipped.contains(i), !matched.contains(i), flipped.count < 2, i >= 0, i < cards.count else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            flipped.insert(i)
            if i < cardFlipAnimations.count {
                cardFlipAnimations[i] = true
            }
        }
        
        GameAudioService.shared.playTap()
        
        if let first = lastFlipped, first >= 0, first < cards.count {
            moves += 1
            if cards[first].symbol == cards[i].symbol {
                // Match found!
                matchStreak += 1
                
                withAnimation(.spring()) {
                    matched.insert(first)
                    matched.insert(i)
                }
                
                flipped = []
                lastFlipped = nil
                GameAudioService.shared.playCorrect()
                
                // Show streak bonus
                if matchStreak >= 2 {
                    withAnimation {
                        showStreakBonus = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            showStreakBonus = false
                        }
                    }
                }
                
                // Check for win
                if matched.count == cards.count {
                    timer?.invalidate()
                    let score = max(0, 100 - moves + (perfectGame ? 20 : 0))
                    GameLeaderboardService.shared.saveScore(gameId: gameId, score: score, timeSeconds: Double(elapsedTime))
                    confettiTrigger = true
                    gameWon = true
                }
            } else {
                // No match
                matchStreak = 0
                perfectGame = false
                GameAudioService.shared.playWrong()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring()) {
                        flipped.remove(first)
                        flipped.remove(i)
                        if first < cardFlipAnimations.count { cardFlipAnimations[first] = false }
                        if i < cardFlipAnimations.count { cardFlipAnimations[i] = false }
                    }
                    lastFlipped = nil
                }
            }
        } else {
            lastFlipped = i
        }
    }
}

struct MemoryCard {
    let symbol: String
}

struct EnhancedCardView: View {
    let symbol: String
    let isFlipped: Bool
    let isMatched: Bool
    let flipAnimation: Bool
    let action: () -> Void
    
    @State private var rotation: Double = 0
    @State private var matchScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Card back
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isMatched
                            ? Color.yellow.opacity(0.3)
                            : (isFlipped ? Color.green.opacity(0.4) : Color.brown.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isMatched ? Color.yellow : Color.green.opacity(0.8),
                                lineWidth: isMatched ? 3 : 2
                            )
                    )
                    .shadow(color: isMatched ? .yellow.opacity(0.5) : .black.opacity(0.3), radius: isMatched ? 8 : 4, y: 2)
                
                // Card content
                if isFlipped || isMatched {
                    Image(systemName: symbol)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isMatched ? .yellow : .white)
                        .shadow(color: isMatched ? .yellow : .clear, radius: 4)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.title2)
                            .foregroundColor(.green.opacity(0.7))
                        Text("?")
                            .font(.caption.bold())
                            .foregroundColor(.green.opacity(0.5))
                    }
                }
            }
            .aspectRatio(0.75, contentMode: .fit)
            .scaleEffect(matchScale)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .onChange(of: isFlipped) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                rotation = newValue ? 180 : 0
            }
        }
        .onChange(of: isMatched) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    matchScale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring()) {
                        matchScale = 1.0
                    }
                }
            }
        }
    }
}
