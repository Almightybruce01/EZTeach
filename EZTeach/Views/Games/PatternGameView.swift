//
//  PatternGameView.swift
//  EZTeach
//
//  Enhanced with difficulty levels, streaks, animations, and celebrations
//

import SwiftUI

struct PatternGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    private let shapes = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill", "star.fill", "heart.fill"]
    private let colors: [Color] = [.cyan, .pink, .green, .orange, .purple, .yellow]
    
    @State private var pattern: [PatternItem] = []
    @State private var options: [PatternItem] = []
    @State private var score = 0
    @State private var round = 0
    @State private var selected: PatternItem? = nil
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var gameOver = false
    @State private var showDifficultyPicker = true
    @State private var difficulty: Difficulty = .easy
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var showStreakBonus = false
    @State private var streakBonusAmount = 0
    @State private var patternScale: CGFloat = 1.0
    @State private var optionScales: [CGFloat] = [1, 1, 1, 1]
    @State private var shakeOffset: CGFloat = 0
    @State private var showConfetti = false
    @State private var revealingPattern = true
    @State private var revealedCount = 0
    @State private var timer: Timer?
    @State private var timeRemaining = 0
    @State private var isPaused = false
    
    struct PatternItem: Identifiable, Equatable {
        let id = UUID()
        let symbol: String
        let color: Color
    }
    
    enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var patternLength: ClosedRange<Int> { 
            switch self { case .easy: return 3...4; case .medium: return 4...5; case .hard: return 5...6 }
        }
        var optionCount: Int { switch self { case .easy: return 3; case .medium: return 4; case .hard: return 5 } }
        var totalRounds: Int { switch self { case .easy: return 8; case .medium: return 10; case .hard: return 12 } }
        var timePerRound: Int { switch self { case .easy: return 15; case .medium: return 12; case .hard: return 10 } }
        var color: Color { switch self { case .easy: return .green; case .medium: return .orange; case .hard: return .red } }
        var useColors: Bool { switch self { case .easy: return false; case .medium: return true; case .hard: return true } }
    }
    
    var body: some View {
        ZStack {
            UnderwaterBackground()
            
            if showConfetti { PatternConfettiView() }
            
            if showDifficultyPicker {
                difficultyPickerView
            } else if gameOver {
                gameOverView
            } else {
                gamePlayView
            }
            
            // Streak bonus popup
            if showStreakBonus {
                VStack {
                    Text("🔥 STREAK BONUS!")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.orange)
                    Text("+\(streakBonusAmount)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.yellow)
                }
                .padding(20)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle(gameTitle)
    }
    
    // MARK: - Difficulty Picker
    private var difficultyPickerView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                Text("Ocean Patterns")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                Text("Find what comes next!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 16) {
                ForEach(Difficulty.allCases, id: \.rawValue) { diff in
                    Button {
                        difficulty = diff
                        showDifficultyPicker = false
                        startGame()
                    } label: {
                        HStack {
                            Image(systemName: diff == .easy ? "1.circle.fill" : diff == .medium ? "2.circle.fill" : "3.circle.fill")
                            Text(diff.rawValue)
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(diff.totalRounds) rounds")
                                    .font(.caption)
                                Text("\(diff.timePerRound)s timer")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
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
        .padding(32)
        .background(Color.black.opacity(0.7))
        .cornerRadius(24)
        .padding()
    }
    
    // MARK: - Gameplay View
    private var gamePlayView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "fish.fill")
                            .foregroundColor(.cyan)
                        Text("Round \(round)/\(difficulty.totalRounds)")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("Streak: \(streak)")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                }
                Spacer()
                
                // Timer
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundColor(timeRemaining <= 5 ? .red : .cyan)
                    Text("\(timeRemaining)s")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(timeRemaining <= 5 ? .red : .white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                
                Spacer()
                
                Text("\(score)")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(round) / CGFloat(difficulty.totalRounds), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
            
            Spacer()
            
            Text("What comes next?")
                .font(.title2.bold())
                .foregroundColor(.white)
                .shadow(color: .cyan, radius: 8)
            
            // Pattern display with animation
            HStack(spacing: 12) {
                ForEach(Array(pattern.enumerated()), id: \.element.id) { index, item in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(difficulty.useColors ? item.color.opacity(0.3) : Color.cyan.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        if index < revealedCount {
                            Image(systemName: item.symbol)
                                .font(.system(size: 32))
                                .foregroundColor(difficulty.useColors ? item.color : .cyan)
                                .shadow(color: (difficulty.useColors ? item.color : .cyan).opacity(0.8), radius: 6)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(difficulty.useColors ? item.color.opacity(0.5) : Color.cyan.opacity(0.5), lineWidth: 2)
                    )
                }
                
                // Question mark for next
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Text("?")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.cyan)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan, lineWidth: 3)
                )
                .scaleEffect(patternScale)
            }
            .padding()
            .background(Color.black.opacity(0.4))
            .cornerRadius(20)
            .offset(x: shakeOffset)
            
            Spacer()
            
            // Options
            if !revealingPattern {
                HStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, opt in
                        Button {
                            selectOption(opt, index: index)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                difficulty.useColors ? opt.color.opacity(0.4) : Color.blue.opacity(0.3),
                                                difficulty.useColors ? opt.color.opacity(0.2) : Color.blue.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Image(systemName: opt.symbol)
                                    .font(.system(size: 36))
                                    .foregroundColor(difficulty.useColors ? opt.color : .white)
                            }
                            .frame(width: 70, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selected == opt ? (isCorrect ? Color.green : Color.red) : 
                                            (difficulty.useColors ? opt.color.opacity(0.6) : Color.cyan.opacity(0.6)),
                                        lineWidth: selected == opt ? 4 : 2
                                    )
                            )
                            .shadow(color: (difficulty.useColors ? opt.color : .cyan).opacity(0.4), radius: 6)
                            .scaleEffect(index < optionScales.count ? optionScales[index] : 1.0)
                        }
                        .disabled(showResult)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    // MARK: - Game Over View
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Image(systemName: starRating >= 3 ? "trophy.fill" : "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(starRating >= 3 ? .yellow : .cyan)
            
            Text(performanceTitle)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.cyan)
            
            // Stars
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < starRating ? "star.fill" : "star")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)
                }
            }
            
            VStack(spacing: 8) {
                Text("Final Score")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text("\(score)")
                    .font(.system(size: 52, weight: .black))
                    .foregroundColor(.white)
                
                if bestStreak > 1 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Best Streak: \(bestStreak)")
                            .foregroundColor(.orange)
                    }
                    .font(.subheadline.bold())
                }
            }
            
            HStack(spacing: 16) {
                Button {
                    showDifficultyPicker = true
                    showConfetti = false
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Difficulty")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(12)
                }
                
                Button {
                    resetGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Play Again")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                }
            }
        }
        .padding(40)
        .background(Color.black.opacity(0.85))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cyan, lineWidth: 3))
        .padding()
    }
    
    // MARK: - Computed Properties
    private var starRating: Int {
        let maxScore = difficulty.totalRounds * 25 // Base 15 + potential streak bonus
        let percentage = Double(score) / Double(maxScore)
        if percentage >= 0.8 { return 3 }
        if percentage >= 0.5 { return 2 }
        if percentage >= 0.2 { return 1 }
        return 0
    }
    
    private var performanceTitle: String {
        switch starRating {
        case 3: return "PATTERN MASTER!"
        case 2: return "Great Work!"
        case 1: return "Good Try!"
        default: return "Keep Practicing!"
        }
    }
    
    // MARK: - Game Logic
    private func startGame() {
        score = 0
        round = 0
        streak = 0
        bestStreak = 0
        gameOver = false
        showConfetti = false
        nextRound()
    }
    
    private func selectOption(_ opt: PatternItem, index: Int) {
        guard selected == nil else { return }
        selected = opt
        showResult = true
        
        let correct = getNextInPattern()
        isCorrect = opt.symbol == correct.symbol && (!difficulty.useColors || opt.color == correct.color)
        
        // Animate selection
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if index < optionScales.count {
                optionScales[index] = 1.2
            }
        }
        
        if isCorrect {
            streak += 1
            bestStreak = max(bestStreak, streak)
            var points = 15
            
            // Streak bonus
            if streak >= 3 {
                let bonus = streak * 5
                points += bonus
                streakBonusAmount = bonus
                withAnimation(.spring()) {
                    showStreakBonus = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { showStreakBonus = false }
                }
            }
            
            score += points
            GameAudioService.shared.playCorrect()
            
            // Success animation
            withAnimation(.spring()) {
                patternScale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring()) { patternScale = 1.0 }
            }
        } else {
            streak = 0
            GameAudioService.shared.playWrong()
            
            // Shake animation
            withAnimation(.default) {
                shakeOffset = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) { shakeOffset = 10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.default) { shakeOffset = 0 }
            }
        }
        
        timer?.invalidate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            nextRound()
        }
    }
    
    private func getNextInPattern() -> PatternItem {
        guard pattern.count >= 2 else { return PatternItem(symbol: shapes[0], color: colors[0]) }
        guard let lastItem = pattern.last else { return PatternItem(symbol: shapes[0], color: colors[0]) }
        let lastSymbol = lastItem.symbol
        let prevSymbol = pattern[pattern.count - 2].symbol
        let idx = shapes.firstIndex(of: lastSymbol) ?? 0
        let prevIdx = shapes.firstIndex(of: prevSymbol) ?? 0
        let step = (idx - prevIdx + shapes.count) % shapes.count
        let nextIdx = (idx + step) % shapes.count
        
        // For colors, also follow a pattern
        let lastColor = lastItem.color
        let colorIdx = colors.firstIndex(of: lastColor) ?? 0
        let nextColorIdx = (colorIdx + 1) % colors.count
        
        return PatternItem(symbol: shapes[nextIdx], color: colors[nextColorIdx])
    }
    
    private func nextRound() {
        round += 1
        selected = nil
        showResult = false
        isCorrect = false
        revealingPattern = true
        revealedCount = 0
        optionScales = Array(repeating: 1.0, count: difficulty.optionCount)
        
        timer?.invalidate()
        
        if round > difficulty.totalRounds {
            gameOver = true
            if starRating >= 2 { showConfetti = true }
            GameLeaderboardService.shared.saveScore(gameId: gameId, score: score)
        } else {
            generatePattern()
            revealPatternAnimated()
        }
    }
    
    private func generatePattern() {
        let len = Int.random(in: difficulty.patternLength)
        let startIdx = Int.random(in: 0..<shapes.count)
        let colorStartIdx = Int.random(in: 0..<colors.count)
        let step = Int.random(in: 1...2)
        
        var p: [PatternItem] = []
        for i in 0..<len {
            let symbolIdx = (startIdx + i * step) % shapes.count
            let colorIdx = (colorStartIdx + i) % colors.count
            p.append(PatternItem(symbol: shapes[symbolIdx], color: colors[colorIdx]))
        }
        pattern = p
        
        // Generate options
        let correct = getNextInPattern()
        var opts = [correct]
        
        while opts.count < difficulty.optionCount {
            let randSymbol = shapes.randomElement()!
            let randColor = colors.randomElement()!
            let item = PatternItem(symbol: randSymbol, color: randColor)
            if !opts.contains(where: { $0.symbol == item.symbol && $0.color == item.color }) {
                opts.append(item)
            }
        }
        options = opts.shuffled()
    }
    
    private func revealPatternAnimated() {
        for i in 0..<pattern.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    revealedCount = i + 1
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(pattern.count) * 0.3 + 0.3) {
            withAnimation {
                revealingPattern = false
            }
            startTimer()
        }
    }
    
    private func startTimer() {
        timeRemaining = difficulty.timePerRound
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                // Time's up - count as wrong
                streak = 0
                GameAudioService.shared.playWrong()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    nextRound()
                }
            }
        }
    }
    
    private func resetGame() {
        showConfetti = false
        startGame()
    }
}

// MARK: - Pattern Confetti
struct PatternConfettiView: View {
    @State private var pieces: [(x: CGFloat, y: CGFloat, rotation: Double, color: Color)] = []
    
    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { i in
                if i < pieces.count {
                    Image(systemName: ["star.fill", "circle.fill", "triangle.fill", "heart.fill"][i % 4])
                        .font(.system(size: CGFloat.random(in: 12...24)))
                        .foregroundColor(pieces[i].color)
                        .position(x: pieces[i].x, y: pieces[i].y)
                        .rotationEffect(.degrees(pieces[i].rotation))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            pieces = (0..<30).map { _ in
                (
                    x: CGFloat.random(in: 0...400),
                    y: -20,
                    rotation: Double.random(in: 0...360),
                    color: [Color.cyan, .pink, .yellow, .green, .orange, .purple].randomElement()!
                )
            }
            
            for i in 0..<pieces.count {
                withAnimation(.easeOut(duration: Double.random(in: 2...4))) {
                    pieces[i].y = 900
                    pieces[i].x += CGFloat.random(in: -100...100)
                    pieces[i].rotation += Double.random(in: 180...720)
                }
            }
        }
    }
}
