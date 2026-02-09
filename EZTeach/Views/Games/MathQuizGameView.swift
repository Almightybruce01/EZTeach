//
//  MathQuizGameView.swift
//  EZTeach
//
//  Enhanced with animations, streaks, combo bonuses, and celebratory effects
//

import SwiftUI
import FirebaseAuth

struct MathQuizGameView: View {
    let gameId: String
    let gameTitle: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var num1 = 0
    @State private var num2 = 0
    @State private var operatorType: String = "+"
    @State private var userAnswer = ""
    @State private var score = 0
    @State private var questionCount = 0
    @State private var correct = false
    @State private var showResult = false
    @State private var gameOver = false
    @State private var startTime = Date()
    
    // Enhanced animation states
    @State private var streak = 0
    @State private var showStreak = false
    @State private var questionScale: CGFloat = 1.0
    @State private var questionRotation: Double = 0
    @State private var scorePopup = 0
    @State private var showScorePopup = false
    @State private var confettiTrigger = false
    @State private var shakeOffset: CGFloat = 0
    @State private var pulseAnswer = false
    @State private var showHint = false
    @State private var hintUsed = false
    
    private let questionsPerGame = 15
    
    private var accentColor: Color { EZTeachColors.brightTeal }
    
    // Streak bonus multiplier
    private var streakMultiplier: Int {
        switch streak {
        case 0...2: return 1
        case 3...5: return 2
        case 6...9: return 3
        default: return 5
        }
    }
    
    var body: some View {
        ZStack {
            MedievalCastleBackground()
            
            // Confetti overlay
            if confettiTrigger {
                ConfettiView()
            }
            
            VStack(spacing: 24) {
                // Enhanced header with streak indicator
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "function")
                            .font(.title2)
                            .foregroundColor(accentColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gameTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack(spacing: 4) {
                            Text("Medieval Math Quest")
                                .font(.caption)
                                .foregroundColor(.orange)
                            if streak >= 3 {
                                Text("🔥 x\(streakMultiplier)")
                                    .font(.caption.bold())
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        ZStack {
                            Text("Score: \(score)")
                                .font(.system(size: 22, weight: .black, design: .monospaced))
                                .foregroundColor(accentColor)
                            
                            if showScorePopup {
                                Text("+\(scorePopup)")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.yellow)
                                    .offset(y: -30)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        HStack(spacing: 4) {
                            Text("\(questionCount)/\(questionsPerGame)")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(EZTeachColors.textMutedLight)
                            
                            // Streak flames
                            if streak >= 3 {
                                HStack(spacing: 2) {
                                    ForEach(0..<min(streak, 5), id: \.self) { _ in
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(streak >= 5 ? Color.yellow : Color.orange.opacity(0.6), lineWidth: streak >= 5 ? 3 : 2))
                .padding(.horizontal)
                
                // Streak banner
                if showStreak && streak >= 3 {
                    Text("🔥 \(streak) IN A ROW! x\(streakMultiplier) BONUS 🔥")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.8))
                                .shadow(color: .orange, radius: 10)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                if !gameOver {
                    VStack(spacing: 24) {
                        // Animated question display
                        Text("\(num1) \(operatorType) \(num2) = ?")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .orange, radius: 12)
                            .scaleEffect(questionScale)
                            .rotationEffect(.degrees(questionRotation))
                            .offset(x: shakeOffset)
                        
                        // Hint button
                        if !hintUsed && !showResult {
                            Button {
                                showHint = true
                                hintUsed = true
                            } label: {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                    Text("Hint")
                                }
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        
                        if showHint {
                            Text(getHint())
                                .font(.subheadline)
                                .foregroundColor(.yellow.opacity(0.8))
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(12)
                        }
                        
                        TextField("Answer", text: $userAnswer)
                            .keyboardType(.numberPad)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(pulseAnswer ? Color.yellow : Color.orange.opacity(0.8), lineWidth: pulseAnswer ? 4 : 3)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.7)))
                            )
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .scaleEffect(pulseAnswer ? 1.02 : 1.0)
                        
                        if showResult {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.title)
                                    Text(correct ? "Correct!" : "The answer was \(correctAnswer)")
                                }
                                .font(.title2.bold())
                                .foregroundColor(correct ? EZTeachColors.tronGreen : EZTeachColors.tronPink)
                                
                                if correct && streak >= 3 {
                                    Text("+\(10 * streakMultiplier) points (x\(streakMultiplier) bonus!)")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Button {
                            if showResult {
                                nextQuestion()
                            } else {
                                checkAnswer()
                            }
                        } label: {
                            HStack {
                                Image(systemName: showResult ? "arrow.right.circle.fill" : "checkmark.seal.fill")
                                Text(showResult ? "Next Quest" : "Check Answer")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: .orange.opacity(0.5), radius: 8)
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    gameOverView
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle(gameTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            GameAudioService.shared.playStart()
            GameAudioService.shared.speakInstructions("Welcome to \(gameTitle)! Solve the math problems to earn points.")
            newQuestion()
        }
    }
    
    private var correctAnswer: Int {
        switch operatorType {
        case "+": return num1 + num2
        case "-": return num1 - num2
        case "×": return num1 * num2
        case "÷": return num2 != 0 ? num1 / num2 : 0
        default: return num1 + num2
        }
    }
    
    private func getHint() -> String {
        switch operatorType {
        case "+": return "Add the numbers together. \(num1) + \(num2)"
        case "-": return "Subtract the second from the first. \(num1) - \(num2)"
        case "×": return "Multiply the numbers. \(num1) × \(num2)"
        case "÷": return "Divide the first by the second. \(num1) ÷ \(num2)"
        default: return "Think carefully!"
        }
    }
    
    private func newQuestion() {
        userAnswer = ""
        showResult = false
        showHint = false
        hintUsed = false
        
        // Animate question appearance
        questionScale = 0.5
        questionRotation = -10
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            questionScale = 1.0
            questionRotation = 0
        }
        
        switch gameId {
        case "math_addition":
            operatorType = "+"
            num1 = Int.random(in: 1...99)
            num2 = Int.random(in: 1...99)
        case "math_subtraction":
            operatorType = "-"
            num1 = Int.random(in: 20...100)
            num2 = Int.random(in: 1...min(50, num1))
        case "math_multiplication":
            operatorType = "×"
            num1 = Int.random(in: 2...12)
            num2 = Int.random(in: 2...12)
        case "math_division":
            operatorType = "÷"
            num2 = Int.random(in: 2...12)
            let result = Int.random(in: 2...12)
            num1 = num2 * result
        case "math_word_problems", "math_maze", "math_fractions":
            operatorType = "+"
            num1 = Int.random(in: 5...50)
            num2 = Int.random(in: 5...50)
        default:
            operatorType = "+"
            num1 = Int.random(in: 1...50)
            num2 = Int.random(in: 1...50)
        }
    }
    
    private func checkAnswer() {
        guard let ans = Int(userAnswer) else { return }
        correct = ans == correctAnswer
        
        withAnimation(.spring()) {
            if correct {
                let points = 10 * streakMultiplier
                score += points
                streak += 1
                scorePopup = points
                showScorePopup = true
                
                // Pulse effect
                pulseAnswer = true
                
                GameAudioService.shared.playCorrect()
                
                // Confetti for big streaks
                if streak == 5 || streak == 10 {
                    confettiTrigger = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        confettiTrigger = false
                    }
                }
                
                // Show streak banner
                if streak >= 3 {
                    showStreak = true
                }
            } else {
                streak = 0
                showStreak = false
                GameAudioService.shared.playWrong()
                
                // Shake effect
                withAnimation(.default) {
                    shakeOffset = -10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.default) {
                        shakeOffset = 10
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.default) {
                        shakeOffset = 0
                    }
                }
            }
            showResult = true
        }
        
        // Reset animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showScorePopup = false
            pulseAnswer = false
        }
    }
    
    private func nextQuestion() {
        questionCount += 1
        if questionCount >= questionsPerGame {
            endGame()
        } else {
            newQuestion()
        }
    }
    
    private func endGame() {
        gameOver = true
        confettiTrigger = true
        let time = Date().timeIntervalSince(startTime)
        GameLeaderboardService.shared.saveScore(gameId: gameId, score: score, timeSeconds: time)
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            // Crown with animation
            Image(systemName: score >= 100 ? "crown.fill" : "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .shadow(color: .orange, radius: 20)
            
            Text("QUEST COMPLETE!")
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundColor(.orange)
            
            Text("Score: \(score)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            // Performance message
            Text(getPerformanceMessage())
                .font(.subheadline)
                .foregroundColor(.yellow)
                .multilineTextAlignment(.center)
            
            // Stats
            HStack(spacing: 30) {
                VStack {
                    Text("\(questionsPerGame)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Questions")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack {
                    Text("\(Int(Date().timeIntervalSince(startTime)))s")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                VStack {
                    Text("\(score / questionsPerGame)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Avg/Q")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Button {
                score = 0
                questionCount = 0
                gameOver = false
                streak = 0
                confettiTrigger = false
                startTime = Date()
                newQuestion()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("New Quest")
                }
                .font(.headline.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 60)
        }
        .padding(40)
        .background(Color.black.opacity(0.85))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.orange, lineWidth: 3))
    }
    
    private func getPerformanceMessage() -> String {
        let percentage = Double(score) / Double(questionsPerGame * 10) * 100
        switch percentage {
        case 90...100: return "🏆 LEGENDARY! You're a Math Master!"
        case 70..<90: return "⭐ Great job! Keep practicing!"
        case 50..<70: return "👍 Good effort! Try again for a higher score!"
        default: return "💪 Keep practicing! You'll get better!"
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = (0..<50).map { _ in
        ConfettiPiece(
            x: CGFloat.random(in: 0...400),
            y: -20,
            color: [Color.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!,
            rotation: Double.random(in: 0...360),
            size: CGFloat.random(in: 8...16)
        )
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<confettiPieces.count, id: \.self) { i in
                Rectangle()
                    .fill(confettiPieces[i].color)
                    .frame(width: confettiPieces[i].size, height: confettiPieces[i].size * 0.6)
                    .rotationEffect(.degrees(confettiPieces[i].rotation))
                    .position(x: confettiPieces[i].x, y: confettiPieces[i].y)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            for i in 0..<confettiPieces.count {
                withAnimation(.easeOut(duration: Double.random(in: 2...4))) {
                    confettiPieces[i].y = 900
                    confettiPieces[i].x += CGFloat.random(in: -100...100)
                    confettiPieces[i].rotation += Double.random(in: 180...720)
                }
            }
        }
    }
}

struct ConfettiPiece {
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var rotation: Double
    var size: CGFloat
}
